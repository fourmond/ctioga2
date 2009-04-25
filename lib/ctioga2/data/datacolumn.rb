# datacolumn.rb: a class holding a 'column' of data
# copyright (c) 2009 by Vincent Fourmond
  
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

  Version::register_svn_info('$Revision$', '$Date$')

  module Data

    # This class holds one column, possibly with error bars.
    class DataColumn
      
      # A Dvector holding ``real'' values
      attr_accessor :values
      
      # A Dvector holding minimal values
      attr_accessor :min_values

      # A Dvector holding maximal values
      attr_accessor :max_values

      # TODO: a method that resembles the code in the old text backend
      # to set errors according to a speficication (relative,
      # absolute, already max/min)

      # TODO: a dup !

      def initialize(values, min = nil, max = nil)
        @values = values
        @min_values = min
        @max_values = max
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
          w = Dobjects::Dvector.new(w.size) do |i|
            v[idx_vector[i]]
          end
          v.replace(w)
        end
      end

      # Whether there are error bars.
      def has_errors?
        return (@min_values && @max_values)
      end

      # Column names.
      def column_names(base)
        if has_errors?
          return [base, "#{base}min", "#{base}max"]
        else
          return [base]
        end
      end

      # Values, [value, min, max], at the given index. If #min and
      # #max are nil only [value] is returned
      def values_at(i)
        if has_errors?
          return [@values[i], @min_values[i], @max_values[i]]
        else
          return [@values[i]]
        end
      end

      # Returns the number of elements.
      def size
        return @values.size
      end

      ColumnSpecsRE = /|min|max/i

      # This function sets the value of the DataColumn object
      # according to a hash: _spec_ => _vector_.  _spec_ can be any of:
      # * 'value', 'values' or '' : the #values
      # * 'min' : #min
      # * 'max' : #max
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
      
      protected

      # All the vectors held by the DataColumn
      def all_vectors
        return [@values, @min_values, @max_values]
      end

    end

  end

end

