# grid.sh: demonstration of the new grid layout
# Copyright 2010 by Vincent Fourmond
# 
# This file is provided as an example of how to use ctioga2. As such,
# you can do whatever you wish with this file.

# Include the definition of ct
. ./test-include.sh


$ct --margin 0.03 --math /samples=20 -t 'Two histograms' \
    --histogram 'x' /fill 0 /fill-color='Red!10' \
    ' -x' /fill-color='Green!20' /fill 0 \

$ct --margin 0.03 --math /samples=20 -t 'Using fill styles' \
    --histogram 'x+30' /fill top /fill-color='Red!10' \
    ' -x + 20' /fill-color='Green!20' /fill 23 \

$ct --margin 0.03 --math /samples=20 -t 'Mixing normal curves and histograms' \
    --histogram 'x' /fill 0 /fill-color='Red!10' \
    ' -x' /fill-color='Green!20' /fill 0 \
    '0.1 * x**2' /fill-color='Blue!20' /fill 0 \
    --xy-plot '0.1*x**2'

$ct --margin 0.03 --math /samples=20 /xrange=0:1 -t 'Cumulative histograms' \
    --histogram /cumulative=0 /gap 1mm 'x' /fill 0 /fill-color='Red!10' \
    '1-x' /fill 0 /fill-color='Green!10'

$ct --margin 0.03 --math /samples=20 /xrange=0:1 -t 'Cumulative histograms, mixed with usual ones' \
    --histogram /cumulative=0 'x' /fill 0 /fill-color='Red!10' \
    '1-x' /fill 0 /fill-color='Green!10' \
    --histogram /cumulative=no \
    '2*x' /fill 0 /fill-color='Blue!10'

$ct --margin 0.03 --math /samples=20 /xrange=0:1 -t 'Cumulative histograms' \
    --fill-color-set 'default!10' --fill 0\
    --histogram /cumulative=next /gap 1mm \
    'x' '1-x' \
    --histogram /cumulative=next \
    '0.5*x' 'x' 
