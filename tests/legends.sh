# legends.sh: various aspects of legends
# Copyright 2009 by Vincent Fourmond 
# This file is provided as an example of how to use ctioga2. As such,
# you can do whatever you wish with this file.

# Include the definition of ct
. ./test-include.sh

$ct -t 'Basic legends' -r 10cmx10cm \
    -l '$\sin x$' 'sin(x)' 'cos(x)' /legend='$\cos x$'

$ct -t 'Counting the legends inside the page size' \
    -r 10cmx10cm /count-legend=true \
    -l '$\sin x$' 'sin(x)' 'cos(x)' /legend='$\cos x$'

$ct -t 'Legend lines' -r 10cmx10cm \
    -l '$\sin x$' 'sin(x)' \
    --legend-line 'A line by itself' /color=Blue \
    'cos(x)' /legend='$\cos x$'

$ct -t 'Legend lines' -r 10cmx10cm \
    -l '$\sin x$' 'sin(x)' \
    --legend-line 'See how the size of the plot adapts to long lines' \
    /color=Blue \
    'cos(x)' /legend='$\cos x$'

$ct -t 'Legends inside' -r 10cmx10cm \
    --legend-inside tc /scale 2 /dy=1.02 \
    -l '$x^2$' 'x**2' \
    -l '$5 x$' '5 * x'

$ct -t 'Legend frames, take 1' -r 10cmx10cm \
    --legend-inside tc /scale 2 /dy=1.02 /frame_color=Black \
    /frame_fill_color='Blue!10' /frame_width=0.5 \
    -l '$x^2$' 'x**2' \
    -l '$5 x$' '5 * x' \
    --legend-line Bottom

$ct -t 'Legend frames, take 2' -r 10cmx10cm \
    --legend-inside cc /scale 2 /dy=1.02 /frame_color=Black \
    /frame_fill_color='White' /frame_fill_transparency=0.2 \
    /frame_width=0.5 /frame_padding=5mm\
    -l '$x^2$' 'x**2' \
    -l '$5 x$' '5 * x' \
    --legend-line 'More padding !'
