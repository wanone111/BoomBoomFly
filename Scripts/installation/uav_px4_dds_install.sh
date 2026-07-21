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

ensure_ref_available() {
	local full_path="$1"
	local ref="$2"

	if [[ -z "${ref}" ]]; then
		return 0
	fi

	if [[ ${DRY_RUN} -eq 1 && ! -d "${full_path}/.git" ]]; then
		run_cmd git -C "${full_path}" fetch origin "${ref}"
		return 0
	fi

	if git -C "${full_path}" rev-parse --verify --quiet "${ref}^{commit}" >/dev/null ||
		git -C "${full_path}" rev-parse --verify --quiet "origin/${ref}^{commit}" >/dev/null; then
		return 0
	fi

	run_cmd git -C "${full_path}" fetch origin "${ref}"
}

checkout_ref() {
	local full_path="$1"
	local ref="$2"

	if [[ -z "${ref}" ]]; then
		return 0
	fi

	# A dry-run may target a directory that has not been cloned yet. In that
	# case there are no local refs to inspect, so print the generic checkout.
	if [[ ${DRY_RUN} -eq 1 && ! -d "${full_path}/.git" ]]; then
		run_cmd git -C "${full_path}" checkout "${ref}"
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
	local display_ref="${ref:-default branch}"

	log "[PLAN] URL=${repo_url}"
	log "[PLAN] PATH=${full_path}"
	log "[PLAN] REF=${display_ref}"

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
	# Clone first and then use checkout_ref so a ref may be either a branch,
	# tag, or an exact commit SHA. git clone --branch cannot accept a SHA.
	run_cmd git clone "${repo_url}" "${full_path}"
	ensure_ref_available "${full_path}" "${ref}"
	checkout_ref "${full_path}" "${ref}"
}

# ============================================================================
# REPOSITORIES: ROS 2 Foxy + PX4 1.16.2 workspace sources
#
# Each repository is represented by three consecutive values:
#   URL, destination below SRC_DIR, branch/tag/commit.
# Self-developed branches are retained only while the remote advertises them;
# otherwise the audited commit is used. Third-party repositories use the exact
# stable tag at the current HEAD, or the audited commit when no exact tag exists.
# ============================================================================
readonly -a REPOSITORIES=(
	# PX4 messages: PX4 1.16.2 ROS 2/DDS interface; PX4 release tag.
	"https://github.com/PX4/px4_msgs.git" "px4_msgs" "v1.16.2"

	# DDS Agent: PX4 uXRCE-DDS to ROS 2 Foxy/Fast DDS 2.0.x; PX4 guidance.
	"https://github.com/eProsima/Micro-XRCE-DDS-Agent.git" "Micro-XRCE-DDS-Agent" "v2.4.2"

	# Gazebo Classic ROS integration: simulation/Nav2 tests; audited Foxy SHA.
	"https://github.com/ros-simulation/gazebo_ros_pkgs.git" "gazebo_ros_pkgs" "b6f7bf121d0c607825b65a28b227a5459a71821b"

	# IMU filters/RViz: sensor and SLAM stack; stable tag at current HEAD.
	"https://github.com/ccny-ros-pkg/imu_tools.git" "imu_tools" "2.0.3"

	# RealSense SDK: required by realsense2_camera; current stable tag.
	"https://github.com/IntelRealSense/librealsense.git" "librealsense" "v2.50.0"

	# MAVLink definitions: required by MAVROS 2.7.0; current release tag.
	"https://github.com/mavlink/mavlink-gbp-release.git" "mavlink" "release/foxy/mavlink/2022.12.30-1"

	# MAVROS bridge: offboard/telemetry/vision pose; current stable tag.
	"https://github.com/mavlink/mavros.git" "mavros" "2.7.0"

	# Nav2: Foxy navigation stack; audited SHA because branch has moved.
	"https://github.com/ros-navigation/navigation2.git" "navigation2" "ca482808a7a7c52ce01ae3c662dc2b980968fc16"

	# Navigation messages: legacy Foxy Nav2 interfaces; current stable tag.
	"https://github.com/ros-planning/navigation_msgs.git" "navigation_msgs" "2.0.2"

	# BoomBoomFly C++ offboard control; audited SHA because remote master is gone.
	"https://github.com/AyasOwen/offboard_cpp.git" "offboard_cpp" "77a02dc09212cdaa1d8ee654f0ae42ae0f04e275"

	# offboard_py is present locally, but its recorded remote no longer exists.
	# It is intentionally excluded until the source is republished.

	# BoomBoomFly launch/MAVROS config; audited SHA because remote master is gone.
	"https://github.com/AyasOwen/px4_bringup.git" "px4_bringup" "0fbdcbf6ee53d6927de75af1d98f22cf5bd4f917"

	# RealSense ROS camera/messages/descriptions; current stable tag.
	"https://github.com/IntelRealSense/realsense-ros.git" "realsense-ros" "4.0.4"

	# BoomBoomFly T265 TF-to-MAVROS vision bridge; current main.
	"https://github.com/AyasOwen/ros2_foxy_vision_to_mavros.git" "ros2_foxy_vision_to_mavros" "main"

	# RPLIDAR ROS 2 driver: laser navigation; audited SHA, no exact tag.
	"https://github.com/Slamtec/rplidar_ros.git" "rplidar_ros" "24cc9b6dea97e045bda1408eaa867ce730fd3fc3"

	# RTAB-Map core: RGB-D/visual SLAM; current Foxy stable tag.
	"https://github.com/introlab/rtabmap.git" "rtabmap" "0.21.1-foxy"

	# RTAB-Map ROS wrappers/messages/SLAM; current Foxy stable tag.
	"https://github.com/introlab/rtabmap_ros.git" "rtabmap_ros" "0.21.1-foxy"

	# Portable serial library: serial_driver dependency; audited master SHA.
	"https://github.com/RoverRobotics-forks/serial-ros2.git" "serial-ros2" "ae46504ae7d4a199ea9bba0e73a6f083bf172f80"

	# BoomBoomFly serial hardware interface; current main.
	"https://github.com/BoomBoomFly/serial_driver_ros2.git" "serial_driver_ros2" "main"

	# SLAM toolbox: Foxy Nav2 mapping; audited SHA, no exact tag.
	"https://github.com/SteveMacenski/slam_toolbox.git" "slam_toolbox" "4786e90c06a4dc6fa811c5057d4e88387fba3829"

	# cv_bridge/OpenCV ROS interfaces: vision nodes; current stable tag.
	"https://github.com/ros-perception/vision_opencv.git" "vision_opencv" "3.0.7"
)

install_repositories() {
	local index

	if (( ${#REPOSITORIES[@]} % 3 != 0 )); then
		die "REPOSITORIES must contain URL/path/ref triplets"
	fi

	for ((index = 0; index < ${#REPOSITORIES[@]}; index += 3)); do
		clone_or_skip \
			"${REPOSITORIES[index]}" \
			"${REPOSITORIES[index + 1]}" \
			"${REPOSITORIES[index + 2]}"
	done
}

verify_packages() {
	# serial_driver_ros2 is the repository directory; package.xml names it serial_driver.
	local -a required_packages=(px4_msgs offboard_cpp px4_bringup serial_driver)
	local package
	local colcon_output
	local missing=0

	if [[ ${DRY_RUN} -eq 1 ]]; then
		log "[DRY] colcon list --base-paths ${SRC_DIR}"
		for package in "${required_packages[@]}"; do
			log "[DRY] verify ROS package: ${package}"
		done
		return 0
	fi

	require_command colcon
	if ! colcon_output="$(colcon list --base-paths "${SRC_DIR}")"; then
		die "colcon list failed for ${SRC_DIR}"
	fi
	printf '%s\n' "${colcon_output}"

	for package in "${required_packages[@]}"; do
		if ! awk -v expected="${package}" '$1 == expected { found = 1 } END { exit !found }' <<<"${colcon_output}"; then
			printf '[ERROR] Required ROS package missing: %s\n' "${package}" >&2
			missing=1
		fi
	done

	[[ ${missing} -eq 0 ]] || die "Workspace package verification failed"
}

install_repositories
verify_packages

log "Done."
