#!/bin/sh

TM_CONFIG=${TM_CONFIG:-$(dirname $0)/config.json}
cd $(dirname $0)
if [ "$ENV" = "devel" ]; then
    EXTRA_WATCH_DIRS="-R /home/jsnell/sites/terra/git/src/"
fi

set -x

export PERL_HASH_SEED=0
exec plackup -s FCGI -r $EXTRA_WATCH_DIRS --access-log=/dev/null
