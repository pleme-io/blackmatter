# blackmatter — Claude Orientation

> **★★★ CSE / Knowable Construction.** This aggregator composes
> blackmatter-* HM/NixOS/Darwin modules. Per Constructive Substrate
> Engineering's principle 1 (solve problems once, in one place): apps
> imported here MUST NOT be re-imported in downstream sharedModules
> lists — that produces "option already declared" errors and breaks
> the substrate's claim of single-source-of-truth. When adding a new
> aggregator-imported app, also remove it from any downstream inline
> import. Canonical spec:
> [`theory/CONSTRUCTIVE-SUBSTRATE-ENGINEERING.md`](https://github.com/pleme-io/theory/blob/main/CONSTRUCTIVE-SUBSTRATE-ENGINEERING.md).

One-sentence purpose: composition root — aggregates every `blackmatter-*`
component plus a handful of upstream flakes (sops-nix, claude-code,
aws-cli, gcloud) into unified HM / NixOS / Darwin modules and a combined
overlay. Downstream consumers (the private `nix` repo, profiles) depend
on this aggregator, not the components directly.

## Classification

- **Archetype:** `blackmatter-aggregator`
- **Flake shape:** **custom** (intentionally not migrated — aggregator
  composes via module `imports`, not a component shape).
- **Component registry:** see `.typescape.yaml` → `components:` for the
  authoritative list of 30 component archetypes.

## Where to look

| Intent | File |
|--------|------|
| Flake inputs (full component list) | `flake.nix` |
| Core HM module (profiles, git, ssh, fragments) | `modules/home-manager/blackmatter/` |
| Core NixOS module | `modules/nixos/blackmatter/` |
| Core Darwin module | `modules/darwin/blackmatter/` |
| Combined overlay | `overlays/` + `flake.nix → overlays.combined` |
| Component registry | `.typescape.yaml → components:` |

## Relationship to substrate

- `substrate/lib/blackmatter-component-flake.nix` — the canonical
  helper adopted by **20 of 30** components. The remaining 10 are custom
  by design (Rust workspaces, build-pattern libraries, package+overlay
  composers); the reason is recorded per-repo in each `.typescape.yaml`
  under `custom_flake_reason`.

## What NOT to do

- Don't turn the aggregator into a component — it's a composition, not a
  unit. `mkBlackmatterFlake` does not apply.
- Don't inline user-identifying data (names, SSH hosts, secrets). Those
  live in the private `nix` repo.
- When a new `blackmatter-*` component is added, update both `flake.nix`
  **and** `.typescape.yaml → components:` so the registry stays in sync.
