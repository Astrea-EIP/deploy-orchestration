# Promotion

## Purpose

This page documents the local promotion flow from `preprod` to `prod`.

## Rules

- Validate `preprod` before promotion.
- Keep `prod` aligned with validated preprod state.
- Maintain full traceability through pull requests and workflow history.

## Updating the map

The routing graph is built when `core-moteur` publishes an image, not on the
server. To update the map (or change the GraphHopper profiles):

1. Publish a new `core-moteur` version tag. The publish workflow downloads the
   OSM extract, builds the graph and pushes `ghcr.io/astrea-eip/graphhopper:<tag>`.
2. Change `graphhopper` to that tag in `environments/preprod.yml` through a pull
   request and validate it.
3. Promote it to `prod` like any other version.

The image carries OCI labels with the `core-moteur` tag, the GraphHopper
version and the date and MD5 of the OSM extract, so the running graph can be
identified.

