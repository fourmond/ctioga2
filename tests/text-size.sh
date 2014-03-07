# axes.sh: various aspects of axes
# Copyright 2009 by Vincent Fourmond
# 
# You can do whatever you want with this file, including removing the
# copyright notice and this text.

. ./test-include.sh


# Auto sizing and legends


$ct -t 'A very long title about quite uninteresting things ' \
    /text-width=6cm /alignment=bottom -r 8cmx12cm \
    -x 'A long label for the $x$ axis demonstrating auto width' /text-width=auto \
    'sin(x)' /legend "First" \
    'sin(x+1)' /legend "First+1" \
    'sin(x+2)' /legend "First+2" \
    'sin(x+3)' /legend "First+3" \
    -y 'An even longer label for the $y$ axis in order to demonstrate that the auto width works also vertically' /text-width=auto

$ct -t 'A quite long title '  -r 8cmx12cm /count-legend=true \
    'sin(x)' /legend "First" \
    'sin(x+1)' /legend "First+1" \
    'sin(x+2)' /legend "First+2" \
    'sin(x+3)' /legend "First+3"

$ct -t 'Title with extremely exagerately immense words '  -r 6.5cmx8cm /count-legend=true \
    'sin(x)' /legend "First" \
    'sin(x+1)' /legend "First+1" \
    'sin(x+2)' /legend "First+2" \
    'sin(x+3)' /legend "First+3"



# # Alternative axes
# $ct 'sin(x)' --x2 --y2 'x**2' --yrange -20:50 'cos(x)' /yaxis left \
#     --draw-text 0,50 'biniou' --yaxis left --yrange -1.2:1.2
