# datacolumn.rb: a class holding a 'column' of data
# copyright (c) 2009-2011 by Vincent Fourmond
  
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details (in the COPYING file).

require 'Dobjects/Dvector'
require 'ctioga2/utils'

# This module contains all the classes used by ctioga
module CTioga2

  module Data

    # This class holds one column, possibly with error bars.
    #
    # \todo a way to concatenate two DataColumns
    #
    # \todo a way to easily access the by "lines"
    class DataColumn
      
      # A Dvector holding ``real'' values
      attr_accessor :values
      
      # A Dvector holding minimal values
      attr_accessor :min_values

      # A Dvector holding maximal values
      attr_accessor :max_values

      # The base date. If this accessor isn't _nil_, then the
      # DataColumn represents a date, and the values are counted in
      # *seconds* with respect to @base_date (which should be a time
      # object).
      attr_accessor :base_date

      # \todo a method that resembles the code in the old text backend
      # to set errors according to a speficication (relative,
      # absolute, already max/min)

      # \todo a dup !

      def initialize(values, min = nil, max = nil)
        @values = values
        @min_values = min
        @max_values = max
      end

      # Creates a DataColumn object
      def self.create(number, with_errors = false)
        a = Dobjects::Dvector.new(number, NaN::NaN)
        if with_errors
          b = Dobjects::Dvector.new(number, NaN::NaN)
          c = Dobjects::Dvector.new(number, NaN::NaN)
        else
          b = nil
          c = nil
        end
        return self.new(a, b, c)
      end


      # Yields all the vectors in turn to apply a given
      # transformation.
      def apply
        for v in all_vectors
          yield v if v
        end
      end

      # Sorts the values according to the index vector given.
      def reindex(idx_vector)
        for v in all_vectors
          # This is slow !
          # Code should be written in C on the dvector side.
          #
          # Or we could use Function.sort, though this is not very
          # elegant nor efficient. (but it would be memory-efficient,
          # though).
          next unless v
          w = Dobjects::Dvector.new(idx_vector.size) do |i|
            v[idx_vector[i]]
          end
          v.replace(w)
        end
      end

      # Whether there are error bars.
      def has_errors?
        return (@min_values && @max_values)
      end

      # Whether the column represents a date
      def is_date?
        return ! @base_date.nil?
      end

      # Converts the (float) value into a date
      def to_time(value)
        return @base_date + value
      end

      # Column names. _base_ is used as a base for the names. If
      # _expand_ is on, always return all the names.
      def column_names(base, expand = false)
        if expand || has_errors?
          return [base, "#{base}min", "#{base}max"]
        else
          return [base]
        end
      end

      # Values at the given index.
      #
      # If _with_errors_ is false, only [value] is returned.
      #
      # If _with_errors_ is true, then, non-existent values are
      # expanded to _nil_ if _expand_nil_ is true or to value if not.
      def values_at(i, with_errors = false, expand_nil = true)
        if ! with_errors 
          return [@values[i]]
        end
        if has_errors?
          return [@values[i], @min_values[i], @max_values[i]]
        else
          if expand_nil
            return [@values[i], nil, nil]
          else
            return [@values[i], @values[i], @values[i]]
          end
        end
      end

      # Vectors: all values if there are error bars, or only the
      # #value one if there isn't.
      def vectors
        if has_errors?
          return [@values, @min_values, @max_values]
        else
          return [@values]
        end
      end

      # Returns the number of elements.
      def size
        return @values.size
      end

      # Sets the values at the given index
      def set_values_at(i, value, min = nil, max = nil)
        @values[i] = value
        if min && max
          ensure_has_errors
          @min_values[i] = min
          @max_values[i] = max
        end
      end

      # Appends the given values at the end of the DataColumn
      #
      # @todo This isn't very efficient. Does it really matter ?
      def push_values(value, min=nil, max=nil)
        set_values_at(@values.size, value, min, max)
      end

      # Creates dummy errors (ie, min_values = max_values = values) if
      # the datacolumn does not currently have one.
      def ensure_has_errors
        if ! has_errors?
          @min_values = @values.dup
          @max_values = @values.dup
        end
      end

      # Concatenates with another DataColumn, making sure the errors
      # and such are not lost.
      def <<(column)
        # If there are error bars, wew make sure we concatenate all of them
        if has_errors? || column.has_errors?
          self.ensure_has_errors
          column.ensure_has_errors
          @min_values.concat(column.min_values)
          @max_values.concat(column.max_values)
        end
        @values.concat(column.values)
      end

      # Only keeps every _n_ points in the DataColumn
      def trim!(nb)
        nb = nb.to_i
        if nb < 2
          return
        end

        new_vects = []
        for v in all_vectors
          if v
            new_values = Dobjects::Dvector.new
            i = 0
            for val in v
              if (i % nb) == 0
                new_values << val
              end
              i+=1
            end
            new_vects << new_values
          else
            new_vects << nil
          end
        end
        set_vectors(new_vects)
      end

      ColumnSpecsRE = /|min|max|err|rerr/i

      # This function sets the value of the DataColumn object
      # according to a hash: _spec_ => _vector_.  _spec_ can be any of:
      # * 'value', 'values' or '' : the #values
      # * 'min' : #min
      # * 'max' : #max
      # * 'err' : absolute error: min is value - error, max is value +
      #    error
      def from_hash(spec)
        s = spec.dup
        @values = spec['value'] || spec['values'] || 
          spec[''] 
        if ! @values
          raise "Need a 'value' specification"
        end
        for k in ['value', 'values', '']
          s.delete(k)
        end
        for key in s.keys
          case key
          when /^min$/i
            @min_values = s[key]
          when /^max$/i
            @max_values = s[key]
          when /^err$/i
            @min_values = @values - s[key]
            @max_values = @values + s[key]
          when /^rerr$/i
            @min_values = @values *(1 - s[key])
            @max_values = @values *(1 + s[key])
          else
            raise "Unkown key: #{key}"
          end
        end
      end


      # Creates and returns a DataColumn object according to the
      # _spec_. See #from_hash for more information.
      def self.from_hash(spec)
        a = DataColumn.new(nil)
        a.from_hash(spec)
        return a
      end

      # Returns the minimum value of all vectors held in this column
      def min
        m = @values.min
        for v in [@min_values, @max_values]
          if v
            m1 = v.min
            if m1 < m           # This also works if m1 is NaN
              m = m1
            end
          end
        end
        return m
      end

      # Returns the maximum value of all vectors held in this column
      def max
        m = @values.max
        for v in [@min_values, @max_values]
          if v
            m1 = v.max
            if m1 > m           # This also works if m1 is NaN
              m = m1
            end
          end
        end
        return m
      end

      def convolve!(kernel, middle = nil)
        middle ||= kernel.size/2
        # We smooth everything, stupidly?
        for v in all_vectors
          v.replace(v.convolve(kernel,middle)) if v
        end
      end

      # Resize all the columns to the given size. 
      def resize!(new_size)
        for v in all_vectors
          v.resize(new_size) if v
        end
      end

      # Bins the values of the columns into nb bins between min and
      # max. Values outside that range are not taken into account. If
      # @a normalize is true, then each value is normalized by the
      # total number of samples.
      #
      # It returns [xv, yv], where xv are the centers of the bins, and
      # yv the counts
      #
      # Does not take into account the error columns.
      def bin(min, max, nb, normalize = false)
        total = @values.size*1.0
        xv = Dobjects::Dvector.new(nb)
        yv = Dobjects::Dvector.new(nb)

        0.upto(nb-1) do |i|
          xv[i] = min + (max-min)*(i+0.5)/nb
          yv[i] = 0
        end
        
        for v in @values
          idx = (v-min)/(max-min)
          if idx > 1.0 or idx < 0
            next
          end
          idx = (idx*nb).to_i
          if idx == nb
            idx = nb-1          # case v = max
          end
          yv[idx] += 1
        end

        if normalize
          yv *= (1.0/total)
        end

        return [xv, yv]
      end

      # Averages over the given indices, and puts the result at the
      # target index.
      #
      # Different averaging modes are available.
      def average_over(istart, iend, itgt, mode = :avg)
        case mode
        when :avg
          # Stupidly average over all the values
          for v in all_vectors
            if v
              av = Utils::average_vector(v, istart, iend)
              v[itgt] = av[0]
            end
          end
        when :stddev
          # Ignore errors, and set them from the standard deviation
          @min_values ||= @values.dup
          @max_values ||= @values.dup

          av = Utils::average_vector(@values, istart, iend, 2)
          @values[itgt] = av[0]
          stddev = (av[1] - av[0]**2)**0.5
          @min_values[itgt] = av[0] - stddev
          @max_values[itgt] = av[0] + stddev
        end
      end
      
      protected

      # All the vectors held by the DataColumn
      def all_vectors
        return [@values, @min_values, @max_values]
      end

      # Sets the vectors to the given list, as might have been
      # returned by #all_vectors
      def set_vectors(vectors)
        @values, @min_values, @max_values = *vectors
      end

    end

  end

end

