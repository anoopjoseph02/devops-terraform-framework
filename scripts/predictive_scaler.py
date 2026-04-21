#!/usr/bin/env python3
"""
Predictive Scaler
==================
Forecasts AKS node count based on historical CPU utilisation trends using
linear regression. Updates input/infra.json with the recommended node count
before Terraform code generation runs.

When Azure Monitor credentials are available, it fetches real 7-day CPU data.
In dev/test environments (no Azure credentials), it uses synthetic seasonal data.

References:
    Garg, S. & Sharma, R. (2023). Predictive Auto-Scaling in Kubernetes Using
    Time-Series Forecasting. Cluster Computing, 26, pp. 2341–2358.
    DOI:10.1007/s10586-022-03777-2
"""

import copy
import datetime
import json
import os
import pathlib
import subprocess
import sys


# ---------------------------------------------------------------------------
# Azure Monitor data fetch
# ---------------------------------------------------------------------------
def fetch_cpu_from_azure(resource_group: str, cluster_name: str, days: int = 7) -> list[float]:
    """
    Fetch hourly CPU utilisation from Azure Monitor via the az CLI.
    Returns a list of float percentages (empty list on failure).
    """
    subscription = os.environ.get("ARM_SUBSCRIPTION_ID", "")
    if not subscription:
        return []

    resource_id = (
        f"/subscriptions/{subscription}"
        f"/resourceGroups/{resource_group}"
        f"/providers/Microsoft.ContainerService"
        f"/managedClusters/{cluster_name}"
    )
    start = (datetime.datetime.utcnow() - datetime.timedelta(days=days)).isoformat()

    cmd = [
        "az", "monitor", "metrics", "list",
        "--resource", resource_id,
        "--metric", "node_cpu_usage_percentage",
        "--interval", "PT1H",
        "--start-time", start,
        "--output", "json",
    ]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        if result.returncode != 0:
            print(f"[WARN] az CLI returned error: {result.stderr[:200]}")
            return []
        data = json.loads(result.stdout)
        values = [
            p["average"]
            for series in data.get("value", [])
            for ts in series.get("timeseries", [])
            for p in ts.get("data", [])
            if p.get("average") is not None
        ]
        print(f"[INFO] Fetched {len(values)} CPU data points from Azure Monitor.")
        return values
    except Exception as exc:
        print(f"[WARN] Azure Monitor fetch failed: {exc}")
        return []


def synthetic_cpu_data(hours: int = 168) -> list[float]:
    """
    Generate synthetic seasonal CPU data for dev/test environments.
    Simulates a 24-h cycle with gentle upward trend.
    """
    import math
    return [
        30
        + 15 * math.sin(2 * math.pi * i / 24)          # daily cycle
        + 0.05 * i                                        # slow upward trend
        + (hash(str(i)) % 7 - 3)                         # deterministic noise
        for i in range(hours)
    ]


# ---------------------------------------------------------------------------
# Forecasting
# ---------------------------------------------------------------------------
def linear_forecast(values: list[float], horizon_hours: int = 24) -> float:
    """
    Fit a linear regression over historical CPU values and extrapolate
    'horizon_hours' steps ahead.
    Returns the predicted mean CPU percentage.
    """
    n = len(values)
    if n < 2:
        return values[0] if values else 50.0

    # Least-squares via normal equations (no numpy required)
    x_mean = (n - 1) / 2
    y_mean = sum(values) / n
    ss_xx  = sum((i - x_mean) ** 2 for i in range(n))
    ss_xy  = sum((i - x_mean) * (v - y_mean) for i, v in enumerate(values))
    slope  = ss_xy / ss_xx if ss_xx else 0
    intercept = y_mean - slope * x_mean
    forecast = intercept + slope * (n + horizon_hours)
    return max(0.0, min(100.0, forecast))


# ---------------------------------------------------------------------------
# Scaling decision
# ---------------------------------------------------------------------------
def cpu_to_node_count(cpu_forecast: float, current_nodes: int) -> tuple[int, str]:
    """
    Map forecasted CPU % to a recommended node count.
    Returns (recommended_count, rationale).
    """
    if cpu_forecast > 80:
        count = min(current_nodes + 2, 10)
        why   = f"Forecast CPU {cpu_forecast:.1f}% > 80%; scale up aggressively"
    elif cpu_forecast > 65:
        count = min(current_nodes + 1, 10)
        why   = f"Forecast CPU {cpu_forecast:.1f}% > 65%; scale up conservatively"
    elif cpu_forecast < 25:
        count = max(current_nodes - 1, 2)
        why   = f"Forecast CPU {cpu_forecast:.1f}% < 25%; scale down to save cost"
    else:
        count = current_nodes
        why   = f"Forecast CPU {cpu_forecast:.1f}% within normal range; no change"
    return count, why


# ---------------------------------------------------------------------------
# Spec update
# ---------------------------------------------------------------------------
def update_aks_in_spec(spec: dict, recommended: int, forecast: float, why: str) -> dict:
    updated = copy.deepcopy(spec)
    for res in updated.get("resources", []):
        if res.get("type") == "aks_cluster":
            old = res.get("node_count", recommended)
            res["node_count"] = recommended
            res["_scaling_metadata"] = {
                "predicted_cpu_pct_24h": round(forecast, 2),
                "previous_node_count":   old,
                "recommended_node_count": recommended,
                "rationale": why,
                "generated_at": datetime.datetime.utcnow().isoformat(),
            }
            print(f"[INFO] AKS '{res['name']}': {old} → {recommended} nodes. {why}")
    return updated


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    spec_path = sys.argv[1] if len(sys.argv) > 1 else "input/infra.json"
    spec      = json.loads(pathlib.Path(spec_path).read_text())

    aks = next(
        (r for r in spec.get("resources", []) if r.get("type") == "aks_cluster"),
        None,
    )
    if not aks:
        print("[INFO] No AKS cluster in spec. Skipping predictive scaling.")
        sys.exit(0)

    rg            = spec.get("resource_group", "")
    cluster_name  = aks.get("name", "")
    current_nodes = int(aks.get("node_count", 3))

    metrics = fetch_cpu_from_azure(rg, cluster_name)
    if not metrics:
        print("[INFO] Using synthetic CPU data (dev/test mode).")
        metrics = synthetic_cpu_data()

    forecast              = linear_forecast(metrics, horizon_hours=24)
    recommended, rationale = cpu_to_node_count(forecast, current_nodes)
    updated_spec          = update_aks_in_spec(spec, recommended, forecast, rationale)

    pathlib.Path(spec_path).write_text(json.dumps(updated_spec, indent=2))
    print(f"[OK] Spec updated. Forecasted CPU: {forecast:.1f}% → {recommended} nodes recommended.")
