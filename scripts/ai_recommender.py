#!/usr/bin/env python3
"""
AI Infrastructure Recommender
==============================
Combines a deterministic rule engine with GPT-4o LLM inference to produce
infrastructure configuration recommendations BEFORE Terraform code generation.

Input : input/infra.json  (or path passed as argv[1])
Output: input/infra_optimised.json   (enriched spec, consumed by generator)
        reports/recommendations.md   (human-readable report for dissertation)

Usage:
    python scripts/ai_recommender.py [input/infra.json]
"""

import copy
import datetime
import json
import os
import pathlib
import sys

import openai

client = openai.OpenAI(api_key=os.environ["OPENAI_API_KEY"])


RULES = {
    "storage": {
        "replication_by_env": {
            "prod":    "GRS",
            "staging": "ZRS",
            "dev":     "LRS",
        },
        "tier_by_access_pattern": {
            "archive": "Cool",
            "active":  "Hot",
            "default": "Hot",
        },
        "min_tls_version": "TLS1_2",
        "allow_blob_public_access": False,
    },
    "aks": {
        "node_count_by_env": {"prod": 3, "staging": 2, "dev": 1},
        "enable_autoscaler":  True,
        "network_plugin":     "azure",
        "vm_size_by_workload": {
            "cpu_intensive":    "Standard_D8s_v3",
            "memory_intensive": "Standard_E8s_v3",
            "general":          "Standard_D4s_v3",
        },
    },
    "key_vault": {
        "soft_delete_retention_days": 90,
        "purge_protection_enabled":   True,
        "sku_name":                   "standard",
    },
}

CONFIDENCE_THRESHOLD = 0.75


def rule_based_recommendations(spec: dict) -> list[dict]:
    """
    Apply deterministic rules derived from Azure Well-Architected Framework.
    Returns a list of recommendation dicts.
    """
    recs = []
    env = spec.get("environment", "dev").lower()

    for res in spec.get("resources", []):
        rtype = res.get("type", "")
        name  = res.get("name", "unnamed")

        # --- Storage account rules ---
        if rtype == "storage_account":
            suggested_rep = RULES["storage"]["replication_by_env"].get(env, "LRS")
            if res.get("replication_type", "LRS") != suggested_rep:
                recs.append({
                    "resource":    name,
                    "field":       "replication_type",
                    "current":     res.get("replication_type", "LRS"),
                    "recommended": suggested_rep,
                    "reason":      f"Azure WAF: {env} env requires {suggested_rep} for durability SLA",
                    "source":      "rule_engine",
                    "confidence":  0.95,
                })
            if res.get("min_tls_version", "") != "TLS1_2":
                recs.append({
                    "resource":    name,
                    "field":       "min_tls_version",
                    "current":     res.get("min_tls_version", "TLS1_0"),
                    "recommended": "TLS1_2",
                    "reason":      "CIS Azure Benchmark 3.15: enforce TLS 1.2 minimum",
                    "source":      "rule_engine",
                    "confidence":  0.99,
                })
            if res.get("allow_blob_public_access", True):
                recs.append({
                    "resource":    name,
                    "field":       "allow_blob_public_access",
                    "current":     True,
                    "recommended": False,
                    "reason":      "CIS Azure Benchmark 3.7: disable public blob access",
                    "source":      "rule_engine",
                    "confidence":  0.99,
                })

        # --- AKS cluster rules ---
        if rtype == "aks_cluster":
            if not res.get("enable_auto_scaling", False):
                recs.append({
                    "resource":    name,
                    "field":       "enable_auto_scaling",
                    "current":     False,
                    "recommended": True,
                    "reason":      "Autoscaling reduces over-provisioning by 20-35% (Garg & Sharma 2023)",
                    "source":      "rule_engine",
                    "confidence":  0.88,
                })
            if res.get("network_plugin", "") != "azure":
                recs.append({
                    "resource":    name,
                    "field":       "network_plugin",
                    "current":     res.get("network_plugin", "kubenet"),
                    "recommended": "azure",
                    "reason":      "Azure CNI required for AKS advanced networking features",
                    "source":      "rule_engine",
                    "confidence":  0.90,
                })

        # --- Key Vault rules ---
        if rtype == "key_vault":
            if not res.get("purge_protection_enabled", False):
                recs.append({
                    "resource":    name,
                    "field":       "purge_protection_enabled",
                    "current":     False,
                    "recommended": True,
                    "reason":      "CIS Azure Benchmark 8.5: enable purge protection",
                    "source":      "rule_engine",
                    "confidence":  0.97,
                })

    return recs


# ---------------------------------------------------------------------------
# LLM engine — contextual, cost-aware recommendations via GPT-4o
# ---------------------------------------------------------------------------
def llm_recommendations(spec: dict) -> list[dict]:
    """
    Ask GPT-4o to review the spec and return additional recommendations
    not covered by the deterministic rule engine.
    """
    prompt = (
        "You are a senior Azure cloud architect reviewing an infrastructure specification. "
        "Identify configuration improvements for cost, security, and reliability that are "
        "NOT already covered by standard CIS benchmark rules. "
        "Return ONLY a JSON object with key 'recommendations' containing an array. "
        "Each item must have: resource (string), field (string), current (any), "
        "recommended (any), reason (string), confidence (float 0-1). "
        "Do not include markdown, explanations, or any text outside the JSON.\n\n"
        f"Specification:\n{json.dumps(spec, indent=2)}"
    )

    try:
        resp = client.chat.completions.create(
            model="gpt-4o",
            response_format={"type": "json_object"},
            messages=[
                {"role": "system", "content": "You return infrastructure recommendations as strict JSON."},
                {"role": "user",   "content": prompt},
            ],
            max_tokens=1500,
            temperature=0.2,
        )
        raw  = resp.choices[0].message.content
        data = json.loads(raw)
        recs = data.get("recommendations", [])
        for r in recs:
            r["source"] = "llm"
        return recs
    except Exception as exc:
        print(f"[WARN] LLM call failed ({exc}); using rule engine only.", file=sys.stderr)
        return []


# ---------------------------------------------------------------------------
# Apply accepted recommendations back to the spec
# ---------------------------------------------------------------------------
def apply_recommendations(spec: dict, recs: list[dict]) -> dict:
    optimised = copy.deepcopy(spec)
    applied   = 0
    for rec in recs:
        if float(rec.get("confidence", 0)) < CONFIDENCE_THRESHOLD:
            continue
        for res in optimised.get("resources", []):
            if res.get("name") == rec.get("resource"):
                res[rec["field"]] = rec["recommended"]
                applied += 1
    print(f"Applied {applied} / {len(recs)} recommendations (confidence >= {CONFIDENCE_THRESHOLD})")
    return optimised


# ---------------------------------------------------------------------------
# Write markdown report
# ---------------------------------------------------------------------------
def write_report(recs: list[dict], path: str):
    pathlib.Path(path).parent.mkdir(parents=True, exist_ok=True)
    lines = [
        f"# AI Infrastructure Recommendations — {datetime.date.today()}\n",
        f"Total recommendations: {len(recs)}\n",
        "| Resource | Field | Current | Recommended | Confidence | Source | Reason |",
        "|----------|-------|---------|-------------|------------|--------|--------|",
    ]
    for r in recs:
        conf = float(r.get("confidence", 0))
        applied = "YES" if conf >= CONFIDENCE_THRESHOLD else "no (low confidence)"
        lines.append(
            f"| {r.get('resource')} | `{r.get('field')}` "
            f"| `{r.get('current')}` | `{r.get('recommended')}` "
            f"| {conf:.0%} | {r.get('source','?')} | {r.get('reason','')} |"
        )
    lines += [
        "",
        f"> Recommendations with confidence ≥ {CONFIDENCE_THRESHOLD:.0%} are auto-applied.",
        f"> See `input/infra_optimised.json` for the updated specification.",
    ]
    pathlib.Path(path).write_text("\n".join(lines))
    print(f"Report written to {path}")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    spec_path = sys.argv[1] if len(sys.argv) > 1 else "input/infra.json"
    spec      = json.loads(pathlib.Path(spec_path).read_text())

    print("Running rule engine...")
    rule_recs = rule_based_recommendations(spec)

    print("Running LLM engine...")
    llm_recs  = llm_recommendations(spec)

    all_recs  = rule_recs + llm_recs
    print(f"Total recommendations generated: {len(all_recs)}")

    optimised = apply_recommendations(spec, all_recs)

    pathlib.Path("input/infra_optimised.json").write_text(
        json.dumps(optimised, indent=2)
    )
    print("Optimised spec written to input/infra_optimised.json")

    write_report(all_recs, "reports/recommendations.md")
