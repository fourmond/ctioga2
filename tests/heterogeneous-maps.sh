# heterogeneous-maps.sh: test cases for complex heterogeneous maps that should look good
# Copyright 2015 by Vincent Fourmond 
# This file is provided as an example of how to use ctioga2. As such,
# you can do whatever you wish with this file.

# Include the definition of ct
. ./test-include.sh
func='sin(6*PI*u*v)'

$ct --xyz-map -t 'First check of smath' \
    --smath /urange=-1:1 /vrange=-1:1 "$func" \
    --contour --smath /samples=30 /urange=-1:1 /vrange=-1:1 "$func" /color-map=Black--Black /contour-number=5


$ct --xyz-map -t 'Three bits' \
    --smath /urange=-1:-0.7 /vrange=-1:1 -L "$func" \
    --smath /urange=-0.7:0.7 /vrange=-1:1 -L "$func" \
    --smath /urange=0.7:1 /vrange=-1:1 -L "$func" \
    --join-datasets /number=3 --plot-last \
    --contour --smath /samples=30  /urange=-1:1 /vrange=-1:1 "$func" /color-map=Black--Black /contour-number=5

$ct --xyz-map -t 'More complicated' --verbose \
    --smath /urange=-1:-0.71 /vrange=-0.7:1 -L "$func" \
    --smath /urange=-0.7:0.7 /vrange=-1:1 -L "$func" \
    --smath /urange=0.71:1 /vrange=-1:0.7 -L "$func" \
    --join-datasets /number=3 --plot-last \
    --contour --smath /samples=30 /urange=-1:1 /vrange=-1:1 "$func" /color-map=Black--Black /contour-number=5

$ct --xyz-map -t 'Transposed' --verbose \
    --smath /vrange=-1:-0.71 /urange=-0.7:1 -L "$func" \
    --smath /vrange=-0.7:0.7 /urange=-1:1 -L "$func" \
    --smath /vrange=0.71:1 /urange=-1:0.7 -L "$func" \
    --join-datasets /number=3 --plot-last \
    --contour --smath /samples=30 /urange=-1:1 /vrange=-1:1 "$func" /color-map=Black--Black /contour-number=5

$ct --xyz-map -t 'With overlapping points' --verbose \
    --smath /samples=11 /urange=-1:-0.7 /vrange=-0.5:1 -L "$func" \
    --smath /urange=-0.7:0.7 /vrange=-1:1 -L "$func" \
    --smath /urange=0.7:1 /vrange=-1:0.5 -L "$func" \
    --join-datasets /number=3 --plot-last \
    --contour --smath /samples=30 /urange=-1:1 /vrange=-1:1 "$func" /color-map=Black--Black /contour-number=5
