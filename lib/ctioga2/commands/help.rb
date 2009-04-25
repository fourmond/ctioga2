# help.rb: displaying the documentation of commands
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
require 'ctioga2/commands/parsers/command-line'

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Commands


    # The base of the 'self-documenting' stuff about commands.
    class Help

      # The commands Help should be working on
      attr_accessor :commands

      # The width of the long option column
      attr_accessor :options_column_width
      
      def initialize(commands)
        @commands = commands
        
        @options_column_width = 20
      end

      # Prints short help text suitable for a --help option about
      # available commands, by groups (ungrouped last).
      #
      # TODO: word splitting.
      def print_commandline_options
        cmds, groups = documented_commands
        for group in groups
          puts unless group == groups[0]
          puts (group && group.name) || "Ungrouped commands"
          for cmd in cmds[group].sort {|a,b|
              a.long_option <=> b.long_option
            }

            strings = cmd.option_strings
            puts "#{leading_spaces}%2s%1s %-#{@options_column_width}s%s" % 
              [ 
               strings[0], (strings[0] ? "," : " "),
               strings[1],
               if strings[1].size >= @options_column_width
                 "\n#{total_leading_spaces}#{strings[2]}"
               else
                 strings[2]
               end
              ]
            if cmd.optional_arguments and cmd.optional_arguments.size > 0
              puts "#{total_leading_spaces}  options: %s" %
                cmd.optional_arguments.keys.sort.map {|x| "/#{x}"}.join(' ')
            end
          end
        end

      end

      # TODO: documentation inaccurate.
      # Returns a Hash of all commands and an ordered list of
      # CommandGroup that should be documented.
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
        groups.delete_if {|g| g.blacklisted }
        return [cmds, groups]
      end


      protected

      # Leading spaces to align a string with the other option texts
      def total_leading_spaces
        return "#{leading_spaces}#{" " *(@options_column_width + 4)}"
        # 4: '-o, '
      end

      # Spaces before any 'short' option appears
      def leading_spaces
        return "    "
      end
      
      # Groups Command by CommandGroup, _nil_ being a proper value,
      # and return the corresponding hash.
      def group_commands
        ret_val = {}
        for cmd in @commands
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

