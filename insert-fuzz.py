#!/usr/bin/env python3

# Purpose
# ----------
# .patch files with `diff` syntax are not always reliable, because the line-numbers might changes from version 
# to version,  which requires us  to  create a  dedicated .patch file  for  every version of apache.
# This approach makes the whole process too tedious / version-specific. Which is why I preferred dedicating
# this py file for hot-patching purposes in a 'universal way'(pseudo-regex approach) since our goal is to support
# as many Apache versions as we can without breaking stuff in the process.


needle = 'int main(int argc, const char * const argv[])\n{' 
with open('./server/main.c', 'r') as f:
    haystack = f.read()

with open('../fuzz.patch.c', 'r') as f:
    fuzzable = f.read()


result = haystack.replace(needle, fuzzable)

with open('./server/main.c', 'w') as f:
    f.write(result)

print('[+] ./server/main.c is patched :^) \n')
