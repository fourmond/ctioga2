# items.rb: individual legend items
# copyright (c) 2008,2009 by Vincent Fourmond

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details (in the COPYING file).

require 'ctioga2/utils'
require 'ctioga2/log'

require 'ctioga2/graphics/styles'

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Graphics

    module Legends

      # All items that can be displayed in a legend derive from this
      # one.
      class LegendItem

        # This class-wide variable is used to number text
        # in a unique fashion
        @@legend_item_numbering = 0

        # Initializes the LegendItem. Children *must* call super to
        # make sure the numbering is dealt with properly.
        def initialize
          @legend_number = @@legend_item_numbering
          @@legend_item_numbering += 1
        end

        # Returns the (width, height) in figure coordinates of the
        # legend element with the given Styles::LegendStyle and
        # FigureMaker reference objects.
        #
        # The returned values can be inaccurate to some extent.
        def size(t, legend_style)
          return [0, 0]
        end

        # Draws the legend at the given top left position (_x_,_y_) in
        # figure coordinates.
        def draw(t, legend_style, x, y)
        end


        protected 

        # The internal name for the legend - one we can use in a
        # get_text_size query.
        def legend_name
          return "legend-#{@legend_number}"
        end

        # Returns the _y_ value for the baseline of the text in terms
        # of figure coordinates.
        def get_baseline_y(t, legend_style, y)
          return y - Types::Dimension.new(:dy,1.0,:y).to_figure(t) 
        end


      end

      # A class representing the style of a single legend line
      # (unrelated to a curve)
      class LegendLine < LegendItem

        # The text of the line
        attr_accessor :text

        # The style of the text, a Styles.FullTextStyle object.
        attr_accessor :style
        
        def initialize(text = "", style = {})
          super()
          @text = text
          @style = Styles::FullTextStyle.from_hash(style)
          @style.justification ||= Tioga::FigureConstants::LEFT_JUSTIFIED

        end

        # Draw one single text line.
        def draw(t, legend_style, x, y)
          y = get_baseline_y(t, legend_style, y) 
          @style.draw_text(t, @text, x, y, legend_name)
        end

        # Computes the size of the line. Height should always be
        # accurate, but width can be 0 sometimes...
        def size(t, legend_style)
          height = legend_style.dy.to_figure(t)

          width = 0.0

          info = t.get_text_size(legend_name)
          
          if info.key? 'width'
            width += t.convert_output_to_figure_dx(10*info['width'])
          end

          return [ width, height ]
        end
        
      end

      # The legend of a curve object, or rather, the legend
      # corresponding to a given
      #
      # TODO: finish to adapt: use FullTextStyle to draw the objects.
      class CurveLegend < LegendItem

        include CTioga2::Log
        
        attr_accessor :curve_style

        def initialize(style)
          super()
          @curve_style = style
        end
        
        # Draw one single text line
        #
        # TODO: adapt here !
        #
        # TODO: _x_ and _y_ are not taken into account the way they should be.
        def draw(t, legend_style, x, y)
          y = get_baseline_y(t, legend_style, y) 
          t.context do 
            # Position specification for the legend pictogram
            margin_specs = { 'left' => x,
              'right' => 1 - x - legend_style.picto_width.to_figure(t),
              'bottom' => y,
              'top' => 1 - y - legend_style.picto_height.to_figure(t)
            }
            debug "Legend margins for '#{@curve_style.legend}' : #{margin_specs.inspect}"
            t.subfigure(margin_specs) do
              # We make the markers slightly smaller than the text
              # around.
              t.rescale_text(0.8)
              @curve_style.draw_legend_pictogram(t)
            end
          end
          t.show_text('x' => x + 
                      legend_style.picto_width.to_figure(t) + 
                      legend_style.picto_to_text.to_figure(t), 
                      'y' => y, 'text' => @curve_style.legend,
                      'measure' => legend_name,
                      'justification' => Tioga::FigureConstants::LEFT_JUSTIFIED)
        end

        # Computes the size of the line. Height should always
        # be accurate, but width can be 0 sometimes...
        def size(t, legend_style)
          height = legend_style.dy.to_figure(t)

          width = legend_style.picto_width.to_figure(t) + 
            legend_style.picto_to_text.to_figure(t) 

          info = t.get_text_size(legend_name)
          
          if info.key? 'width'
            width += t.convert_output_to_figure_dx(10*info['width'])
          end

          return [ width, height ]
        end
        
        
      end
    end

  end
end
