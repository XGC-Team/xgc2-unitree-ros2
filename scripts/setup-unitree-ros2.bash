#!/usr/bin/env bash

# Source this file; do not execute it.  It changes only the current shell's ROS
# and CycloneDDS environment and never changes host networking or starts a node.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "Source this script instead of executing it:" >&2
  echo "  source scripts/setup-unitree-ros2.bash" >&2
  exit 2
fi

unitree_ros_distro="${XGC2_UNITREE_ROS_DISTRO:-${ROS_DISTRO:-jazzy}}"
unitree_network_interface="${XGC2_UNITREE_NETWORK_INTERFACE:-enP2p1s0}"

case "${unitree_ros_distro}" in
  humble|jazzy)
    ;;
  *)
    echo "Unsupported ROS distro: ${unitree_ros_distro}" >&2
    return 3
    ;;
esac

if [[ ! "${unitree_network_interface}" =~ ^[A-Za-z0-9_.:-]+$ ]]; then
  echo "Invalid network interface name: ${unitree_network_interface}" >&2
  return 4
fi

unitree_ros_setup="/opt/ros/${unitree_ros_distro}/setup.bash"
if [[ ! -r "${unitree_ros_setup}" ]]; then
  echo "ROS setup not found: ${unitree_ros_setup}" >&2
  return 5
fi

if command -v ip >/dev/null 2>&1 && ! ip link show dev "${unitree_network_interface}" >/dev/null 2>&1; then
  echo "Network interface does not exist: ${unitree_network_interface}" >&2
  echo "For an offline shell, set XGC2_UNITREE_NETWORK_INTERFACE=lo." >&2
  return 6
fi

# shellcheck disable=SC1090
source "${unitree_ros_setup}"

if [[ -n "${XGC2_UNITREE_OVERLAY_SETUP:-}" ]]; then
  if [[ ! -r "${XGC2_UNITREE_OVERLAY_SETUP}" ]]; then
    echo "Overlay setup not found: ${XGC2_UNITREE_OVERLAY_SETUP}" >&2
    return 7
  fi
  # shellcheck disable=SC1090
  source "${XGC2_UNITREE_OVERLAY_SETUP}"
fi

export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
export CYCLONEDDS_URI="<CycloneDDS><Domain><General><Interfaces><NetworkInterface name=\"${unitree_network_interface}\" priority=\"default\" multicast=\"default\" /></Interfaces></General></Domain></CycloneDDS>"

unset unitree_ros_distro unitree_network_interface unitree_ros_setup
