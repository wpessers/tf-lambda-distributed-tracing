# Python OTel Lambda Layer Implementation Plan

## Overview

Replace the Node.js Lambda functions and OpenTelemetry instrumentation layer with Python equivalents on a separate `python` branch. The two Lambda functions (launch request + mission control) will be rewritten in Python using stdlib-only dependencies (`urllib.request`, `logging`) and the runtime-provided `boto3`. The Terraform module and layer definitions will be updated for the Python 3.13 runtime and the `opentelemetry-python` instrumentation layer (built from source). All language-agnostic infrastructure (API Gateway, DynamoDB, collector layer, test script) stays unchanged.

## Current State Analysis

The project deploys two Node.js Lambda functions behind API Gateway REST APIs, instrumented with OpenTelemetry via Lambda layers. The architecture uses a reusable Terraform module (`infrastructure/modules/otel-lambda/`) that wires up a Lambda function with an instrumentation layer and a collector layer.

Node.js-specific aspects that must change:
- Lambda source code: TypeScript handlers bundled with esbuild (`src/launch/requestLaunchLambda.ts`, `src/mission/controlMissionLambda.ts`)
- Build pipeline: `package.json` with esbuild + npm
- Terraform module: `runtime = "nodejs22.x"`, `AWS_LAMBDA_EXEC_WRAPPER = "/opt/otel-handler"`, `OTEL_NODE_ENABLED_INSTRUMENTATIONS` env var
- Layer definition: `opentelemetry-nodejs-layer.zip`, default ARN `opentelemetry-nodejs-0_18_0`

### Key Discoveries:
- `infrastructure/modules/otel-lambda/main.tf:32` — runtime hardcoded to `"nodejs22.x"`
- `infrastructure/modules/otel-lambda/main.tf:47` — wrapper path hardcoded to `"/opt/otel-handler"`
- `infrastructure/modules/otel-lambda/main.tf:56` — `OTEL_NODE_ENABLED_INSTRUMENTATIONS` set conditionally
- `infrastructure/modules/otel-lambda/variables.tf:30` — default instrumentation layer ARN points to Node.js layer
- Python OTel layer uses `/opt/otel-instrument` (different from all other languages which use `/opt/otel-handler`)
- Python uses the inverse instrumentation model: everything is enabled by default, use `OTEL_PYTHON_DISABLED_INSTRUMENTATIONS` to turn things off
- By default only botocore and HTTP instrumentations are active (cold-start optimization); set `OTEL_PYTHON_DISABLED_INSTRUMENTATIONS` to `none` to enable all
- Python deployment zip needs zero external dependencies: `urllib.request` is stdlib, `boto3` is pre-installed in the Lambda runtime, `logging` is stdlib

## Desired End State

A `python` branch where:
1. Both Lambda functions are Python 3.13, using `urllib.request`, `boto3`, and `logging`
2. The OTel Python instrumentation layer is built from source and checked in as `opentelemetry-python-layer.zip`
3. The Terraform module uses Python runtime, wrapper path, and env vars
4. `terraform apply` deploys successfully and traces flow end-to-end through the collector to the backend
5. The same dual-layer pattern is preserved: launch Lambda uses the public layer ARN, mission Lambda uses the custom-built layer

### Verification:
- `terraform apply` completes without errors
- `curl -X POST .../launch -d '{"rocketName":"test","destination":"Mars"}'` returns 200 with `{"rocketName":"test","destination":"Mars","status":"LAUNCHING"}`
- Traces appear in the observability backend showing spans for: Lambda invocation, urllib HTTP call, boto3 DynamoDB operations

## What We're NOT Doing

- Restructuring the repo to support multiple languages simultaneously (each language lives on its own branch)
- Parameterizing the Terraform module to accept runtime/wrapper as variables (we modify in-place)
- Adding tests or CI
- Changing the API Gateway definitions, DynamoDB schema, or collector configuration
- Using any external Python dependencies (no `requests`, no `structlog`)

## Implementation Approach

Work on a `python` branch created from `main`. Modify files in-place — delete Node.js source/config, add Python equivalents. The Terraform module is edited directly (not parameterized) since each language branch owns its own copy.

---

## Phase 1: Branch Setup, Python Source Code, and Build Script

### Overview
Create the `python` branch, write the two Python Lambda handlers, create a build script, and clean up Node.js artifacts.

### Changes Required:

#### 1.1 Create the branch

```bash
git checkout -b python
```

#### 1.2 Delete Node.js-specific files

Remove these files (they will be replaced or are no longer needed):

- `src/launch/requestLaunchLambda.ts`
- `src/mission/controlMissionLambda.ts`
- `package.json`
- `tsconfig.json`
- `package-lock.json`
- `opentelemetry-nodejs-layer.zip`

```bash
git rm src/launch/requestLaunchLambda.ts src/mission/controlMissionLambda.ts \
  package.json tsconfig.json package-lock.json opentelemetry-nodejs-layer.zip
```

#### 1.3 Create the Launch Lambda handler

**File**: `src/launch/request_launch_lambda.py`

```python
import json
import logging
import os
import urllib.request

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event, context):
    logger.info("Incoming launch request")

    request_body = event.get("body")
    if not request_body:
        raise ValueError("Missing launch request")

    body = json.loads(request_body)
    rocket_name = body["rocketName"]
    destination = body["destination"]

    mission_control_base_url = os.environ["MISSION_CONTROL_BASE_URL"]
    req = urllib.request.Request(
        f"{mission_control_base_url}/mission/{rocket_name}", method="GET"
    )
    with urllib.request.urlopen(req) as response:
        mission = json.loads(response.read().decode())

    status = "UNDERWAY" if mission["progress"] > 0 else "LAUNCHING"

    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "rocketName": rocket_name,
                "destination": destination,
                "status": status,
            }
        ),
    }
```

This is a direct port of `requestLaunchLambda.ts`:
- `pino` → stdlib `logging` (auto-instrumented by OTel Python layer)
- `fetch()` → `urllib.request` (auto-instrumented by OTel Python layer)
- Same JSON request/response shape (matches `src/launch/openapi.json`)

#### 1.4 Create the Mission Control Lambda handler

**File**: `src/mission/control_mission_lambda.py`

```python
import json

import boto3


def handler(event, context):
    rocket_name = event["pathParameters"]["rocketName"]
    if not rocket_name:
        raise ValueError("No rocket name specified")

    client = boto3.client("dynamodb", region_name="eu-central-1")

    response = client.get_item(
        TableName="Mission", Key={"RocketName": {"S": rocket_name}}
    )

    if "Item" not in response:
        client.put_item(
            TableName="Mission",
            Item={
                "RocketName": {"S": rocket_name},
                "Destination": {"S": "Mars"},
                "Progress": {"N": "0"},
            },
        )

    return {
        "statusCode": 200,
        "body": json.dumps({"destination": "Mars", "progress": 10}),
    }
```

This is a direct port of `controlMissionLambda.ts`:
- `@aws-sdk/client-dynamodb` → `boto3` (pre-installed in Lambda runtime, auto-instrumented by OTel Python layer via botocore instrumentation)
- Same DynamoDB operations: get_item then conditional put_item
- Same JSON response shape (matches `src/mission/openapi.json`)

#### 1.5 Create the build script

**File**: `build.sh`

```bash
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
```

```bash
chmod +x build.sh
```

The Python deployment package has zero external dependencies, so the build is just copying files and zipping. The zip structure will be:
```
lambdas.zip
├── request_launch_lambda.py
├── control_mission_lambda.py
└── collector.yaml
```

#### 1.6 Update `.gitignore`

**File**: `.gitignore`

Replace the Node.js-specific entries with Python equivalents:

```gitignore
__pycache__/
*.pyc

dist/

**/.terraform*
*.tfstate*

collector.yaml
```

Removed:
- `node_modules/` (no longer relevant)
- `**/@types/` (TypeScript artifact, no longer relevant)

Added:
- `__pycache__/` and `*.pyc` (Python bytecode cache)

### Success Criteria:

#### Automated Verification:
- [x] Branch `python` exists: `git branch --list python`
- [x] Node.js files are deleted: `! test -f package.json && ! test -f tsconfig.json && ! test -f src/launch/requestLaunchLambda.ts`
- [x] Python files exist: `test -f src/launch/request_launch_lambda.py && test -f src/mission/control_mission_lambda.py`
- [x] Build script runs without errors: `bash build.sh`
- [x] Zip contains expected files: `unzip -l dist/lambdas.zip` shows `request_launch_lambda.py`, `control_mission_lambda.py`, `collector.yaml`
- [x] Python syntax is valid: `python3 -c "import py_compile; py_compile.compile('src/launch/request_launch_lambda.py', doraise=True)"` and same for mission

#### Manual Verification:
- [ ] No Node.js artifacts remain in the working tree (no `.ts`, no `package.json`, no `node_modules/`)

---

## Phase 2: Terraform Changes

### Overview
Update the Terraform module, layer definitions, and Lambda configurations for Python 3.13 runtime with the OTel Python instrumentation layer.

### Changes Required:

#### 2.1 Update the OTel Lambda module

**File**: `infrastructure/modules/otel-lambda/main.tf`

Changes:
1. Line 32: `runtime` from `"nodejs22.x"` to `"python3.13"`
2. Line 47: `AWS_LAMBDA_EXEC_WRAPPER` from `"/opt/otel-handler"` to `"/opt/otel-instrument"`
3. Line 56: Replace `OTEL_NODE_ENABLED_INSTRUMENTATIONS` with `OTEL_PYTHON_DISABLED_INSTRUMENTATIONS`

The `runtime` line becomes:

```hcl
  runtime       = "python3.13"
```

The full `environment` block becomes:

```hcl
  environment {
    variables = merge(
      {
        AWS_LAMBDA_EXEC_WRAPPER                     = "/opt/otel-instrument"
        OTEL_TRACES_EXPORTER                        = "otlp"
        OTEL_METRICS_EXPORTER                       = "none"
        OTEL_LOGS_EXPORTER                          = "none"
        OTEL_LOG_LEVEL                              = "DEBUG"
        OTEL_TRACES_SAMPLER                         = "always_on"
        OPENTELEMETRY_COLLECTOR_CONFIG_URI           = "/var/task/collector.yaml"
        OTEL_LAMBDA_DISABLE_AWS_CONTEXT_PROPAGATION = true
      },
      var.disabled_instrumentations != null ? { OTEL_PYTHON_DISABLED_INSTRUMENTATIONS = var.disabled_instrumentations } : {},
      var.extra_env_vars
    )
  }
```

#### 2.2 Update module variables

**File**: `infrastructure/modules/otel-lambda/variables.tf`

Changes:
1. Rename `enabled_instrumentations` → `disabled_instrumentations`, update description
2. Update `instrumentation_layer_arn` default to the public Python layer ARN

Replace lines 16-20:

```hcl
variable "disabled_instrumentations" {
  description = "Comma-separated list of Python instrumentations to disable (set to 'none' to enable all)"
  type        = string
  default     = null
}
```

Replace lines 28-31:

```hcl
variable "instrumentation_layer_arn" {
  type    = string
  default = "arn:aws:lambda:eu-central-1:184161586896:layer:opentelemetry-python-0_17_0:1"
}
```

The `collector_layer_arn` default stays unchanged (collector is language-agnostic).

#### 2.3 Update layer definitions

**File**: `infrastructure/layer.tf`

Replace the Node.js instrumentation layer with a Python one. Update the collector layer's `compatible_runtimes` metadata.

```hcl
resource "aws_lambda_layer_version" "python_layer" {
  layer_name               = "otel-python-layer-test"
  filename                 = "../opentelemetry-python-layer.zip"
  compatible_runtimes      = ["python3.13"]
  compatible_architectures = ["arm64"]
}

resource "aws_lambda_layer_version" "collector_layer" {
  layer_name               = "otel-collector-layer-test"
  filename                 = "../opentelemetry-collector-layer-arm64.zip"
  compatible_runtimes      = ["python3.13"]
  compatible_architectures = ["arm64"]
}
```

#### 2.4 Update Launch Lambda configuration

**File**: `infrastructure/lambda-launch.tf`

Changes:
1. Line 6: `handler` → `request_launch_lambda.handler` (Python module.function format, files at zip root)
2. Line 8: Remove `enabled_instrumentations` (Python auto-discovers urllib and logging)

The module block becomes:

```hcl
module "request_launch" {
  source = "./modules/otel-lambda"

  name     = "request-launch"
  filename = "../dist/lambdas.zip"
  handler  = "request_launch_lambda.handler"

  extra_env_vars = {
    MISSION_CONTROL_BASE_URL = aws_api_gateway_stage.mission_test.invoke_url
  }

  collector_layer_arn = aws_lambda_layer_version.collector_layer.arn
}
```

The launch Lambda continues to use the **default public layer ARN** (now pointing to `opentelemetry-python-0_17_0`), preserving the dual-layer testing pattern.

The rest of the file (IAM policy, role policy, Lambda permission) stays unchanged.

#### 2.5 Update Mission Lambda configuration

**File**: `infrastructure/lambda-mission.tf`

Changes:
1. Line 6: `handler` → `control_mission_lambda.handler`
2. Line 8: Remove `enabled_instrumentations`
3. Line 10: Update layer reference from `nodejs_layer` → `python_layer`

The module block becomes:

```hcl
module "control_mission" {
  source = "./modules/otel-lambda"

  name     = "control-mission"
  filename = "../dist/lambdas.zip"
  handler  = "control_mission_lambda.handler"

  instrumentation_layer_arn = aws_lambda_layer_version.python_layer.arn
  collector_layer_arn       = aws_lambda_layer_version.collector_layer.arn
}
```

The rest of the file (IAM policy, role policy, Lambda permission) stays unchanged.

### Success Criteria:

#### Automated Verification:
- [x] Terraform validates: `cd infrastructure && terraform validate`
- [x] Terraform plan shows expected changes (2 Lambda functions updated, layer resources replaced): `cd infrastructure && terraform plan`
- [x] No references to `nodejs` remain in Terraform: `grep -r "nodejs" infrastructure/` returns nothing
- [x] No references to `otel-handler` remain: `grep -r "otel-handler" infrastructure/` returns nothing
- [x] No references to `enabled_instrumentations` remain: `grep -r "enabled_instrumentations" infrastructure/` returns nothing

#### Manual Verification:
- [x] Review `terraform plan` output to confirm only expected resources are changing (Lambda functions, layers) — API Gateway, DynamoDB, and IAM should be unaffected

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the terraform plan looks correct before proceeding to Phase 3.

---

## Phase 3: Build the Python OTel Layer from Source

### Overview
Clone the `opentelemetry-lambda` repository, build the Python instrumentation layer zip, and place it at the repo root. This requires Docker.

### Steps:

#### 3.1 Clone and build the layer

```bash
git clone https://github.com/open-telemetry/opentelemetry-lambda.git /tmp/opentelemetry-lambda
cd /tmp/opentelemetry-lambda/python
```

Build using the provided script (requires Docker running):

```bash
bash run.sh -n opentelemetry-python-layer -b true
```

This builds the layer inside a Docker container matching the Lambda runtime environment (necessary because Python wheels contain compiled native code).

The output zip will be in `/tmp/opentelemetry-lambda/python/src/build/`.

#### 3.2 Copy the layer zip to the repo

```bash
cp /tmp/opentelemetry-lambda/python/src/build/opentelemetry-python-layer.zip \
   /Users/wpessers/development/tf-lambda-distributed-tracing/opentelemetry-python-layer.zip
```

#### 3.3 Clean up

```bash
rm -rf /tmp/opentelemetry-lambda
```

### Success Criteria:

#### Automated Verification:
- [x] Layer zip exists: `test -f opentelemetry-python-layer.zip`
- [x] Layer zip contains the wrapper script: `unzip -l opentelemetry-python-layer.zip | grep otel-instrument`
- [x] Layer zip contains OTel Python packages: `unzip -l opentelemetry-python-layer.zip | grep opentelemetry`

#### Manual Verification:
- [x] Docker was available and the build completed without errors

**Implementation Note**: If the build script name or output path differs from what's documented here, check the `python/README.md` in the cloned repo for up-to-date instructions. The exact build command may vary between releases.

---

## Phase 4: Deploy and Verify

### Overview
Build the Lambda deployment package, deploy with Terraform, and verify end-to-end tracing.

### Steps:

#### 4.1 Build the Lambda deployment package

```bash
bash build.sh
```

#### 4.2 Deploy

```bash
cd infrastructure
terraform apply
```

#### 4.3 Test

```bash
curl -X POST https://<api-id>.execute-api.eu-central-1.amazonaws.com/test/launch \
  -H "Content-Type: application/json" \
  -d '{"rocketName":"test","destination":"Mars"}'
```

Expected response:
```json
{"rocketName": "test", "destination": "Mars", "status": "LAUNCHING"}
```

Or use the existing test script (update the URL if needed):
```bash
cd infrastructure
bash test.sh
```

### Success Criteria:

#### Automated Verification:
- [x] `terraform apply` completes without errors
- [x] curl returns HTTP 200 with the expected JSON shape

#### Manual Verification:
- [x] Traces appear in the observability backend (e.g. Grafana Tempo)
- [x] Trace contains spans for: Lambda invocation, urllib HTTP request (launch -> mission), boto3 DynamoDB get_item/put_item
- [x] Both Lambda functions' CloudWatch logs show OTel initialization messages
- [x] The dual-layer pattern works: launch Lambda (public ARN) and mission Lambda (custom-built layer) both produce traces

---

## Testing Strategy

### Functional Testing:
- POST to `/launch` returns 200 with correct JSON shape
- Mission Lambda creates DynamoDB items on first call, reads them on subsequent calls
- Cross-service HTTP call from launch -> mission produces a connected distributed trace

### OTel-Specific Testing:
- Verify `urllib.request` calls generate HTTP spans (launch Lambda calling mission API)
- Verify `boto3` DynamoDB calls generate DB spans (mission Lambda)
- Verify `logging` calls are correlated with trace context (if logging instrumentation is included in the layer)
- Compare traces from the public layer (launch) vs custom-built layer (mission)

### Troubleshooting:
- If no traces appear: check CloudWatch logs for OTel initialization errors, verify `OTEL_LOG_LEVEL=DEBUG` output
- If `urllib` calls aren't traced: the layer may not include urllib instrumentation by default — try adding `OTEL_PYTHON_DISABLED_INSTRUMENTATIONS=none` via `disabled_instrumentations` variable to force-enable all instrumentations
- If cold starts are slow: remove `OTEL_PYTHON_DISABLED_INSTRUMENTATIONS=none` to let the layer use its default cold-start optimization (only botocore + HTTP)

## File Change Summary

| File | Action | What Changes |
|---|---|---|
| `src/launch/requestLaunchLambda.ts` | Delete | Replaced by Python |
| `src/mission/controlMissionLambda.ts` | Delete | Replaced by Python |
| `package.json` | Delete | Replaced by `build.sh` |
| `tsconfig.json` | Delete | No longer needed |
| `package-lock.json` | Delete | No longer needed |
| `opentelemetry-nodejs-layer.zip` | Delete | Replaced by Python layer |
| `src/launch/request_launch_lambda.py` | Create | Python launch handler |
| `src/mission/control_mission_lambda.py` | Create | Python mission handler |
| `build.sh` | Create | Build script |
| `opentelemetry-python-layer.zip` | Create | Built from source (Phase 3) |
| `.gitignore` | Modify | Python patterns instead of Node.js |
| `infrastructure/modules/otel-lambda/main.tf` | Modify | Python runtime, wrapper, env vars |
| `infrastructure/modules/otel-lambda/variables.tf` | Modify | Rename variable, update default ARN |
| `infrastructure/layer.tf` | Modify | Python layer, update compatible_runtimes |
| `infrastructure/lambda-launch.tf` | Modify | Python handler, remove enabled_instrumentations |
| `infrastructure/lambda-mission.tf` | Modify | Python handler, remove enabled_instrumentations, update layer ref |

## Files That Stay Unchanged

- `infrastructure/main.tf` — Provider config
- `infrastructure/dynamodb.tf` — DynamoDB table
- `infrastructure/api-gateway-launch.tf` — Launch API Gateway
- `infrastructure/api-gateway-mission.tf` — Mission API Gateway
- `infrastructure/modules/otel-lambda/outputs.tf` — Module outputs
- `infrastructure/test.sh` — Test script
- `src/launch/openapi.json` — Launch API spec (used by API Gateway)
- `src/mission/openapi.json` — Mission API spec (used by API Gateway)
- `collector.yaml.example` — Collector config template
- `opentelemetry-collector-layer-arm64.zip` — Collector layer (language-agnostic)

## References

- Research document: `thoughts/tasks/otel-lambda-multi-language-layers/2026-02-21-research.md`
- OpenTelemetry Lambda repo: https://github.com/open-telemetry/opentelemetry-lambda
- Python layer README: https://github.com/open-telemetry/opentelemetry-lambda/tree/main/python
- OTel Lambda auto-instrumentation docs: https://opentelemetry.io/docs/platforms/faas/lambda-auto-instrument/
