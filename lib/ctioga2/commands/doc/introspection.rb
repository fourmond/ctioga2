# introspection.rb: get informations about what is known to ctioga2
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

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Commands

    # The base of the 'self-documentation' of CTioga2
    module Documentation

      # This class provides facilities to display information
      class Introspection
        
        # Display all known commands, along with their definition place
        def list_commands(raw = false)
          puts "Known commands:" unless raw
          cmds = Interpreter::commands
          names = cmds.keys.sort
          if raw
            puts names
          else
            max = names.inject(0) {|m,x| [m,x.size].max}
            max2 = names.inject(0) {|m,x| [m,cmds[x].long_option.size].max}
            for n in names
              f,l = cmds[n].context
              puts "\t%-#{max}s\t--%-#{max2}s\t(#{f}: #{l})" % 
                [n, cmds[n].long_option ]
            end
          end
        end

        # List known groups
        def list_groups(raw = false)
          puts "Known groups:" unless raw
          groups = Interpreter::groups
          names = groups.keys.sort
          if raw
            puts names
          else
            for n in names
              f,l = groups[n].context
              puts "\t#{n}\t(#{f}: #{l})"
            end
          end
        end

        # List known types
        def list_types(raw = false)
          puts "Known types:" unless raw
          types = Interpreter::types
          names = types.keys.sort
          if raw
            puts names
          else
            for n in names
              f,l = types[n].context
              puts "\t#{n}\t(#{f}: #{l})"
            end
          end
        end

        # Lauches an editor to edit the given command:
        def edit_command(cmd)
          cmd = Interpreter::command(cmd)
          if cmd
            edit_file(*cmd.context)
          end
        end

        # Lauches an editor to edit the given command:
        def edit_group(group)
          group = Interpreter::group(group)
          if group
            edit_file(*group.context)
          end
        end

        # Lauches an editor to edit the given command:
        def edit_type(type)
          type = Interpreter::type(type)
          if type
            edit_file(*type.context)
          end
        end


        protected 

        # Launches an editor to edit the given file at the given place.
        def edit_file(file, line)
          editor = ENV['EDITOR'] || 'emacs'
          if ENV['CT2_DEV_HOME']
            file = "#{ENV['CT2_DEV_HOME']}/#{file}"
          end
          system("#{editor} +#{line} #{file} &")
        end

      end

      IntrospectionGroup = 
        CmdGroup.new('introspection', "Introspection",
                     "Displays information about the internals of ctioga2",
                     100, true)

      RawOption = {'raw' => CmdArg.new('boolean')}

      ListCommandsCmd = 
        Cmd.new('list-commands', nil, '--list-commands',
                [], RawOption) do |p, opts|
        Introspection.new.list_commands(opts['raw'])
      end

      ListCommandsCmd.describe("List known commands",
                               <<EOH, IntrospectionGroup)
List all commands known to ctioga2
EOH

      ListGroupsCmd = 
        Cmd.new('list-groups', nil, '--list-groups',
                [], RawOption) do |p, opts|
        Introspection.new.list_groups(opts['raw'])
      end

      ListGroupsCmd.describe("List known groups",
                             <<EOH, IntrospectionGroup)
List all command groups known to ctioga2
EOH

      ListTypesCmd = 
        Cmd.new('list-types', nil, '--list-types',
                [], RawOption) do |p, opts|
        Introspection.new.list_types(opts['raw'])
      end

      ListTypesCmd.describe("List known types",
                             <<EOH, IntrospectionGroup)
List all types known to ctioga2
EOH

      EditCommandCmd = 
        Cmd.new('edit-command', nil, '--edit-command',
                [ CmdArg.new('text')]) do |plotmaker, cmd|
        Introspection.new.edit_command(cmd)
      end

      EditCommandCmd.describe("Edit the command",
                               <<EOH, IntrospectionGroup)
Edit the given command in an editor. It will only work from the 
top directory of a ctioga2 source tree.
EOH

      EditGroupCmd = 
        Cmd.new('edit-group', nil, '--edit-group',
                [ CmdArg.new('text')]) do |plotmaker, cmd|
        Introspection.new.edit_group(cmd)
      end

      EditGroupCmd.describe("Edit the group",
                            <<EOH, IntrospectionGroup)
Edit the given group in an editor. It will only work from the 
top directory of a ctioga2 source tree.
EOH

      EditTypeCmd = 
        Cmd.new('edit-type', nil, '--edit-type',
                [ CmdArg.new('text')]) do |plotmaker, cmd|
        Introspection.new.edit_type(cmd)
      end

      EditTypeCmd.describe("Edit the type",
                            <<EOH, IntrospectionGroup)
Edit the given type in an editor. It will only work from the 
top directory of a ctioga2 source tree.
EOH

      VersionRawCmd = 
        Cmd.new('version-raw', nil, '--version-raw',
                [ ]) do |plotmaker|
        print Version::version
      end

      VersionRawCmd.describe("Raw version",
                             <<EOH, IntrospectionGroup)
Prints the raw version number, without any other decoration and 
newline.
EOH

      

    end

  end


end

