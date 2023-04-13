#!/bin/sh

set -e
set -u

semver_lte() {
	printf '%s\n%s' "${1}" "${2}" | sort -C -V
}

random_bounded() {
	# This will be running on a GitHub actions runner, we don't really care
	# that much for POSIX-compliance.
	echo "$(( $(od -An -N1 -tu1 /dev/urandom) % ${1} ))"
}

retry() {
	delay="$(random_bounded 5)"
	attempts="${1}"
	shift

	for _ in $(seq 1 "${attempts}"); do
		ret="$(eval "${*}")" && echo "${ret}" && return 0
		sleep "${delay}"
	done

	return 1
}

get_package_version() {
	sed -e '/^Version:/!d' -e 's/.*:\s*//' "obs/${1}/${1}.spec"
}

get_package_source() {
	sed -e '/^Source0:/!d' -e 's/.*:\s\+//' "obs/${1}/${1}.spec"
}

get_latest_release() {
	curl -sL "https://api.github.com/repos/${1}/${2}/tags" \
		| jq -r '
			map(select(
				.name | test("^v?([0-9]|[1-9][0-9]*)\\.([0-9]|[1-9][0-9]*)\\.([0-9]|[1-9][0-9]*)")
			))
			| first
			| .name
			' \
		| sed 's/^v//'
}

install_osc () {
	sudo apt-get update && sudo apt-get install osc
}

checkout_obs_package() {
	osc --config "${PWD}/oscrc" co home:scheatkode "${1}"
}

sync_changes_to_obs() {
	cd home:scheatkode
	osc --config "../oscrc" remove "${1}"/*.tar.gz || true

	cp -f "../obs/${1}"/* ../*.tar.gz "${1}/"

	osc --config "../oscrc" add "${1}"/*
	osc --config "../oscrc" ci -m "Bump ${1} to ${2}" "${1}"
	cd -
}

bump_specfile_version() {
	sed -i "/^Version:/s/\S*\$/${2}/" "obs/${1}/${1}.spec"
}

commit_version_bump() {
	git -C obs add "${1}/${1}.spec"
	git -C obs commit -m "Bump ${1} to ${2}"
}

push_version_bump() {
	git -C obs fetch origin master
	git -C obs pull --rebase origin master
	git -C obs push origin master
}

fetch_release_asset() {
	curl -LO "$(get_package_source "${1}" | sed -e "s/%{name}/${1}/g" -e "s/%{version}/${2}/g")"
}

main() {
	org="${1}"
	package="${2}"

	new="$(retry 5 get_latest_release "${org}" "${package}")"
	old="$(get_package_version "${package}")"

	# Nothing to do, version is up to date.
	semver_lte "${new}" "${old}" && return 0

	install_osc

	bump_specfile_version "${package}" "${new}"
	commit_version_bump "${package}" "${new}"

	# Retrying to avoid conflicts with parallel runners
	retry 5 push_version_bump
	retry 5 fetch_release_asset "${package}" "${new}"

	checkout_obs_package "${package}"
	sync_changes_to_obs "${package}" "${new}"
}

main "${@}"
