#!/usr/bin/env bash
# Source the ROS 2 underlay and, when present, the colcon overlay of the
# workspace, then hand over to the requested command.
set -e

# shellcheck disable=SC1090,SC1091
source "/opt/ros/${ROS_DISTRO}/setup.bash"

if [ -f "${WORKSPACE}/install/setup.bash" ]; then
    # shellcheck disable=SC1090,SC1091
    source "${WORKSPACE}/install/setup.bash"
fi

exec "$@"
