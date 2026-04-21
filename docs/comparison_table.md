# Comparison with Existing Solutions

This table directly addresses the dissertation reviewer's requirement for
"Comparison with Existing Solutions."

---

## Feature comparison matrix

| Capability | This project | Terraform Cloud | Pulumi AI | Env0 | Scalr | Spacelift |
|---|---|---|---|---|---|---|
| **AI/LLM code generation** | GPT-4o, JSON-mode | None | GPT-4 (beta) | None | None | None |
| **Natural language → IaC** | JSON/YAML spec | None | Partial | None | None | None |
| **AI resource recommendations** | Rule engine + LLM hybrid | None | None | None | None | None |
| **Anomaly detection** | Isolation Forest (sklearn) | None | None | None | None | None |
| **Predictive scaling** | Linear regression (24h CPU) | None | None | None | None | None |
| **Automated remediation** | Self-heal script (4 strategies) | Manual | None | None | Manual | None |
| **Drift detection** | Scheduled GitHub Action | Paid plan | None | None | None | None |
| **Security gate** | Checkov (HARD fail on HIGH/CRITICAL) | Sentinel (policy-as-code) | None | OPA | Checkov (soft) | OPA |
| **Cost estimation** | Infracost (CI gate) | Native (paid) | None | Infracost | Infracost | None |
| **Input validation** | JSON Schema (jsonschema) | None | None | None | None | None |
| **Evaluation metrics** | deploy_metrics.jsonl + report | None | None | None | None | None |
| **Open source** | Yes (GitHub Actions) | No (SaaS) | Partial | No | No | No |
| **Self-hosted** | Yes | No | Yes | No | Yes | No |
| **Cloud support** | Azure (extensible) | Multi-cloud | Multi-cloud | Multi-cloud | Multi-cloud | Multi-cloud |
| **Pricing** | Free (OpenAI API cost only) | Free + paid tiers | Free + paid | Paid | Paid | Paid |

---

## Quantitative comparison

Based on Sokolowski et al. (2022) and Adiputra et al. (2022):

| Metric | Manual baseline | Terraform Cloud | This project (target) |
|--------|----------------|-----------------|----------------------|
| Provisioning time | 120 min | ~45 min | ≤ 12 min |
| Error rate | 18% | ~8% | ≤ 5% |
| Security issues / deploy | 3.2 | ~1.5 (Sentinel) | ≤ 0 HIGH |
| Cost estimate accuracy | 60% | ~75% (native) | ≥ 85% (Infracost) |

---

## Key differentiator narrative

No existing commercial or open-source tool combines:

1. **LLM-driven IaC generation** with structured JSON-mode output (deterministic, repeatable)
2. **AI resource recommendations** from a hybrid rule + LLM engine applied *before* code generation
3. **ML-based anomaly detection** on deployment history using Isolation Forest
4. **Predictive scaling** using time-series forecasting on live Azure Monitor CPU data
5. **Automated remediation** with four distinct strategies keyed to error type
6. **Measurable evaluation framework** producing dissertation-grade KPI reports

Terraform Cloud is the closest competitor by feature breadth, but it is proprietary,
requires paid plans for drift detection and cost estimation, and has no AI layer.
Pulumi AI has LLM generation but no anomaly detection, predictive scaling, or evaluation.

This project is the only open-source solution covering all five AI capability dimensions
identified in the dissertation reviewer's feedback.
