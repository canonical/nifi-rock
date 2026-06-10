# NiFi Rock

Rocks for Apache NiFi.
This repository hosts all the necessary files to build NiFi Rock

## Overview

This rock builds **Apache NiFi** and packages it as a Pebble-managed OCI container.

## Project Structure

```
nifi-rock/
├─ <major.minor>/
│  ├─ rockcraft.yaml         # Rockcraft manifest defining the rock
│  ├─ goss.yaml
│  └─ goss_wait.yaml
├─ DEVELOPING.md
├─ justfile
├─ LICENSE
└─ README.md
```

## Licensing

Two license files are included in the rock image:

- `licenses/LICENSE-nifi` – Apache 2.0 license for upstream NiFi
- `licenses/LICENSE-nifi-rock` – Apache 2.0 license for this rock's source
