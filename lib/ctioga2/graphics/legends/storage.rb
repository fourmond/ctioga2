# storage.rb: an object holding legends
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

module CTioga2

  Version::register_svn_info('$Revision: 938 $', '$Date: 2009-04-05 02:14:04 +0200 (Sun, 05 Apr 2009) $')

  module Graphics

    # This module holds all the classes dealing with legends
    module Legends

      # This class holds a series of legends for curves.
      class LegendStorage

        # An array of LegendItem objects, in the order in which they
        # should get displayed.
        attr_accessor :contents

        def initialize
          @contents = []
        end

        # Adds a LegendItem or a Container to the LegendStorage
        # object.
        def add_item(item)
          @contents << item
        end

        # Returns a flat array of LegendItem that belong to the same
        # LegendArea as the object in which the LegendStorage was
        # created.
        def harvest_contents
          retval = []
          for el in @contents
            if el.is_a? LegendItem
              retval << el
            elsif el.is_a? Elements::Container and 
                (not el.legend_area)
              retvat += el.legend_storage.harvest_contents
            end
          end
          return retval
        end

      end

    end
  end

end

