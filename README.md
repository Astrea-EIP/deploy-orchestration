# Deploy Orchestration

This repository defines deployed versions of all services.

## Environments

- `preprod.yml`: staging environment
- `prod.yml`: production environment

## Rules

- No business logic
- Only commit SHAs or tags
- PR required for all changes
- CI validates commit existence

## Deployment flow

1. Update preprod
2. Validate in staging
3. Promote to prod