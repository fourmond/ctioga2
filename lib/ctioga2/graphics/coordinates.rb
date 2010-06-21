# coordinates.rb: coordinate transformations
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

    # Deals with transforming the coordinates of all datasets
    #
    # \todo
    # * offsets
    # * scales
    # * x/y log
    # * non-linear transformations ?
    # * the possibility to provide locations using this.
    # * conversion of datasets.
    #
    # \todo Shouldn't this facility be axis-local ? Non-linear
    # transformations definitely belong there as well (and that would
    # be almost trivial to write !).
    class CoordinateTransforms

      # A scaling factor for coordinates:
      attr_accessor :x_scale, :y_scale

      # An offset for coordinates
      attr_accessor :x_offset, :y_offset

      # Whether to use logarithmic coordinates
      attr_accessor :x_log, :y_log

      # Creates a CoordinateTransformations object.
      def initialize
      end

      # Apply a transformation to a Data::Dataset holding 2D signals.
      # Modifies the dataset in place.
      def transform_2d!(dataset)
        for w in [:x , :y]
          if v = self.send("#{w}_scale") 
            dataset.send(w).apply do |x|
              x.mul!(v)
            end
          end
          if v = self.send("#{w}_offset") 
            dataset.send(w).apply do |x|
              x.add!(v)
            end
          end
          if v = self.send("#{w}_log") 
            dataset.send(w).apply do |x|
              x.safe_log10!
            end
          end
        end
      end
    end

  end
end

