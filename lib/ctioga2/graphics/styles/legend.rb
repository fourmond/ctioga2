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
        attr_accessor :dy

        # The width of the legend pictogram, a Types::Dimension object.
        attr_accessor :picto_width

        # The height of the legend pictogram, a Types::Dimension object.
        attr_accessor :picto_height

        # The distance between the legend pictogram and the text
        attr_accessor :picto_to_text

        # The overall scale of the legend
        attr_accessor :scale

        # The scale of the legend text -- relative to the overall
        # scale.
        attr_accessor :text_scale

        # The scale of the pictogram
        attr_accessor :symbol_scale

        def initialize
          @dy = Types::Dimension.new(:dy, 1.6, :y)

          @picto_width = Types::Dimension.new(:dy, 1.6, :x)
          @picto_height = Types::Dimension.new(:dy, 0.6, :y)

          @picto_to_text = Types::Dimension.new(:dy, 0.3, :x)

          @scale = 0.8
          @text_scale = 0.82
          @symbol_scale = 1
        end
      end
    end
  end
end

