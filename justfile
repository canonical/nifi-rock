set export
set fallback


[private]
default:
	just --list

[private]
push-to-registry VERSION:
	#!/usr/bin/env bash
	set -euxo pipefail

	rock_version="$(cat $VERSION/rockcraft.yaml | yq '.version')"

	rockcraft.skopeo --insecure-policy copy --dest-tls-verify=false \
	  "oci-archive:${VERSION}/nifi_${rock_version}_amd64.rock" \
	  "docker://localhost:32000/nifi-rock-dev:${rock_version}"

pack VERSION DEBUG="":
	cd "${VERSION}" && rockcraft pack {{DEBUG}}

clean VERSION:
	cd "${VERSION}" && rockcraft clean
	cd "${VERSION}" && rm -f *.rock

run VERSION: (pack VERSION) (push-to-registry VERSION)
	#!/usr/bin/env bash
	set -euxo pipefail

	rock_version="$(cat $VERSION/rockcraft.yaml | yq '.version')"

	# Pull by digest rather than tag so the container under test is exactly the
	# image just pushed, even if the tag is reused.
	DIGEST="$(rockcraft.skopeo --insecure-policy inspect --tls-verify=false "docker://localhost:32000/nifi-rock-dev:${rock_version}" | jq -r .Digest)"
	IMAGE_REF="localhost:32000/nifi-rock-dev@${DIGEST}"
	cd "${VERSION}" && \
	env GOSS_KUBECTL_BIN="$(which kubectl)" GOSS_OPTS="--color" GOSS_WAIT_OPTS="-r 480s -s 2s" \
	kgoss edit -i "${IMAGE_REF}"

test VERSION: (pack VERSION) (push-to-registry VERSION)
	#!/usr/bin/env bash
	set -euxo pipefail

	rock_version="$(cat $VERSION/rockcraft.yaml | yq '.version')"

	DIGEST="$(rockcraft.skopeo --insecure-policy inspect --tls-verify=false "docker://localhost:32000/nifi-rock-dev:${rock_version}" | jq -r .Digest)"
	IMAGE_REF="localhost:32000/nifi-rock-dev@${DIGEST}"
	cd "${VERSION}" && \
	env GOSS_KUBECTL_BIN="$(which kubectl)" GOSS_OPTS="--color" GOSS_WAIT_OPTS="-r 480s -s 2s" \
	kgoss run -i "${IMAGE_REF}"