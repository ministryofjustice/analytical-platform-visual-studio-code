#!/usr/bin/env bash

# Restore Bash configuration
if [[ ! -f "/home/analyticalplatform/.bashrc" ]]; then
  cp /opt/visual-studio-code/.bashrc /home/analyticalplatform/.bashrc
fi

if [[ ! -f "/home/analyticalplatform/.bash_logout" ]]; then
  cp /opt/visual-studio-code/.bashrc /home/analyticalplatform/.bash_logout
fi

if [[ ! -f "/home/analyticalplatform/.profile" ]]; then
  cp /opt/visual-studio-code/.bashrc /home/analyticalplatform/.profile
fi

# Create workspace directory
if [[ ! -d "/home/analyticalplatform/workspace" ]]; then
  mkdir --parent /home/analyticalplatform/workspace
fi

# Start Visual Studio Code Server
/usr/bin/code serve-web \
  --without-connection-token \
  --accept-server-license-terms \
  --host 0.0.0.0 \
  --port 8080
