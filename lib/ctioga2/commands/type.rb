# type.rb: named types, based on metabuilder
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
require 'ctioga2/metabuilder/types'

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Commands

    # A named type, based on CTioga2::MetaBuilder::Type
    class CommandType

      # The underlying  CTioga2::MetaBuilder::Type object.
      attr_accessor :type

      # The unique identification of this type.
      attr_accessor :name

      # The description of this type
      attr_accessor :description

      # The context of definition [file, line]
      attr_accessor :context


      # Makes sure the return value is a CommandType. Will fail
      # miserably if not.
      def self.get_type(obj)
        if obj.is_a? CommandType
          return obj
        else 
          if obj.is_a? Symbol
            warn "Converting type specifcation #{obj.inspect} to string at #{caller[1]}"
            obj = obj.to_s
          end
          type = Interpreter::type(obj)
          if type
            return type
          else
            raise InvalidType, "Type #{obj.inspect} unknown"
          end
        end
      end

      # _type_ is the type of the argument in a descriptive fashion,
      # as could be fed to CTioga2::MetaBuilder::Type.get_type, or
      # directly a MetaBuilder::Type object.
      def initialize(name, type, desc = nil)
        if type.is_a? MetaBuilder::Type
          @type = type
        else
          @type = CTioga2::MetaBuilder::Type.get_type(type)
        end
        @name = name 
        @description = desc
        caller[1].gsub(/.*\/ctioga2\//, 'lib/ctioga2/') =~ /(.*):(\d+)/
        @context = [$1, $2.to_i]

        Interpreter::register_type(self)
      end
      
    end

  end

end

