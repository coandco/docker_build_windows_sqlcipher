#!/usr/bin/env bash

# MIT License
#
# Copyright (c) 2017-2018 Maxim Biro <nurupo.contributions@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


# Common directory paths

readonly WORKSPACE_DIR="/workspace"
readonly BUILD_DIR="/build"
readonly DEP_DIR="$WORKSPACE_DIR/$ARCH/dep-cache"
readonly APT_CACHE_DIR="$WORKSPACE_DIR/$ARCH/apt_cache"

# Create the expected directory structure

# Just make sure those exist
mkdir -p "$WORKSPACE_DIR"
mkdir -p "$DEP_DIR"
mkdir -p "$APT_CACHE_DIR"
mkdir -p "$BUILD_DIR"

# Get packages

apt-get update
apt-get install -y --no-install-recommends \
                   autoconf \
                   automake \
                   build-essential \
                   bsdtar \
                   ca-certificates \
                   cmake \
                   git \
                   libtool \
                   pkg-config \
                   tclsh \
                   unzip \
                   wget \
                   yasm \
                   zip \
                   g++-mingw-w64-i686 \
                   gcc-mingw-w64-i686 \
                   g++-mingw-w64-x86-64 \
                   gcc-mingw-w64-x86-64


