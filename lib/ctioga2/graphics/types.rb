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

  Version::register_svn_info('$Revision: 948 $', '$Date: 2009-04-17 00:41:44 +0200 (Fri, 17 Apr 2009) $')

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


    # Some various predefined constants that can be used for Types
    # to simplify my work.

    # A MetaBuilder::Type specification for colors.
    ColorTypeSpec = {
      :type => :tioga_color,
      :namespace => Tioga::ColorConstants
    }

    # A MetaBuilder::Type specification for colors or false
    ColorOrFalseTypeSpec = {
      :type => :tioga_color,
      :namespace => Tioga::ColorConstants,
      :shortcuts => {'none' => false }
    }

    # A MetaBuilder::Type specification for line styles
    LineStyleSpec = {
      :type => :tioga_line_style,
      :namespace => LineStyles
    }

    # A MetaBuilder::Type specification for markers
    MarkerSpec = {
      :type => :tioga_marker,
      :namespace => Tioga::MarkerConstants,
      :shortcuts => {
        'None' => 'None',
        'no' => 'None',
        'none' => 'None',
        'off' => 'None', 
      },
    }

  end
end
