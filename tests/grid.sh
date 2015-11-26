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
    --define-background-style background /background_color=Pink \
    /watermark='two line\\watermark' \
    --inset grid:1,0 'sin(x)' \
    --next-inset grid:0,1 'x**2'

# Use ranges
$ct --setup-grid 3x3 \
    --inset grid:0,0 'sin(x)' \
    --next-inset grid:0,1 'x**2' \
    --next-inset grid:0,2 'x**2' \
    --next-inset grid:1-2,1-2 'x**2'

# Further tests of non-uniform grids
# Non-uniform cell sizes
$ct --setup-grid 1,2x2 --inset grid:1,0 'sin(x)' \
    --next-inset grid:0,1 'x**2'

$ct --setup-grid 2x2,1 --inset grid:1,0 'sin(x)' \
    --next-inset grid:0,1 'x**2'


# Next !
$ct --setup-grid 2x2 \
    --inset grid:next 'sin(x)' \
    --next-inset grid:next 'x**2' \
    --next-inset grid:next 'x**3' \
    --next-inset grid:next  'x'

# Next !
$ct --define-axis-style '.grid-left axis.left' /axis-label-color Red \
    --define-axis-style '.grid-bottom axis.bottom' /axis-label-text "Auto !" \
    --define-axis-style '.grid-bottom axis' /background-lines-color Purple \
    --define-axis-style '.grid-2-0 axis' /decoration none \
    --define-curve-style '.grid-1-1 curve' /marker SquareOpen /marker-scale 0.3  \
    --define-background-style '.grid-odd-row background' /background-color Black\!10 \
    --setup-grid 3x3 \
    --inset grid:next 'sin(x)' \
    --next-inset grid:next 'x**2' \
    --next-inset grid:next 'x**3' \
    --next-inset grid:next  'x' \
    --next-inset grid:next  'x' \
    --next-inset grid:next  'x' \
    --next-inset grid:next  'x' \
    --next-inset grid:next  'x' \
    --next-inset grid:next  'x' \
