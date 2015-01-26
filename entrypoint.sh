#!/bin/sh

# If /crashplan/conf is a volume, ensure it has the necessary
# configuration files.
if ! [ -f /crashplan/conf/default.service.xml ]; then
	cp -a /crashplan/conf.orig/* /crashplan/conf/
fi

exec "$@"

