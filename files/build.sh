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

# Check arguments

readonly ARCH="${ARCH:-x86_64}"

if [ -z "$ARCH" ]
then
  echo "Error: No architecture was specified. Please specify either 'i686' or 'x86_64', case sensitive, as the first argument to the script."
  exit 1
fi

if [[ "$ARCH" != "i686" ]] && [[ "$ARCH" != "x86_64" ]]
then
  echo "Error: Incorrect architecture was specified. Please specify either 'i686' or 'x86_64', case sensitive, as the first argument to the script."
  exit 1
fi

# More directory variables

readonly BUILD_DIR="/build"
readonly OUTPUT_DIR="/output"
readonly DEP_DIR="$WORKSPACE_DIR/$ARCH/dep-cache"
readonly APT_CACHE_DIR="$WORKSPACE_DIR/$ARCH/apt_cache"

# Build dir should be empty

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

set -euox pipefail

# Use all cores for building

MAKEFLAGS=j$(nproc)
export MAKEFLAGS

readonly WGET_OPTIONS="--timeout=10"

# Helper functions

# We check sha256 of all tarballs we download
check_sha256()
{
  if ! ( echo "$1  $2" | sha256sum -c --status - )
  then
    echo "Error: sha256 of $2 doesn't match the known one."
    echo "Expected: $1  $2"
    echo -n "Got: "
    sha256sum "$2"
    exit 1
  else
    echo "sha256 matches the expected one: $1"
  fi
}

# If it's not a tarball but a git repo, let's check a hash of a file containing hashes of all files
check_sha256_git()
{
  # There should be .git directory
  if [ ! -d ".git" ]
  then
    echo "Error: this function should be called in the root of a git repository."
    exit 1
  fi
  # Create a file listing hashes of all the files except .git/*
  find . -type f | grep -v "^./.git" | LC_COLLATE=C sort --stable --ignore-case | xargs sha256sum > /tmp/hashes.sha
  check_sha256 "$1" "/tmp/hashes.sha"
}

# Strip binaries to reduce file size, we don't need this information anyway
strip_all()
{
  set +e
  for PREFIX_DIR in $DEP_DIR/*; do
    strip --strip-unneeded $PREFIX_DIR/bin/*
    $ARCH-w64-mingw32-strip --strip-unneeded $PREFIX_DIR/bin/*
    $ARCH-w64-mingw32-strip --strip-unneeded $PREFIX_DIR/lib/*
  done
  set -e
}

# OpenSSL

OPENSSL_PREFIX_DIR="$DEP_DIR/libopenssl"
OPENSSL_VERSION=1.0.2s
# hash from https://www.openssl.org/source/
OPENSSL_HASH="cabd5c9492825ce5bd23f3c3aeed6a97f8142f606d893df216411f07d1abab96"
OPENSSL_FILENAME="openssl-$OPENSSL_VERSION.tar.gz"

rm -rf "$OPENSSL_PREFIX_DIR"
mkdir -p "$OPENSSL_PREFIX_DIR"

wget $WGET_OPTIONS "https://www.openssl.org/source/$OPENSSL_FILENAME"
check_sha256 "$OPENSSL_HASH" "$OPENSSL_FILENAME"
bsdtar --no-same-owner --no-same-permissions -xf "$OPENSSL_FILENAME"
rm $OPENSSL_FILENAME
cd openssl*

CONFIGURE_OPTIONS="--prefix=$OPENSSL_PREFIX_DIR shared"
if [[ "$ARCH" == "x86_64" ]]
then
  CONFIGURE_OPTIONS="$CONFIGURE_OPTIONS mingw64 --cross-compile-prefix=x86_64-w64-mingw32-"
elif [[ "$ARCH" == "i686" ]]
then
  CONFIGURE_OPTIONS="$CONFIGURE_OPTIONS mingw --cross-compile-prefix=i686-w64-mingw32-"
fi

./Configure $CONFIGURE_OPTIONS
make
make install
echo -n $OPENSSL_VERSION > $OPENSSL_PREFIX_DIR/done

CONFIGURE_OPTIONS=""

cd ..
rm -rf ./openssl*

# SQLCipher

SQLCIPHER_PREFIX_DIR="$DEP_DIR/libsqlcipher"
SQLCIPHER_VERSION=v4.2.0
SQLCIPHER_HASH="105c1b813f848da038c03647a8bfc9d42fb46865e6aaf4edfd46ff3b18cdccfc"
SQLCIPHER_FILENAME="$SQLCIPHER_VERSION.tar.gz"

rm -rf "$SQLCIPHER_PREFIX_DIR"
mkdir -p "$SQLCIPHER_PREFIX_DIR"

wget $WGET_OPTIONS "https://github.com/sqlcipher/sqlcipher/archive/$SQLCIPHER_FILENAME"
check_sha256 "$SQLCIPHER_HASH" "$SQLCIPHER_FILENAME"
bsdtar --no-same-owner --no-same-permissions -xf "$SQLCIPHER_FILENAME"
rm $SQLCIPHER_FILENAME
cd sqlcipher*

sed -i s/'LIBS="-lcrypto  $LIBS"'/'LIBS="-lcrypto -lgdi32  $LIBS"'/g configure
sed -i s/'LIBS="-lcrypto $LIBS"'/'LIBS="-lcrypto -lgdi32  $LIBS"'/g configure
sed -i s/'if test "$TARGET_EXEEXT" = ".exe"'/'if test ".exe" = ".exe"'/g configure
sed -i 's|exec $PWD/mksourceid manifest|exec $PWD/mksourceid.exe manifest|g' tool/mksqlite3h.tcl

# Do not remove trailing whitespace and dont replace tabs with spaces in the patch below,
#  otherwise the patch will fail to apply
> Makefile.in-patch cat << "EOF"
--- Makefile.in	2017-07-24 04:33:46.944080013 +0000
+++ Makefile.in-patch	2017-07-24 04:50:47.340596990 +0000
@@ -1074,7 +1074,7 @@
    $(TOP)/ext/fts5/fts5_varint.c \
    $(TOP)/ext/fts5/fts5_vocab.c  \

-fts5parse.c:	$(TOP)/ext/fts5/fts5parse.y lemon
+fts5parse.c:	$(TOP)/ext/fts5/fts5parse.y lemon$(BEXE)
 	cp $(TOP)/ext/fts5/fts5parse.y .
 	rm -f fts5parse.h
 	./lemon$(BEXE) $(OPTS) fts5parse.y

EOF

patch -l < Makefile.in-patch

./configure --host="$ARCH-w64-mingw32" \
            --prefix="$SQLCIPHER_PREFIX_DIR" \
            --disable-shared \
            --enable-tempstore=yes \
            CFLAGS="-O2 -g0 -DSQLITE_HAS_CODEC -I$OPENSSL_PREFIX_DIR/include/" \
            LDFLAGS="$OPENSSL_PREFIX_DIR/lib/libcrypto.a -lcrypto -lgdi32 -L$OPENSSL_PREFIX_DIR/lib/"

sed -i s/"TEXE = $"/"TEXE = .exe"/ Makefile

make
make install
cp "$SQLCIPHER_PREFIX_DIR/bin/sqlcipher.exe" "$OUTPUT_DIR/"
