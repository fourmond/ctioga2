# axes.sh: various aspects of axes
# Copyright 2009 by Vincent Fourmond
# 
# You can do whatever you want with this file, including removing the
# copyright notice and this text.

. ./test-include.sh

$ct -x '$x$ values' 'sin(x)' -y '$y$ values' 

$ct -t 'Notice how the top shrinks' \
    -x '$x$ values' 'sin(x)' -y '$y$ values' 

$ct -t 'Now, second Y axis on the left' \
    -x '$x$ values' 'sin(x)' -y '$y_1$ values' \
    --y2 'x**2'

$ct -t 'See how to specify the second Y label' \
    -x '$x$ values' 'sin(x)' -y '$y_1$ values' \
    --y2 'x**2' -y '$y_2$ values' 

# @todo this shows it is cumbersome to change all the colors in one go:
# providing a --axis-color that just works would be great.

$ct -t 'At origins' \
    --axis-style left /location=x0 \
    --top none --right none \
    -x '$x$ values' '2*sin(x)+1' -y '$y$ values' \



# See how the meaning of y and yaxis is dependent on the default axis.
$ct -t 'With different colors for the axes' \
    -x '$x$ values' 'sin(x)' -y '$y_1$ values' /color Red \
    --axis-style y /stroke_color Red \
    --label-style yaxis /color Red \
    --y2 'x**2' -y '$y_2$ values' /color Blue \
    --label-style yaxis /color Blue \
    --axis-style y /stroke_color Blue 

# Various aspects of axis customization
$ct -t 'Tweaking the aspect of labels ' \
    -x '$x$ values' /shift=3 /scale=2 'sin(x)' \
    -y '$y$ values' /shift=5mm /scale=5mm \
    --label-style x /scale=7mm 

# Multiline labels
$ct -t 'A very long title about quite uninteresting things ' \
    /text-width=6cm /alignment=bottom -r 8cmx12cm \
    -x 'A long label for the $x$ axis demonstrating auto width' /text-width=auto  'sin(x)' \
    -y 'An even longer label for the $y$ axis in order to demonstrate that the auto width works also vertically' /text-width=auto /valign=bottom

$ct -t 'Log scale' \
    --ylog --background-lines left Gray /style=Dots \
    'exp(6*sin(x))'

$ct -t 'Horizontal $y$ tick labels' \
    -x '$x$ values' 'sin(x)' -y 'Labels should be left aligned and vert. centered' \
    --axis-style left /tick-label-angle=-90 /tick-label-valign=center \
    /tick-label-halign=right /tick-label-shift=0


# # Alternative axes
# $ct 'sin(x)' --x2 --y2 'x**2' --yrange -20:50 'cos(x)' /yaxis left \
#     --draw-text 0,50 'biniou' --yaxis left --yrange -1.2:1.2
