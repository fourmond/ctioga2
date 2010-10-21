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
require 'ctioga2/data/indexed-dtable'

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')


  # \todo now, port the backend infrastructure...

  # This module holds all the code that deals with manipulation and
  # acquisition of data of any sort.
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

      # Returns true if X or Y columns have errors
      def has_xy_errors?
        return self.y.has_errors? || self.x.has_errors?
      end

      # Sorts all columns according to X values
      def sort!
        idx_vector = Dobjects::Dvector.new(@x.values.size) do |i|
          i
        end
        f = Dobjects::Function.new(@x.values.dup, idx_vector)
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

      # Iterates over all the values of the Dataset.  Values of
      # optional arguments are those of DataColumn::values_at.
      def each_values(expand = false, expand_nil = true)
        @x.size.times do |i|
          v = @x.values_at(i,expand, expand_nil)
          for y in @ys
            v += y.values_at(i,expand, expand_nil)
          end
          yield i, *v
        end
      end

      # The overall number of columns
      def size
        return 1 + @ys.size
      end

      # Concatenates another Dataset to this one
      def <<(dataset)
        if dataset.size != self.size
          raise "Can't concatenate datasets that don't have the same number of columns: #{self.size} vs #{dataset.size}"
        end
        @x << dataset.x
        @ys.size.times do |i|
          @ys[i] << dataset.ys[i]
        end
      end


      # Trims all data columns. See DataColumn#trim!
      def trim!(nb)
        for col in all_columns
          col.trim!(nb)
        end
      end

      
      # Modifies the dataset to only keep the data for which the block
      # returns true. The block should take the following arguments,
      # in order:
      #
      # _x_, _xmin_, _xmax_, _y_, _ymin_, _ymax_, _y1_, _y1min_, _y1max_,
      #  _z_, _zmin_, _zmax_, _y2_, _y2min_, _y2max_, _y3_, _y3min_, _y3max_
      #
      def select!(&block)
        target = []
        @x.size.times do |i|
          args = @x.values_at(i, true)
          args.concat(@ys[0].values_at(i, true) * 2)
          if @ys[1]
            args.concat(@ys[1].values_at(i, true) * 2)
            for yvect in @ys[2..-1]
              args.concat(yvect.values_at(i, true))
            end
          end
          if block.call(*args)
            target << i
          end
        end
        for col in all_columns
          col.reindex(target)
        end
      end

      # Same as #select!, but you give it a text formula instead of a
      # block. It internally calls #select!, by the way ;-)...
      def select_formula!(formula)
        names = @x.column_names('x', true)
        names.concat(@x.column_names('y', true))
        names.concat(@x.column_names('y1', true))
        if @ys[1]
          names.concat(@x.column_names('z', true))
          names.concat(@x.column_names('y2', true))
          i = 3
          for yvect in @ys[2..-1]
            names.concat(@x.column_names("y#{i}", true))
            i += 1
          end
        end
        block = eval("proc do |#{names.join(',')}|\n#{formula}\nend")
        select!(&block)
      end

      # \todo a dup !

      # Average all the non-X values of successive data points that
      # have the same X values. It is a naive version that also
      # averages the error columns.
      def average_duplicates!
        last_x = nil
        last_x_first_idx = 0
        xv = @x.values
        i = 0
        vectors = all_vectors
        while i < xv.size
          x = xv[i]
          if ((last_x == x) && (i != (xv.size - 1)))
            # Do nothing
          else
            if last_x_first_idx < (i - 1)  || 
                ((last_x == x) && (i == (xv.size - 1)))
              if i == (xv.size - 1)
                e = i
              else
                e = i-1
              end                 # The end of the slice.

              ## \todo In real, to do this properly, one would
              # have to write a proper function in DataColumn that
              # does averaging over certain indices possibly more
              # cleverly than the current way to do.
              for v in vectors
                subv = v[last_x_first_idx..e]
                ave = subv.sum/subv.size
                v.slice!(last_x_first_idx+1, e - last_x_first_idx)
                v[last_x_first_idx] = ave
              end
              i -= e - last_x_first_idx
            end
            last_x = x
            last_x_first_idx = i
          end
          i += 1
        end
        
      end


      # Returns an IndexedDTable representing the XYZ
      # data. Information about errors are not included.
      #
      # @todo For performance, this will have to be turned into a real
      # Dtable or Dvector class function. This function is just going
      # to be *bad* ;-)
      def indexed_table
        # We convert the index into three x,y and z arrays
        x = @x.values.dup
        y = @ys[0].values.dup
        z = @ys[1].values.dup
        
        xvals = x.sort.uniq
        yvals = y.sort.uniq
        
        # Now building reverse hashes to speed up the conversion:
        x_index = {}
        i = 0
        xvals.each do |x|
          x_index[x] = i
          i += 1
        end

        yvals.each do |x|
          y_index[x] = i
          i += 1
        end

        table = Dtable.new(xvals.size, yvals.size)
        # We initialize all the values to NaN
        table.set(0.0/0.0)
        
        x.each_index do |i|
          table[x_index[x[i]], y_index[y[i]]] = z[i]
        end
        return IndexedTable.new(xvals, yvals, table)
      end

      protected

      # Returns all DataColumn objects held by this Dataset
      def all_columns
        return [@x, *@ys]
      end

      # Returns all Dvectors of the columns one by one.
      def all_vectors
        return all_columns.map {|x| x.vectors}.flatten(1)
      end
      
    end

  end

end

