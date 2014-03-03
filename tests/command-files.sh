# axes.sh: various aspects of axes
# Copyright 2009 by Vincent Fourmond
# 
# You can do whatever you want with this file, including removing the
# copyright notice and this text.

. ./test-include.sh

for f in command-files/*.ct2; do
    $ct -f $f
done

