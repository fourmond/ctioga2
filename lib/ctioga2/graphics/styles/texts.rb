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

      # Horizontal or vertical
      LocationVertical = {
        :left => true,
        :right => true,
        :bottom => false,
        :top => false,
        :at_x_origin => true,
        :at_y_origin => false
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
          dict = prepare_show_text_dict(text, x_or_loc, y, measure)
          t.show_text(dict)
        end

        protected
        
        # Prepares the dictionnary for use with show_text
        def prepare_show_text_dict(text, x_or_loc, y = nil, measure = nil)
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
          return dict
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
        # Attributes such as scale, shift and angle are taken from the
        # corresponding _default_ if _default_ isn't nil.
        def draw(t, default = nil, measure = nil)
          if @text
            dict = prepare_label_dict(t, default, measure) 
            t.show_text(dict)
          end
        end

        # Gets the extension of the label, in units of text height.
        # Default values for the various parameters are taken from the
        # _default_ parameter if they are not specified.
        def label_extension(t, default = nil, side = nil)
          if @text
            dict = prepare_label_dict(t, default, nil) 
            case side
            when :bottom, :right
              extra = 0.5       # To account for baseline ?
            when :top, :left
              extra = 1
            else                # We take the safe side !
              extra = 1
            end
            return (dict['shift'] + extra) * dict['scale']
          else
            return 0
          end
        end

        protected 
        
        def prepare_label_dict(t, default = nil, measure = nil)
          dict = prepare_show_text_dict(@text, @loc, nil, measure)
          if default
            for attribute in %w(scale angle shift)
              if ! dict.key?(attribute)
                dict[attribute] = t.send("#{default}_#{attribute}")
              end
            end
          end
          return dict
        end

      end

      # Same thing as FullTextStyleOptions, but also permits to
      # override the #text part of the whole stuff..
      FullTextLabelOptions = FullTextStyleOptions.dup
      FullTextLabelOptions['text'] = CmdArg.new('text')



      # The style for a string marker. Hmmm, this is somewhat
      # redundant with TiogaPrimitiveCall::MarkerOptions and I don't
      # like that.
      class MarkerStringStyle < BasicStyle
        
        MarkerOptions = {
          'color' => 'color',
          'stroke_color' => 'color',
          'fill_color' => 'color',
          'scale' => 'float',
          'horizontal_scale' => 'float',
          'vertical_scale' => 'float',
          'angle' => 'float',
          'justification' => 'justification',
          'alignment' => 'alignment',
        }


        # The angle of the text
        attr_accessor :angle

        # The scale of the text
        attr_accessor :scale

        # The horizontal scale of the text
        attr_accessor :horizontal_scale

        # The vertical scale of the text
        attr_accessor :vertical_scale

        # The vertical alignment 
        attr_accessor :alignement

        # The horizontal alignment
        attr_accessor :justification

        # Colors
        attr_accessor :color
        attr_accessor :stroke_color
        attr_accessor :fill_color

        # A number between 1 to 14 -- a PDF font
        attr_accessor :font

        # The rendering mode.
        attr_accessor :mode
        
        def initialize
          # It make sense to use both by default, as it would be
          # confusing to provide both fill_ and stroke_color that
          # don't have effects by default...
          @mode = Tioga::FigureConstants::FILL_AND_STROKE
        end


        # Draws the string marker at the given location
        def draw_string_marker(t, text, x, y)
          dict = self.to_hash
          dict['text'] = text
          dict['at'] = [x, y]
          # TODO !
          dict['mode'] = 
          t.show_marker(dict)
        end

        # Returns the true vertical scale of the marker
        def real_vertical_scale
          return (@vertical_scale || 1.0) * (@scale || 1.0)
        end
      end
      
      StringMarkerOptions = {
        'color' => CmdArg.new('color'),
        'stroke_color' => CmdArg.new('color'),
        'fill_color' => CmdArg.new('color'),
        'scale' => CmdArg.new('float'),
        'horizontal_scale' => CmdArg.new('float'),
        'vertical_scale' => CmdArg.new('float'),
        'angle' => CmdArg.new('float'),
        'justification' => CmdArg.new('justification'),
        'alignment' => CmdArg.new('alignment'),
        'font' => CmdArg.new('pdf-font')
      }

      # A LaTeX font. It should be applied to text using the function
      # #fontify.
      #
      # \todo add real font attributes (family, and so on...)
      class LaTeXFont
        # The font command (bf, sf...). Naive but effective !
        attr_accessor :font_command

        def initialize
          # Nothing to be done
        end

        def self.from_text(txt)
          # For now, only the naive way of things:
          font = self.new
          font.font_command = txt
          return font
        end

        # Returns text wrapping _txt_ with the appropriate functions
        # to get the appropriate font in LaTeX.
        def fontify(txt)
          if @font_command
            return "{\\#{@font_command} #{txt}}"
          end
          return txt
        end
        
      end
      

    end
  end
end

