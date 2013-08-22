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
require 'ctioga2/commands/doc/wordwrap'

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Commands

    module Documentation

      # Displays help about command-line options and such.
      class CommandLineHelp

        # How much space to leave for the options ?
        attr_accessor :options_column_width

        # How many columns do we have at all ?
        attr_accessor :total_width

        # Whether output has (moderate) terminal capabilities
        attr_accessor :to_tty

        # Whether we should send output to pager if output has
        # terminal support.
        attr_accessor :to_pager

        # Styles, ie a hash 'object' (option, argument...) => ANSI
        # color code.
        attr_accessor :styles

        # Color output ?
        attr_accessor :color

        # The default value for the #styles attribute.
        DefaultStyles = {
          'switch' => "01",
          'title' => "01;04",
          'arguments' => '32',
          'options' => '34'
        }

        # Creates an object to display command-line help. Available
        # values for the options are given by the hash
        # CommandLineHelpOptions. Their meaning is:
        # 
        # * 'pager': disables or enables the use of a pager when
        #   sending output to a terminal
        def initialize(options)
          @options_column_width = 20
          @to_pager = if options.key? 'pager'
                        options['pager']
                      else
                        true
                      end

          @styles = DefaultStyles.dup
          @color = true
        end

        # Prints short help text suitable for a --help option about
        # available commands, by groups (ungrouped last). It takes a
        # list of all commands (_cmds_) and the list of _groups_ to
        # display.
        # 
        # \todo maybe the part about sending to the pager should be
        # factorized into a neat utility class ?
        def print_commandline_options(cmds, groups)
          @to_tty = false
          if STDOUT.tty? 
            begin
              require 'curses'
              Curses.init_screen
              @total_width = Curses.cols
              Curses.close_screen
              @to_tty = true
            rescue
            end
          end
          @total_width ||= 80   # 80 by default

          # Disable color output if not a to a terminal
          if ! @to_tty
            @color = false
          end

          if @to_tty and @to_pager
            # We pass -R as default value...
            ENV['LESS'] = 'R'
            output = IO::popen("pager", "w")
            pager = true
          else
            output = $stdout
            pager = false
          end
          
          for group in groups
            output.puts unless group == groups[0]
            name = (group && group.name) || "Ungrouped commands"
            if group && group.blacklisted 
              name << " (blacklisted)"
            end
            output.puts style(name, 'title')
            for cmd in cmds[group].sort {|a,b|
                a.long_option <=> b.long_option
              }

              output.puts format_one_entry(cmd)
            end
          end
          output.close
        end

        protected

        # Formats one entry of the commands
        def format_one_entry(cmd)
          sh, long, desc = cmd.option_strings
          
          str = "#{leading_spaces}%2s%1s %-#{@options_column_width}s" % 
            [ sh, (sh ? "," : " "), long]

          size = @total_width - total_leading_spaces.size

          # Do the coloring: we need to parse option string first
          if str =~ /(.*--\S+)(.*)/
            switch = $1
            args = $2
            str = "#{style(switch,'switch')}#{style(args,'arguments')}"
          end
          
          # Now, add the description.
          desc_lines = WordWrapper.wrap(desc, size)
          if long.size >= @options_column_width
            str += "\n#{total_leading_spaces}"
          end
          str += desc_lines.join("\n#{total_leading_spaces}")

          if cmd.has_options?
            op_start = '  options: '
            options = cmd.optional_arguments.
              keys.sort.map { |x| "/#{cmd.normalize_option_name(x)}"}.join(' ') 
            opts_lines = WordWrapper.wrap(options, size - op_start.size)
            str += "\n#{total_leading_spaces}#{style(op_start,'switch')}" + 
              style(opts_lines.join("\n#{total_leading_spaces}#{' ' * op_start.size}"), 'options')
          end
          return str
        end

        # Leading spaces to align a string with the other option texts
        def total_leading_spaces
          return "#{leading_spaces}#{" " *(@options_column_width + 4)}"
          # 4: '-o, '
        end

        # Spaces before any 'short' option appears
        def leading_spaces
          return "    "
        end

        # Colorizes some text with the given ANSI code.
        #
        # Word wrapping should be used *before*, as it will not work
        # after.
        def colorize(str, code)
          # We split into lines, as I'm unsure color status is kept
          # across lines
          return str.split("\n").map {|s|
            "\e[#{code}m#{s}\e[0m"
          }.join("\n")
        end

        # Changes the style of the object.
        def style(str, what)
          if ! @color
            return str
          end
          if @styles[what]
            return colorize(str, @styles[what])
          else
            return str
          end
        end

      end

    end

  end

end
