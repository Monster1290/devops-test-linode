#!/bin/bash

image_id=$(docker stop app)

if [[ $! -eq 0 ]]; then
  docker rm app
  docker rmi "${image_id}"
else
  exit 0
fi