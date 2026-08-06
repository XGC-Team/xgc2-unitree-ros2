#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

case "${ROS_DISTRO:-}" in
  humble|jazzy)
    ;;
  *)
    echo "ROS_DISTRO must be humble or jazzy; got '${ROS_DISTRO:-unset}'." >&2
    exit 2
    ;;
esac

if [[ -n "${XGC2_EXPECT_UBUNTU_CODENAME:-}" ]]; then
  # shellcheck disable=SC1091
  source /etc/os-release
  if [[ "${VERSION_CODENAME:-}" != "${XGC2_EXPECT_UBUNTU_CODENAME}" ]]; then
    echo "Expected Ubuntu ${XGC2_EXPECT_UBUNTU_CODENAME}, got ${VERSION_CODENAME:-unknown}." >&2
    exit 3
  fi
fi

if [[ -n "${XGC2_EXPECT_DEB_ARCH:-}" ]]; then
  actual_arch="$(dpkg --print-architecture)"
  if [[ "${actual_arch}" != "${XGC2_EXPECT_DEB_ARCH}" ]]; then
    echo "Expected ${XGC2_EXPECT_DEB_ARCH}, got ${actual_arch}." >&2
    exit 4
  fi
fi

readonly ROS_SETUP="/opt/ros/${ROS_DISTRO}/setup.bash"
if [[ ! -r "${ROS_SETUP}" ]]; then
  echo "ROS setup not found: ${ROS_SETUP}" >&2
  exit 5
fi

if [[ -n "${XGC2_BUILD_ROOT:-}" ]]; then
  build_root="${XGC2_BUILD_ROOT}"
  mkdir -p -- "${build_root}"
else
  build_root="$(mktemp -d "${RUNNER_TEMP:-/tmp}/xgc2-unitree-ros2.${ROS_DISTRO}.XXXXXX")"
fi
readonly build_root

set +u
# shellcheck disable=SC1090
source "${ROS_SETUP}"
set -u

export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

readonly interfaces_build="${build_root}/build/interfaces"
readonly interfaces_install="${build_root}/install/interfaces"
readonly example_build="${build_root}/build/example"
readonly example_install="${build_root}/install/example"

colcon --log-base "${build_root}/log/interfaces" build \
  --base-paths "${REPO_ROOT}/cyclonedds_ws/src" \
  --build-base "${interfaces_build}" \
  --install-base "${interfaces_install}" \
  --packages-select unitree_api unitree_go unitree_hg \
  --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_TESTING=OFF

set +u
# shellcheck disable=SC1090
source "${interfaces_install}/setup.bash"
set -u

colcon --log-base "${build_root}/log/example" build \
  --base-paths "${REPO_ROOT}/example/src" \
  --build-base "${example_build}" \
  --install-base "${example_install}" \
  --packages-select unitree_ros2_example \
  --cmake-args -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_TESTING=OFF

set +u
# shellcheck disable=SC1090
source "${example_install}/setup.bash"
set -u

readonly -a expected_packages=(
  unitree_api
  unitree_go
  unitree_hg
  unitree_ros2_example
)

for package in "${expected_packages[@]}"; do
  ros2 pkg prefix "${package}"
done

readonly -a b2_executables=(
  b2_sport_client
  b2_stand_example
  b2w_sport_client
  b2w_stand_example
)

readonly example_prefix="$(ros2 pkg prefix unitree_ros2_example)"

for executable in "${b2_executables[@]}"; do
  executable_path="${example_prefix}/lib/unitree_ros2_example/${executable}"
  if [[ ! -x "${executable_path}" ]]; then
    echo "Missing installed executable: ${executable_path}" >&2
    exit 6
  fi
  if ! ros2 pkg executables unitree_ros2_example | awk '{print $2}' | grep -Fxq "${executable}"; then
    echo "ros2 pkg executables cannot discover ${executable}." >&2
    exit 7
  fi
done

# Interface introspection is read-only.  Do not execute any robot-control sample
# in CI, including the B2 stand and sport clients asserted above.
ros2 interface show unitree_go/msg/LowState >/dev/null
ros2 interface show unitree_api/msg/Request >/dev/null

printf 'Validated ROS %s on %s (%s). Build root: %s\n' \
  "${ROS_DISTRO}" \
  "${XGC2_EXPECT_UBUNTU_CODENAME:-unspecified Ubuntu}" \
  "${XGC2_EXPECT_DEB_ARCH:-$(dpkg --print-architecture)}" \
  "${build_root}"
