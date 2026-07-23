#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

SRC_DIR="${PROJECT_ROOT}/src"
OUTPUT_ROOT="${PROJECT_ROOT}"
ROS_SETUP="/opt/ros/foxy/setup.bash"
APPLY_PATCHES=0
PRINT_PLAN=0
JOBS=2
LIBUSB_ROOT=""
PYTHON_DEPS_PATH=""
AMENT_EXTRA_PREFIX=""
REALSENSE_FIRMWARE_CACHE=""

usage() {
	cat <<EOF
Usage:
  ${SCRIPT_NAME} [options]

Build the M1 T265 + D435 + MAVROS software profile without starting ROS nodes or
hardware. The script removes inherited ROS overlays before sourcing ROS 2 Foxy.

Options:
  --src-dir <path>       Source directory. Default: ${SRC_DIR}
  --output-root <path>   Parent for build/m1_profile, install/m1_profile and
                         log/m1_profile. Default: ${OUTPUT_ROOT}
  --jobs <count>         Maximum CMake/make parallel jobs. Default: ${JOBS}
  --libusb-root <path>   Optional extracted sysroot containing
                         usr/include/libusb-1.0 and usr/lib/*/libusb-1.0.so.
  --python-path <path>   Optional Python dependency directory appended after
                         the clean ROS environment is loaded.
  --ament-prefix <path>  Optional extracted ROS package prefix appended after
                         the clean ROS environment is loaded.
  --realsense-firmware-cache <path>
                         Optional local mirror containing librealsense's
                         Releases/ firmware tree.
  --apply-patches        Apply reviewed project patches when required.
  --print-plan           Print the resolved build plan without changing files.
  -h, --help             Show this help message.

Excluded packages are read from workspace.excluded_packages.
EOF
}

log() {
	printf '%s\n' "$*"
}

die() {
	printf '[ERROR] %s\n' "$*" >&2
	exit 1
}

absolute_path() {
	local path="$1"
	if [[ "${path}" == /* ]]; then
		printf '%s\n' "${path}"
	else
		printf '%s/%s\n' "$(pwd)" "${path}"
	fi
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--src-dir)
			[[ $# -ge 2 ]] || die "--src-dir requires a path"
			SRC_DIR="$2"
			shift 2
			;;
		--output-root)
			[[ $# -ge 2 ]] || die "--output-root requires a path"
			OUTPUT_ROOT="$2"
			shift 2
			;;
		--jobs)
			[[ $# -ge 2 ]] || die "--jobs requires a count"
			JOBS="$2"
			shift 2
			;;
		--libusb-root)
			[[ $# -ge 2 ]] || die "--libusb-root requires a path"
			LIBUSB_ROOT="$2"
			shift 2
			;;
		--python-path)
			[[ $# -ge 2 ]] || die "--python-path requires a path"
			PYTHON_DEPS_PATH="$2"
			shift 2
			;;
		--ament-prefix)
			[[ $# -ge 2 ]] || die "--ament-prefix requires a path"
			AMENT_EXTRA_PREFIX="$2"
			shift 2
			;;
		--realsense-firmware-cache)
			[[ $# -ge 2 ]] || die "--realsense-firmware-cache requires a path"
			REALSENSE_FIRMWARE_CACHE="$2"
			shift 2
			;;
		--apply-patches)
			APPLY_PATCHES=1
			shift
			;;
		--print-plan)
			PRINT_PLAN=1
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

[[ "${JOBS}" =~ ^[1-9][0-9]*$ ]] || die "--jobs must be a positive integer"

SRC_DIR="$(absolute_path "${SRC_DIR}")"
OUTPUT_ROOT="$(absolute_path "${OUTPUT_ROOT}")"
BUILD_BASE="${OUTPUT_ROOT}/build/m1_profile"
INSTALL_BASE="${OUTPUT_ROOT}/install/m1_profile"
LOG_BASE="${OUTPUT_ROOT}/log/m1_profile"
EXCLUSION_FILE="${PROJECT_ROOT}/workspace.excluded_packages"
MAVROS_PATCH="${PROJECT_ROOT}/patches/mavros/foxy_tf2_eigen_h.patch"
MAVROS_REPO="${SRC_DIR}/mavros"
EXTRA_CMAKE_ARGS=()
COLCON_CMAKE_OPTIONS=()

[[ -d "${SRC_DIR}" ]] || die "Source directory not found: ${SRC_DIR}"
[[ -f "${ROS_SETUP}" ]] || die "ROS setup not found: ${ROS_SETUP}"
[[ -f "${EXCLUSION_FILE}" ]] || die "Exclusion file not found: ${EXCLUSION_FILE}"
[[ -f "${MAVROS_PATCH}" ]] || die "MAVROS patch not found: ${MAVROS_PATCH}"
[[ -d "${MAVROS_REPO}/.git" ]] || die "MAVROS Git repository not found: ${MAVROS_REPO}"

if [[ -n "${LIBUSB_ROOT}" ]]; then
	LIBUSB_ROOT="$(absolute_path "${LIBUSB_ROOT}")"
	LIBUSB_INCLUDE="${LIBUSB_ROOT}/usr/include/libusb-1.0"
	LIBUSB_LIBRARY="$(
		find "${LIBUSB_ROOT}/usr/lib" -name 'libusb-1.0.so' -print -quit 2>/dev/null
	)"
	[[ -f "${LIBUSB_INCLUDE}/libusb.h" ]] ||
		die "libusb header not found below --libusb-root: ${LIBUSB_INCLUDE}/libusb.h"
	[[ -n "${LIBUSB_LIBRARY}" ]] ||
		die "libusb library not found below --libusb-root: ${LIBUSB_ROOT}/usr/lib"
	EXTRA_CMAKE_ARGS+=(
		"-DLIBUSB_INC=${LIBUSB_INCLUDE}"
		"-DLIBUSB_LIB=${LIBUSB_LIBRARY}"
	)
	if [[ -f "${LIBUSB_ROOT}/usr/include/asio.hpp" ]]; then
		EXTRA_CMAKE_ARGS+=("-DASIO_INCLUDE_DIRS=${LIBUSB_ROOT}/usr/include")
	fi
	GEOGRAPHICLIB_MODULE="${LIBUSB_ROOT}/usr/share/cmake/geographiclib"
	GEOGRAPHICLIB_LIBRARY="$(
		find "${LIBUSB_ROOT}/usr/lib" -name 'libGeographic.so' -print -quit 2>/dev/null
	)"
	if [[ -f "${GEOGRAPHICLIB_MODULE}/FindGeographicLib.cmake" &&
		-f "${LIBUSB_ROOT}/usr/include/GeographicLib/Config.h" &&
		-n "${GEOGRAPHICLIB_LIBRARY}" ]]; then
		EXTRA_CMAKE_ARGS+=(
			"-DCMAKE_MODULE_PATH=${GEOGRAPHICLIB_MODULE}"
			"-DGeographicLib_INCLUDE_DIRS=${LIBUSB_ROOT}/usr/include"
			"-DGeographicLib_LIBRARIES=${GEOGRAPHICLIB_LIBRARY}"
			"-DGeographicLib_LIBRARY_DIRS=$(dirname "${GEOGRAPHICLIB_LIBRARY}")"
		)
	fi
fi

if [[ -n "${PYTHON_DEPS_PATH}" ]]; then
	PYTHON_DEPS_PATH="$(absolute_path "${PYTHON_DEPS_PATH}")"
	[[ -d "${PYTHON_DEPS_PATH}" ]] ||
		die "Python dependency directory not found: ${PYTHON_DEPS_PATH}"
fi

if [[ -n "${AMENT_EXTRA_PREFIX}" ]]; then
	AMENT_EXTRA_PREFIX="$(absolute_path "${AMENT_EXTRA_PREFIX}")"
	[[ -d "${AMENT_EXTRA_PREFIX}/share/ament_index" ]] ||
		die "Ament index not found below --ament-prefix: ${AMENT_EXTRA_PREFIX}"
fi

if [[ -n "${REALSENSE_FIRMWARE_CACHE}" ]]; then
	REALSENSE_FIRMWARE_CACHE="$(absolute_path "${REALSENSE_FIRMWARE_CACHE}")"
	[[ -f "${REALSENSE_FIRMWARE_CACHE}/Releases/TM2/FW/target/0.2.0.951/target-0.2.0.951.mvcmd" ]] ||
		die "T265 firmware not found below --realsense-firmware-cache"
	EXTRA_CMAKE_ARGS+=("-DREALSENSE_FIRMWARE_URL=file://${REALSENSE_FIRMWARE_CACHE}")
fi

if [[ -n "${LIBUSB_ROOT}" || -n "${PYTHON_DEPS_PATH}" || -n "${AMENT_EXTRA_PREFIX}" ||
	-n "${REALSENSE_FIRMWARE_CACHE}" ]]; then
	COLCON_CMAKE_OPTIONS+=(--cmake-force-configure)
fi

mapfile -t EXCLUDED_PACKAGES < <(
	awk 'NF && $1 !~ /^#/ { print $1 }' "${EXCLUSION_FILE}"
)
[[ ${#EXCLUDED_PACKAGES[@]} -gt 0 ]] || die "Exclusion file contains no packages"

PATCH_STATE="unknown"
if git -C "${MAVROS_REPO}" apply --reverse --check "${MAVROS_PATCH}" >/dev/null 2>&1; then
	PATCH_STATE="applied"
elif git -C "${MAVROS_REPO}" apply --check "${MAVROS_PATCH}" >/dev/null 2>&1; then
	PATCH_STATE="required"
else
	die "MAVROS source is incompatible with the reviewed Foxy patch"
fi

log "Project root: ${PROJECT_ROOT}"
log "Source:       ${SRC_DIR}"
log "Build base:   ${BUILD_BASE}"
log "Install base: ${INSTALL_BASE}"
log "Log base:     ${LOG_BASE}"
log "ROS setup:    ${ROS_SETUP}"
log "MAVROS patch: ${PATCH_STATE}"
log "libusb root:  ${LIBUSB_ROOT:-system}"
log "Python deps:  ${PYTHON_DEPS_PATH:-system}"
log "Ament prefix: ${AMENT_EXTRA_PREFIX:-system}"
log "RS firmware:  ${REALSENSE_FIRMWARE_CACHE:-network/default}"
log "Excluded:     ${EXCLUDED_PACKAGES[*]}"
log "Profile:      mavros vision_to_mavros realsense2_camera px4_bringup"

if [[ ${PRINT_PLAN} -eq 1 ]]; then
	exit 0
fi

if [[ "${PATCH_STATE}" == "required" ]]; then
	[[ ${APPLY_PATCHES} -eq 1 ]] ||
		die "MAVROS Foxy patch is required; review it and rerun with --apply-patches"
	git -C "${MAVROS_REPO}" apply "${MAVROS_PATCH}"
	log "Applied MAVROS Foxy compatibility patch"
fi

# Do not inherit an older workspace overlay. Keep only the system tool path,
# then source the selected ROS distribution from a known baseline.
unset AMENT_PREFIX_PATH CMAKE_PREFIX_PATH COLCON_PREFIX_PATH PYTHONPATH
unset LD_LIBRARY_PATH PKG_CONFIG_PATH ROS_DISTRO ROS_VERSION ROS_PYTHON_VERSION
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
set +u
# shellcheck disable=SC1090
source "${ROS_SETUP}"
set -u

if [[ -n "${PYTHON_DEPS_PATH}" ]]; then
	export PYTHONPATH="${PYTHON_DEPS_PATH}:${PYTHONPATH:-}"
fi

if [[ -n "${AMENT_EXTRA_PREFIX}" ]]; then
	export AMENT_PREFIX_PATH="${AMENT_EXTRA_PREFIX}:${AMENT_PREFIX_PATH:-}"
	export CMAKE_PREFIX_PATH="${AMENT_EXTRA_PREFIX}:${CMAKE_PREFIX_PATH:-}"
	export LD_LIBRARY_PATH="${AMENT_EXTRA_PREFIX}/lib:${LD_LIBRARY_PATH:-}"
	export PYTHONPATH="${AMENT_EXTRA_PREFIX}/lib/python3.8/site-packages:${PYTHONPATH:-}"
fi

if [[ -n "${LIBUSB_ROOT}" ]]; then
	export LD_LIBRARY_PATH="${LIBUSB_ROOT}/usr/lib/x86_64-linux-gnu:${LIBUSB_ROOT}/usr/lib:${LD_LIBRARY_PATH:-}"
fi

if env | grep -Eq '^(AMENT_PREFIX_PATH|CMAKE_PREFIX_PATH|COLCON_PREFIX_PATH|PYTHONPATH|LD_LIBRARY_PATH)=.*px4_ws'; then
	die "Old px4_ws overlay remains in the build environment"
fi

export CMAKE_BUILD_PARALLEL_LEVEL="${JOBS}"
export MAKEFLAGS="-j${JOBS}"
export PYTHONDONTWRITEBYTECODE=1

mkdir -p "${BUILD_BASE}" "${INSTALL_BASE}" "${LOG_BASE}"

colcon --log-base "${LOG_BASE}" build \
	--base-paths "${SRC_DIR}" \
	--build-base "${BUILD_BASE}" \
	--install-base "${INSTALL_BASE}" \
	--executor sequential \
	--event-handlers console_direct+ \
	--packages-up-to mavros vision_to_mavros realsense2_camera px4_bringup \
	--packages-skip "${EXCLUDED_PACKAGES[@]}" \
	"${COLCON_CMAKE_OPTIONS[@]}" \
	--cmake-args \
		-DBUILD_TESTING=OFF \
		-DBUILD_EXAMPLES=OFF \
		-DBUILD_GRAPHICAL_EXAMPLES=OFF \
		"${EXTRA_CMAKE_ARGS[@]}"

log "M1 profile build completed"
