#!/usr/bin/env bash

if [[ "$(curl --silent http://localhost:8080 | grep Microsoft)" == *"Microsoft Corporation"* ]]; then
  exit 0
else
  exit 1
fi
