#!/bin/sh
set  -e

echo "::: Setting up ROOT environment"
cd /opt/root
source bin/thisroot.sh
cd ${HOME}
echo "::: Setting up ROOT environment... [done]"

exec "$@"
