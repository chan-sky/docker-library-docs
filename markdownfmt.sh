#!/usr/bin/env bash
set -e

exec docker run -i --rm -v "$PWD":/scratch -w /scratch -u "$(id -u):$(id -g)" tianon/markdownfmt markdownfmt "$@"
