# draw.sh: tests for drawing commands
# Copyright 2010 by Vincent Fourmond 
# This file is provided as an example of how to use ctioga2. As such,
# you can do whatever you wish with this file.

# Include the definition of ct
. ./test-include.sh

$ct -t 'Text drawing' -r 10cmx10cm \
    'sin(x)' --draw-text 0,0 'Valign at baseline' /alignment baseline \
    /color BrickRed /scale 1.2 \
    --draw-line -6,0 6,0 /color Green /line_style Dots 

