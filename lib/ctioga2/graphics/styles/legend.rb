# legend.rb: style of legends
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

      # Style of a given Legends::LegendStorage object.
      class LegendStorageStyle < BasicStyle

        # The distance between two lines, a Types::Dimension object.
        deprecated_attribute :dy, 'dimension', "use vpadding instead"

        # The minimum distance between successive vertical elements
        typed_attribute :vpadding, 'dimension'

        # The width of the legend pictogram, a Types::Dimension object.
        attr_accessor :picto_width

        # The height of the legend pictogram, a Types::Dimension object.
        attr_accessor :picto_height

        # The distance between the legend pictogram and the text
        attr_accessor :picto_to_text

        # The overall scale of the legend
        typed_attribute :scale, 'float'

        # The scale of the legend text -- relative to the overall
        # scale.
        typed_attribute :text_scale, 'float'

        # The scale of the pictogram
        typed_attribute :symbol_scale, 'float'


        # A frame around the legend
        sub_style :frame, BoxStyle

        # Padding around the frame
        typed_attribute :frame_padding, 'dimension'

        def initialize

          # @dy = Types::Dimension.new(:dy, 1.6, :y)

          @vpadding = Types::Dimension.new(:dy, 0.3, :y)

          @picto_width = Types::Dimension.new(:dy, 1.6, :x)
          @picto_height = Types::Dimension.new(:dy, 0.6, :y)

          @picto_to_text = Types::Dimension.new(:dy, 0.3, :x)

          @scale = 0.8
          @text_scale = 0.82
          @symbol_scale = 1

          @frame = BoxStyle.new()
          
          @frame_padding = Types::Dimension.from_text("1mm", :x)
        end

        def dy_to_figure(t)

          # Defaults to one line height + the padding

          if @dy
            return @dy.to_figure(t, :y)
          end

          line = Types::Dimension.new(:dy, 1, :y) 
          return line.to_figure(t, :y) + @vpadding.to_figure(t, :y)
        end

        def vpadding_to_figure(t)
          if @dy 
            line = Types::Dimension.new(:dy, 1, :y) 
            return (@dy.to_figure(t, :y) - line.to_figure(t, :y))
          end
          return @vpadding.to_figure(t, :y)
        end

      end

      class MultiColumnLegendStyle < BasicStyle

        # Padding !
        typed_attribute :dx, 'dimension'

        # Number of columns
        typed_attribute :columns, 'integer'
        
        def initialize()

          @dx = Types::Dimension.new(:dy, 0.2, :x)

          @columns = 2
        end
      end
    end
  end
end

