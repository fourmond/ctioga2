# texts.rb: style for textual objects
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

  Version::register_svn_info('$Revision$', '$Date$')

  module Graphics

    module Styles

      # Conversion between the #location attribute and the real
      # constant used for Tioga
      LocationToTiogaLocation = {
        :left => Tioga::FigureConstants::LEFT,
        :right => Tioga::FigureConstants::RIGHT,
        :bottom => Tioga::FigureConstants::BOTTOM,
        :top => Tioga::FigureConstants::TOP,
        :at_x_origin => Tioga::FigureConstants::AT_X_ORIGIN,
        :at_y_origin => Tioga::FigureConstants::AT_Y_ORIGIN
      }


      # The style of a text object. This class is suitable for
      # inclusion as a Hash to FigureMaker#show_axis, for the tick
      # labels.
      class BaseTextStyle < BasicStyle
        
        # The angle of the text
        attr_accessor :angle

        # The 'shift' of the text. Only meaningful for axes and tick
        # labels, where the position of the text is specified using a
        # side rather than a precise position
        attr_accessor :shift

        # The scale of the text
        attr_accessor :scale

        # The vertical alignment 
        attr_accessor :alignement

        # The horizontal alignment
        attr_accessor :justification

        # Draw the _text_ at the given location with the given style.
        # If _y_ is _nil_, then _x_or_loc_ is taken to be a location
        # (see FigureMaker#show_text).
        def draw_text(t, text, x_or_loc, y = nil, measure = nil)
          dict = self.to_hash
          dict['text'] = text
          if y
            dict['at'] = [x_or_loc, y]
          else
            # Perform automatic conversion on the location
            if x_or_loc.is_a? Symbol
              x_or_loc = LocationToTiogaLocation[x_or_loc]
            end
            dict['loc'] = x_or_loc
          end
          if measure
            dict['measure'] = measure
          end
          t.show_text(dict)
        end
      end



      # The style of a full text object.
      class FullTextStyle < BaseTextStyle
        # The color of the text
        attr_accessor :color

        # The (horizontal) position with respect to a location. You'll
        # seldom need that.
        attr_accessor :position
      end

      # A hash that can be used as a base for optional arguments to
      # things that take texts.
      FullTextStyleOptions = {
        'angle' => CmdArg.new('float'),
        'shift' => CmdArg.new('float'),
        'scale' => CmdArg.new('float'),
        'justification' => CmdArg.new('justification'),
        'color' => CmdArg.new('color'),
        'align' => CmdArg.new('alignment'),
      }

      # A label.
      class TextLabel < FullTextStyle
        # The text of the label. _nil_ or _false_ means there will be
        # no text displayed
        attr_accessor :text
        
        # The location of the label.
        attr_accessor :loc

        def initialize(text = nil)
          @text = text
        end
        
        # Draw the label, if #text is not _nil_ or _false_.
        def draw(t, measure = nil)
          if @text
            self.draw_text(t, @text, @loc, nil, measure)
          end
        end

      end

    end
  end
end

