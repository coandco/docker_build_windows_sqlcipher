FROM debian:stretch-slim

ADD files/setup.sh /tmp

RUN /tmp/setup.sh

ADD files/build.sh /tmp

ENTRYPOINT ["/tmp/build.sh"]
