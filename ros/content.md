# What is [ROS](https://www.ros.org/)?

The Robot Operating System (ROS) is a set of software libraries and tools that help you build robot applications. From drivers to state-of-the-art algorithms, and with powerful developer tools, ROS has what you need for your next robotics project. And it's all open source.

> [wikipedia.org/wiki/Robot_Operating_System](https://en.wikipedia.org/wiki/Robot_Operating_System)

[%%LOGO%%](https://www.ros.org/)

# How to use this image

## Creating a `Dockerfile` to install ROS packages

To create your own ROS docker images and install custom packages, here's a simple example of installing the C++, Python client library demos using the official released Debian packages via apt-get.

```dockerfile
FROM %%IMAGE%%:foxy

# install ros package
RUN apt-get update && apt-get install -y \
      ros-${ROS_DISTRO}-demo-nodes-cpp \
      ros-${ROS_DISTRO}-demo-nodes-py && \
    rm -rf /var/lib/apt/lists/*

# launch ros package
CMD ["ros2", "launch", "demo_nodes_cpp", "talker_listener_launch.py"]
```

Note: all ROS images include a default entrypoint that sources the ROS environment setup before executing the configured command, in this case the demo packages launch file. You can then build and run the Docker image like so:

```console
$ docker build -t my/ros:app .
$ docker run -it --rm my/ros:app
[INFO] [launch]: process[talker-1]: started with pid [813]
[INFO] [launch]: process[listener-2]: started with pid [814]
[INFO] [talker]: Publishing: 'Hello World: 1'
[INFO] [listener]: I heard: [Hello World: 1]
[INFO] [talker]: Publishing: 'Hello World: 2'
[INFO] [listener]: I heard: [Hello World: 2]
...
```

## Creating a `Dockerfile` to build ROS packages

To create your own ROS docker images and build custom packages, here's a simple example of installing a package's build dependencies, compiling it from source, and installing the resulting build artifacts into a final multi-stage image layer.

```dockerfile
ARG FROM_IMAGE=%%IMAGE%%:foxy
ARG OVERLAY_WS=/opt/ros/overlay_ws

# multi-stage for caching
FROM $FROM_IMAGE AS cacher

# clone overlay source
ARG OVERLAY_WS
WORKDIR $OVERLAY_WS/src
RUN echo "\
repositories: \n\
  ros2/demos: \n\
    type: git \n\
    url: https://github.com/ros2/demos.git \n\
    version: ${ROS_DISTRO} \n\
" > ../overlay.repos
RUN vcs import ./ < ../overlay.repos

# copy manifests for caching
WORKDIR /opt
RUN mkdir -p /tmp/opt && \
    find ./ -name "package.xml" | \
      xargs cp --parents -t /tmp/opt && \
    find ./ -name "COLCON_IGNORE" | \
      xargs cp --parents -t /tmp/opt || true

# multi-stage for building
FROM $FROM_IMAGE AS builder

# install overlay dependencies
ARG OVERLAY_WS
WORKDIR $OVERLAY_WS
COPY --from=cacher /tmp/$OVERLAY_WS/src ./src
RUN . /opt/ros/$ROS_DISTRO/setup.sh && \
    apt-get update && rosdep install -y \
      --from-paths \
        src/ros2/demos/demo_nodes_cpp \
        src/ros2/demos/demo_nodes_py \
      --ignore-src \
    && rm -rf /var/lib/apt/lists/*

# build overlay source
COPY --from=cacher $OVERLAY_WS/src ./src
ARG OVERLAY_MIXINS="release"
RUN . /opt/ros/$ROS_DISTRO/setup.sh && \
    colcon build \
      --packages-select \
        demo_nodes_cpp \
        demo_nodes_py \
      --mixin $OVERLAY_MIXINS

# source entrypoint setup
ENV OVERLAY_WS $OVERLAY_WS
RUN sed --in-place --expression \
      '$isource "$OVERLAY_WS/install/setup.bash"' \
      /ros_entrypoint.sh

# run launch file
CMD ["ros2", "launch", "demo_nodes_cpp", "talker_listener_launch.py"]
```

The example above starts by using [`vcstool`](https://github.com/dirk-thomas/vcstool) to clone source repos of interest into the cacher stage. One could similarly `COPY` code from the local build context into the source directory as well. Package manifest files are then cached in a temporary directory where the following builder stage may copy from to install necessary dependencies with [`rosdep`](https://github.com/ros-infrastructure/rosdep). This is done prior to copying the rest of the source files to preserve the multi-stage build cache, given unaltered manifests do not alter declared dependencies, saving time and bandwidth. The overlay is then built using [`colcon`](https://colcon.readthedocs.io/en/released/), the entrypoint updated to source the workspace, and the default command set to launch the demo.

Note: `--from-paths` and `--packages-select` are set here as so to only install the dependencies and build for the demo C++ and Python packages, among many in the demo git repo that was cloned. To install the dependencies and build all the packages in the source workspace, merely change the scope by setting `--from-paths src/` and dropping the `--packages-select` arguments.

For more advance examples such as daisy chaining multiple overlay workspaces to improve caching of docker image build layers, using tools such as ccache to accelerate compilation with colcon, or using buildkit to save build time and bandwidth even when dependencies change, the project `Dockerfile`s in the ROS 2 [Navigation2](https://github.com/ros-planning/navigation2) repo are excellent resources.

## Deployment use cases

This dockerized image of ROS is intended to provide a simplified and consistent platform to build and deploy distributed robotic applications. Built from the [official Ubuntu image](https://hub.docker.com/_/ubuntu/) and ROS's official Debian packages, it includes recent supported releases for quick access and download. This provides roboticists in research and industry with an easy way to develop, reuse and ship software for autonomous actions and task planning, control dynamics, localization and mapping, swarm behavior, as well as general system integration.

Developing such complex systems with cutting edge implementations of newly published algorithms remains challenging, as repeatability and reproducibility of robotic software can fall to the wayside in the race to innovate. With the added difficulty in coding, tuning and deploying multiple software components that span across many engineering disciplines, a more collaborative approach becomes attractive. However, the technical difficulties in sharing and maintaining a collection of software over multiple robots and platforms has for a while exceeded time and effort than many smaller labs and businesses could afford.

With the advancements and standardization of software containers, roboticists are primed to acquire a host of improved developer tooling for building and shipping software. To help alleviate the growing pains and technical challenges of adopting new practices, we have focused on providing an official resource for using ROS with these new technologies.

For a complete listing of supported architectures and base images for each ROS Distribution Release, please read the official REP on target platforms for either [ROS 1](https://www.ros.org/reps/rep-0003.html) or for [ROS 2](https://www.ros.org/reps/rep-2000.html).

## Deployment suggestions

The available tags include supported distros along with a hierarchy tags based off the most common meta-package dependencies, designed to have a small footprint and simple configuration:

-	`ros-core`: minimal ROS install
-	`ros-base`: basic tools and libraries (also tagged with distro name with LTS version as `latest`)
-	`ros1-bridge`: tools and libraries to run hybrid ROS 1 - ROS 2 systems and bridge messages between them

In the interest of keeping `ros-core` tag minimal in image size, developer tools such as `rosdep`, `colcon` and `vcstools` are not shipped in `ros_core`, but in `ros-base` instead.

The rest of the common meta-packages such as `desktop` are hosted on repos under OSRF's Docker Hub profile [here](https://hub.docker.com/r/osrf/ros/). These meta-packages include graphical dependencies and hook a host of other large packages such as X11, X server, etc. So in the interest of keeping the official images lean and secure, the desktop packages are just being hosted with OSRF's profile. For an extensive list of available variants, please read the official REP on target platforms for either [ROS 1](https://ros.org/reps/rep-0150.html) or for [ROS 2](https://www.ros.org/reps/rep-2001.html).

### Volumes

ROS uses the `~/.ros/` directory for storing logs, and debugging info. If you wish to persist these files beyond the lifecycle of the containers which produced them, the `~/.ros/` folder can be mounted to an external volume on the host, or a derived image can specify volumes to be managed by the Docker engine. By default, the container runs as the `root` user, so `/root/.ros/` would be the full path to these files.

For example, if one wishes to use their own `.ros` folder that already resides in their local home directory, with a username of `ubuntu`, we can simply launch the container with an additional volume argument:

```console
$ docker run -v "/home/ubuntu/.ros/:/root/.ros/" %%IMAGE%%
```

### Devices

Some application may require device access for acquiring images from connected cameras, control input from human interface device, or GPUS for hardware acceleration. This can be done using the [`--device`](https://docs.docker.com/engine/reference/commandline/run/#add-host-device-to-container---device) run argument to mount the device inside the container, providing processes inside hardware access.

### Networks

ROS allows for peer-to-peer networking of processes (potentially distributed across machines) that are loosely coupled using the ROS communication infrastructure. ROS implements several different styles of communication, including synchronous RPC-style communication over services, asynchronous streaming of typed data over topics, combinations of both prior via request/reply and status/feedback over actions, and run-time settings via configuration over parameters. To abide by the best practice of [one process per container](https://docs.docker.com/articles/dockerfile_best-practices/), Docker networks can be used to string together several running ROS processes. For further details see the Deployment example further below.

Alternatively, more permissive network settings can be used to share all host network interfaces with the container, such as [`host` network driver](https://docs.docker.com/network/host/), simplifying connectivity with external network participants. Be aware however that this removes the networking namespace separation between containers, and can affect the ability of DDS participants to communicate between containers, as documented [here](https://community.rti.com/kb/how-use-rti-connext-dds-communicate-across-docker-containers-using-host-driver).

## Deployment example

### Docker Compose

In this example we'll demonstrate using [`docker compose`](https://docs.docker.com/compose/) to spawn a pair of message publisher and subscriber nodes in separate containers connected through shared software defined network.

> Create the directory `~/ros_demos` and add the first `Dockerfile` example from above. In the same directory, also create file `compose.yaml` with the following that runs a C++ publisher with a Python subscriber:

```yaml
services:
  talker:
    build: ./
    command: ros2 run demo_nodes_cpp talker

  listener:
    build: ./
    environment:
      - "PYTHONUNBUFFERED=1"
    command: ros2 run demo_nodes_py listener
```

> Use `docker compose` inside the same directory to launch our ROS nodes. Given the containers created derive from the same docker compose project, they will coexist on shared project network:

```console
$ docker compose up -d
```

> Notice that a new network named `ros_demos_default` has been created, as can be shown further with:

```console
$ docker network inspect ros_demos_default
```

> We can monitor the logged output of each container, such as the listener node like so:

```console
$ docker compose logs listener
```

> Finally, we can stop and remove all the relevant containers using `docker compose` from the same directory:

```console
$ docker compose stop
$ docker compose rm
```

> Note: the auto-generated network, `ros_demos_default`, will persist until you explicitly remove it using `docker compose down`.

### ROS 1 Bridge

To ease ROS 2 migration, [`ros1_bridge`](https://index.ros.org/p/ros1_bridge) is a ROS 2 package that provides bidirectional communication between ROS 1 and ROS 2. As a minimal example, given the ROS 2 Dockerfile above, we'll create the ROS 1 equivalent below, and name the Dockerfile appropriately.

```dockerfile
FROM %%IMAGE%%:noetic

# install ros package
RUN apt-get update && apt-get install -y \
      ros-${ROS_DISTRO}-ros-tutorials \
      ros-${ROS_DISTRO}-common-tutorials && \
    rm -rf /var/lib/apt/lists/*

# launch ros package
CMD ["roslaunch", "roscpp_tutorials", "talker_listener_launch"]
```

The compose file bellow spawns services for both talker listener demos while connecting the two via a dynamic bridge. You may then view the log output from both pairs of talker and listener nodes cross talking over the `/chatter` topic.

```yaml
services:
  ros1:
    build:
      context: ./
      dockerfile: ros1.Dockerfile

  ros2:
    build:
      context: ./
      dockerfile: ros2.Dockerfile

  bridge:
    image: ros:foxy-ros1-bridge
    environment:
      - "ROS_HOSTNAME=bridge"
      - "ROS_MASTER_URI=http://ros1:11311"
    command: ros2 run ros1_bridge dynamic_bridge
```

# More Resources

[ROS.org](http://www.ros.org/): Main ROS website  
[Q&A](https://answers.ros.org/questions/): Ask questions. Get answers  
[Forums](https://discourse.ros.org/): Hear the latest discussions  
[Blog](http://www.ros.org/news/): Stay up-to-date  
[Packages](https://index.ros.org/?search_packages=true): Discover indexed packages  
[OSRF](https://www.osrfoundation.org/): Open Source Robotics Foundation

## ROS 2

[Index](https://docs.ros.org): ROS 2 Documentation  
[Design](https://design.ros2.org/): ROS 2 Design Articles

## ROS 1

[Wiki](http://wiki.ros.org/Documentation): ROS 1 Documentation
