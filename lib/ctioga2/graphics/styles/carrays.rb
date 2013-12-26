# carrays.rb: 'circular arrays'
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

  module Graphics

    module Styles

      # A CirularArray, i.e an array from which one can extract
      # successive elements in a fixed order, and that turns back to
      # the first element once all have been used (hence 'circular').
      class CircularArray
        
        # The set through which we go
        attr_reader :set

        # Defines the set of elements we'll be circling through and
        # resets the index.
        def set=(s)
          @set = s
          @value = 0
        end
        
        def initialize(set)
          @set = set
        end

        # Returns the next element in the array
        def next
          @value ||= 0
          if @value >= @set.size
            @value = 0
          end
          val = @set[@value]
          @value += 1
          return val
        end
      end

    end
  end
end

