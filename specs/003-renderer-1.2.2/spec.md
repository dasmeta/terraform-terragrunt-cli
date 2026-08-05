# Adopt Renderer 1.2.2

## Why

This driver pins `dasmeta/generic/renderer//modules/infra-yaml-loader` at 1.2.1.
That loader release contains a defect that aborts evaluation for any workspace path
matching a hardcoded directory convention
(`2-products/<product>/<cluster>/setups/<name>`): it interpolates `regex()` capture
lists into a string and fails with

```
Error: Invalid template interpolation value
  Cannot include the given value in a string template: string required, but have tuple.
```

Renderer 1.2.2 removes that directory-inferred linking entirely. Workspace links are
declared — either through the YAML `linked_workspaces` list or through a
`${path.output}` reference that already names the workspace — and never guessed from
folder names. See `specs/006-infra-yaml-loader-path-linking/` in
`terraform-renderer-generic`.

Separately, this driver's `modules/unit-generator` calls
`provider::deepmerge::mergo` while declaring `required_version = "~> 1.3"`.
Terraform supports provider-defined functions only from 1.8, so a consumer on an
older Terraform fails while parsing the module instead of reporting an unsupported
version.

## What

- Bump the `infra-yaml-loader` pin from 1.2.1 to 1.2.2.
- Raise `required_version` to `~> 1.8` for the modules that reach
  `provider::deepmerge::mergo`: the root module and `modules/unit-generator`.
  `modules/root-generator` keeps `~> 1.3` — it uses no provider functions.
- Correct two stale expectations in the `linked-stacks` example that have been
  failing since before this change: an over-escaped dependency reference, and an
  input rendered as JSON when the renderer emits HCL.
- Add `AGENTS.md`, a diagnostic guide for this driver.

## Acceptance Criteria

- the driver consumes loader 1.2.2 and no workspace path can abort evaluation
- explicit `linked_workspaces` and interpolation-detected links still produce
  Terragrunt `dependency` blocks and unit ordering
- every example plans with no failing `check` assertions, including `linked-stacks`
- module code and README requirement tables agree on the version constraints

## Notes

- No YAML contract change for consumers. A repository that relied on the implicit
  setup-to-cluster link must declare it, as every other managed repository already
  does.
- The generated units' own `required_version` is unrelated: it comes from the
  `terraform_version` input, not from this module's constraint.
