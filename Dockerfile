###############################################################################
# Redis sentinel base image
# Creation date: 05/04/2018
# Author: eltonplima
###############################################################################
FROM python:2.7-alpine3.7

ENV HOME /home/app
WORKDIR /home/app
RUN apk update && apk add redis && pip install supervisor
COPY . /
RUN chmod +x /entrypoint.sh
HEALTHCHECK --interval=10s --timeout=2s --retries=3 CMD ping -c 1 -w 1 $SENTINEL_HOST
ENTRYPOINT /entrypoint.sh
