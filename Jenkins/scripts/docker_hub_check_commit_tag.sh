#!/bin/bash

# Simple script to check if current git commit in Jenkins pipline execution is exists as tag in image repository

REPO="monster1290/test-repo"
tags=$(wget --http-user=${DOCKER_HUB_USER} --http-password=${DOCKER_HUB_PASS} -q https://registry.hub.docker.com/v1/repositories/${REPO}/tags -O -  | sed -e 's/[][]//g' -e 's/"//g' -e 's/ //g' | tr '}' '\n'  | awk -F: '{print $3}')

for tag in $tags; do
  if [ "$tag" == "$GIT_COMMIT" ]; then
    exit 1
  fi
done