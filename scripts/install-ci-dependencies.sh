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

apt-get update
apt-get install -y --no-install-recommends \
  libeigen3-dev \
  libyaml-cpp-dev \
  "ros-${ROS_DISTRO}-rmw-cyclonedds-cpp" \
  "ros-${ROS_DISTRO}-rosbag2-cpp" \
  "ros-${ROS_DISTRO}-rosidl-generator-dds-idl"

rm -rf /var/lib/apt/lists/*
