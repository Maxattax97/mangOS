#!/bin/bash

script="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
srcdir=$script/../

docker run -v $srcdir:/mangos --privileged -it mangos-builder /bin/bash
