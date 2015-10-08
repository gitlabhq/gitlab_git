#!/bin/bash
if [ -f /.dockerinit ]; then
    apt-get update -qq
    apt-get install -y -qq libicu-dev cmake
else
    export PATH=$HOME/bin:/usr/local/bin:/usr/bin:/bin
fi
