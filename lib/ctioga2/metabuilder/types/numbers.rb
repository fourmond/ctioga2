# numbers.rb : Different Types to deal with numbers
# Copyright (C) 2006 Vincent Fourmond
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA


require 'ctioga2/utils'

module CTioga2

  Version::register_svn_info('$Revision: 945 $', '$Date: 2009-04-12 01:03:50 +0200 (Sun, 12 Apr 2009) $')

  module MetaBuilder

    # The module Types should be used for all subclasses of
    # Type, to keep the place clean and tidy.
    module Types

      # An integer
      class IntegerParameter < Type

        type_name :integer, 'number', 0

        def string_to_type_internal(str)
          return Integer(str)
        end

      end

      # A float
      class FloatParameter < Type

        type_name :float, 'number', 0.0

        def string_to_type_internal(str)
          return Float(str)
        end

      end

      # A Float Range.
      class FloatRangeParameter < Type

        RANGE_RE = /([^:]+):([^:]+)/

        type_name :float_range, 'range'
        
        def string_to_type_internal(str)
          raise IncorrectInput, "#{str} is not a valid range" unless 
            str =~ RANGE_RE
          s,e = Float($1), Float($2)
          return Range.new(s,e)
        end

        def type_to_string_internal(value)
          return "#{value.first.to_s}:#{value.last.to_s}"
        end
        
      end

      # Returns a [ start, end ] array where elements are either Float
      # or _nil_.
      class PartialFloatRangeType < Type

        RANGE_RE = /([^:]+)?:([^:]+)?/

        type_name :partial_float_range, 'range'
        
        def string_to_type_internal(str)
          raise IncorrectInput, "#{str} is not a valid range" unless 
            str =~ RANGE_RE
          s,e = ($1 ? Float($1) : nil), ($2 ? Float($2) : nil)
          return [s, e]
        end

        def type_to_string_internal(value)
          return "#{value.first.to_s}:#{value.last.to_s}"
        end
        
      end

    end

  end
end
