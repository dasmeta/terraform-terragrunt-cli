# Plan

1. Add `module "infra_yaml_fetched"` to driver `main.tf` using registry source
   `dasmeta/generic/renderer//modules/infra-yaml-fetched` `1.1.1`.
2. Replace duplicated YAML locals with `module.infra_yaml_fetched` outputs.
3. Extend unit generator with Terragrunt dependency `mock_outputs` support.
4. Validate `basic`, `with-shared-configs`, and `linked-stacks` examples.

## Validation

- `terraform init` and `terraform validate` in driver examples
- `meta validate` on generated units where applicable
