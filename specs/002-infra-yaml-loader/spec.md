# Infra YAML Loader Integration

## Why

`terraform-terragrunt-cli` duplicated YAML discovery, shared-config merge,
workspace filtering, and linked-workspace auto-detection in `locals.tf`. That
logic now lives in `dasmeta/generic/renderer//modules/infra-yaml-loader`.

The Terragrunt driver should consume the shared submodule and keep only
Terragrunt-specific unit generation in this repository.

## What

- call `infra-yaml-loader` from registry version `1.2.0`
- remove duplicated YAML locals from the driver root module
- keep Terragrunt-native unit generation, dependency blocks, and mock outputs

## Acceptance Criteria

- driver root module uses `dasmeta/generic/renderer//modules/infra-yaml-loader`
- duplicated YAML merge/filter locals are removed from `locals.tf`
- linked terragrunt units support `mock_outputs` for validate/plan workflows
- existing YAML examples continue to work without format changes
