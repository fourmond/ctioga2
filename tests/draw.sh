# draw.sh: tests for drawing commands
# Copyright 2010 by Vincent Fourmond 
# This file is provided as an example of how to use ctioga2. As such,
# you can do whatever you wish with this file.

# Include the definition of ct
. ./test-include.sh

$ct -t 'Text drawing' -r 10cmx10cm \
    'sin(x)' --draw-text 0,0 'center plus baseline' /alignment baseline \
    /color BrickRed /scale 1.2 \
    --draw-line -6,0 6,0 /color Green /style Dots \
    --draw-line 0,-1 0,1 /color Blue /style Dashes \
    --draw-text 0,-0.3 'left plus bottom' /justification left \
    /color Orange /scale 1.2  /alignment bottom \
    --draw-line -6,-0.3 6,-0.3 /color Green /style Dots 



$ct -t 'Boxes' -r 10cmx10cm \
    'sin(x)' \
    --draw-box -2,0.2 2,-0.2 /color=Blue /width=2 \
    --draw-box -5,0.8 -3,-0.4 /fill-color=Pink /color=Black \
    --draw-box 3,0.8 7,0 /fill-color=Pink /fill-transparency=0.7

$ct -t 'Styled lines' -r 10cmx10cm --math-xrange -3:3 \
    'sin(x)' \
    --draw-line -2,0.2 2,-0.2 /color=Blue /width=2 \
    --default-line-style line /style=Dots \
    --default-line-style line2 /width=1 \
    --draw-line 2,0.2 -2,-0.2 /color=Red /width=2 \
    --draw-line 2,-0.2 -2,-0.2 /color=Green /base-style=line2

