# point.rb: a point in a given dataset
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
require 'ctioga2/data/datacolumn'
require 'ctioga2/data/dataset'

module CTioga2

  module Data

    # This class represents a datapoint, ie. an index in a given
    # DataSet.
    class DataPoint

      # The Dataset object the point is in
      attr_accessor :dataset
      
      # The index of the data point within the Dataset
      attr_accessor :index
      
      # Creates a DataPoint with the given information.
      def initialize(dataset,index)
        @dataset = dataset
        @index = index
      end

      # Creates a DataPoint object based on the following _text_
      # specification. It needs a reference to a _plotmaker_, since it
      # accesses the data stack.
      #
      # Specification: ({_dataset_})?(_relative_|@_index_)
      def self.from_text(plotmaker, text, dataset = nil)
        if text =~ /^(?:\s*\{([^}]+)\})?\s*(?:([.\d]+)|@(\d+))\s*$/
          which = $1 || -1
          if $2
            rel = Float($2)
          else
            idx = $3.to_i
          end
          dataset ||= plotmaker.data_stack.stored_dataset(which)
          
          if ! dataset
            raise "Invalid or empty dataset: #{which}"
          end
          if rel
            idx = (rel * (dataset.x.values.size - 1)).to_i
          end
          return DataPoint.new(dataset, idx)
        else
          raise "Not a valid datapoint specification: '#{text}'"
        end
      end

      def x
        return @dataset.x.values[@index]
      end

      def y
        return @dataset.y.values[@index]
      end

      def point
        return [self.x, self.y]
      end

      # Returns the averaged X value around the datapoint
      def x_val(navg = 3)

        xvect = @dataset.x.values
        di = (navg-1)/2
        navg = 2*di + 1

        idx = usable_index(di, xvect.size)

        xval = 0
        (idx-di).upto(idx+di) do |i|
          xval += xvect[i]
        end
        return xval/(navg)
      end
      

      # Returns the averaged Y value around the datapoint
      def y_val(navg = 3)
        yvect = @dataset.y.values
        di = (navg-1)/2
        navg = 2*di + 1

        idx = usable_index(di, yvect.size)

        yval = 0
        (idx-di).upto(idx+di) do |i|
          yval += yvect[i]
        end
        return yval/(navg)
      end

      # Returns the value of the slope around the datapoint. This is
      # obtained using a linear regression, so it should be rather
      # reliable.
      def slope(navg = 3)
        xvect = @dataset.x.values
        yvect = @dataset.y.values
        di = (navg-1)/2
        navg = 2*di + 1

        idx = usable_index(di, xvect.size)

        sx = 0
        sxx = 0
        sxy = 0
        sy = 0

        (idx-di).upto(idx+di) do |i|
          sx += xvect[i]
          sy += yvect[i]
          sxx += xvect[i]**2
          sxy += xvect[i] * yvect[i]
        end
        if sxx*navg == sx*sx
          return 1
        else
          return (sxy * navg - sx*sy)/(sxx * navg - sx*sx)
        end
      end

      ## Returns the average value of the difference between two
      # consecutive X values
      def dx(navg = 3)
        xvect = @dataset.x.values
        di = (navg-1)/2
        navg = 2*di + 1

        idx = usable_index(di, xvect.size)
        return (xvect[idx+di]-xvect[idx-di])/navg
      end
      

      protected
      # Makes sure the boudaries for averaging are fine
      def usable_index(di, size)
        # Boundary checks
        if @index - di < 0
          return di
        elsif @index + di >= size
          return size - 1 - di
        end
        return @index
      end


    end

  end

end

