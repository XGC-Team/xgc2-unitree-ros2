#!/usr/bin/env bash

set -euo pipefail

case "${ROS_DISTRO:-}" in
  humble|jazzy)
    ;;
  *)
    echo "ROS_DISTRO must be humble or jazzy; got '${ROS_DISTRO:-unset}'." >&2
    exit 2
    ;;
esac

export DEBIAN_FRONTEND=noninteractive

for pkg in \
  libeigen3-dev \
  libyaml-cpp-dev \
  "ros-${ROS_DISTRO}-rmw-cyclonedds-cpp" \
  "ros-${ROS_DISTRO}-rosbag2-cpp" \
  "ros-${ROS_DISTRO}-rosidl-generator-dds-idl"
do
  if ! dpkg -s "${pkg}" >/dev/null 2>&1; then
    echo "image is missing ${pkg}; use xgc2-build-*-full-*" >&2
    exit 1
  fi
done
