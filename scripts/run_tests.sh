#!/bin/bash

set -e

SOURCE_DIRECTORY=$1

# TODO: Add files to omit

echo "Running unit tests..."
if ! pipenv run coverage run --source=$SOURCE_DIRECTORY -m unittest discover -s tests/unit -v; then
    echo "Unit tests failed!"
    exit 1
fi
mv .coverage .coverage.unit

COMPONENT_TEST_DIR="tests/component"

if [ -d "$COMPONENT_TEST_DIR" ] && [ "$(find "$COMPONENT_TEST_DIR" -type f -name "*.py" | wc -l)" -gt 0 ]; then
    echo "Running component tests..."
    if ! pipenv run coverage run --source=$SOURCE_DIRECTORY -m unittest discover -s "$COMPONENT_TEST_DIR" -v; then
        echo "Component tests failed!"
        exit 1
    fi
    mv .coverage .coverage.component
    echo "Combining coverage data..."
    pipenv run coverage combine .coverage.unit .coverage.component
else
    echo "No component tests found. Skipping..."
    cp .coverage.unit .coverage
fi

echo "Generating coverage report..."
pipenv run coverage report --fail-under=80

echo "Test execution complete!"