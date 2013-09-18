# text.sh: test for the text backend
# Copyright 2009 by Vincent Fourmond 
# This file is provided as an example of how to use ctioga2. As such,
# you can do whatever you wish with this file.

# Include the definition of ct
. ./test-include.sh

ruby ./generate-data.rb

$ct -t "Parametric plot" --marker auto \
    --text --margin 0.03 --xy-parametric --line-style no\
    3d-data.dat@1:2:3

$ct -t "Info through size" --marker auto \
    --text --margin 0.03 --xy-parametric /z1=marker_scale \
    --line-style no\
    3d-data.dat@1:2:3

$ct -t "Mapped size" --marker auto \
    --text --margin 0.03 --xy-parametric /z1=marker_scale \
    --line-style no \
    3d-data.dat@1:2:3 /marker_min_scale=0.2

$ct -t "Both size and color" --marker auto \
    --text --margin 0.03 --xy-parametric /z1=marker_scale /z2=marker_color \
    --line-style no \
    3d-data.dat@1:2:3:3


