# grid.sh: demonstration of the new grid layout
# Copyright 2010 by Vincent Fourmond
# 
# This file is provided as an example of how to use ctioga2. As such,
# you can do whatever you wish with this file.

# Include the definition of ct
. ./test-include.sh

# Plain grid
$ct --setup-grid 2x2 --inset grid:1,0 'sin(x)' \
    --next-inset grid:0,1 'x**2'

# Non-uniform cell sizes
$ct --setup-grid 1,2x2,1 --inset grid:1,0 'sin(x)' \
    --next-inset grid:0,1 'x**2'

# Additional specification
$ct --setup-grid 1,2x2,1 --inset grid:1,0,xl=0.3 'sin(x)' \
    --next-inset grid:0,1,yt=0.7,xr=0.9 'x**2'

# Use of style sheets to simplify the handling of background/axes and
# the like
$ct --setup-grid 1,2x2,1 \
    --default-background-style background /background_color=Pink \
    /watermark='two line\\watermark' \
    --inset grid:1,0 'sin(x)' \
    --next-inset grid:0,1 'x**2'