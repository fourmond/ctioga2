# backends.sh: few things with backends (and testing other stuff too)
# Copyright 2014 by Vincent Fourmond
# 
# This file is provided as an example of how to use ctioga2. As such,
# you can do whatever you wish with this file.

# Include the definition of ct
. ./test-include.sh

$ct --math-samples 1001 -t 'Smoothing' \
    'sin(x)+0.1*sin(100*x)' \
    --smooth-last 9 --plot-last \
    --smooth 9 'sin(x)+0.1*sin(100*x)+0.1'

$ct 'sin(x)' --marker auto --marker-scale 0.4 \
    --cherry-pick-last 'y < 0.5' --plot-last \
    --cherry-pick  'y > 0.5' 'sin(x)'
