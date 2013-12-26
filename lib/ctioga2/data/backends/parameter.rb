# parameter.rb : A class to describe a parameter
# Copyright (C) 2006 Vincent Fourmond
 
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

require 'ctioga2/metabuilder/type'

module CTioga2

  module Data

    module Backends

      # A parameter describes a way of storing some information into an
      # instance of an object. No type checking is done on the target object
      # when the actual reading/writing is done. However, the type checking
      # is done upstream by the Description system.
      #
      # A Parameter consists of several things:
      #
      # * a #name, to identify it in a unique fashion;
      # * a #type, used to convert to and from String and for user
      #   interaction in general;
      # * some explanative text, used to inform the user: #long_name and
      #   #description
      # * two symbols that are used to gain read and write access of the
      #   parameter on the target object.
      #
      # The Parameter class can be used to maintain a set of
      # meta-informations about types in a given object.
      class Parameter 
        
        # The short name of the parameter
        attr_accessor :name
        
        # The long name of the parameter, to be translated
        attr_accessor :long_name
        
        # The function names that should be used to set the symbol and
        # retrieve it's current value. The corresponding functions should
        # read or return a string, and writer(reader) should be a noop.
        attr_accessor :reader_symbol, :writer_symbol
        
        # The (text) description of the parameter
        attr_accessor :description
        
        # The actual Commands::CommandType of the parameter
        attr_accessor :type

        # Creates a new Parameter with the given symbols. Remember that
        # if you don't intend to use #get, #get_raw, #set and #set_raw,
        # you don't need to pass meaningful values to _writer_symbol_ and
        # _reader_symbol_. 
        def initialize(name, writer_symbol,
                       reader_symbol,
                       long_name, type,
                       description)
          @name = name
          @writer_symbol = writer_symbol
          @reader_symbol = reader_symbol
          @description = description
          @long_name = long_name
          @type = Commands::CommandType::get_type(type)
        end


        # Sets directly the target parameter, without type conversion
        def set_value(target, val)
          target.send(@writer_symbol, val) 
        end
        
        # Uses the #writer_symbol of the _target_ to set the value of the
        # parameter to the one converted from the String _str_
        def set_from_string(target, str)
          set_value(target, string_to_type(str)) 
        end
        

        # Aquires the value from the backend, and returns it in the
        # form of a string
        def get_string(target)
          return type_to_string(get_value(target))
        end

        # Aquires the value from the backend, and returns it.
        def get_value(target)
          target.send(@reader_symbol)
        end

      end
    end
  end
end
