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

  Version::register_svn_info('$Revision: 939 $', '$Date: 2009-04-05 14:48:44 +0200 (Sun, 05 Apr 2009) $')

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

        # The scale of the legend text
        attr_accessor :text_scale

        def initialize
          @dy = Types::Dimension.new(:dy, 1.6, :y)

          @picto_width = Types::Dimension.new(:dy, 1.6, :x)
          @picto_height = Types::Dimension.new(:dy, 0.6, :y)

          @picto_to_text = Types::Dimension.new(:dy, 0.3, :x)

          @text_scale = 0.65
        end
      end
    end
  end
end

