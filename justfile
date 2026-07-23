set export
set fallback


[private]
default:
	just --list

# A self-contained docker registry, so `just test` works with only docker
# present and does not depend on the microk8s `registry` addon being enabled
# separately. Matches the airflow and temporal rock justfiles.
[private]
start-local-registry:
	docker start registry || docker run -d -p 5000:5000 --name registry registry:2

[private]
stop-local-registry:
	docker stop registry && docker rm registry

[private]
push-to-local-registry VERSION:
	#!/usr/bin/env bash
	set -euxo pipefail

	rock_version="$(cat $VERSION/rockcraft.yaml | yq '.version')"

	rockcraft.skopeo --insecure-policy copy --dest-tls-verify=false \
	  "oci-archive:${VERSION}/nifi_${rock_version}_amd64.rock" \
	  "docker://localhost:5000/nifi-rock-dev:${rock_version}"

pack VERSION DEBUG="":
	cd "${VERSION}" && rockcraft pack {{DEBUG}}

clean VERSION:
	cd "${VERSION}" && rockcraft clean
	cd "${VERSION}" && rm -f *.rock

run VERSION: (pack VERSION) (start-local-registry) (push-to-local-registry VERSION)
	#!/usr/bin/env bash
	set -euxo pipefail
	trap 'just stop-local-registry' EXIT

	rock_version="$(cat $VERSION/rockcraft.yaml | yq '.version')"

	# Pull by digest rather than tag so the container under test is exactly the
	# image just pushed, even if the tag is reused.
	DIGEST="$(rockcraft.skopeo --insecure-policy inspect --tls-verify=false "docker://localhost:5000/nifi-rock-dev:${rock_version}" | jq -r .Digest)"
	IMAGE_REF="localhost:5000/nifi-rock-dev@${DIGEST}"
	cd "${VERSION}" && \
	env GOSS_KUBECTL_BIN="$(which kubectl)" GOSS_OPTS="--color" GOSS_WAIT_OPTS="-r 480s -s 2s" \
	kgoss edit -i "${IMAGE_REF}"

test VERSION: (pack VERSION) (start-local-registry) (push-to-local-registry VERSION)
	#!/usr/bin/env bash
	set -euxo pipefail
	trap 'just stop-local-registry' EXIT

	rock_version="$(cat $VERSION/rockcraft.yaml | yq '.version')"

	DIGEST="$(rockcraft.skopeo --insecure-policy inspect --tls-verify=false "docker://localhost:5000/nifi-rock-dev:${rock_version}" | jq -r .Digest)"
	IMAGE_REF="localhost:5000/nifi-rock-dev@${DIGEST}"
	cd "${VERSION}" && \
	env GOSS_KUBECTL_BIN="$(which kubectl)" GOSS_OPTS="--color" GOSS_WAIT_OPTS="-r 480s -s 2s" \
	kgoss run -i "${IMAGE_REF}"
