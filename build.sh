#!/bin/bash
tag=latest
docker build -t smillerc/gfortran-dev:${tag} -f Dockerfile .
docker push smillerc/gfortran-dev:${tag}