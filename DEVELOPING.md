# Developing NiFi Rocks

This document describes how to build, test, and validate the Apache NiFi Rocks packaged in this repository.

---

## Installing dependencies

The following dependencies are required to develop and test changes to the NiFi rocks:

- a K8s distribution (ideally k8s by Canonical)
- rockcraft
- yq
- kubectl
- just
- docker
- goss
- kgoss

There are convenient snaps for all of the above dependencies besides goss and kgoss. The recommended way to install these until a goss snap is released would be:

```bash
goss_base_url="https://github.com/goss-org/goss/releases/latest/download"
curl -L ${goss_base_url}/goss-linux-amd64 -o /usr/local/bin/goss
chmod +rx /usr/local/bin/goss
curl -L ${goss_base_url}/kgoss -o /usr/local/bin/kgoss
chmod +rx /usr/local/bin/kgoss
```

---

## Repository Structure

```
.
├── <major.minor>/
│   └── <version>-24.04/
│       ├── rockcraft.yaml
│       ├── goss.yaml
│       └── goss_wait.yaml
├── DEVELOPING.md
├── justfile
├── LICENSE
└── README.md
```

Each version directory contains everything needed to build that NiFi release.

---

## Building the Rock

To build the NiFi Rock, go to the directory that corresponds to your desired version. For example:

```bash
cd 2.9/2.9.0-24.04
rockcraft pack
```

This produces a `.rock` artifact (e.g., `nifi-rock_2.9.0_amd64.rock`) in the same directory.

---

## Using the Justfile

The justfile provides shortcuts for common developer actions.

| Command | Description |
| ------- | ----------- |
| `just pack <major.minor>` | Build the `.rock` for the given version |
| `just clean <major.minor>` | Remove build artifacts and reset workspace |
| `just test <major.minor>` | Run validation and health checks (goss tests) |
| `just run <major.minor>` | Launch a test container to inspect the built image |

### Example usage

```bash
just pack 2.9
just run 2.9
```

---

## Testing and Validation

`goss.yaml` and `goss_wait.yaml` define validation checks that ensure:

- NiFi starts and runs as expected within the rock.
- All required services and dependencies are present.

### To execute the tests

```bash
just test 2.9
```

---

## Versioning

Each NiFi version maintains its own isolated build definition under `<major.minor>/<version>-24.04/`. Future versions follow the same structure. Shared components such as the justfile remain at the repository root.

---

## License

This project is licensed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).
