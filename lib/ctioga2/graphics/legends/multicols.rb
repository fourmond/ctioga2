# items.rb: individual legend items
# copyright (c) 2013 by Vincent Fourmond

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

      # This class is an item that holds other items, and displays
      # them in columns.
      #
      # @todo Add support for tiling on lines too ;-)...
      #
      # @todo Add support for filling up to some width/height.
      #
      # @todo Choose the order (vert first or horiz first)
      class MultiColumnLegend < LegendItem

        # The underlying storage
        attr_accessor :storage

        # The style
        attr_accessor :style

        def initialize(cols = 2)
          super()
          @storage = LegendStorage.new
          @style = Styles::MultiColumnLegendStyle.new
        end

        # Adds an item to the underlying storage.
        def add_item(item)
          @storage.add_item(item)
        end

        # Draws all the legends
        def draw(t, legend_style, x, y)
          items = storage.harvest_contents()
          size(t, legend_style)

          index = 0
          
          dy = 0
          dx = 0
          cur_height = legend_style.dy_to_figure(t)
          
          for it in items
            w, h = it.size(t, legend_style)
            col = index % @style.columns

            # Flush
            if col == 0
              dy -= cur_height unless index == 0
              dx = 0
              cur_height = h
            else
              dx += @column_widths[col - 1]
            end


            if cur_height < h
              cur_height = h
            end

            it.draw(t, legend_style, x + dx, y + dy)
            index += 1
          end
          
        end

        # Computes the size of all the legends, and also update the
        # @column_widths array.
        def size(t, legend_style)
          items = storage.harvest_contents()

          # Always that much !
          cur_height = legend_style.dy_to_figure(t)
          widths = [0] * @style.columns
          height = 0
          index = 0
          for it in items
            w,h = it.size(t, legend_style)
            col = index % @style.columns

            # Flush
            if col == 0
              height += cur_height unless index == 0
              cur_height = h
            end
            if widths[col] < w
              widths[col] = w
            end
            if cur_height < h
              cur_height = h
            end
            index += 1
          end

          height += cur_height
          # Now add padding to the columns widths:
          (widths.size()-1).times do |i|
            widths[i] += @style.dx.to_figure(t, :x)
          end

          @column_widths = widths
          width = widths.reduce(:+) # Do padding !
          return [width, height]
        end
        
      end
    end

  end
end
