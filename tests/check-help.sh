# check-help.sh: checking the help texts. 
# Copyright 2015 by Vincent Fourmond
# 
# You can do whatever you want with this file, including removing the
# copyright notice and this text.

. ./test-include.sh

# This command does not generate any output. But is a useful check.
for f in $($ct --list-commands /format=raw); do
    $ct  --help-on $f > /dev/null
done

