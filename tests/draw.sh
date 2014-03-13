# draw.sh: tests for drawing commands
# Copyright 2010 by Vincent Fourmond 
# This file is provided as an example of how to use ctioga2. As such,
# you can do whatever you wish with this file.

# Include the definition of ct
. ./test-include.sh

$ct -t 'Text drawing' -r 10cmx10cm \
    'sin(x)' --draw-text 0,0 'center plus baseline' /alignment baseline \
    /color BrickRed /scale 1.2 \
    --draw-line -6,0 6,0 /color Green /style Dots \
    --draw-line 0,-1 0,1 /color Blue /style Dashes \
    --draw-text 0,-0.3 'left plus bottom' /justification left \
    /color Orange /scale 1.2  /alignment bottom \
    --draw-line -6,-0.3 6,-0.3 /color Green /style Dots \
    --draw-text 0,0.6 'right top (h/v)' /halign right \
    /color Orange /scale 1.2  /valign top \
    --draw-line -6,0.6 6,0.6 /color Green /style Dots 




$ct -t 'Boxes' -r 10cmx10cm \
    'sin(x)' \
    --draw-box -2,0.2 2,-0.2 /color=Blue /width=2 \
    --draw-box -5,0.8 -3,-0.4 /fill-color=Pink /color=Black \
    --draw-box 3,0.8 7,0 /fill-color=Pink /fill-transparency=0.7 \
    --draw-box -2,0.2 2,-0.2 /color=Red /width=1 /style=Dashes /shape=round /radius=0.8 \
    --draw-box -2,0.2 2,-0.2 /color=Purple /width=1 /style=Dots /shape=round /radius=1.4

$ct -t 'Styled lines and text' -r 10cmx10cm --math-xrange -3:3 \
    'sin(x)' \
    --draw-line -2,0.2 2,-0.2 /color=Blue /width=2 \
    --define-line-style base /style=Dots \
    --define-line-style line2 /width=1 \
    --draw-line 2,0.2 -2,-0.2 /color=Red /width=2 \
    --draw-line 2,-0.2 -2,-0.2 /color=Green /base-style=line2 \
    --draw-line 2.5,-0.4 2.5,0.5 /color=Purple /line_width=3 /line_style=Solid \
    --draw-text 0,0 'style changes apply to the whole graph' \
    --define-text-style base /scale=1.6 /color=Green \
    --define-text-style text1 /color='Red!20' \
    --draw-text 0,0.5 'with default style' \
    --draw-text 0,-0.5 'with text1 style' /base-style=text1
    

$ct -t 'Styled markers' -r 10cmx10cm --math-xrange -3:3 \
    'sin(x)' \
    --define-marker-style base /color=Red \
    --define-marker-style marker1 /vertical_scale=2 \
    --define-marker-style marker-string /horizontal_scale=2 \
    --draw-marker '0,0' TriangleUp \
    --draw-marker '1,0' TriangleUp /base-style=marker1 \
    --draw-string-marker '0,0.5' TriangleUp /base-style=marker-string \
    --draw-string-marker '0,-0.5' TriangleUp /base-style=marker-string \
    /vertical_scale=0.5 /color=Green \
    --draw-string-marker '0,-0.2' TriangleUp /base-style=marker-string \
    /horizontal_scale=1 /color=Blue

# Now, we need to create a PNG and a JPEG file

echo "Creating necessary JPEG and PNG files"
convert -size 320x85 xc:white -pointsize 72 -fill Red -draw "text 25,60 'JPEG'" t1.jpeg
convert -size 320x85 xc:white -pointsize 72 -fill Red -draw "text 25,60 'PNG'" -stroke black -draw 'rectangle 230,10 280,60' t1.png

$ct --drawing-frame /units=1cm \
    -t 'PNG and JPEG images' -r 10cmx10cm \
    --draw-image t1.jpeg 1,1 3,3 \
    --draw-image t1.png 1,4 3,6 \
    --draw-image t1.png 4,4 6,6 /aspect-ratio=contract  \
    --draw-image t1.png 4,7 6,9 /aspect-ratio=expand \
    --draw-image t1.jpeg 1.5,1.5 3.5,3.5 /transparency=0.5


$ct -t 'Tangents: a direction, and a proper arrow' -r 10cmx10cm \
    'sin(x)' \
    --draw-tangent 0.5  \
    --draw-tangent 0.6 /xto=5 /color=Black /line-style=Dashes /nbavg=3\
    --draw-tangent 0.3 /xextent=1 /color=Pink /style=Dots /nbavg=3
