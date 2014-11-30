# backends.sh: few things with backends (and testing other stuff too)
# Copyright 2014 by Vincent Fourmond
# 
# This file is provided as an example of how to use ctioga2. As such,
# you can do whatever you wish with this file.

# Include the definition of ct
. ./test-include.sh

$ct --direct --histogram --margin 0.03 \
    '1 2' --xrange 0.5:1.5 
