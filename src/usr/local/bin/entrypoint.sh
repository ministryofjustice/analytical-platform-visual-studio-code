#!/usr/bin/env bash

mkdir --parent /home/analyticalplatform/workspace

/usr/bin/code serve-web \
  --without-connection-token \
  --accept-server-license-terms \
  --host 0.0.0.0 \
  --port 8080
