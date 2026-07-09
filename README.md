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

## Running the whole stack locally

`docker-compose.yml` starts the full Astrea stack in one command: MongoDB,
the GraphHopper routing engine, `api-back`, and `app-web`.

Prerequisites:

- Docker and Docker Compose installed.
- All six Astrea-EIP repositories cloned as siblings under the same parent
  directory (`docker-compose.yml` builds each service from `../<repo>`).
- A one-time manual step: download an OSM extract covering your test area
  (for example the Pays-de-la-Loire extract from
  [Geofabrik](https://download.geofabrik.de/), consistent with Epitech
  Nantes) and place it at `data/map.osm.pbf`. This file is intentionally not
  committed (too large) and GraphHopper will not start without it.

```bash
docker compose up --build
```

Exposed ports: `app-web` on `4200`, `api-back` on `5217` (Swagger at
`/swagger`), GraphHopper on `8989`, MongoDB on `27017`.

This is for local development/demo purposes. It's separate from `api-back`'s
own `docker-compose.yml`, which only starts a disposable MongoDB for backend-only
development — see `api-back/CONTRIBUTING.md`.

### Going to production

Not implemented yet, but the same Dockerfiles are meant to be reused for a
public deployment, with a few additions: a reverse proxy (Caddy or Nginx) for
HTTPS, `app-web` served as a production build through Nginx instead of `ng
serve`, a full (not test-sized) OSM extract, and secrets provided through a
non-committed `.env` file on the server. Still plain Docker Compose (a
`docker-compose.prod.yml` consuming the versions declared in
`environments/prod.yml`) — no Kubernetes or Terraform at this team's scale.

## Rules

- Use `version` everywhere for deployed references.
- Do not introduce `ref`.
- All changes must go through pull requests.
- `prod` changes must stay traceable to validated preprod state.
