# Copyright 2009 by Vincent Fourmond
# 
# You can do whatever you want with this file, including removing the
# copyright notice and this text.
#
# The purpose of this file is just to dump the command-lines I use to
# test new features, as a basic example, and as a reminder for writing
# later documentation (or even remembering the features exist...)

. ./test-include.sh

# Alternative axes
$ct 'sin(x)' --x2 --y2 'x**2' --yrange -20:50 'cos(x)' /yaxis left \
    --yaxis left --yrange -1.2:1.2

$ct --legend-inside cc /scale=5 'sin(x)' /legend biniou


