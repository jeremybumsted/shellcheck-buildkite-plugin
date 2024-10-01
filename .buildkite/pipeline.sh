#!/bin/bash

set -euo pipefail

SHELLCHECK_BASE_PATH="shellcheck"

# We want to check to see if this build originates from a fork PR;
# If BUILDKITE_PULL_REQUEST is not "false", then the value of
# BUILDKITE_PULL_REQUEST_REPO can be used to capture the URL of the fork
# so that the agent running "selftest" can get the correct commit.
if [ "${BUILDKITE_PULL_REQUEST}" != "false" ]; then
    echo "This should be the repo: ${BUILDKITE_PULL_REQUEST_REPO}"
    SHELLCHECK_BASE_PATH="https://${BUILDKITE_PULL_REQUEST_REPO}"
fi

if [ -z "${SHELLCHECK_BASE_PATH}" ]; then
    echo "🚨 no base path found for Shellcheck plugin"
    exit 1
fi

cat <<- YAML | buildkite-agent pipeline upload
steps:
  - label: run bats tests
    plugins:
      - plugin-tester#v1.1.1: ~

  - label: run shellcheck
    plugins:
      - shellcheck#v1.3.0:
          files:
            - hooks/*
            - buildkite/*.sh

  - label: ":sparkles: lint"
    plugins:
      - plugin-linter#v3.3.0:
          id: shellcheck

  - label: selftest
    plugins:
      - $SHELLCHECK_BASE_PATH#${BUILDKITE_COMMIT}:
          files:
            - hooks/*
            - buildkite/*.sh

YAML