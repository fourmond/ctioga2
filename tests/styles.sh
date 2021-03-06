# style.sh: tests for advanced styling
# Copyright 2010 by Vincent Fourmond 
# This file is provided as an example of how to use ctioga2. As such,
# you can do whatever you wish with this file.

# Include the definition of ct
. ./test-include.sh

$ct -t 'Using stylesheets' -r 10cmx10cm \
    --load-style styles.ctss \
    'cos(x)' /class=bottom \
    ' -cos(x)' /id=mcos /class=bottom\
    --gradient Red Blue \
    sin'(x+0##5)+1'  \
    --end

$ct --define-axis-style '*' /axis-label-color Blue \
    --define-axis-style .y /axis-label-color Red /stroke-color Orange \
    --define-axis-style .top /stroke-color Purple \
    --define-line-style '#ln' /color Green \
    --define-line-style .pink /color Pink \
    --define-legend-style .inside /frame-color Green \
    -t 'Manual style definition' -r 10cmx10cm \
    --legend-inside tc /class=inside \
    'x**2' /legend='$x^2$' \
    --draw-line 0,0 5,50 /id=ln \
    --draw-arrow 0,0 -5,50 /class=pink

$ct --define-axis-style '.different axis' /axis-label-color Blue \
    -r 10cmx10cm \
    --load-style styles.ctss \
    --setup-grid 2x1 \
    --inset grid:0,0 \
    -t 'Complex styling' \
    'cos(x)' \
    --next-inset grid:1,0 /class=different \
    'cos(x)' \
    --end

$ct -r 10cmx10cm \
    --load-style styles.ctss \
    --root-plot /class=different \
    -t 'Styling root plot + direct children' \
    'cos(x)' \
    --gradient Red Blue \
    'sin(x+1##4)'


