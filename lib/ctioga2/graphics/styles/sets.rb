# sets.rb: sets
# copyright (c) 2009, 2014 by Vincent Fourmond
  
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

require 'ctioga2/graphics/styles/colorbrewer'

# This module contains all the classes used by ctioga
module CTioga2

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
          "gradient1" => 
          [DarkMagenta, DarkGreen, OrangeRed, DarkRed, DarkBlue ],
          "gradient2" => 
          [LightPlum, PaleGreen, Gold, RedBrown, SkyBlue ],
          "gnuplot" => 
          [Red, [0,1.0,0], Blue, Magenta, Cyan, Yellow, Black, Coral, Gray],
          'nil' => [nil]
        }

        begin
          t = Tioga::FigureMaker.new
          lst = []
          10.times do |i|
            lst << t.hls_to_rgb([36*i, 0.5, 1.0])
          end
          ColorSets['wheel10'] = lst

          lst = []
          20.times do |i|
            lst << t.hls_to_rgb([18*i, 0.5, 1.0])
          end
          ColorSets['wheel20'] = lst

          colortype = Commands::CommandType.get_type('color')
          for k,v in ColorBrewerSets
            for n, a in v
              if n > 4
                ColorSets["cb-#{k.downcase}-#{n}"] = a.map do |c|
                  colortype.string_to_type(c)
                end
              end
            end
          end
          
        end

        MarkerSets = { 
          "default" => 
          [Bullet, TriangleUp, Square, Plus, Times, Diamond, TriangleDown],
          "open" => 
          [BulletOpen, TriangleUpOpen, SquareOpen, PlusOpen, TimesOpen, 
           DiamondOpen, TriangleDownOpen],
        }

        for k, b in { 
            'number1' => 171, 
            'number2' => 181, 
            'number3' => 191, 
            'number4' => 201
          }
          lst = []
          1.upto(10) do |i|
            lst << [14, b + i]
          end
          MarkerSets[k] = lst
        end

        MarkerSets["alternate"] = MarkerSets["default"].
          zip(MarkerSets["open"]).flatten(1)

        LineWidthSets = {
          'default' => [1.0]
        }

        XAxisSets = {
          'default' => ['x']
        }

        YAxisSets = {
          'default' => ['y']
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

