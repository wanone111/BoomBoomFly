#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

SRC_DIR="${PROJECT_ROOT}/src"
DO_UPDATE=0
DRY_RUN=0

usage() {
	cat <<EOF
Usage:
  ${SCRIPT_NAME} [options]

Options:
  --update            Update existing git repositories.
  --src-dir <path>    Target ROS 2 src directory. Default: ${SRC_DIR}
  --dry-run           Print planned actions without cloning or updating.
  -h, --help          Show this help message.
EOF
}

log() {
	printf '%s\n' "$*"
}

die() {
	printf '[ERROR] %s\n' "$*" >&2
	exit 1
}

require_command() {
	local cmd="$1"
	command -v "${cmd}" >/dev/null 2>&1 || die "Required command not found: ${cmd}"
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--update)
			DO_UPDATE=1
			shift
			;;
		--src-dir)
			[[ $# -ge 2 ]] || die "--src-dir requires a path"
			SRC_DIR="$2"
			shift 2
			;;
		--dry-run)
			DRY_RUN=1
			shift
			;;
		-h | --help)
			usage
			exit 0
			;;
		*)
			die "Unknown option: $1"
			;;
	esac
done

require_command git

if [[ "${SRC_DIR}" != /* ]]; then
	SRC_DIR="$(pwd)/${SRC_DIR}"
fi

if [[ ${DRY_RUN} -eq 1 ]]; then
	if [[ ! -d "${SRC_DIR}" ]]; then
		log "[DRY] mkdir -p ${SRC_DIR}"
	fi
else
	mkdir -p "${SRC_DIR}"
fi

if [[ ${DRY_RUN} -eq 0 && ! -d "${SRC_DIR}" ]]; then
	die "Failed to create src directory: ${SRC_DIR}"
fi

log "Project root: ${PROJECT_ROOT}"
log "Target src:   ${SRC_DIR}"

run_cmd() {
	if [[ ${DRY_RUN} -eq 1 ]]; then
		printf '[DRY] '
		printf '%q ' "$@"
		printf '\n'
		return 0
	fi

	"$@"
}

ref_exists_on_remote() {
	local full_path="$1"
	local ref="$2"

	git -C "${full_path}" show-ref --verify --quiet "refs/remotes/origin/${ref}"
}

ref_exists_as_tag() {
	local full_path="$1"
	local ref="$2"

	git -C "${full_path}" show-ref --verify --quiet "refs/tags/${ref}"
}

checkout_ref() {
	local full_path="$1"
	local ref="$2"

	if [[ -z "${ref}" ]]; then
		return 0
	fi

	if ref_exists_on_remote "${full_path}" "${ref}"; then
		run_cmd git -C "${full_path}" checkout -B "${ref}" "origin/${ref}"
	elif ref_exists_as_tag "${full_path}" "${ref}"; then
		run_cmd git -C "${full_path}" checkout --detach "${ref}"
	else
		run_cmd git -C "${full_path}" checkout "${ref}"
	fi
}

update_repo() {
	local full_path="$1"
	local ref="$2"

	run_cmd git -C "${full_path}" fetch --all --tags --prune
	checkout_ref "${full_path}" "${ref}"

	if [[ ${DRY_RUN} -eq 1 ]]; then
		return 0
	fi

	if [[ -n "${ref}" ]]; then
		if ref_exists_as_tag "${full_path}" "${ref}" && ! ref_exists_on_remote "${full_path}" "${ref}"; then
			log "[INFO] ${ref} is a tag; skip git pull."
			return 0
		fi
	fi

	local current_branch
	current_branch="$(git -C "${full_path}" symbolic-ref --quiet --short HEAD || true)"
	if [[ -z "${current_branch}" ]]; then
		log "[INFO] Detached HEAD in ${full_path}; skip git pull."
		return 0
	fi

	run_cmd git -C "${full_path}" pull --ff-only
}

clone_or_skip() {
	local repo_url="$1"
	local target_dir="$2"
	local ref="${3:-}"

	local full_path="${SRC_DIR}/${target_dir}"

	if [[ -d "${full_path}/.git" ]]; then
		log "[SKIP] ${target_dir} already exists"
		if [[ ${DO_UPDATE} -eq 1 ]]; then
			log "[UPDT] ${target_dir}"
			update_repo "${full_path}" "${ref}"
		fi
		return
	fi

	if [[ -e "${full_path}" ]]; then
		die "${full_path} exists but is not a git repository"
	fi

	log "[CLONE] ${target_dir}"
	if [[ -n "${ref}" ]]; then
		run_cmd git clone --branch "${ref}" "${repo_url}" "${full_path}"
	else
		run_cmd git clone "${repo_url}" "${full_path}"
	fi
}

clone_or_skip "https://github.com/PX4/px4_msgs.git" "px4_msgs" "v1.16.1"
clone_or_skip "https://github.com/eProsima/Micro-XRCE-DDS-Agent.git" "Micro-XRCE-DDS-Agent"
clone_or_skip "https://github.com/wanone111/vision_to_dds.git" "vision_to_dds"
clone_or_skip "https://github.com/BoomBoomFly/offboard_cpp.git" "offboard_cpp"
clone_or_skip "https://github.com/BoomBoomFly/serial_driver_ros.git" "serial_driver_ros"
clone_or_skip "https://github.com/IntelRealSense/librealsense.git" "librealsense" "v2.53.1"
clone_or_skip "https://github.com/IntelRealSense/realsense-ros.git" "realsense-ros" "4.0.4"
clone_or_skip "https://github.com/BoomBoomFly/px4_bringup.git" "px4_bringup"

log "Done."
