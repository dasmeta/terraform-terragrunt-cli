# Implementation Plan

## Scope

Adopt renderer 1.2.2, align the Terraform version constraint with the provider
functions this driver uses, and leave the examples green.

## Current State

- `main.tf` pins `dasmeta/generic/renderer//modules/infra-yaml-loader` at 1.2.1.
- `modules/unit-generator/locals.tf` calls `provider::deepmerge::mergo`; its
  `versions.tf` and the root `versions.tf` declare `~> 1.3`.
- `modules/root-generator` uses no provider functions.
- `examples/linked-stacks` has a `check` that fails on 1.2.1, before any change
  here: one condition is over-escaped (`\\\"` where the generated file contains a
  plain `"`), and one expects `"second-bool":true` while the renderer emits
  `second-bool = true`.

## Steps

1. Bump the loader pin to 1.2.2 in `main.tf` and the README module table.
2. Raise `required_version` to `~> 1.8` in the root module,
   `modules/unit-generator`, and the example roots; update README requirement
   tables.
3. Confirm the `linked-stacks` check failure predates the bump by re-running it
   against the 1.2.1 pin.
4. Correct the two stale expectations.
5. Plan every example and confirm no failing checks.

## Validation

- Baseline: `examples/linked-stacks` reproduced the same check failure on the 1.2.1
  pin, confirming it is not a regression from 1.2.2.
- `terraform plan` for `examples/basic`, `examples/linked-stacks`,
  `examples/with-shared-configs`, `examples/empty-yaml` — no failing checks
- `terraform fmt -check -recursive .`
- `pre-commit` hooks on commit, including `terraform_docs`

## Breaking Changes

None for the YAML contract. Consumers pinned below Terraform 1.8 must upgrade,
which they already need for the provider functions this driver emits.

## Follow-Up

- Apply the same renderer bump to `terraform-terramate-cli` and
  `terraform-tfe-cloud`.
