<!--

********************************************************************************

WARNING:

    DO NOT EDIT "kapacitor/README.md"

    IT IS AUTO-GENERATED

    (from the other files in "kapacitor/" combined with a set of templates)

********************************************************************************

-->

# Quick reference

-	**Maintained by**:  
	[InfluxData](https://github.com/influxdata/influxdata-docker)

-	**Where to get help**:  
	[the Docker Community Slack](https://dockr.ly/comm-slack), [Server Fault](https://serverfault.com/help/on-topic), [Unix & Linux](https://unix.stackexchange.com/help/on-topic), or [Stack Overflow](https://stackoverflow.com/help/on-topic)

# Supported tags and respective `Dockerfile` links

-	[`1.7`, `1.7.7`](https://github.com/influxdata/influxdata-docker/blob/98c1460c26ffb6d62d5cc659b1ead23c67437e5d/kapacitor/1.7/Dockerfile)

-	[`1.7-alpine`, `1.7.7-alpine`, `alpine`](https://github.com/influxdata/influxdata-docker/blob/98c1460c26ffb6d62d5cc659b1ead23c67437e5d/kapacitor/1.7/alpine/Dockerfile)

-	[`1.8`, `1.8.0`, `latest`](https://github.com/influxdata/influxdata-docker/blob/98c1460c26ffb6d62d5cc659b1ead23c67437e5d/kapacitor/1.8/Dockerfile)

-	[`1.8-alpine`, `1.8.0-alpine`](https://github.com/influxdata/influxdata-docker/blob/98c1460c26ffb6d62d5cc659b1ead23c67437e5d/kapacitor/1.8/alpine/Dockerfile)

# Quick reference (cont.)

-	**Where to file issues**:  
	[https://github.com/influxdata/influxdata-docker/issues](https://github.com/influxdata/influxdata-docker/issues?q=)

-	**Supported architectures**: ([more info](https://github.com/docker-library/official-images#architectures-other-than-amd64))  
	[`amd64`](https://hub.docker.com/r/amd64/kapacitor/), [`arm64v8`](https://hub.docker.com/r/arm64v8/kapacitor/)

-	**Published image artifact details**:  
	[repo-info repo's `repos/kapacitor/` directory](https://github.com/docker-library/repo-info/blob/master/repos/kapacitor) ([history](https://github.com/docker-library/repo-info/commits/master/repos/kapacitor))  
	(image metadata, transfer size, etc)

-	**Image updates**:  
	[official-images repo's `library/kapacitor` label](https://github.com/docker-library/official-images/issues?q=label%3Alibrary%2Fkapacitor)  
	[official-images repo's `library/kapacitor` file](https://github.com/docker-library/official-images/blob/master/library/kapacitor) ([history](https://github.com/docker-library/official-images/commits/master/library/kapacitor))

-	**Source of this description**:  
	[docs repo's `kapacitor/` directory](https://github.com/docker-library/docs/tree/master/kapacitor) ([history](https://github.com/docker-library/docs/commits/master/kapacitor))

# Kapacitor

Kapacitor is an open source data processing engine written in Go. It can process both stream and batch data.

[Kapacitor Official Documentation](https://docs.influxdata.com/kapacitor/latest/introduction/getting_started/)

![logo](https://raw.githubusercontent.com/docker-library/docs/43d87118415bb75d7bb107683e79cd6d69186f67/kapacitor/logo.png)

## Using this image

### Using the default configuration

Start the Kapacitor container with default options:

```console
$ docker run -p 9092:9092 kapacitor
```

Start the Kapacitor container sharing the data directory with the host:

```console
$ docker run -p 9092:9092 \
      -v $PWD:/var/lib/kapacitor \
      kapacitor
```

Modify `$PWD` to the directory where you want to store data associated with the Kapacitor container.

You can also have Docker control the volume mountpoint by using a named volume.

```console
$ docker run -p 9092:9092 \
      -v kapacitor:/var/lib/kapacitor \
      kapacitor
```

### Configuration

Kapacitor can be either configured from a config file or using environment variables. To mount a configuration file and use it with the server, you can use this command:

Generate the default configuration file:

```console
$ docker run --rm kapacitor kapacitord config > kapacitor.conf
```

Modify the default configuration, which will now be available under `$PWD`. Then start the Kapacitor container.

```console
$ docker run -p 9092:9092 \
      -v $PWD/kapacitor.conf:/etc/kapacitor/kapacitor.conf:ro \
      kapacitor
```

Modify `$PWD` to the directory where you want to store the configuration file.

For environment variables, the format is `KAPACITOR_$SECTION_$NAME`. All dashes (`-`) are replaced with underscores (`_`). If the variable isn't in a section, then omit that part. If the config section is an array, use a number to set the nth value in the configuration file.

Examples:

```console
KAPACITOR_HOSTNAME=kapacitor
KAPACITOR_LOGGING_LEVEL=INFO
KAPACITOR_REPORTING_ENABLED=false
KAPACITOR_INFLUXDB_0_URLS_0=http://influxdb:8086
```

Find more about configuring Kapacitor [here](https://docs.influxdata.com/kapacitor/latest/introduction/installation/)

#### Running as root

Starting in v1.7.4, Kapacitor no longer run as the root user by default. If a user wants to revert this change they can set `KAPACITOR_AS_ROOT=true` as an environment variable.

### Exposed Ports

-	9092 TCP -- HTTP API endpoint

#### Subscriptions

Subscriptions allow InfluxDB to push data to Kapacitor for faster alerting instead of requiring Kapacitor to pull data from InfluxDB.

These examples assume you are using a custom configuration file that takes advantage of Docker's built-in service discovery capability. In order to do so, we'll first create a new network:

```console
$ docker network create influxdb
```

Next, we'll start our InfluxDB container named `influxdb`:

```console
$ docker run -d --name=influxdb \
      --net=influxdb \
      influxdb
```

Start the Kapacitor container with the container hostname matching the container name so Kapacitor can automatically create subscriptions correctly and with the `KAPACITOR_INFLUXDB_0_URLS_0` value set to point at InfluxDB.

```console
$ docker run -p 9092:9092 \
    --name=kapacitor \
    -h kapacitor \
    --net=influxdb \
    -e KAPACITOR_INFLUXDB_0_URLS_0=http://influxdb:8086 \
    kapacitor
```

You can also start Kapacitor sharing the same network interface of the InfluxDB container. If you do this, Docker will act as if both processes were being run on the same machine.

```console
$ docker run -p 9092:9092 \
      --name=kapacitor \
      --net=container:influxdb \
      kapacitor
```

When run like this, InfluxDB can be communicated with over `localhost`.

### CLI / SHELL

Start the container:

```console
$ docker run --name=kapacitor -d -p 9092:9092 kapacitor
```

Run another container linked to the `kapacitor` container for using the client. Set the env `KAPACITOR_URL` so the client knows how to connect to Kapacitor. Mount in your current directory for accessing TICKscript files.

```console
$ docker run --rm --net=container:kapacitor \
      -v $PWD:/root -w=/root -it \
      kapacitor bash -l
```

Then, from within the container, you can use the `kapacitor` command to interact with the daemon.

See [this](https://docs.influxdata.com/kapacitor/latest/introduction/getting_started/) for a more detailed getting started guide with Kapacitor.

# Image Variants

The `kapacitor` images come in many flavors, each designed for a specific use case.

## `kapacitor:<version>`

This is the defacto image. If you are unsure about what your needs are, you probably want to use this one. It is designed to be used both as a throw away container (mount your source code and start the container to start your app), as well as the base to build other images off of.

## `kapacitor:<version>-alpine`

This image is based on the popular [Alpine Linux project](https://alpinelinux.org), available in [the `alpine` official image](https://hub.docker.com/_/alpine). Alpine Linux is much smaller than most distribution base images (~5MB), and thus leads to much slimmer images in general.

This variant is useful when final image size being as small as possible is your primary concern. The main caveat to note is that it does use [musl libc](https://musl.libc.org) instead of [glibc and friends](https://www.etalabs.net/compare_libcs.html), so software will often run into issues depending on the depth of their libc requirements/assumptions. See [this Hacker News comment thread](https://news.ycombinator.com/item?id=10782897) for more discussion of the issues that might arise and some pro/con comparisons of using Alpine-based images.

To minimize image size, it's uncommon for additional related tools (such as `git` or `bash`) to be included in Alpine-based images. Using this image as a base, add the things you need in your own Dockerfile (see the [`alpine` image description](https://hub.docker.com/_/alpine/) for examples of how to install packages if you are unfamiliar).

# License

View [license information](https://github.com/influxdata/kapacitor/blob/master/LICENSE) for the software contained in this image.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

Some additional license information which was able to be auto-detected might be found in [the `repo-info` repository's `kapacitor/` directory](https://github.com/docker-library/repo-info/tree/master/repos/kapacitor).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
