#!/bin/sh

if ! [ -f /crashplan/conf/default.service.xml ]; then
	cp -a /crashplan/conf.orig/* /crashplan/conf/
fi

exec "$@"

