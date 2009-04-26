# groups.rb: a group of commands
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

    # A group of commands, organized along a same theme.
    class CommandGroup

      # The commands belonging to the group
      attr_accessor :commands

      # The name of the group
      attr_accessor :name

      # A short, unique, codelike name for the group.
      attr_accessor :id

      # A (longer) description of the group
      attr_accessor :description

      # The priority of the group. It influences the positioning of
      # its command-line options in the --help display. Lower
      # priorities come first.
      attr_accessor :priority

      # Whether the group is blacklisted or not, ie whether the group's
      # help text will be displayed at all. 
      attr_accessor :blacklisted

      # The context of definition (file, line...)
      attr_accessor :context
      
      def initialize(id, name, desc = nil, priority = 0, blacklist = false,
                     register = true)
        @commands = []
        @name = name
        @id = id
        @description = desc || name
        @priority = priority
        @blacklisted = blacklist

        if register 
          Interpreter.register_group(self)
        end

        # The context in which the group was defined
        @context = caller[1].gsub(/.*\/ctioga2\//, 'lib/ctioga2/')
      end
      
    end

  end

end

