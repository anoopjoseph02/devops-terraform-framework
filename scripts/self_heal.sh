#!/bin/bash
# scripts/self_heal.sh
# Enhanced self-healing remediation script.
# Called by terraform-cd.yml when terraform apply fails.
# Attempts intelligent recovery based on the error type.

set -euo pipefail

LOGFILE="reports/self_heal_log.jsonl"
mkdir -p reports

log_event() {
    local action="$1"
    local outcome="$2"
    echo "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\
\"run_id\":\"${GITHUB_RUN_ID:-local}\",\
\"action\":\"$action\",\"outcome\":\"$outcome\"}" >> "$LOGFILE"
}

echo "=== Self-healing initiated ==="

# Capture the error from terraform apply
ERROR_OUTPUT=$(terraform apply -auto-approve 2>&1 || true)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo "Terraform apply succeeded on retry."
    log_event "retry_apply" "success"
    exit 0
fi

echo "Error output:"
echo "$ERROR_OUTPUT"

# ---- Strategy 1: Resource already exists -> import it ----
if echo "$ERROR_OUTPUT" | grep -qE "already exists|ResourceGroupAlreadyExists|StorageAccountAlreadyTaken"; then
    echo "[HEAL] Detected 'already exists' conflict. Attempting import..."
    RESOURCE=$(echo "$ERROR_OUTPUT" | grep -oP 'azurerm_\w+\.\w+' | head -1 || true)
    if [ -n "$RESOURCE" ]; then
        RESOURCE_ID=$(echo "$ERROR_OUTPUT" | grep -oP '(?<=ID: ")[^"]+' | head -1 || true)
        if [ -n "$RESOURCE_ID" ]; then
            terraform import "$RESOURCE" "$RESOURCE_ID" || true
            terraform apply -auto-approve
            log_event "import_and_apply" "success"
            exit 0
        fi
    fi
    log_event "import_and_apply" "failed_no_id"
fi

# ---- Strategy 2: State lock -> force unlock ----
if echo "$ERROR_OUTPUT" | grep -q "state blob is already locked\|Error locking state"; then
    echo "[HEAL] Detected state lock. Attempting force-unlock..."
    LOCK_ID=$(echo "$ERROR_OUTPUT" | grep -oP '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -1 || true)
    if [ -n "$LOCK_ID" ]; then
        terraform force-unlock -force "$LOCK_ID" || true
        sleep 5
        terraform apply -auto-approve
        log_event "force_unlock_and_apply" "success"
        exit 0
    fi
    log_event "force_unlock" "failed_no_lock_id"
fi

# ---- Strategy 3: Provider registration needed ----
if echo "$ERROR_OUTPUT" | grep -q "not registered\|SubscriptionNotRegistered"; then
    echo "[HEAL] Detected unregistered provider. Attempting registration..."
    PROVIDER=$(echo "$ERROR_OUTPUT" | grep -oP 'Microsoft\.\w+' | head -1 || true)
    if [ -n "$PROVIDER" ]; then
        az provider register --namespace "$PROVIDER" --wait || true
        terraform apply -auto-approve
        log_event "provider_register_and_apply" "success"
        exit 0
    fi
    log_event "provider_register" "failed_no_provider"
fi

# ---- Strategy 4: Quota exceeded -> raise GitHub issue ----
if echo "$ERROR_OUTPUT" | grep -qE "QuotaExceeded|CoreQuota|capacity"; then
    echo "[HEAL] Quota exceeded. Cannot auto-remediate. Creating GitHub issue..."
    gh issue create \
        --title "Azure quota exceeded — run ${GITHUB_RUN_ID:-local}" \
        --body "$(echo "$ERROR_OUTPUT" | head -30)" \
        --label "infrastructure,quota" || true
    log_event "quota_exceeded_issue_created" "manual_intervention_required"
    exit 1
fi

# ---- Strategy 5: General failure -> create GitHub issue and fail ----
echo "[HEAL] No automatic remediation available. Creating GitHub issue..."
gh issue create \
    --title "Terraform apply failed — run ${GITHUB_RUN_ID:-local}" \
    --body "$(echo "$ERROR_OUTPUT" | head -50)" \
    --label "infrastructure,failure" || true
log_event "unhandled_error_issue_created" "failed"
exit 1
