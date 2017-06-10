# text.sh: test for the text backend
# Copyright 2009 by Vincent Fourmond 
# This file is provided as an example of how to use ctioga2. As such,
# you can do whatever you wish with this file.

# Include the definition of ct
. ./test-include.sh

ruby ./generate-data.rb

$ct -t "3d map with NaNs" \
    --text --margin 0.03 --xyz-map \
    --color-map 'White(-1)--Red(0)--Green' \
    3d-data.dat@1:2:5

$ct -t "... and the holes are transparent" \
    --math-xrange -3:3 \
    'sin(3*x)' /line-width=2 \
    --text --margin 0.03 --xyz-map \
    --color-map 'White(-1)--Red(0)--Green' \
    3d-data.dat@1:2:5

