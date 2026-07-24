# NiFi Rock

Rocks for Apache NiFi.
This repository hosts all the necessary files to build NiFi Rock

## Overview

This rock packages **Apache NiFi** as a Pebble-managed OCI container on Ubuntu
26.04 with a Java 21 runtime, for use as the workload image of the Charmed
NiFi 2.x operator.

The rock consumes the `-ubuntuN` artifact built from source by the SOSS pipeline and published by [central-uploader](https://github.com/canonical/central-uploader/releases), verifies its published SHA-512, and prunes the bundled NARs down to a
version-controlled allowlist.

## Project Structure

```
nifi-rocks/
├─ <major.minor>/
│  ├─ rockcraft.yaml         # Rockcraft manifest defining the rock
│  ├─ nars.keep              # NAR allowlist applied at build time
│  ├─ goss.yaml              # smoke tests run against the built image
│  ├─ goss_wait.yaml         # readiness gate for the smoke tests
│  └─ scripts/
│     └─ start.sh            # Pebble entrypoint wrapper
├─ justfile
├─ DEVELOPING.md
├─ LICENSE
└─ README.md
```

## Building

```bash
cd 2.10
rockcraft pack
```

See [DEVELOPING.md](DEVELOPING.md) for dependencies, artifact verification, and
how to re-pin the source on a version bump.

## What the rock provides

| Path | Purpose | Default behaviour |
| :---- | :---- | :---- |
| `/opt/nifi` | NiFi install (bin, conf, lib, docs) | Image |
| `/var/lib/nifi/data` | database and flowfile repositories, local state, `flow.json.gz` | Writable; ephemeral unless a volume is mounted |
| `/var/lib/nifi/content_repository` | content repository | Writable; ephemeral unless a volume is mounted |
| `/var/lib/nifi/provenance_repository` | provenance repository | Writable; ephemeral unless a volume is mounted |
| `/var/log/nifi` | Logs | Ephemeral |

The workload runs as the base image's `ubuntu` user (uid/gid `1000`). Pebble
starts a single `nifi` service and a `nifi-ready` TCP readiness check on the web
port.

Repository paths are absolute under `/var/lib/nifi` rather than relative to
`NIFI_HOME`, so a consumer can mount storage there without overriding any
NiFi properties.

## Configuration

The rock ships minimal working defaults only; no secrets are baked in. v1 serves
the UI and REST API over **HTTP on 8080 with anonymous access**, so it boots and
is usable with no external configuration.

A standalone consumer can override a few settings at runtime via environment
variables, which `start.sh` applies to `nifi.properties` before launch — the
same interface the upstream `apache/nifi` image exposes:

| Variable | Overrides |
| :---- | :---- |
| `NIFI_WEB_HTTP_HOST` | `nifi.web.http.host` |
| `NIFI_WEB_HTTP_PORT` | `nifi.web.http.port` |
| `NIFI_WEB_PROXY_HOST` | `nifi.web.proxy.host` |
| `NIFI_SENSITIVE_PROPS_KEY` | `nifi.sensitive.props.key` |
| `SINGLE_USER_CREDENTIALS_USERNAME` / `_PASSWORD` | applied via `nifi.sh set-single-user-credentials` |

Each is a no-op when unset, so the shipped default survives and mounting a full
`conf/` directory or pushing a rendered `nifi.properties` works as an
alternative.

> **Overriding the web port also requires overriding the readiness check.** The
> rock's baked `nifi-ready` check probes TCP `8080`. If you move the web port,
> that check keeps probing `8080` and fails (`connection refused`); the service
> still runs, since the check is `level: ready` and not wired to restart, but
> the rock never reports ready. Override the check in your own Pebble layer when
> you change the port.

## Licensing

Two license files are included in the rock image:

- `licenses/LICENSE-nifi` – Apache 2.0 license for upstream NiFi
- `licenses/LICENSE-nifi-rock` – Apache 2.0 license for this rock's source
