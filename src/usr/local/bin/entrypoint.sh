#!/usr/bin/env bash

# Restore Bash configuration
cp /opt/visual-studio-code/.bashrc /home/analyticalplatform/.bashrc
cp /opt/visual-studio-code/.bash_logout /home/analyticalplatform/.bash_logout
cp /opt/visual-studio-code/.profile /home/analyticalplatform/.profile

mkdir --parent /home/analyticalplatform/workspace

/usr/bin/code serve-web \
  --without-connection-token \
  --accept-server-license-terms \
  --host 0.0.0.0 \
  --port 8080
