# draw.sh: tests for drawing commands
# Copyright 2010 by Vincent Fourmond 
# This file is provided as an example of how to use ctioga2. As such,
# you can do whatever you wish with this file.

# Include the definition of ct
. ./test-include.sh

$ct --setup-grid 1x2 \
    --inset grid:0,0 -t "Lines that spawn several insets" \
    'sin(x)' \
    --next-inset grid:0,1 \
    'cos(x)' \
    --draw-line -6,0 8,4 /color Purple \
    --draw-line -6,0.5 8,4.5 /color Blue /clipped=false

