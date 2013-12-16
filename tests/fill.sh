# fill.sh: demonstration and tests of the fill styles
# Copyright 2013 by Vincent Fourmond
# 
# This file is provided as an example of how to use ctioga2. As such,
# you can do whatever you wish with this file.

# Include the definition of ct
. ./test-include.sh


$ct --margin 0.03  -t 'Above and below' \
    'x' /fill bottom /fill-color='Red!10' \
    'x+1' /fill top /fill-color='Green!10' \

$ct --margin 0.03  -t 'Left and right' \
    'x' /fill right /fill-color='Red!10' \
    'x+1' /fill left /fill-color='Green!10' \

$ct --margin 0.03  -t 'Values and point' \
    'sin(x)' /fill 0.5 /fill-color='Red!10' \
    'sin(x)+2' /fill 1.8 /fill-color='Green!10' \
    'sin(x)+5' /fill xy:0,3 /fill-color='Blue!10' \
