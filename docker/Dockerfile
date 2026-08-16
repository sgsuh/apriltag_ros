# syntax=docker/dockerfile:1

# Development and runtime environment for apriltag_ros on ROS 2 Jazzy.
ARG ROS_DISTRO=jazzy
FROM ros:${ROS_DISTRO}-ros-base

ARG ROS_DISTRO
ARG USERNAME=ros
ARG USER_UID=1000
ARG USER_GID=${USER_UID}
ARG WORKSPACE=/ws

ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=${ROS_DISTRO}
ENV WORKSPACE=${WORKSPACE}

# Tooling to build, lint and debug ROS 2 packages.
RUN apt-get update && apt-get install -y --no-install-recommends \
        bash-completion \
        build-essential \
        ccache \
        cmake \
        gdb \
        git \
        less \
        nano \
        python3-colcon-common-extensions \
        python3-pip \
        python3-rosdep \
        python3-vcstool \
        sudo \
        wget \
    && rm -rf /var/lib/apt/lists/*

# Ubuntu 24.04 ships a default "ubuntu" user on UID 1000; drop it so the
# container user can match the UID/GID of the host user owning the sources.
RUN if getent passwd ${USER_UID} > /dev/null; then \
        userdel -r "$(getent passwd ${USER_UID} | cut -d: -f1)"; \
    fi \
    && (getent group ${USER_GID} > /dev/null || groupadd --gid ${USER_GID} ${USERNAME}) \
    && useradd --uid ${USER_UID} --gid ${USER_GID} --create-home --shell /bin/bash ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

# Resolve the declared dependencies in a layer that only package.xml invalidates.
COPY package.xml ${WORKSPACE}/src/apriltag_ros/package.xml
RUN apt-get update \
    && rosdep update --rosdistro ${ROS_DISTRO} \
    && rosdep install --from-paths ${WORKSPACE}/src --ignore-src --rosdistro ${ROS_DISTRO} -y \
    && rm -rf /var/lib/apt/lists/*

COPY . ${WORKSPACE}/src/apriltag_ros
RUN chown -R ${USER_UID}:${USER_GID} ${WORKSPACE}

USER ${USERNAME}
WORKDIR ${WORKSPACE}

# Pre-build the workspace so the image is usable without any extra step. At
# runtime the sources are bind-mounted and can be rebuilt with `colcon build`.
RUN . /opt/ros/${ROS_DISTRO}/setup.sh \
    && colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release

RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> /home/${USERNAME}/.bashrc \
    && echo "[ -f ${WORKSPACE}/install/setup.bash ] && source ${WORKSPACE}/install/setup.bash" >> /home/${USERNAME}/.bashrc

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
