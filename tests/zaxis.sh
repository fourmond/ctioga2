# heterogeneous-maps.sh: test cases for complex heterogeneous maps that should look good
# Copyright 2015 by Vincent Fourmond 
# This file is provided as an example of how to use ctioga2. As such,
# you can do whatever you wish with this file.

# Include the definition of ct
. ./test-include.sh
func='sin(6*PI*u*v)'

$ct --xyz-map -t 'Style of Z axis' \
    --new-zaxis zvalues /location right \
    --smath /urange=-1:1 /vrange=-1:1 "$func" /zaxis zvalues \
    --axis-style zvalues /tick-label-color Blue \
    --label-style zvalues_ticks /angle 60
