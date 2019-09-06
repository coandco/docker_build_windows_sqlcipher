#!/bin/bash

docker build . -t builder

docker run --rm -it -v $(pwd):/output:rw builder:latest
