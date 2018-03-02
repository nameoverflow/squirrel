#!/bin/bash

hash=$(git rev-parse HEAD)
sed -i '.bak' 's/git-commit-hash/'"$hash"'/g' travis-deploy-package.json
