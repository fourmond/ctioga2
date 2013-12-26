# lists.rb : Different Types to deal with types where
# you can choose among several possibilities
# Copyright (C) 2006, 2009 Vincent Fourmond
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

  module MetaBuilder

    # The module Types should be used for all subclasses of
    # Type, to keep the place clean and tidy.
    module Types

      # A regular expression matching true
      TRUE_RE = /^\s*(true|yes|on)\s*$/i

      # A regular expression matching false
      FALSE_RE = /^\s*(false|no(ne)?|off)\s*$/i


      # A boolean parameter
      class BooleanParameter < Type

        type_name :boolean
        
        def type_name
          return 'bool'
        end

        # Yes, this *really* is a boolean !
        def boolean?
          return true
        end
        
        def string_to_type_internal(str)
          if str == true or str =~ TRUE_RE
            return true
          else
            return false
          end
        end

        def type_to_string_internal(val)
          if val
            return "true"
          else
            return "false"
          end
        end

        # Booleans are a special case for option parser, as they
        # are handled completely differently
        def option_parser_long_option(name, biniou = nil)
          return "--[no-]#{name}"
        end
      end

      # A list of symbols. A hash :list must be provided that states
      # the correspondance between the legal symbols that can be
      # accepted by this parameter and their "english" name.
      # This parameter can typically be used to prompt the user
      # for different choices.
      class ListParameter < Type

        type_name :list

        def initialize(type)
          super
          raise "type must have a :list key" unless type.has_key?(:list)
          # We make a copy for our own purposes.
          @hash = type[:list].dup
        end
        
        def type_name
          return 'list'
        end
        
        def string_to_type_internal(str)
          if @hash.has_key?(str.to_sym)
            return str.to_sym
          else
            raise IncorrectInput, "Invalid input: '#{str}' should be one of " +
              @hash.keys.map {|s| s.to_s}.join(',')
          end
        end

        def type_to_string_internal(val)
          return val.to_s
        end
      end


      # A choice between different symbols based on regular expressions.
      class REListParameter < Type

        type_name :re_list

        def initialize(type)
          super
          raise "type must have a :list key" unless type.has_key?(:list)
          # We make a copy for our own purposes.
          @re_hash = type[:list].dup
        end
        
        def type_name
          return 'relist'
        end
        
        def string_to_type_internal(str)
          for k,v in @re_hash
            if str =~ /^\s*#{k}\s*$/
              return v
            end
          end
          raise IncorrectInput, "Invalid input: '#{str}' should match " +
            @re_hash.keys.map {|s| s.to_s}.join(',')
        end

        def type_to_string_internal(val)
          return val.to_s
        end
      end

      # An array of identical elements of type specified by :subtype. Defaults
      # to String
      class ArrayParameter < Type
        type_name :array

        def initialize(type)
          super
          # We make a copy for our own purposes.
          subtype = type[:subtype] || {:type => :string}
          @subtype = Type.get_type(subtype)
          @separator = type[:separator] || /\s*,\s*/
          @alternative_separator = type[:alternative_separator] || nil
          @separator_out = type[:separator_out] || ','
        end

        def type_name
          return 'array'
        end

        def string_to_type_internal(str)
          if @alternative_separator && str =~ @alternative_separator
            ary = str.split(@alternative_separator)
          else
            ary = str.split(@separator)
          end
          return ary.map do |a|
            @subtype.string_to_type(a)
          end
        end

        def type_to_string_internal(val)
          return val.map do |a|
            @subtype.type_to_string(a)
            # Won't alway work !
          end.join(@separator_out)
        end
      end

      # A Type used for sets for Graphics::Styles::CircularArray
      # objects.
      #
      # \todo write a gradient stuff !!!
      class SetParameter < ArrayParameter
        type_name :set

        def initialize(type)
          super
          @separator = /\s*\|\s*/
          @separator_out = '|'
        end

        def type_name
          return 'set'
        end

        def string_to_type_internal(str)
          multiply = nil
          if str =~ /(.*)\*\s*(\d+)\s*$/
            multiply = $2.to_i
            str = $1
          end
          if str =~ /^\s*gradient:(.+)--(.+),(\d+)\s*$/
            s,e,nb = $1, $2, $3.to_i
            s,e = @subtype.string_to_type(s),@subtype.string_to_type(e)
            fact = if nb > 1
                     1.0/(nb - 1)     # The famous off-by one...
                   else
                     warn { "Incorrect gradient number: '#{nb}'" }
                     1.0
                   end
            array = []
            nb.times do |i|
              array << Utils::mix_objects(e,s, i * fact)
            end
          elsif str =~ /(.*)!(\d+)(?:!(.*))?\s*$/
            # We have a mixing
            nb = $2.to_i
            fact = nb*0.01
            if fact > 1.0 || fact < 0.0
              error { "Invalid number for mixing: #{nb}, using 50"}
              fact = 0.5
            end
            st1 = $1
            st2 = $3 || 'White' # default to colors !

            ar1 = string_to_type(st1)
            ar2 = string_to_type(st2)
            
            # Make all the sequential combinations until we fall back
            # on the first one.
            ts = ar1.size.lcm(ar2.size)
            ar1 *= ts/ar1.size
            ar2 *= ts/ar2.size

            arf = []
            ar1.each_index do |i|
              arf << Utils::mix_objects(ar1[i], ar2[i], fact)
            end
            return arf
          else
            array = super
          end
          if multiply
            # Seems that I've finally managed to understand what zip
            # is useful for !
            array = array.zip(*([array]*(multiply-1))).flatten(1)
          end
          return array
        end

      end

    end
  end
end
