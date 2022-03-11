#!/bin/bash

# deps fixup 
apt-get update
apt-get install -y brotli libbrotli-dev libxml2-dev libssl-dev wget curl

# download llvm & compiler-rt to enable custom ASAN interceptors
# https://releases.llvm.org/download.html#10.0.0
apt-get install -y llvm 
wget https://github.com/llvm/llvm-project/releases/download/llvmorg-10.0.0/compiler-rt-10.0.0.src.tar.xz
tar -xvf compiler-rt-10.0.0.src.tar.xz
rm compiler-rt-10.0.0.src.tar.xz
cd compiler-rt-10.0.0.src
mkdir build-compiler-rt
cd build-compiler-rt
cmake ../
make
export LD_LIBRARY_PATH=/usr/local/lib:$(pwd)/lib/linux:$LD_LIBRARY_PATH

cd ../../

mkdir -p /usr/local/apache_lab/
PREFIX=/usr/local/apache_lab/

## Download Apache httpd
# -----------------------------
wget https://archive.apache.org/dist/httpd/httpd-2.4.52.tar.gz
tar -xvzf httpd-2.4.52.tar.gz && rm httpd-2.4.52.tar.gz
cd ./httpd-2.4.52/


# handling dependencies 
# -----------------------------
mkdir -p deps-dir/
cd ./deps-dir

# APR
wget https://archive.apache.org/dist/apr/apr-1.7.0.tar.gz
tar -xvzf apr-1.7.0.tar.gz && rm apr-1.7.0.tar.gz && mv ./apr-1.7.0 apr
cd apr/
./configure --prefix="$PREFIX/apr/"
make && make install
cd ..


# APR-UTIL
wget https://archive.apache.org/dist/apr/apr-util-1.6.1.tar.gz
tar -xvzf apr-util-1.6.1.tar.gz && rm apr-util-1.6.1.tar.gz && mv ./apr-util-1.6.1 apr-util
cd apr-util/
./configure --prefix="$PREFIX/apr-util/" --with-apr="$PREFIX/apr/"
make && make install
cd ..

# EXPAT
wget  https://github.com/libexpat/libexpat/releases/download/R_2_4_1/expat-2.4.1.tar.gz
tar -xvzf expat-2.4.1.tar.gz && rm expat-2.4.1.tar.gz && mv ./expat-2.4.1 expat
cd expat/
./configure --prefix="$PREFIX/expat/"
make && make install
cd ../

# PCRE
wget http://ftp.cs.stanford.edu/pub/exim/pcre/pcre-8.45.tar.gz
tar -xvzf pcre-8.45.tar.gz && rm pcre-8.45.tar.gz && mv ./pcre-8.45 pcre
cd pcre/
./configure --prefix="$PREFIX/pcre/"
make && make install
cd ../



## Compile httpd
# -----------------------------

# return to the httpd directory
cd ../

# apply hot-patching to enable fuzzing via AFL
chmod +x ../insert-fuzz.py
../insert-fuzz.py

# configure compiler, flags and DSOs/apache modules

CC=afl-clang-fast \
CXX=afl-clang-fast++ \
CFLAGS="-g -fsanitize=address -fno-sanitize-recover=all -I$(pwd)/../compiler-rt-10.0.0.src/lib  -shared-libasan" \
CXXFLAGS="-g -fsanitize=address -fno-sanitize-recover=all" \
LDFLAGS="-fsanitize=address -fno-sanitize-recover=all -lm" \
./configure --with-apr="$PREFIX/apr/" \
            --with-apr-util="$PREFIX/apr-util/" \
            --with-expat="$PREFIX/expat/" \
            --with-pcre="$PREFIX/pcre/" \
            --disable-pie \
            --disable-so \
            --disable-example-ipc \
            --disable-example-hooks \
            --disable-optional-hook-export \
            --disable-optional-hook-import \
            --disable-optional-fn-export \
            --disable-optional-fn-import \
            --with-mpm=prefork \
            --enable-static-support \
            --enable-mods-static=reallyall \
            --enable-debugger-mode \
            --with-crypto --with-openssl \
            --disable-shared

# compile
make -j $(nproc)
# make install
