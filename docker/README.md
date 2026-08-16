# Docker environment (ROS 2 Jazzy)

A container that builds and runs `apriltag_ros` on ROS 2 Jazzy (Ubuntu 24.04).
All dependencies (`apriltag`, `apriltag_msgs`, `cv_bridge`, `image_transport`,
`image_proc`, `camera_ros`, ...) are resolved with `rosdep` from the ROS 2 Jazzy
apt repository, so nothing needs to be installed on the host.

## Layout

| Path | Purpose |
| --- | --- |
| `Dockerfile` | Image based on `ros:jazzy-ros-base`, installs dependencies and pre-builds the workspace |
| `docker-compose.yml` | Service definition: source bind mount, colcon volumes, X11 forwarding |
| `docker-compose.host-net.yml` | Optional override that puts the container on the host network |
| `entrypoint.sh` | Sources `/opt/ros/jazzy/setup.bash` and the workspace overlay |

Inside the container the colcon workspace is `/ws`:

- `/ws/src/apriltag_ros` — bind mount of this repository (edit on the host)
- `/ws/build`, `/ws/install`, `/ws/log` — named volumes, so build artifacts never
  land in the host checkout

## Build the image

```sh
cd docker
USER_UID=$(id -u) USER_GID=$(id -g) docker compose build
```

`USER_UID`/`USER_GID` make the container user own the bind-mounted sources; they
default to `1000`.

## Run

Interactive shell (ROS 2 and the workspace overlay are already sourced):

```sh
docker compose run --rm apriltag
```

Run the standalone node directly:

```sh
docker compose run --rm apriltag \
    ros2 run apriltag_ros apriltag_node --ros-args \
        -r image_rect:=/camera/image \
        -r camera_info:=/camera/camera_info \
        --params-file /ws/install/apriltag_ros/share/apriltag_ros/cfg/tags_36h11.yaml
```

Run the composable node launch file (needs a camera, see below):

```sh
docker compose run --rm apriltag ros2 launch apriltag_ros camera_36h11.launch.yml
```

## Rebuild after editing the sources

The sources are bind-mounted, so a rebuild only needs a shell in the container:

```sh
docker compose run --rm apriltag colcon build --symlink-install \
    --cmake-args -DCMAKE_BUILD_TYPE=Release
```

Run the linters (`clang-format`, `cppcheck`) the same way:

```sh
docker compose run --rm apriltag bash -lc \
    'colcon build --symlink-install --cmake-args -DBUILD_TESTING=ON && colcon test && colcon test-result --verbose'
```

## Camera and display

- **Camera**: uncomment the `devices:` block in `docker-compose.yml` to pass a
  `/dev/video*` device through.
- **GUI tools** (`rviz2`, `image_view`): `DISPLAY` and `/tmp/.X11-unix` are
  already forwarded. On a plain X11 host, allow the container first with
  `xhost +local:docker`.

## Networking

The service uses the default bridge network, where DDS discovery works between
processes in the container.

To talk to ROS 2 nodes running outside the container, add the host-network
override:

```sh
docker compose -f docker-compose.yml -f docker-compose.host-net.yml run --rm apriltag
```

Known issue: on WSL2 the host network interface does not carry DDS discovery
traffic, so with that override nodes no longer find each other — even two
processes inside the same container. Stay on the default bridge network there.

`ROS_DOMAIN_ID` and `RMW_IMPLEMENTATION` can be overridden per invocation, e.g.
`ROS_DOMAIN_ID=7 docker compose run --rm apriltag`.
