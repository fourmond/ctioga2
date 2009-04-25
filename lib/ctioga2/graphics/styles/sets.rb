# carrays.rb: 'circular arrays'
# copyright (c) 2009 by Vincent Fourmond
  
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details (in the COPYING file).

require 'ctioga2/utils'
require 'ctioga2/log'

# This module contains all the classes used by ctioga
module CTioga2

  Version::register_svn_info('$Revision: 948 $', '$Date: 2009-04-17 00:41:44 +0200 (Fri, 17 Apr 2009) $')

  module Graphics

    module Styles

      # Various arrays and hashes suitable for use with CircularArray and
      # CurveStyleFactory
      module Sets
        include Tioga::FigureConstants

        ColorSets = { 
          "default" => 
          [Red, Green, Blue, Cyan, Magenta, Orange],
          "pastel1" => 
          [MediumSeaGreen, RoyalBlue, Pumpkin, DarkChocolate, Lilac, Crimson],
          "colorblind" => 
          [BrightBlue, Goldenrod, Coral, Lilac, FireBrick, RoyalPurple],
        }

        MarkerSets = { 
          "default" => 
          [Bullet, TriangleUp, Square, Plus, Times],
          "open" => 
          [BulletOpen, TriangleUpOpen, SquareOpen, PlusOpen, TimesOpen],
        }

        LineWidthSets = {
          'default' => [1.0]
        }

        LineStyleSets = {
          'default' => [ LineStyles::Solid,
                         LineStyles::Dots,
                         LineStyles::Dashes,
                         LineStyles::Small_Dots,
                         LineStyles::Dot_Long_Dash,
                         LineStyles::Dash_Dot_Dot ]
        }
      
      end
    end
  end
end

