#!/bin/bash

# run fuzzer
export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/apache2/lib/:$(pwd)/../compiler-rt-10.0.0.src/build-compiler-rt/lib/linux:$LD_LIBRARY_PATH
AFL_MAP_SIZE=256000 \
SHOW_HOOKS=1 \
ASAN_OPTIONS=detect_leaks=0,abort_on_error=1,symbolize=0,debug=true,check_initialization_order=true,detect_stack_use_after_return=true,strict_string_checks=true,detect_invalid_pointer_pairs=2 \
AFL_DISABLE_TRIM=1 \
 afl-fuzz \
    -t 2000 \
    -m none \
    -i './input-cases/' \
    -o './out-dir' \
    -x './dict/http_request_fuzzer.dict.txt' \
    -- '/usr/local/apache2/bin/httpd' -X -f $(pwd)/conf/default.conf

