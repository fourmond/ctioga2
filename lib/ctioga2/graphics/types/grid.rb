# grib.rb: setup and use of a "graph grid"
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

  Version::register_svn_info('$Revision$', '$Date$')

  module Graphics

    # This class provides a grid-like layout through the use of a grid
    # setup command and a grid box specification.
    #
    # This
    class GridLayout

      # The margins (left, right, top, bottom) around the whole grid
      attr_accessor :outer_margins

      # The X offset to go from the right-hand side of one element to
      # the left-hand-side of the next
      attr_accessor :delta_x

      # The Y offset to go from the bottom of one element to
      # the top of the next.
      attr_accessor :delta_y

      # The nup: an array nb horizontal, nb vertical
      attr_accessor :nup

      def initialize
      end

    end

  end
end

