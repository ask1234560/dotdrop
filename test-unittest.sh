#!/bin/sh
# author: deadc0de6 (https://github.com/deadc0de6)
# Copyright (c) 2023, deadc0de6

# stop on first error
set -e

workers=${DOTDROP_WORKERS}
if [ ! -z ${workers} ]; then
  unset DOTDROP_WORKERS
  echo "DISABLE workers"
fi

# execute tests with coverage
if [ -z ${GITHUB_WORKFLOW} ]; then
  ## local
  export COVERAGE_FILE=
  # do not print debugs when running tests (faster)
  # tests
  PYTHONPATH="dotdrop" nose2 --with-coverage --coverage dotdrop --plugin=nose2.plugins.mp -N0
else
  ## CI/CD
  export COVERAGE_FILE="${cur}/.coverage"
  # tests
  PYTHONPATH="dotdrop" nose2 --with-coverage --coverage dotdrop
fi
#PYTHONPATH="dotdrop" python3 -m pytest tests