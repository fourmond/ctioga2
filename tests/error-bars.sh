# error-bars.sh: error bars and others
# Copyright 2014 by Vincent Fourmond
# 
# You can do whatever you want with this file, including removing the
# copyright notice and this text.

. ./test-include.sh

# First is not a figure in itself, just a test of the ctable-like
# facility of ctioga2.

$ct --math-samples 50 -L 't:t**2/10:sin(t**20)' -P /save=error-bars.dat

$ct --text error-bars.dat@'$1:$2:yerr=$3' /legend 'Y error bars' \
    error-bars.dat@'$1:$2+3:xerr=$3' /legend 'X error bars' \
    error-bars.dat@'$1:$2-3:$3:yerr=$3' /where 'z > 0.1' /legend 'With selection' \
    error-bars.dat@'$1:$2-6:xerr=$3:$3**2:yerr=$3' /where 'z < 0.5' /legend 'Second With selection'
