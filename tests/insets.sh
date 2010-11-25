# grid.sh: demonstration of the new grid layout
# Copyright 2010 by Vincent Fourmond
# 
# This file is provided as an example of how to use ctioga2. As such,
# you can do whatever you wish with this file.

# Include the definition of ct
. ./test-include.sh

# 
$ct 'x**2' --inset 'tl:0.2,0.9:0.4,0.3' \
    'cos(x)'

# Oversimplified
$ct 'x**2' --inset 'cc:0.3' \
    'cos(x)'