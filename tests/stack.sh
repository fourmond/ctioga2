# backends.sh: few things with backends (and testing other stuff too)
# Copyright 2014 by Vincent Fourmond
# 
# This file is provided as an example of how to use ctioga2. As such,
# you can do whatever you wish with this file.

# Include the definition of ct
. ./test-include.sh

$ct --margin 0.03 \
    --load 'sin(x)' --load 'cos(x)' \
    --join-datasets --plot-last \
    --load 'sin(x)+1' --append 'cos(x)+1' \
    --plot-last


# Testing averages
# All should be the same !
$ct --math /samples=11 --margin 0.03 --marker auto \
    --marker-set open --line-style no \
    --plot 'sin(x)' \
    --load 'sin(x)' \
    --avg-dup-last --plot-last \
    --load 'sin(x)' \
    --join-datasets --sort-last --avg-dup-last --plot-last
