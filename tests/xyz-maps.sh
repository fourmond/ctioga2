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
    --xyz-map 3d-data.dat@1:2:3 /color-map '#fff--#22f' /zaxis zvalues \
    --label-style zvalues_label /text=machin

$ct -t "Neat 3d map, with a legend (on the left)" \
    --text --margin 0.03 --new-zaxis zvalues /location left \
    --xyz-map 3d-data.dat@1:2:3 /color-map '#fff--#22f' /zaxis zvalues \
    --label-style zvalues_label /text=machin \
    -y '' --left ticks 

$ct -t "Neat 3d map, with a legend (at the bottom)" \
    --text --margin 0.03 --new-zaxis zvalues /location bottom \
    --xyz-map 3d-data.dat@1:2:3 /color-map '#fff--#22f' /zaxis zvalues \
    --label-style zvalues_label /text=machin \
    -x '' --bottom ticks 

$ct --legend-inside tc /scale 1 \
    --legend-line "Neat 3d map, with a legend (at the top)" \
    --text --margin 0.03 --new-zaxis zvalues /location top \
    --xyz-map 3d-data.dat@1:2:3 /color-map '#fff--#22f' /zaxis zvalues \
    --label-style zvalues_label /text=machin

$ct --legend-inside tc /scale 1 \
    --legend-line "Neat 3d level plot, with a legend (at the top) -- and a crappy title !" \
    --text --margin 0.03 --new-zaxis zvalues /location top \
    --contour 3d-data.dat@1:2:3 /color-map '#000--#22f' /zaxis zvalues \
    --label-style zvalues_label /text=Label

$ct -t "3d map with ugly but evenly spaced colors, with a legend (on the right)" \
    --text --margin 0.03 --new-zaxis zvalues /location right \
    --xyz-map 3d-data.dat@1:2:3 /color-map 'Red--Green--Blue--Pink--Purple' /zaxis zvalues \
    --label-style zvalues_label /text="Z values"

$ct -t "3d map with color maps from color sets" \
    --text --margin 0.03 --new-zaxis zvalues /location right \
    --xyz-map 3d-data.dat@1:2:3 /color-map 'pastel1' /zaxis zvalues \
    --label-style zvalues_label /text="Z values"


$ct -t "3d map with color maps from color sets (and HLS variation)" \
    --text --margin 0.03 --new-zaxis zvalues /location right \
    --xyz-map 3d-data.dat@1:2:3 /color-map 'hls:pastel1' /zaxis zvalues \
    --label-style zvalues_label /text="Z values"

$ct -t "3d map with color maps from complicated color sets" \
    --text --margin 0.03 --new-zaxis zvalues /location right \
    --xyz-map 3d-data.dat@1:2:3 /color-map 'gnuplot!!30' /zaxis zvalues \
    --label-style zvalues_label /text="Z values"

$ct -t "3d map with colorbrewer color set" \
    --text --margin 0.03 --new-zaxis zvalues /location right \
    --xyz-map 3d-data.dat@1:2:3 /color-map 'cb-puor-11' /zaxis zvalues \
    --label-style zvalues_label /text="Z values"

