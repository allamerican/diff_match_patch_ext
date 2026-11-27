require 'mkmf'

# diff_match_patch.h is header-only C++ with no other dependencies.
$CXXFLAGS << ' -std=c++11'
# Some Rubies (e.g. 3.3) are built with empty CXXFLAGS, which compiles C++ unoptimized.
$CXXFLAGS << ' -O2' unless $CXXFLAGS =~ /(\A|\s)-O/

create_makefile('diff_match_patch_ext/diff_match_patch_ext')
