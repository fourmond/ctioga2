#! /bin/sh

# Demonstration that ctioga2 is polymorphic. Running this command-line
# is equivalent to running ctioga2 -f polymorphic.ct2 - apart from the
# fact that in the latter case, the output file is polymorphic.pdf
# instead of Plot.pdf.

ctioga2 --title 'A nice title, for sure' --math 'sin(x)' \
    -x 'The X label' -y 'The Y label'