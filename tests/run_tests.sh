#!/bin/sh
set -e

# Run extensive tests before versioning as per copilot instructions
echo "--------------------------------------------------"
echo "Running Local Tests..."
echo "--------------------------------------------------"
cd test-project/local
devenv shell -- "uv --version && nixfmt --version"
cd ../..

echo "--------------------------------------------------"
echo "Running Remote Tests..."
echo "--------------------------------------------------"
cd test-project/remote
devenv shell -- "uv --version && nixfmt --version"
cd ../..

echo "--------------------------------------------------"
echo "Tests Passed!"
echo "--------------------------------------------------"
