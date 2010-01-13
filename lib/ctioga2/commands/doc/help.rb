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

    module Documentation

      # Displays help about command-line options and such.
      class CommandLineHelp

        # How much space to leave for the options ?
        attr_accessor :options_column_width

        def initialize
          @options_column_width = 20
        end

        # Prints short help text suitable for a --help option about
        # available commands, by groups (ungrouped last). It takes a
        # list of all commands (_cmds_) and the list of _groups_ to
        # display.
        #
        # \todo word splitting.
        #
        # \todo why not try color, too ;-) ??? (but probably in a
        # derived class ?).
        def print_commandline_options(cmds, groups)
          for group in groups
            puts unless group == groups[0]
            name = (group && group.name) || "Ungrouped commands"
            if group && group.blacklisted 
              name << " (blacklisted)"
            end
            puts name
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
              if cmd.has_options?
                puts "#{total_leading_spaces}  options: %s" %
                  cmd.optional_arguments.keys.sort.map {|x| "/#{x}"}.join(' ')
              end
            end
          end

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
        
      end

    end

  end

end
