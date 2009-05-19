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

# In addition to the former, here are some useful constants
# This module contains all the classes used by ctioga
module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

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


    ColorType = CmdType.new('color', {
                              :type => :tioga_color,
                              :namespace => Tioga::ColorConstants
                            }, <<EOD)
A Tioga color.
EOD

    ColorOrFalseType = 
      CmdType.new('color-or-false', {
                    :type => :tioga_color,
                    :namespace => Tioga::ColorConstants,
                    :shortcuts => {'none' => false }
                  }, <<EOD)
A Tioga color, or false to say that nothing should be drawn.
EOD

    LineStyleType = 
      CmdType.new('line-style', {
                    :type => :tioga_line_style,
                    :namespace => LineStyles
                  }, <<EOD)
A line style.
EOD

    MarkerType = 
      CmdType.new('marker', {
                    :type => :tioga_marker,
                    :namespace => Tioga::MarkerConstants,
                    :shortcuts => {
                      'None' => 'None',
                      'no' => 'None',
                      'none' => 'None',
                      'off' => 'None', 
                    },}, <<EOD)
A Tioga Marker.
EOD

    PointType = 
      CmdType.new('point', :point, <<EOD)
A given point on a figure.
EOD

    JustificationType = 
      CmdType.new('justification', :tioga_justification, <<EOD)
Horizontal aligment for text.
EOD

    AlignmentType = 
      CmdType.new('alignment', :tioga_align, <<EOD)
Vertical aligment for text.
EOD

    PDFFont = 
      CmdType.new('pdf-font', :integer, <<EOD)
A number between 1 and 14 that designates one of the 14 standard 
PDF fonts.
EOD

    AlignedPointType = 
      CmdType.new('aligned-point', {:type => :aligned_point, 
                    :default => :frame}, <<EOD)
A point together with alignment specifications.
EOD

    FrameMarginsType = 
      CmdType.new('frame-margins', :frame_margins, <<EOD)
Margins around a plot.
EOD

    # Now, axes stuff:

    AxisDecorationType = 
      CmdType.new('axis-decoration', :tioga_axis_type, <<EOD)
Kinds of decoration on a axis line, such as nothing, lines, ticks, 
tick labels...
EOD

    # Dimensions

    DimensionType = 
      CmdType.new('dimension', { :type => :dimension, 
                    :default => :dy }, <<EOD)
Dimension, in absolute units, or in units of text height (default),
figure, frame or page coordinates.
EOD

    # Boxes

    BoxType = 
      CmdType.new('box', :box, <<EOD)
The specification for a box, such as an inset. Specifications vary for
now... TODO: to be written later on.
EOD

  end
end
