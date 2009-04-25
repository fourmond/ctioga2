# dataset.rb: a class holding *one* dataset
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

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')


  # TODO: now, port the backend infrastructure...

  # This module holds all the code that deals with manipulation and
  # aquisition of data of any sort.
  module Data

    # This is the central class of the data manipulation in ctioga.
    # It is a series of 'Y' DataColumn indexed on a unique 'X'
    # DataColumn. This can be used to represent multiple XY data sets,
    # but also XYZ and even more complex data. The actual
    # signification of the various 'Y' columns are left to the user.
    class Dataset

      # The X DataColumn
      attr_accessor :x

      # All Y DataColumn (an Array of DataColumn)
      attr_accessor :ys

      # The name of the Dataset, such as one that could be used in a
      # legend (like for the --auto-legend option of ctioga).
      attr_accessor :name

      # Creates a new Dataset object with the given data columns
      # (Dvector or DataColumn). #x is the first one
      def initialize(name, columns)
        columns.each_index do |i|
          if columns[i].is_a? Dobjects::Dvector
            columns[i] = DataColumn.new(columns[i])
          end
        end
        @x = columns[0]
        @ys = columns[1..-1]
        @name = name
      end

      # Creates a new Dataset from a specification. This function
      # parses a specification in the form of:
      # * a:b{:c}+
      # * spec=a{:spec2=b}+
      #
      # It yields each of the unprocessed text, not necessarily in the
      # order they were read, and expects a Dvector as a return value.
      #
      # It then builds a suitable Dataset object with these values,
      # and returns it.
      #
      # It is *strongly* *recommended* to use this function for
      # reimplementations of Backends::Backend#query_dataset.
      def self.dataset_from_spec(name, spec)
        specs = []
        i = 0
        for s in spec.split(/:/)
          if s =~ /^(x|y\d*|z)(#{DataColumn::ColumnSpecsRE})=(.*)/i
            which, mod, s = $1.downcase,($2 && $2.downcase) || "value",$3
            
            case which
            when /x/
              idx = 0
            when /y(\d+)?/
              if $1
                idx = $1.to_i
              else
                idx = 1
              end
            when /z/
              idx = 2
            end
            specs[idx] ||= {}
            specs[idx][mod] = yield s
          else
            specs[i] = {"value" =>  yield(s)}
          end
          i += 1
        end
        columns = []
        for s in specs
          columns << DataColumn.from_hash(s)
        end
        return Dataset.new(name, columns)
      end

      # The main Y column (ie, the first one)
      def y
        return @ys[0]
      end

      # The Z column, if applicable
      def z
        return @ys[1]
      end

      # Sorts all columns according to X values
      def sort!
        idx_vector = Dobjects::Dvector.new(@x.values.size) do |i|
          i
        end
        f = Dobjects::Function.new(@data.x.dup, idx_vector)
        f.sort
        # Now, idx_vector contains the indices that make X values
        # sorted.
        for col in all_columns
          col.reindex(idx_vector)
        end
      end

      # Returns an array with Column names.
      def column_names
        retval = @x.column_names("x")
        @ys.each_index do |i|
          retval += @ys[i].column_names("y#{i+1}")
        end
        return retval
      end

      # Iterates over all the values of the Dataset
      def each_values
        @x.size.times do |i|
          v = @x.values_at(i)
          for y in @ys
            v += y.values_at(i)
          end
          yield i, *v
        end
      end

      # The overall number of columns
      def size
        return 1 + @ys.size
      end
        

      # TODO: a dup !

      protected

      # Returns all DataColumn objects held by this Dataset
      def all_columns
        return [@x, *@ys]
      end
      
    end

  end

end

