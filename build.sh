#!/bin/bash
tag=9.3
docker build -t smillerc/gfortran-dev:${tag} -f Dockerfile .
# docker push smillerc/gfortran-dev:${tag}