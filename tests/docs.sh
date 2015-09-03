# docs.sh: tests for documentation commands
# Copyright 2015 by Vincent Fourmond 
# This file is provided as an example of how to use ctioga2. As such,
# you can do whatever you wish with this file.

# Include the definition of ct
. ./test-include.sh

# This file should not produce any output


for f in $(ctioga2 --list-commands /format=raw | grep ^write-html); do
    $ct --$f > /dev/null
done

$ct --write-man xx ../man/ctioga2.1.template > /dev/null
