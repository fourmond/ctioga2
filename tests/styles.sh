# style.sh: tests for advanced styling
# Copyright 2010 by Vincent Fourmond 
# This file is provided as an example of how to use ctioga2. As such,
# you can do whatever you wish with this file.

# Include the definition of ct
. ./test-include.sh

$ct -t 'Using stylesheets' -r 10cmx10cm \
    --load-style styles.ctss \
    'cos(x)' \
    --gradient Red Blue \
    sin'(x+0##5)'  \
    --end

$ct --define-axis-style '*' /axis-label-color Blue \
    --define-axis-style .y /axis-label-color Red /stroke-color Pink \
    --define-axis-style .top /stroke-color Purple \
    -t 'Manual style definition' -r 10cmx10cm \
    'cos(x)'

