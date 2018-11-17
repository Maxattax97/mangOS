#! /bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "WARNING: It is recommended that you build under the root user so that permissions do not time out (as with sudo) during the build process."
fi
