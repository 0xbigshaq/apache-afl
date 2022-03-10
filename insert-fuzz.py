#!/usr/bin/env python3

# Purpose
# ----------
# .patch files with `diff` syntax are not always reliable, because the line-numbers might changes from version 
# to version,  which requires us  to  create a  dedicated .patch file  for  every version of apache.
# This approach makes the whole process too tedious / version-specific. Which is why I preferred dedicating
# this py file for hot-patching purposes in a 'universal way'(pseudo-regex approach) since our goal is to support
# as many Apache versions as we can without breaking stuff in the process.


# hot-patch #1: Enable fuzzing via stdin
needle = 'int main(int argc, const char * const argv[])\n{' 
with open('../fuzz.patch.c', 'r') as f:
    fuzzable = f.read()

with open('./server/main.c', 'r+') as f:
    haystack = f.read()
result = haystack.replace(needle, fuzzable)
    f.seek(0)
    f.write(result)
print('[+] ./server/main.c is patched :^) \n')



# hot-patch #2: Disable randomness to improve stability
with open('./server/core.c', 'r+') as f:
    haystack = f.read()
needle = 'rv = apr_generate_random_bytes(seed, sizeof(seed));' 
disable_random = '''
    	// ---- PATCH -----
        // rv = apr_generate_random_bytes(seed, sizeof(seed));
    	char constant_seed[] = {0x78,0xAB,0xF5,0xDB,0xE2,0x7F,0xD2,0x8A};
        memcpy(seed, constant_seed, sizeof(seed));
        rv = APR_SUCCESS;
        //-------------------------------------------------

'''
result = haystack.replace(needle, disable_random)
    f.seek(0)
    f.write(result)
    print('[+] ./server/core.c is patched :^) \n')



with open('./server/core.c', 'w') as f:
    f.write(result)

print('[+] ./server/core.c is patched :^) \n')