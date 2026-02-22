#!/usr/bin/env bash
set -euo pipefail

rm -rf dist
mkdir dist

cp src/launch/request_launch_lambda.py dist/
cp src/mission/control_mission_lambda.py dist/
cp collector.yaml dist/

cd dist
zip -r lambdas.zip ./*

echo "Built dist/lambdas.zip"
