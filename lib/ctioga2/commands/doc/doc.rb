# doc.rb: a class holding all informations
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
require 'ctioga2/commands/commands'
require 'ctioga2/commands/doc/help'

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Commands

    # The base of the 'self-documentation' of CTioga2
    module Documentation

      # The base class for all documentation.
      class Doc
        
        # The hash containing all the commands, as returned
        # by Interpreter::commands.
        attr_accessor :commands

        # The hash containing all the groups, as returned
        # by Interpreter::commands.
        attr_accessor :groups

        # Wether or not to ignore blacklisted commands
        attr_accessor :ignore_blacklisted

        # The CommandLineHelp object in charge of displaying
        # information about command-line
        attr_accessor :command_line_help


        # Create a Doc object caring about the current state of
        # registered commands and such.
        def initialize
          @commands = Interpreter::commands
          @groups = Interpreter::groups

          @ignore_blacklisted = ! (ENV.key?("CT2_DEV") && 
                                   ! ENV["CT2_DEV"].empty?)

          @command_line_help = CommandLineHelp.new
        end

        # Returns a [ cmds, groups ] hash containing the list of
        # commands, and the groups to be documented.
        def documented_commands
          cmds = group_commands

          groups = cmds.keys.sort do |a,b|
            if ! a
              1
            elsif ! b
              -1
            else
              a.priority <=> b.priority
            end
          end
          if @ignore_blacklisted
            groups.delete_if {|g| g.blacklisted }
          end
          return [cmds, groups]
        end

        # Display command-line help.
        def display_command_line_help
          @command_line_help.
            print_commandline_options(*self.documented_commands)
        end

        protected 


        # Groups Command by CommandGroup, _nil_ being a proper value,
        # and return the corresponding hash.
        def group_commands
          ret_val = {}
          for name, cmd in @commands
            group = cmd.group
            if ret_val.key?(group)
              ret_val[group] << cmd
            else
              ret_val[group] = [cmd]
            end
          end
          
          return ret_val
        end

      end
    end
  end
end

