# arguments.rb: arguments to commands
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
require 'ctioga2/commands/type'

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Commands

    # An argument to a Command
    #
    # @todo There should be real options mangling capacities, with:
    # * (possibly deprecated) aliases for options
    # * _ to - mangling
    # * other things ?
    class CommandArgument

      # The type of the argument, a CommandType object.
      attr_accessor :type

      # The name of the argument. Uniquely for display in the help
      # documentation.
      attr_accessor :name

      # A small description of the argument
      attr_accessor :description

      # The target for the option, in case it is different from its
      # name
      attr_accessor :option_target

      # Whether or not the option is deprecated.
      #
      # If evaluates as true and different from _true_, is converted
      # into a string used as an explanation to the user
      attr_accessor :option_deprecated

      # _type_ is a named CommandType
      def initialize(type, name = nil, desc = nil)
        @type = CommandType.get_type(type)
        @name = name
        @description = desc

        @option_target = nil
        @option_deprecated = false
      end
      
      # Returns a name suitable for display in a documentation, such
      # as the command-line help.
      def displayed_name
        if @name
          return @name
        else
          return @type.name
        end
      end

    end

  end

end

