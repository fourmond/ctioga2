# types.rb: various useful types to interact with Tioga
# copyright (c) 2009 by Vincent Fourmond
  
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details (in the COPYING file).

require 'ctioga2/graphics/types/dimensions'
require 'ctioga2/graphics/types/point'
require 'ctioga2/graphics/types/boundaries'
require 'ctioga2/graphics/types/boxes'
require 'ctioga2/graphics/types/bijection'
require 'ctioga2/graphics/types/location'
require 'ctioga2/graphics/types/fill'


require 'ctioga2/graphics/types/grid'

# In addition to the former, here are some useful constants
# This module contains all the classes used by ctioga
module CTioga2

  module Graphics

    # A small convenience module for line styles
    module LineStyles
      include Tioga::FigureConstants

      Line_Type_Dash_Dot_Dot = [[5,2,1,2,1,2],0]
      Line_Type_Small_Dots = [[0.5,1],0]

      # Shortcut for line styles:
      Solid  = Line_Type_Solid
      Dots   = Line_Type_Dots
      Dashes = Line_Type_Dashes
      Small_Dots = Line_Type_Small_Dots
      Dot_Long_Dash = Line_Type_Dot_Long_Dash
      Dash_Dot_Dot = Line_Type_Dash_Dot_Dot
    end
    
    NoRE = /no(ne)?|off/i

    ColorType = CmdType.new('color', {
                              :type => :tioga_color,
                              :namespace => Tioga::ColorConstants,
                            }, <<EOD)
A color. It can take three forms:
 * a named color, see 
{url: http://tioga.rubyforge.org/doc/classes/Tioga/ColorConstants.html}
for the list of color names.
 * an HTML color: for instance, @#f00@ or @#ff0000@ is red;
 * a list of three numbers between 0 and 1: @1,0,0@ is red too.
EOD

    ColorOrFalseType = 
      CmdType.new('color-or-false', {
                    :type => :tioga_color,
                    :namespace => Tioga::ColorConstants,
                    :shortcuts => { 
                      NoRE => false 
                    }
                  }, <<EOD)
A {type: color}, or none to say that nothing should be drawn.
EOD


    RegionSideType = 
      CmdType.new('region-side', {
                    :type => :list,
                    :list => {},
                    :shortcuts => {
                      'above' => :above,
                      'below' => :below,
                      'ignore' => false,
                    }
                  }, <<EOD)
Within a {command: region}, designates the position of the curve with
respect to the region:
 * @above@
 * @below@
 * @ignore@ if this curve is not to be taken into account
EOD

                    
                    
    LineStyleType = 
      CmdType.new('line-style', {
                    :type => :tioga_line_style,
                    :namespace => LineStyles,
                    :shortcuts => {
                      NoRE => false,
                    }
                  }, <<EOD)
A line style, which is one of @solid@, @dots@, @dashes@, @small_dots@,
a series of comma-separated numbers which are the length of the
strokes and gaps, or @no@, @none@ or @off@ to mean no line.
EOD

    MarkerType = 
      CmdType.new('marker', {
                    :type => :tioga_marker,
                    :namespace => Tioga::MarkerConstants,
                    :shortcuts => {
                      NoRE  => false
                    }
                  }, <<EOD)
A Tioga Marker, ie either a name from the list at {url:
http://tioga.rubyforge.org/doc/Tioga/MarkerConstants.html}, such as
@Box@, @Star@, @Spade@ or two or three comma-separated numbers,
_font_, _number_ and _width_. _font_ defines the font (standard PDF
fonts, from 1 to 14), _number_ the number of the character within the
font (between 0 and 255), and if _width_ is specified, the marker is
stroked and not filled, and the number is the line width for the
stroke.
EOD

    PointType = 
      CmdType.new('point', :point, <<EOD)
A given point on a figure.
EOD

# We need a very specific type for that as we want to have a reference
# to the level too !
    LevelType = 
      CmdType.new('level', :level, <<EOD)
A level on a XYZ map (that is, just a Z value).
EOD

   JustificationRE = {
      /l(eft)?/i => Tioga::FigureConstants::LEFT_JUSTIFIED,
      /c(enter)?/i => Tioga::FigureConstants::CENTERED,
      /r(ight)?/i => Tioga::FigureConstants::RIGHT_JUSTIFIED
    }

    JustificationType = 
      CmdType.new('justification', {:type => :re_list,
                    :list => JustificationRE}, <<EOD)
Horizontal aligment of the (with respect to its location). Can be one of:
 * @l@ or @left@
 * @c@, @center@
 * @r@, @right@
EOD

    TextAlignType = 
      CmdType.new('text-align', 
                  {:type => :re_list,
                    :list => JustificationRE,
                    :shortcut => {
                      NoRE => :no
                    }
                  }, <<EOD)
Horizontal aligment for text within its box. Only of use
for texts with a given text width.
Can be one of:
 * @l@ or @left@
 * @c@, @center@
 * @r@, @right@
 * @no@ or @none@ to not issue aligning commands, in which case you get 
full LaTeX-justified paragraphs (probably with a lot of hyphens).
EOD

   # Regular expression for vertical alignment
   AlignmentRE = {
      /t(op)?/i => Tioga::FigureConstants::ALIGNED_AT_TOP,
      /c(enter)|m(idheight)/i => Tioga::FigureConstants::ALIGNED_AT_MIDHEIGHT,
      /B|Baseline|baseline/ => Tioga::FigureConstants::ALIGNED_AT_BASELINE,
      /b(ottom)?/ => Tioga::FigureConstants::ALIGNED_AT_BOTTOM
    }

    AlignmentType = 
        CmdType.new('alignment', {:type => :re_list,
                      :list => AlignmentRE}, 
                    <<EOD)
Vertical aligment for text. Can be one of:
 * @t@ or @top@
 * @c@, @center@, @m@ or @midheight@ (vertically centered)
 * @B@, @Baseline@ or @baseline@ to align at the baseline
 * @b@ or @bottom@
EOD

    PDFFont = 
      CmdType.new('pdf-font', :integer, <<EOD)
A number between 1 and 14 that designates one of the 14 standard 
PDF fonts. (see for instance
{url: http://tioga.rubyforge.org/doc/classes/Tioga/MarkerConstants.html}
for more information).
EOD

    AlignedPointType = 
      CmdType.new('aligned-point', {:type => :aligned_point, 
                    :default => :frame}, <<EOD)
A point together with alignment specifications, used to place some 
elements such as legends for instance, that require alignment information. 

The first two letters represent the alignment:

 * @t@ for top
 * @b@ for bottom
 * @c@ for center
 * @l@ for left and
 * @r@ for right

These letters can optionally be followed by the exact location of the
point in frame coordinates. If not provided, a reasonable default
value is chosen.

Examples:

 * @tl@ is a point at the top left of the frame aligned to the top
   and left;
 * @cl:0.1,0.6@ is vertically centered and aligned to the left, and
   positioned 10% from the left and 60% from the bottom.
EOD

    FrameMarginsType = 
      CmdType.new('frame-margins', {:type => 
                    :frame_margins, :shortcuts => 
                    { /^\s*auto\s*$/i => nil}}, <<EOD)
Margins around a plot, ie the distance from the side of the plot to
the corresponding side of the container (most likely the whole
PDF). It can take three forms:
 * @dimension@ (applies to all sides)
 * @left_right, top_bottom@
 * @left, right, top, bottom@

Each of these elements is a valid {type: dimension}.

It can also be @auto@, in which case the position of the margins is
computed automatically to accomodate the various labels/ticks.
EOD

    # Now, axes stuff:

    AxisDecorationType = 
      CmdType.new('axis-decoration', :tioga_axis_type, <<EOD)
Kinds of decoration on a axis line, such as nothing, lines, ticks, 
tick labels. Possible values:
 * @hidden@, @off@, @no@, @none@: no axis at all
 * @line@: only a line
 * @ticks@: only ticks
 * @major@: only major ticks
 * @major-num@: major ticks along with their labels
 * @full@: major ticks and labels + minor ticks
EOD

    TicksSideRE = {
      /i(nside)?/i =>  {'ticks_inside' => true,
        'ticks_outside' => false},
      /o(utside)?/i => {'ticks_outside' => true,
        'ticks_inside' => false},
      /b(oth)?/i => {'ticks_outside' => true,
        'ticks_inside' => true}
    }

    TicksSideType = 
      CmdType.new('ticks-side', {:type => :re_list,
                    :list => TicksSideRE}, <<EOD)
On what side of an axis line are the ticks positioned:
 * @inside@: on the inside
 * @outside@: on the outside
 * @both@: on both the inside and the outside
EOD


    # Dimensions

    DimensionType = 
      CmdType.new('dimension', { :type => :dimension, 
                    :default => :dy }, <<EOD)

A dimension, in absolute units, or in units of text height, figure,
frame or page coordinates. It is in the form 
@value unit@
where @value@ is a number and unit can be one of @pt@,
@bp@, @in@, @cm@ (absolute units, same meaning as in TeX), 
@dy@ (@1.0 dy@ is the height of a text
line), @figure@ or @f@ (for figure coordinates, i.e. the coordinates of the
plot), @frame@ or @F@ (@1.0 frame@ is the full size of the current subplot) and
@page@ or @p@ (@1.0 page@ is the whole height/width of the output file).

It can also be @auto@, which is 1.0 in frame units (ie the width or
the height of the current plot).
EOD


    DimensionOrNoType = 
      CmdType.new('dimension-or-no', { :type => :dimension, 
                    :default => :dy,
                    :shortcuts => {
                      NoRE => false
                    }
                  }, <<EOD)
A {type: dimension}, or @no@ or @none@.
EOD
    # Boxes

    BoxType = 
      CmdType.new('box', :box, <<EOD)
The specification for a box, such as an inset. It can be a grid
specification, such as @grid:0,1@. For this to work, a grid must have
been setup beforehand using {command: setup-grid}.

It can also be an {type: aligned-point} together with a width and
optionally a height in frame coordinates, such as:

 * @cc:0.3@: a box in the center of size 30% width and 30% height;
 * @bl:0.1,0.2:0.7,0.2@ a box starting from the point at 10% from the left
   and 20% from the bottom, with a width of 70% and a height of 20%.
EOD

    # Coordinate transformations
    BijectionType = 
      CmdType.new('bijection', :bijection, <<EOD)
A pair of functions of x specifying a bidirectional coordinate
transformation separated by a double colon (@::@), in the order
@from::to@.

Each of the functions must be valid Ruby code - it is not exactly
mathematical functions, in particular Ruby does not like floats which
are missing digits on either side of the dot : for instance, @.3@ and
@1.@ are not valid. Sorry.

In most of the usual cases, the coordinate transform is an involution,
that is from and to is the same function (this is the case for
a/x). In this case, you can omit the second function.
EOD

  end
end
