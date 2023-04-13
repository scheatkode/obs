#!/bin/sh

set -e
set -u
set -x

/usr/bin/luajit /usr/bin/busted "${@}"
