# gradient.sh: gradients, and all about ensuring they don't interfere with the rest
# Copyright 2011 by Vincent Fourmond
# 
# This file is provided as an example of how to use ctioga2. As such,
# you can do whatever you wish with this file.

# Include the definition of ct
. ./test-include.sh

$ct --gradient Red Purple 'sin(x) + 0##11*0.1' 

$ct --gradient Red Purple \
    --legend-inside tc \
    --legend-line "Does legend work ?" \
    'x**2 + 0##11*3'