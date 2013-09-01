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

      # The style of a text object. This class is suitable for
      # inclusion as a Hash to FigureMaker#show_axis, for the tick
      # labels.
      #
      # @todo alignement and justification are poor names. halign
      # and/or valign would be better.
      class BaseTextStyle < BasicStyle
        
        # The angle of the text
        typed_attribute :angle, 'float'

        # The 'shift' of the text. Only meaningful for axes and tick
        # labels, where the position of the text is specified using a
        # side rather than a precise position.
        typed_attribute :shift, 'dimension'

        # The scale of the text. In text height by default, but you
        # can specify a real size too
        typed_attribute :scale, 'dimension'

        # The vertical alignment 
        typed_attribute :alignment, 'alignment'

        # The horizontal alignment
        typed_attribute :justification, 'justification'

        # Draw the _text_ at the given location with the given style.
        # If _y_ is _nil_, then _x_or_loc_ is taken to be a location
        # (see FigureMaker#show_text).
        def draw_text(t, text, x_or_loc, y = nil, measure = nil)
          t.context do
            dict = prepare_show_text_dict(t, text, x_or_loc, y, measure)
            t.show_text(dict)
          end
        end

        def shift_dy(t)
          if @shift
            return @shift.to_dy(t)
          end
          return nil
        end

        def scale_dy(t)
          if @scale
            return @scale.to_dy(t)
          end
          return nil
        end

        def hash_for_tioga(t)
          dict = self.to_hash
          if dict.key? 'shift'
            dim = dict['shift']
            dict['shift'] = dim.to_dy(t)
          end
          if dict.key? 'scale'
            dim = dict['scale']
            dict['scale'] = dim.to_dy(t)
          end
          return dict
        end

        protected
        
        # Prepares the dictionnary for use with show_text
        def prepare_show_text_dict(t, text, x_or_loc, y = nil, measure = nil)
          dict = self.hash_for_tioga(t)
          dict['text'] = text

          if y
            dict['at'] = [x_or_loc, y]
          else
            # Perform automatic conversion on the location
            case x_or_loc
            when Symbol, Types::PlotLocation
              ## @todo It won't be easy to implement shifts for this,
              ## though it may be useful eventually.
              x_or_loc = Types::PlotLocation.new(x_or_loc).tioga_location
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
        typed_attribute :color, 'color'

        # The (horizontal) position with respect to a location. You'll
        # seldom need that.
        #
        # @todo Maybe this needs to fo in TextLabel rather than here ?
        typed_attribute :position, 'float'
      end

      # A hash that can be used as a base for optional arguments to
      # things that take texts.
      FullTextStyleOptions = FullTextStyle.options_hash()

      # A label.
      class TextLabel < FullTextStyle
        # The text of the label. _nil_ or _false_ means there will be
        # no text displayed
        typed_attribute :text, "text"
        
        # The location of the label.
        #
        # @todo This will have to eventually use PlotLocation, as it
        # makes much more sense.
        typed_attribute :loc, "location"

        def initialize(text = nil, loc = nil)
          super()
          @text = text
          @loc = loc
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
        def label_extension(t, default = nil, location = nil)
          if @text
            dict = prepare_label_dict(t, default, nil)
            extra = 0
            if location
              extra = location.label_extra_space(t)
            end
            return (dict['shift'] + extra) * dict['scale']
          else
            return 0
          end
        end

        protected 
        
        def prepare_label_dict(t, default = nil, measure = nil)
          dict = prepare_show_text_dict(t, @text, @loc, nil, measure)
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


      FullTextLabelOptions = TextLabel.options_hash()



      # The style for a string marker. Hmmm, this is somewhat
      # redundant with TiogaPrimitiveCall::MarkerOptions and I don't
      # like that.
      class MarkerStringStyle < BasicStyle
        
        # The angle of the text
        typed_attribute :angle, 'float'

        # The scale of the text
        typed_attribute :scale, "float"

        # The horizontal scale of the text
        typed_attribute :horizontal_scale, "float"

        # The vertical scale of the text
        typed_attribute :vertical_scale, "float"

        # The vertical alignment 
        typed_attribute :alignment, "alignment"

        # The horizontal alignment
        typed_attribute :justification, "justification"

        # Colors
        typed_attribute :color, 'color-or-false'
        typed_attribute :stroke_color, 'color-or-false'
        typed_attribute :fill_color, 'color-or-false'


        # A number between 1 to 14 -- a PDF font
        typed_attribute :font, "pdf-font"

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
          t.show_marker(dict)
        end

        # Draws the string marker at the given location
        def draw_marker(t, marker, x, y)
          dict = self.to_hash
          dict['marker'] = marker
          dict['at'] = [x, y]
          t.show_marker(dict)
        end

        # Returns the true vertical scale of the marker
        def real_vertical_scale
          return (@vertical_scale || 1.0) * (@scale || 1.0)
        end
      end


      # A LaTeX font. It should be applied to text using the function
      # #fontify.
      #
      # \todo add real font attributes (family, and so on...)
      #
      # @todo Deprecate in favor of the latter class
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

      # Full font information
      #
      # @todo There is a whole bunch of work to be done on the Tioga
      # side to make sure that things work.
      class FullLatexFont < BasicStyle
        
        # The size of the text
        typed_attribute :size, 'float'

        # I remove those since they don't work for the time being

        # # Font family
        # typed_attribute :family, 'text'

        # # Font series
        # typed_attribute :series, 'text'

        # # Font shape
        # typed_attribute :shape, 'text'
        

        # Set global font information based on this style
        #
        # This only works from within a figure !
        def set_global_font(t)
          # for a in %w(family series shape)
          #   v = self.send(a)
          #   t.send("tex_font#{a}=", v) if v
          # end


          if @size
            fact = @size/t.default_font_size
            t.rescale_text(fact)
          end
        end

      end
      

    end
  end
end

