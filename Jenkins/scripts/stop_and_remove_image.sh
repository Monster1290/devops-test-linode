#!/bin/bash

image_id=$(docker stop app)

if [[ $! -eq 1 ]]; then
  exit 0
fi

docker rm app
docker rmi "${image_id}"