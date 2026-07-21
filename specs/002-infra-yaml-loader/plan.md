# Plan

1. Add `module "infra_yaml_loader"` to driver `main.tf` using registry source
   `dasmeta/generic/renderer//modules/infra-yaml-loader` `1.2.1`.
2. Replace duplicated YAML locals with `module.infra_yaml_loader` outputs.
3. Extend unit generator with Terragrunt dependency `mock_outputs` support.
4. Add a repo-local empty-YAML regression test for the shared loader.
5. Validate `basic`, `with-shared-configs`, and `linked-stacks` examples.

## Validation

- `terraform init` and `terraform validate` in driver examples
- `terraform init` and `terraform plan` in `examples/empty-yaml`
- `meta validate` on generated units where applicable
