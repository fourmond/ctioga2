# regions.sh: colored regions...
# Copyright 2011 by Vincent Fourmond
# 
# This file is provided as an example of how to use ctioga2. As such,
# you can do whatever you wish with this file.

# Include the definition of ct
. ./test-include.sh

$ct --region /color Blue /transparency 0.7 \
    '30 - x**2' 'x**2' 

$ct --region /color Blue /transparency 0.7 \
    --legend-inside tc \
    -l 'Top' '30 - x**2' \
    'x**2' /legend Bottom

$ct --xrange -1:4 \
    --region /color Blue /transparency 0.7 \
    --legend-inside tc \
    -l 'Top' '30 - x**2' \
    'x**2' /legend Bottom

$ct --region /color Blue /transparency 0.7 \
    --legend-inside tc --xrange -1:5 --yrange -10:15 \
    -l 'Top' '30 - x**2' \
    'x**2' /legend Bottom

$ct --region /color Blue /pattern=xlines \
    /reversed-color Orange /reversed-pattern=xlines \
    '30 - x**2' 'x**2' 
