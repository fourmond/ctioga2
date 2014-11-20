# plots.sh: tests for basic plots
# Copyright 2009 by Vincent Fourmond 
# This file is provided as an example of how to use ctioga2. As such,
# you can do whatever you wish with this file.

# Include the definition of ct
. ./test-include.sh

$ct -t 'Basic usage' 'sin(x)' 'cos(x)'

$ct -t 'Basic dataset expansion' --auto-legend 'sin(x+0##5)'


# Compare the two following command-lines:
$ct -t 'Use of \texttt{-{}-marker Circle}' 'sin(x)' --marker Circle \
    'cos(x)'  ' -sin(x)'
$ct -t 'Use of \texttt{/marker=Circle}' 'sin(x)' \
    'cos(x)' /marker=Circle ' -sin(x)'
# Note the space before -sin(x) to avoid it to be mistaken for an
# option.

$ct -t 'Selection of Y range' --yrange -0.1:1.3 'sin(x)' 'cos(x)' 

$ct -t 'Use of a plot margin' --margin 0.03 'sin(x)' 'cos(x)' 

$ct -t 'Cancel the use of markers' --line-style no --marker auto \
    'sin(x)' 'cos(x)' ' -sin(x)' /marker=no /line-style=Solid


$ct -t 'Styles' --math-samples 30 --margin 0.03 \
    --marker auto \
    'sin(x)' /path-style=splines \
    'cos(x)' /path-style=impulses /marker=no
