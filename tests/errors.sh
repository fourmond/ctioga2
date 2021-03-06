# errors.sh: various error conditions that should not be too harsh (ie no crash)
# Copyright 2014 by Vincent Fourmond
# 
# You can do whatever you want with this file, including removing the
# copyright notice and this text.

. ./test-include.sh

$ct -x '$x$ values in % of stuff' 'sin(x)' -y '$y$ values' 

$ct -x '$x$ values in % of stuff' 'sin(x)' -y '$y$ values' 

# This should not crash hard
$ct -t "Error" '0.0/0.0'

# Grid specification out of grid, should not cause a backtrace
$ct --setup-grid 2x1 --inset grid:2,2 'sin(x)'


# Parsing errors
for f in command-files/errors/*.ct2; do
    $ct -f $f
done

