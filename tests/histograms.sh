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

$ct --margin 0.03 --math /samples=20 -t 'Mixing normal curves and histograms' \
    --histogram 'x' /fill 0 /fill-color='Red!10' \
    ' -x' /fill-color='Green!20' /fill 0 \
    '0.1 * x**2' /fill-color='Blue!20' /fill 0 \
    --xy-plot '0.1*x**2'
