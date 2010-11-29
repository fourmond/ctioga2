# text.sh: test for the text backend
# Copyright 2009 by Vincent Fourmond 
# This file is provided as an example of how to use ctioga2. As such,
# you can do whatever you wish with this file.

# Include the definition of ct
. ./test-include.sh

ruby ./generate-data.rb

$ct -t "Neat 3d map (with crappy colors)" \
    --text --margin 0.03 --xyz-map \
    3d-data.dat@1:2:3

$ct -t "Neat 3d map (with nicer white to blue colors)" \
    --text --margin 0.03 --xyz-map \
    3d-data.dat@1:2:3 /color-map '#fff--#22f'

$ct -t "Neat 3d map, with a legend (on the right)" \
    --text --margin 0.03 --new-zaxis zvalues /location right \
    --xyz-map 3d-data.dat@1:2:3 /color-map '#fff--#22f' /zaxis zvalues

