#!/usr/bin/env python3
"""
Deployment Anomaly Detector
============================
Uses Isolation Forest (sklearn) to detect anomalous deployment patterns
in the historical run log. Falls back to z-score when sklearn is unavailable
or history is insufficient.

Input : reports/deploy_metrics.jsonl   (one JSON object per line, auto-appended by CD)
Output: reports/anomaly_report.md
Exit  : 0 = no anomaly in latest run
        1 = anomaly detected in latest run (fails the CI/CD job)

References:
    Liu, F.T., Ting, K.M., Zhou, Z.H. (2008). Isolation Forest.
    IEEE ICDM 2008. DOI:10.1109/ICDM.2008.17

    Soldani, J. et al. (2021). Anomaly Detection for Microservices.
    Journal of Systems and Software, 182. DOI:10.1016/j.jss.2021.111061
"""

import datetime
import json
import pathlib
import sys


FEATURE_KEYS = [
    "duration_seconds",
    "resources_added",
    "resources_changed",
    "resources_destroyed",
    "plan_size_bytes",
]

MIN_HISTORY = 10       # minimum records before ML model is used
CONTAMINATION = 0.05   # expected anomaly rate (5%)
ZSCORE_THRESHOLD = 2.5


def load_metrics(path: str = "reports/deploy_metrics.jsonl") -> list[dict]:
    p = pathlib.Path(path)
    if not p.exists():
        print(f"[INFO] No metrics file found at {path}. Nothing to analyse.")
        return []
    records = [json.loads(line) for line in p.read_text().splitlines() if line.strip()]
    print(f"[INFO] Loaded {len(records)} deployment records.")
    return records


def extract_features(records: list[dict]) -> list[list[float]]:
    return [
        [float(r.get(k, 0)) for k in FEATURE_KEYS]
        for r in records
    ]


def detect_isolation_forest(features: list[list[float]]) -> tuple[list[bool], list[float]]:
    from sklearn.ensemble import IsolationForest
    import numpy as np
    X      = np.array(features)
    model  = IsolationForest(contamination=CONTAMINATION, random_state=42, n_estimators=100)
    preds  = model.fit_predict(X)          # -1 = anomaly, 1 = normal
    scores = model.score_samples(X)        # lower = more anomalous
    return [p == -1 for p in preds], scores.tolist()


def detect_zscore(records: list[dict]) -> tuple[list[bool], list[float]]:
    """Fallback: z-score on deployment duration only."""
    import math
    durations = [float(r.get("duration_seconds", 0)) for r in records]
    mean = sum(durations) / len(durations)
    variance = sum((d - mean) ** 2 for d in durations) / len(durations)
    std = math.sqrt(variance) or 1.0
    zscores = [(d - mean) / std for d in durations]
    return [abs(z) > ZSCORE_THRESHOLD for z in zscores], zscores


def detect_anomalies(records: list[dict]) -> tuple[list[bool], list[float], str]:
    if len(records) < MIN_HISTORY:
        print(f"[INFO] Only {len(records)} records (need {MIN_HISTORY}). Using z-score fallback.")
        flags, scores = detect_zscore(records)
        return flags, scores, "zscore"
    try:
        features = extract_features(records)
        flags, scores = detect_isolation_forest(features)
        return flags, scores, "isolation_forest"
    except ImportError:
        print("[WARN] scikit-learn not available. Falling back to z-score.")
        flags, scores = detect_zscore(records)
        return flags, scores, "zscore"


def write_report(
    records:   list[dict],
    anomalies: list[bool],
    scores:    list[float],
    method:    str,
    path:      str = "reports/anomaly_report.md",
):
    pathlib.Path(path).parent.mkdir(parents=True, exist_ok=True)
    flagged = [
        (r, s)
        for r, is_anom, s in zip(records, anomalies, scores)
        if is_anom
    ]

    lines = [
        f"# Deployment Anomaly Report — {datetime.date.today()}",
        "",
        f"**Detection method**: {method}",
        f"**Runs analysed**: {len(records)}",
        f"**Anomalies detected**: {len(flagged)}",
        "",
    ]

    if flagged:
        lines += [
            "## Flagged deployments",
            "",
            "| Run ID | Timestamp | Duration (s) | +Added / ~Changed / -Destroyed | Score |",
            "|--------|-----------|-------------|-------------------------------|-------|",
        ]
        for r, s in flagged:
            lines.append(
                f"| `{r.get('run_id', '?')}` "
                f"| {r.get('timestamp', '?')} "
                f"| {r.get('duration_seconds', '?')} "
                f"| +{r.get('resources_added', 0)} / "
                f"~{r.get('resources_changed', 0)} / "
                f"-{r.get('resources_destroyed', 0)} "
                f"| `{s:.4f}` |"
            )
        lines += [
            "",
            "## Recommended actions",
            "",
            "1. Review the flagged run's Terraform plan for unexpected resource changes.",
            "2. Check Azure Activity Log for concurrent manual modifications.",
            "3. If safe, re-run `terraform apply` after confirming the plan.",
            "4. If not safe, run `terraform state rm <resource>` and investigate.",
        ]
    else:
        lines.append("No anomalies detected in this batch. All deployments within normal parameters.")

    pathlib.Path(path).write_text("\n".join(lines))
    print(f"Anomaly report written to {path}")


if __name__ == "__main__":
    records = load_metrics()

    if not records:
        print("No records to analyse. Exiting cleanly.")
        sys.exit(0)

    anomalies, scores, method = detect_anomalies(records)
    write_report(records, anomalies, scores, method)

    # Only fail the pipeline if the LATEST run is anomalous
    if anomalies and anomalies[-1]:
        latest = records[-1]
        print(
            f"\n[ANOMALY] Latest run {latest.get('run_id', '?')} is anomalous "
            f"(score={scores[-1]:.4f}). Review reports/anomaly_report.md"
        )
        sys.exit(1)

    print("[OK] Latest deployment is within normal parameters.")
    sys.exit(0)
