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

  Version::register_svn_info('$Revision: 900 $', '$Date: 2009-03-01 15:10:29 +0100 (Sun, 01 Mar 2009) $')

  module Commands

    # A group of commands, organized along a same theme.
    class CommandGroup

      # The commands belonging to the group
      attr_accessor :commands

      # The name of the group
      attr_accessor :name

      # A (longer) description of the group
      attr_accessor :description

      # The priority of the group. It influences the positioning
      # of its command-line options in the --help display. Lower
      # priorities come first.
      attr_accessor :priority

      # Whether the group is blacklisted or not, ie whether the group's
      # help text will be displayed at all. 
      attr_accessor :blacklisted
      
      def initialize(name, desc = nil, priority = 0, blacklist = false,
                     register = true)
        @commands = []
        @name = name
        @description = desc || name
        @priority = priority
        @blacklisted = blacklist

        if register 
          Interpreter.register_group(self)
        end
      end
      
    end

  end

end

