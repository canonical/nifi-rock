# Developing NiFi Rocks

This document describes how to build, test, and validate the Apache NiFi Rocks packaged in this repository.

---

## Installing dependencies

---

## Repository Structure

```
.
├── <major.minor>/
│   ├── rockcraft.yaml
│   ├── goss.yaml
│   └── goss_wait.yaml
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
cd 2.9
rockcraft pack
```

This produces a `.rock` artifact (e.g., `nifi-rock_2.9.0_amd64.rock`) in the same directory.

---

## Versioning

Each NiFi version maintains its own isolated build definition under `<major.minor>/`. Future versions follow the same structure. Shared components such as the justfile remain at the repository root.

---

## License

This project is licensed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).
