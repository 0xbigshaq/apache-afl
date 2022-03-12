# apache-afl

An automated setup for compiling & fuzzing Apache httpd server.

More info about the process/journey can be found here: https://0xbigshaq.github.io/2022/03/12/fuzzing-smarter-part2

# Usage

To start the build process, run:

```
./afl-toolchain.sh
```

To start fuzzing:
```
cd fuzzer-dir/
./afl-runner.sh
```

> Tested on: AFL Version ++4.00c (release) under a `aflplusplus/aflplusplus` docker image
