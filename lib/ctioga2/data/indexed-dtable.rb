# indexed-dtable.rb: A Dtable object with non-uniform XY values
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

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')


  module Data

    # An indexed Dtable.
    #
    # This object represents an indexed Dtable, that is a Dtable with
    # given values of X and Y (not necessarily uniform). Its main use
    # is to get back a uniform (non-indexed) Dtable, for use with
    # create_image
    #
    # An important information is that places where there was no data
    # is implicitly represented as NaN
    class IndexedDTable

      # The underlying Dtable
      attr_accessor :table

      # X values
      attr_accessor :x_values

      # Y values
      attr_accessor :y_values

      def initialize(x, y, t)
        @table = t
        @x_values = x
        @y_values = y
      end

    end

  end

end

