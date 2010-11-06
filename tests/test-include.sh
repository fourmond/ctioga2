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
# The way to invoque ctioga2
ct="ctioga2 $ct_add --echo --math $CT_ADD "