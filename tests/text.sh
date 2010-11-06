# text.sh: test for the text backend
# Copyright 2009 by Vincent Fourmond 
# This file is provided as an example of how to use ctioga2. As such,
# you can do whatever you wish with this file.

# Include the definition of ct
. ./test-include.sh


t1=tmp-1.dat
echo "Writing temporary data to $t1"
echo "1 2" > $t1
echo "2 5" >> $t1
echo "bidule machin" >> $t1
echo "3 8" >> $t1
echo "4 3" >> $t1

$ct -t "All 4 dots should be joined by lines" \
    --text --margin 0.03 --marker auto $t1

$ct -t "Dots should be joined 2 by 2" \
    --text --margin 0.03 --marker auto \
    $t1 /split-on-nan true



# echo "Removing temporary files"
# rm -f $t1