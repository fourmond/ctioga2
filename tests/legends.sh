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
