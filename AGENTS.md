# AGENTS.md — terraform-terragrunt-cli

Diagnostic guide for AI agents and engineers debugging this driver or a setup that
consumes it. Hand-maintained; keep the symptom table honest and evidence-based.

## What this repo is

The Terragrunt driver: it turns a repository of workspace YAML into a Terragrunt
unit tree (`terragrunt.hcl` per unit plus a shared `root.hcl`). It generates files;
it never applies infrastructure itself.

```
YAML ──▶ infra-yaml-loader ──▶ locals.units ──▶ root-generator  ──▶ root.hcl
         (registry submodule)   (this repo)     unit-generator  ──▶ <unit>/terragrunt.hcl
                                                                    generated_providers.tf
                                                                    generated_versions.tf
```

- **`modules/root-generator`** — one shared `root.hcl` (remote state, common config).
- **`modules/unit-generator`** — one unit per workspace: the `terraform` block,
  `dependency` blocks, `inputs`, provider config, version constraints.
- Discovery, shared-config merge, and link detection are **not** in this repo. They
  live in `dasmeta/generic/renderer//modules/infra-yaml-loader` — see that repo's
  `AGENTS.md` for the YAML contract and loader-stage symptoms.

**Decide which stage owns the symptom first.** Workspace missing or merged wrong →
loader. Wrong unit ordering or `dependency` wiring → `locals.tf` here plus the
loader's link detection. Wrong file content → `modules/*/templates/*.tftpl`. Wrong
plan for the target module → not this repo.

## Linked units

Two declared sources, merged in `locals.tf`:

```hcl
linked_workspaces = distinct(concat(
  try(item.linked_workspaces, []),                      # explicit YAML list
  try(local.auto_detected_linked_workspaces[path], []), # ${path.output} references
))
```

Each entry becomes a Terragrunt `dependency` block and an ordering edge. **Nothing
is inferred from directory names** — renderer 1.2.2 removed a rule that guessed
links from `2-products/.../setups/` path shape.

## Diagnostics: symptom → cause → check

| symptom | likely cause | check / fix |
|---|---|---|
| `Invalid template interpolation value … have tuple` inside the loader module | loader ≤ 1.2.1 with a path matching the removed convention | bump the `infra-yaml-loader` pin to ≥ 1.2.2 |
| module fails while **parsing**, before any plan output | Terraform < 1.8 — `modules/unit-generator` calls `provider::deepmerge::mergo` | check the Terraform version actually running; this module declares `~> 1.8` |
| a unit is missing from the generated tree | its YAML resolved to no `source`/`version`, so the loader dropped it | probe the loader directly (see the renderer repo's `AGENTS.md`) and compare `yaml_files_raw` with `yaml_files` |
| `dependency` block for a unit that does not exist | a literal `${...}` in `variables`/`providers` was read as a workspace reference — there is no existence filter | search the YAML for `${` values that are not workspace paths |
| ordering wrong but the `dependency` block exists | the link is declared, the unit path key is not what you expect (path minus `.yaml`) | compare against the loader's `yaml_paths` |
| `inputs` value rendered as JSON instead of HCL, or vice versa | expectation written against an older renderer | the current renderer emits `key = <jsonencode(value)>` per key, e.g. `second-bool = true` |
| edits to `_terragrunt/` or the example `output/` disappear | generated directories, rewritten every apply | change YAML or the `.tftpl` templates |

## Inspecting and validating

Examples are the test suite — there are no `.tftest.hcl` files. A `check` failure
prints as a **Warning**, so a plan that "succeeded" can still have failing
assertions:

```bash
for e in examples/basic examples/linked-stacks examples/with-shared-configs examples/empty-yaml; do
  terraform -chdir=$e init -backend=false >/dev/null
  terraform -chdir=$e plan -no-color | grep -E "Warning: Check|^Error|Plan:|No changes"
done
```

Examples carry committed state and generated `output/`, so "No changes" is the
normal healthy result — read the check warnings, not the plan summary.

Before blaming a change here, re-run the failing example against the **previous**
pin. That is how the stale `linked-stacks` expectations were separated from the
1.2.2 bump.

## Known traps

- **The loader is a separate release.** Bumping this driver does not move the loader;
  the pin in `main.tf` does. Check it before concluding a renderer fix "did not land".
- **Unused module outputs are still evaluated.** A defect in a loader code path this
  driver never reads can still break its plan.
- **Constraint layering.** `required_version` here applies to whoever runs this
  module. The generated units' constraint comes from the `terraform_version` input
  and is deliberately independent.
- **Only `modules/unit-generator` needs 1.8.** `modules/root-generator` stays at
  `~> 1.3` on purpose; do not raise it without a provider-function reason.

## Version compatibility

| component | constraint | why |
|---|---|---|
| root module | `~> 1.8` | reaches `provider::deepmerge::mergo` through `modules/unit-generator` |
| `modules/unit-generator` | `~> 1.8` | calls `provider::deepmerge::mergo` directly |
| `modules/root-generator` | `~> 1.3` | pure templating, no provider functions |
| generated units | `terraform_version` input | consumer policy, not a module requirement |

## Changing this repo

- Write a `specs/NNN-name/{spec,plan,tasks}.md` package before changing behavior.
- Add or extend an example with `check` blocks — the only test mechanism here.
- `pre-commit` runs on commit and rewrites README tables via `terraform_docs`; stage
  its changes and re-commit rather than hand-editing generated tables.
- Conventional commits drive semantic-release: `fix` → patch, `feat` → minor.
- Never commit client-specific names into this repo — it is published.
