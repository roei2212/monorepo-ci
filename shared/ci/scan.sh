#!/usr/bin/env bash
set -euo pipefail

SERVICE="$1"

echo "[SCAN] Running security scan for ${SERVICE}"

# סריקת סודות ברמת הריפו (אפשר להריץ פעם אחת מחוץ ללופ)
echo "[SCAN] Secrets scan (gitleaks)"
gitleaks detect --no-git -v || true

case "${SERVICE}" in
  user-service)
    pushd user-service > /dev/null
    npm install
    npm audit --audit-level=high || true
    popd > /dev/null
    ;;
  transaction-service)
    pushd transaction-service > /dev/null
    python -m pip install -r requirements.txt
    bandit -r . || true
    popd > /dev/null
    ;;
  notification-service)
    pushd notification-service > /dev/null
    go vet ./... || true
    popd > /dev/null
    ;;
  *)
    echo "[SCAN] Unknown service: ${SERVICE}"
    exit 1
    ;;
esac
