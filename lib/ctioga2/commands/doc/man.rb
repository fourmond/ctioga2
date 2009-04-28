# man.rb: conversion of the internal help into a hand-modifiable manual page.
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
require 'ctioga2/log'
require 'ctioga2/commands/commands'
require 'ctioga2/commands/parsers/command-line'

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Commands

    module Documentation

      # Converts help texts found in the Command descriptions into a
      # manual page that can be further edited and *updated* using this
      # module.
      class Man

        include Log

        # The Doc object Help2Man should be working on.
        attr_accessor :doc

        def initialize(doc)
          @doc = doc
        end

        RoffCommentRE = /\.\s*\\"/

        # Writes a manual page to the given _io_ stream, using _version_
        # as the target version (the one ending up in the headers).
        #
        # NO... We should *input* a manual page, and spit out
        # replacement texts.
        def write_manual_page(version, input, out = STDOUT)
          passed_header = false
          if input.is_a? String
            filename = input
            input = File::open(input)
          elsif input.respond_to? :path
            filename = input.path
          else
            filename = "unkown"
          end

          @cmds, @groups = @doc.documented_commands
          @cmd_exclude = {}
          @group_exclude = {}

          while line = input.gets
            case line
            when /^#{RoffCommentRE}\s*write-header\s*$/
              out.puts header_string(version, filename)
              passed_header = true
            when /^#{RoffCommentRE}\s*write-commands\s*$/
              write_commands(out)
            when /^#{RoffCommentRE}\s*write-group:\s*(.*)\s*$/
              id = $1
              if @groups[id]
                write_group(out, g)
              else
                warn "Unkown group: #{id}"
              end
            else
              if passed_header
                out.puts line
              end
            end
          end
          out.close
          input.close
        end

        protected

        # Writes out all commands to _out_.
        def write_commands(out)
          for group in @groups
            next if @group_exclude[group]
            write_group(out, group)
          end
        end

        # Writes out a single _group_ 
        def write_group(out, group)
          write_group_name(out, group)
          write_group_commands(out, group)
        end

        # Writes out a single _group_ 
        def write_group_name(out, group)
          out.puts 
          out.puts ".SS #{group.name}"
          out.puts 
        end

        # Writes the remaining commands of a group
        def write_group_commands(out, group)
          first = true
          for cmd in @cmds[group].sort {|a,b|
              a.long_option <=> b.long_option
            }
            next if @cmd_exclude[cmd]
            out.puts
            if first
              out.puts ".TP 8"    # This isn't correct in the case when
              # commands have already been written out.
              first = false
            else
              out.puts ".TP"
            end
            write_command(out, cmd)
          end
          # Now blacklist the group
          @group_exclude[group] = true
        end

        def write_command(out, cmd)
          write_command_signature(out, cmd)
          write_command_description(out, cmd)
          out.puts ".br"
          write_command_options(out, cmd)
          out.puts ".br"
          write_corresponding_command(out, cmd)
        end

        # Writes a signature (ie the option specification) for the
        # command
        def write_command_signature(out, cmd)
          short, long, dummy = cmd.option_strings
          long, *args = long.split(/\s+/)
          args = " \\fI#{args.join(' ')}\\fR"
          out.puts ".B %s%s%s%s" % [ short, (short ? ", " : ""), long, args ]
          # Blacklist commands whose signature we wrote.
          @cmd_exclude[cmd] = true
        end


        # Returns the description for the command
        def write_command_description(out, cmd)
          out.puts cmd.long_description.gsub(/\s+$/,'')
        end

        # Displays the optional arguments for the given command
        def write_command_options(out, cmd)
          if cmd.optional_arguments and cmd.optional_arguments.size > 0
            # .map {|x| "/#{x}="} ??? Does not seem to help much
            options = cmd.optional_arguments.keys.sort.join(' ')
            out.puts ".B Optional arguments:\n.I #{options}"
          end
        end

        # Displays the corresponding 'file' command
        def write_corresponding_command(out, cmd)
          arguments = cmd.arguments.map {|a| a.displayed_name}.join(',')
          if cmd.optional_arguments and cmd.optional_arguments.size > 0
            arguments += ",option=..." 
          end
          out.puts ".B Corresponding command:\n.I #{cmd.name}(#{arguments})"
        end


        # Returns the header string
        def header_string(version, file)
          return ManualPageHeader % [ file, 
                                      CTioga2::Version::last_modified_date, 
                                      version ]
        end

        ManualPageHeader = <<'EOF'
.\" This is the manual page for ctioga2
.\"
.\" Copyright 2009 by Vincent Fourmond
.\"
.\" This file is generated from the ctioga2 code and from the file %s
.\"
.\" This program is free software; you can redistribute it and/or modify
.\" it under the terms of the GNU General Public License as published by
.\" the Free Software Foundation; either version 2 of the License, or
.\" (at your option) any later version.
.\"  
.\" This program is distributed in the hope that it will be useful,
.\" but WITHOUT ANY WARRANTY; without even the implied warranty of
.\" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
.\" GNU General Public License for more details (in the COPYING file).
.\"
.TH CTIOGA2 1 "%s" "Version %s" "Command-line interface for Tioga"
EOF

      end
    end

  end
end
