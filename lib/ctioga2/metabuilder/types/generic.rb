# generic.rb: conversion-function based type (or the Death of MetaBuilder)
# you can choose among several possibilities
# Copyright (C) 2010 Vincent Fourmond
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

  Version::register_svn_info('$Revision$', '$Date$')


  module MetaBuilder

    module Types

      # A type based on a conversion function from_text from a given
      # class/module.
      class FunctionBasedType < Type

        type_name :function_based
        
        def type_name
          return 'function_based'
        end


        def initialize(type)
          super
          raise "type must have a :class key" unless type.has_key?(:class)
          # We make a copy for our own purposes.
          @cls = type[:class]
          @func_name = type[:func_name] || :from_text
        end

        def string_to_type_internal(str)
          return @cls.send(@func_name, str)
        end

        def type_to_string_internal(val)
          return val.to_s
        end
      end

    end
  end
end
