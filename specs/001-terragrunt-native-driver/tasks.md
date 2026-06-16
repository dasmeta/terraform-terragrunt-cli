# Tasks

1. Inspect current `terraform-terragrunt-cli` data model and isolate what is
   reused from the current unit normalization path.
2. Design the Terragrunt-native unit template contract:
   - source rendering
   - inputs rendering
   - dependency rendering
   - ordering rendering
3. Replace `module "terraform_setups"` with native Terragrunt rendering.
4. Update unit generator templates to render `dependency` and `dependencies`
   blocks from linked setups.
5. Update examples to assert Terragrunt-native files instead of generated
   Terraform root setup files.
6. Run Terragrunt validation commands on all examples.
7. Update README and docs to describe the Terragrunt-native driver model.
