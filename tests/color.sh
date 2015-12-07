# color.sh: all ways to specify colors
# Copyright 2012 by Vincent Fourmond
# 
# You can do whatever you want with this file, including removing the
# copyright notice and this text.

. ./test-include.sh

$ct --legend-inside br \
    'x' /color=Red /legend='Tioga color: Red' \
    '2*x' /color=\#729 /legend='HTML syntax: \#729' \
    '3*x' /color=0.1,0.9,0.2 /legend='RGB fractions: 0.1,0.9,0.2' \
    '0.5*x' /color=hls:0.1,0.9,0.2 /legend='HLS fractions: hls:0.1,0.9,0.2' \
    '0.1*x' /color='#729!50!Green' /legend='xcolor mix: \#729!50!Green'

$ct --math /samples=30 --marker auto --line-style no \
    --marker-color-set Red\|Green\|Red\!30\|Green\!30 \
    'x+1##8' x+12 /marker-color Red
