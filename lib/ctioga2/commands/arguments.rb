# commands.rb: implementation of command-driven approach
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

    # An argument to a Command
    class CommandArgument

      # The type of the argument, a CTioga2::MetaBuilder::Type object.
      attr_accessor :type

      # The name of the argument. Uniquely for display in the help
      # documentation.
      attr_accessor :name

      # A small description of the argument
      attr_accessor :description

      # _type_ is the type of the argument in a descriptive fashion,
      # as could be fed to CTioga2::MetaBuilder::Type.get_type, or
      # directly a MetaBuilder::Type object.
      def initialize(type, name = nil, desc = nil)
        if type.is_a? MetaBuilder::Type
          @type = type
        else
          @type = CTioga2::MetaBuilder::Type.get_type(type)
        end
        @name = name || @type.type_name
        @description = desc
      end
      
      # Returns a name suitable for display in a documentation, such
      # as the command-line help.
      def displayed_name
        if @name
          return @name
        else
          @type.type_name
        end
      end

    end

  end

end

