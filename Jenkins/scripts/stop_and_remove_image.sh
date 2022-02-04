#!/bin/bash

image_id=$(docker stop app)

# shellcheck disable=SC2181
if [[ $? -eq 0 ]]; then
  echo "Container stopped"
  docker rm app
  echo "Container removed"
  docker rmi "${image_id}"
  echo "Old image removed"
else
  echo "No running container on this instance"
  exit 0
fi