# deploy-orchestration

`deploy-orchestration` defines the deployed state of Astrea-EIP environments.
It owns environment configuration, validation, and promotion workflows.

## What belongs here

This repository owns:

- environment files for `preprod` and `prod`
- validation scripts for deployed versions
- promotion workflows between environments
- repository-local orchestration documentation

This repository does not own:

- application business logic
- frontend, mobile, backend, or engine feature code
- central contribution rules

## Local development

Use the validation tooling when changing environment files.

```bash
python scripts/validate_env.py environments/preprod.yml
python scripts/validate_env.py environments/prod.yml
```

## Rules

- Use `version` everywhere for deployed references.
- Do not introduce `ref`.
- All changes must go through pull requests.
- `prod` changes must stay traceable to validated preprod state.
