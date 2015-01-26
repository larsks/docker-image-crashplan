FROM ubuntu:trusty
MAINTAINER Lars Kellogg-Stedman <lars@oddbit.com>

ENV DEBIAN_FRONTEND noninteractive

EXPOSE 4242 4243

RUN apt-get update && \
	apt-get -y --force-yes install wget; \
	apt-get clean

# fetch crashplan package
RUN cd /tmp; \
	wget --quiet -O crashplan.tgz \
	http://download1.us.code42.com/installs/linux/install/CrashPlan/CrashPlan_3.7.0_Linux.tgz; \
	tar -x -f crashplan.tgz

# install crashplan
COPY install-crashplan.sh /tmp/CrashPlan-install/install-crashplan.sh
RUN cd /tmp/CrashPlan-install; ./install-crashplan.sh; cd /tmp; rm -rf CrashPlan-install
RUN ln -s /crashplan/conf /var/lib/crashplan; \
	ln -s /usr/local/crashplan /crashplan

VOLUME /srv/backups
VOLUME /crashplan/log
VOLUME /crashplan/conf

COPY my.service.xml /crashplan/conf.orig/my.service.xml
COPY start-crashplan.sh /crashplan/bin/start-crashplan.sh
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/crashplan/bin/start-crashplan.sh"]

