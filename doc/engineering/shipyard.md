# Shipyard

Shipyard is the build pipeline for {% BRAND_NAME %} and other projects, generating artifacts like RPMs for use in building clusters.

## Per-application config

Each {% BRAND_NAME %} application should define a `.shipyard.yml` file structured to provide the relevant metadata and dependencies.

### Description

The description key should be constrained to 80-character columns
