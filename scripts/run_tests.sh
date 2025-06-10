#!/bin/bash

# Run unit tests
echo "Running unit tests..."
if ! pipenv run coverage run --source=layers -m unittest discover -s tests then;
    echo "Unit tests failed."
    exit 1
fi
echo "Unit tests passed."

# Generate coverage report
echo "Generating coverage report..."
pipenv run coverage report --omit="tests/*" --fail-under=80

echo "Test execution complete!"