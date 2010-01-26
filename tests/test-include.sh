# test-include.sh: setup for the tests
# Copyright 2009 by Vincent Fourmond.
# You can do whatever you want with this file.

if [ -z $NOXPDF ]; then
    ct_xpdf="-X"
else
    ct_xpdf=""
fi
# The way to invoque ctioga2
ct="ctioga2 $ct_xpdf --echo --math $CT_ADD "