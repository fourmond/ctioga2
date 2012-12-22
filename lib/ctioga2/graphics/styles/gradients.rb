# gradients.rb: objects dealing with (color) gradients
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

require 'ctioga2/graphics/coordinates'

# This module contains all the classes used by ctioga
module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Graphics

    module Styles

      
      # A color gradient with two points
      #
      # \todo There could be many more
      #
      # @todo This will have to be replaced by a real color map based
      # on what
      class TwoPointGradient < BasicStyle

        include Log
        
        # The starting color (for x = 0)
        typed_attribute :start, 'color'

        # The ending color (for x = 1)
        typed_attribute :end, 'color'

        def initialize(s,e)
          warn { "This class shouldn't be used anymore at #{caller.inspect}" }
          @start = s
          @end = e
        end

        # Returns the color for the given value of _x_ (between 0 and 1)
        def color(x)
          return Utils::mix_objects(@end,@start, x)
        end
        
      end

    end
  end
end
