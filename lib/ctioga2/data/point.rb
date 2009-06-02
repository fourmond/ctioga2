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

  Version::register_svn_info('$Revision$', '$Date$')


  module Data

    # This class represents a datapoint, ie. an index in a given
    # DataSet.
    class DataPoint

      # The Dataset object the point is in
      attr_accessor :dataset
      
      # The index of the data point within the Dataset
      attr_accessor :index
      
      # Creates a DataPoint with the given information.
      def initialize(index, dataset)
      end

      # Creates a DataPoint object based on the following _text_
      # specification. It needs a reference to a _plotmaker_, since it
      # accesses the data stack.
      #
      # Specification: ({_dataset_})?(_relative_|@_index_)
      def self.from_text(plotmaker, text)
        if text =~ /^(?:\s*\{([^}]+)\})?\s*(?:([.\d]+)|@(\d+))\s*$/
          which = $1 || -1
          if $2
            rel = Float($2)
          else
            idx = $3.to_i
          end
          dataset = plotmaker.data_stack.stored_dataset(which)
          if ! dataset
            raise "Invalid or empty dataset: #{which}"
          end
          if rel
            idx = (rel * dataset.x.values.size).to_i
          end
          return DataPoint.new(dataset, idx)
        else
          raise "Not a valid datapoint specification: '#{text}'"
        end
      end
    end

    # TODO: functions returning xy values + slope for the given
    # datapoint. For each, possibility to average over several points.
    
  end

end

