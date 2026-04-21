#!/bin/bash
# scripts/capture_metrics.sh
# Appends one JSON record to reports/deploy_metrics.jsonl after every CD run.
# Called by terraform-cd.yml after terraform apply (with if: always()).

set -euo pipefail
mkdir -p reports

DURATION="${DEPLOY_DURATION_SECONDS:-0}"
PLAN_FILE="terraform/plan.txt"
STATUS="${JOB_STATUS:-unknown}"

ADDED=0
CHANGED=0
DESTROYED=0
PLAN_SIZE=0

if [ -f "$PLAN_FILE" ]; then
    ADDED=$(grep -c "will be created" "$PLAN_FILE" 2>/dev/null || true)
    CHANGED=$(grep -c "will be updated in-place\|will be replaced" "$PLAN_FILE" 2>/dev/null || true)
    DESTROYED=$(grep -c "will be destroyed" "$PLAN_FILE" 2>/dev/null || true)
    PLAN_SIZE=$(wc -c < "$PLAN_FILE" || true)
fi

RECORD="{
  \"run_id\":             \"${GITHUB_RUN_ID:-$(date +%s)}\",
  \"timestamp\":          \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",
  \"duration_seconds\":   $DURATION,
  \"resources_added\":    $ADDED,
  \"resources_changed\":  $CHANGED,
  \"resources_destroyed\": $DESTROYED,
  \"plan_size_bytes\":    $PLAN_SIZE,
  \"status\":             \"$STATUS\",
  \"branch\":             \"${GITHUB_REF_NAME:-unknown}\"
}"

echo "$RECORD" | tr -d '\n' >> reports/deploy_metrics.jsonl
echo "" >> reports/deploy_metrics.jsonl

echo "Metrics captured for run ${GITHUB_RUN_ID:-local}"

# Commit back to repo
git config user.name  "github-actions"
git config user.email "actions@github.com"
git add reports/deploy_metrics.jsonl
git commit -m "ci: append deployment metrics [skip ci]" || echo "Nothing to commit"
git push || echo "Push failed (non-blocking)"
