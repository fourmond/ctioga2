# test-include.sh: setup for the tests
# Copyright 2009 by Vincent Fourmond.
# You can do whatever you want with this file.

ct_add=""
if [ -z "$NOXPDF" ]; then
    ct_add="$ct_add -X"
fi
if [ "$DEBUG" ]; then
    ct_add="$ct_add --debug"
fi

# We can do code coverage
if [ "$COVERAGE" ]; then
    rm -f .cov                  # To reset the number
    coverage_name=$(basename ${0%%.sh})"-%02d"
    ct_add="--coverage $coverage_name $ct_add"
fi

# The way to invoke ctioga2
ct="ctioga2 $ct_add --echo --math $CT_ADD "
if [ "$RUBY" ]; then
    ct="$RUBY ../bin/$ct"
fi
