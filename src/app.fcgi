#!/bin/sh

cd $(dirname $0)
if [ "$ENV" = "devel" ]; then
    EXTRA_WATCH_DIRS="-R /home/jsnell/sites/terra/git/src/"
fi

set -x

exec plackup -s FCGI -r $EXTRA_WATCH_DIRS --access-log=/dev/null

