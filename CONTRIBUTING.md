# Contributing to `deploy-orchestration`

`deploy-orchestration` follows the Astrea-EIP engineering handbook for workflow, review, and release governance.

## Required references

Read these handbook sections before opening a pull request:

- `architecture/environments`
- `repositories/deploy-orchestration`
- `workflows/release-flow`
- `operations/deploy-orchestration`
- `operations/preprod`
- `operations/promotion-flow`

## Local rules

- Keep this repository limited to environment state, validation, and promotion.
- Use `version` as the only deployment reference field.
- Do not add business logic here.
- Validate environment files before requesting review.
