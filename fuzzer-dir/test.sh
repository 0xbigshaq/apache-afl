#!/bin/bash

cat $1 | LD_LIBRARY_PATH=/usr/local/lib:/usr/local/apache2/lib/:$(pwd)/../compiler-rt-10.0.0.src/build-compiler-rt/lib/linux:$LD_LIBRARY_PATH /usr/local/apache2/bin/httpd -X && tput sgr0