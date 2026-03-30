#!/usr/bin/env bash
set -euo pipefail

SERVICE="$1"

echo "[TEST] Running tests for ${SERVICE}"

case "${SERVICE}" in
  user-service)
    pushd user-service > /dev/null
    npm install
    npm test -- --ci --reporters=junit --reporter-options "outputFile=reports/junit/junit.xml"
    popd > /dev/null
    ;;
  transaction-service)
    pushd transaction-service > /dev/null
    python -m pip install -r requirements.txt
    pytest --junitxml=reports/junit/junit.xml --cov=. --cov-report=xml
    popd > /dev/null
    ;;
  notification-service)
    pushd notification-service > /dev/null
    go test ./... -v
    # אפשר להוסיף דוחות עם go-junit-report
    popd > /dev/null
    ;;
  *)
    echo "[TEST] Unknown service: ${SERVICE}"
    exit 1
    ;;
esac
