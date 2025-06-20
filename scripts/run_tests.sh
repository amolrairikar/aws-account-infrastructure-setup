#!/bin/bash

set -e

SOURCE_DIRECTORY=""
OMIT_LIST=""

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --source)
            SOURCE_DIRECTORY="$2"
            shift 2
            ;;
        --omit)
            OMIT_LIST="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 --source <source_directory> [--omit <comma_separated_paths_to_omit_from_test_coverage>]"
            exit 1
            ;;
    esac
done

if [ -z "$SOURCE_DIRECTORY" ]; then
    echo "Error: --source is required"
    exit 1
fi

OMIT_ARGS=""
if [ -n "$OMIT_LIST" ]; then
    IFS=',' read -ra OMIT_ARRAY <<< "$OMIT_LIST"
    for ITEM in "${OMIT_ARRAY[@]}"; do
        OMIT_ARGS+="--omit=$ITEM "
    done
fi

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
pipenv run coverage report $OMIT_ARGS --fail-under=80
echo "Test execution complete!"