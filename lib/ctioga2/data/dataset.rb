# dataset.rb: a class holding *one* dataset
# copyright (c) 2009-2011 by Vincent Fourmond
  
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

      include Log

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

        # Cache for the indexed dtable
        @indexed_dtable = nil
      end

      # Creates a 
      def self.create(name, number)
        cols = []
        number.times do
          cols << Dobjects::Dvector.new()
        end
        return self.new(name, cols)
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
      def each_values(with_errors = false, expand_nil = true)
        @x.size.times do |i|
          v = @x.values_at(i,with_errors, expand_nil)
          for y in @ys
            v += y.values_at(i,with_errors, expand_nil)
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

      # Appends the given values (as yielded by each_values(true)) to
      # the stack. Elements of _values_ laying after the last
      # DataColumn in the Dataset are simply ignored. Giving less than
      # there should be will give interesting results.
      def push_values(*values)
        @x.push_values(*(values[0..2]))
        @ys.size.times do |i|
          @ys[i].push_values(*(values.slice(3*(i+1),3)))
        end
      end

      # Almost the same thing as #push_values, but when you don't care
      # about the min/max things.
      def push_only_values(values)
        @x.push_values(values[0])
        @ys.size.times do |i|
          @ys[i].push_values(values[i+1])
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

      # Applies formulas to values. Formulas are like text-backend
      # specification: ":"-separated specs of the target
      def apply_formulas(formula)
        columns = []
        columns << Dobjects::Dvector.new(@x.size) do |i|
          i
        end
        columns << @x.values
        for y in @ys
          columns << y.values
        end

        # Names:
        heads = {
          'x' => 1,
          'y' => 2,
          'z' => 3,
        }
        i = 1
        for f in @ys
          heads["y#{i}"] = i+1
          i += 1
        end

        result = []
        for f in formula.split(/:/) do
          fm = Utils::parse_formula(f, nil, heads)
          debug { 
            "Using formula #{fm} for column spec: #{f} (##{result.size})" 
          }
          result << DataColumn.new(Dobjects::Dvector.
                                   compute_formula(fm, 
                                                   columns))
        end
        return Dataset.new(name + "_mod", result)
      end


      # Returns an IndexedDTable representing the XYZ
      # data. Information about errors are not included.
      #
      # @todo For performance, this will have to be turned into a real
      # Dtable or Dvector class function. This function is just going
      # to be *bad* ;-)
      #
      # @todo The cache should be invalidated when the contents of the
      # Dataset changes (but that will be *real* hard !)
      def indexed_table
        if @indexed_dtable
          return @indexed_dtable
        end
        # We convert the index into three x,y and z arrays
        x = @x.values.dup
        y = @ys[0].values.dup
        z = @ys[1].values.dup
        
        xvals = x.sort.uniq
        yvals = y.sort.uniq
        
        # Now building reverse hashes to speed up the conversion:
        x_index = {}
        i = 0
        xvals.each do |v|
          x_index[v] = i
          i += 1
        end

        y_index = {}
        i = 0
        yvals.each do |v|
          y_index[v] = i
          i += 1
        end

        table = Dobjects::Dtable.new(xvals.size, yvals.size)
        # We initialize all the values to NaN
        table.set(0.0/0.0)
        
        x.each_index do |i|
          ix = x_index[x[i]]
          iy = y_index[y[i]]
          # Y first !
          table[iy, ix] = z[i]
        end
        @indexed_dtable = IndexedDTable.new(xvals, yvals, table)
        return @indexed_dtable
      end

      # Returns a x,y Function
      #
      # @todo add algorithm
      def make_contour(level)
        dtable = indexed_table
        x,y,gaps = *dtable.make_contour(level)

        # We remove any gap corresponding to the element size,
        # meaningless.
        gaps -= [x.size]
        n = 0.0/0.0
        gaps.sort.reverse.each do |i|
          x.insert(i,n)
          y.insert(i,n)
        end
        return Dobjects::Function.new(x,y)
      end

      # Smooths the data using a naive gaussian-like convolution (but
      # not exactly). Not for use for reliable data filtering.
      def naive_smooth!(number)
        kernel = Dobjects::Dvector.new(number) { |i|
          Utils.cnk(number,i)
        }
        mid = number - number/2 - 1
        for y in @ys
          y.convolve!(kernel, mid)
        end
      end

      # Returns a hash of Datasets indexed on the values of the
      # columns _cols_. Datasets contain the same number of columns.
      def index_on_cols(cols = [2])
        # Transform column number into index in the each_values call
        cols.map! do |i|
          i*3 
        end

        datasets = {}
        self.each_values(true) do |i,*values|
          signature = cols.map do |i|
            values[i]
          end
          datasets[signature] ||= Dataset.create(name, self.size)
          datasets[signature].push_values(*values)
        end
        return datasets
      end

      
      # Massive linear regressions over all X and Y values
      # corresponding to a unique set of all the other Y2... Yn
      # values.
      #
      # Returns the [coeffs, lines]
      #
      # @todo Have the possibility to elaborate on the regression side
      # (in particular force b to 0)
      def reglin(options = {})
        cols = []
        2.upto(self.size-1) do |i|
          cols << i
        end
        datasets = index_on_cols(cols)

        # Create two new datasets:
        # * one that collects the keys and a,b
        # * another that collects the keys and x1,y1, x2y2
        coeffs = Dataset.create("coefficients", self.size)
        lines = Dataset.create("lines", self.size)

        for k,v in datasets
          f = Dobjects::Function.new(v.x.values, v.y.values)
          if options['linear']  # Fit to y = a*x
            d = f.x.dup
            d.mul!(f.x)
            sxx = d.sum
            d.replace(f.x)
            d.mul!(f.y)
            sxy = d.sum
            a = sxy/sxx
            coeffs.push_only_values(k + [a,0])
            lines.push_only_values(k + [f.x.min, a * f.x.min])
            lines.push_only_values(k + [f.x.max, a * f.x.max])
          else
            a,b = f.reglin
            coeffs.push_only_values(k + [a, b])
            lines.push_only_values(k + [f.x.min, b + a * f.x.min])
            lines.push_only_values(k + [f.x.max, b + a * f.x.max])
          end
          
        end

        return [coeffs, lines]
      end

      # Merges one or more other data sets into this one; one or more
      # columns are designated as "master" columns and their values
      # must match in all datasets. Extra columns are simply appended,
      # in the order in which the datasets are given
      #
      # Comparisons between the values are made in abritrary precision
      # unless precision is given, in which case values only have to
      # match to this given number of digits.
      #
      # @todo update column names.
      #
      # @todo write provisions for column names, actually ;-)...
      def merge_datasets_in(datasets, columns = [0], precision = nil)
        # First thing, the data precision block:

        prec = if precision then
                 proc do |x|
            ("%.#{@precision}g" % x) # This does not need to be a Float
          end
               else
                 proc {|x| x}   # For exact comparisons
               end

        # First, we build an index of the master columns of the first
        # dataset.

        hash = {}
        self.each_values(false) do |i, *cols|
          signature = columns.map {|j|
            prec.call(cols[j])
          }
          hash[signature] = i
        end

        remove_indices = columns.sort.reverse

        for set in datasets
          old_columns = set.all_columns
          for i in remove_indices
            old_columns.slice!(i)
          end

          # Now, we got rid of the master columns, we add the given
          # number of columns

          new_columns = []
          old_columns.each do |c|
            new_columns << DataColumn.create(@x.size, c.has_errors?)
          end

          set.each_values(false) do |i, *cols|
            signature = columns.map {|j|
              prec.call(cols[j])
            }
            idx = hash[signature]
            if idx
              old_columns.each_index  { |j|
                new_columns[j].
                set_values_at(idx, 
                              * old_columns[j].values_at(i, true, true))
              }
            else
              # Data points are lost
            end
          end
          @ys.concat(new_columns)
        end

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

