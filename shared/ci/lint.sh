#!/usr/bin/env bash
set -euo pipefail

SERVICE="$1"

echo "[LINT] Running lint for ${SERVICE}"

case "${SERVICE}" in
  user-service)
    pushd user-service > /dev/null
    npm install
    npx eslint . || exit 1
    popd > /dev/null
    ;;
  transaction-service)
    pushd transaction-service > /dev/null
    python3 -m pip install -r requirements.txt
    flake8 . || pylint . || exit 1
    popd > /dev/null
    ;;
  notification-service)
    pushd notification-service > /dev/null
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
    golangci-lint run ./... || exit 1
    popd > /dev/null
    ;;
  *)
    echo "[LINT] Unknown service: ${SERVICE}"
    exit 1
    ;;
esac
