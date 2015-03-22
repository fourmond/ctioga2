# markers.sh: some advanced marker stuff ?
# Copyright 2015 by Vincent Fourmond 
# This file is provided as an example of how to use ctioga2. As such,
# you can do whatever you wish with this file.

# Include the definition of ct
. ./test-include.sh

$ct -t 'Two ways to draw open markers (with chosen line width)' \
    --marker auto \
    'sin(x)' /marker=BoxOpen /marker-line-width=0.2 \
    'cos(x)' /marker-line-width=0.2 /marker-fill-color=no

$ct -t 'Different fill and stroke colors' \
    --marker auto --marker-line-width 0.3 \
    'sin(x)' /marker-fill-color=Pink \
    'cos(x)' /marker-color=Blue /marker-line-color=Brown /marker-line-width 0.8
