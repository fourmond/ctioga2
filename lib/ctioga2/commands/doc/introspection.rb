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

  module Commands

    module Documentation

      # This class provides facilities to display information
      class Introspection
        
        # Display all known commands, along with their definition place
        def list_commands(format = :pretty)
          cmds = Interpreter::commands
          names = cmds.keys.sort
          case format
          when :list
            puts names
          when :yaml
            require 'yaml'
            commands = {}
            for n in names
              cmd = cmds[n]
              command = {}
              command['name'] = n
              f,l = cmd.context
              command['file'] = f
              command['line'] = l.to_i
              command['long_option'] = cmd.long_option
              command['short_option'] = cmd.short_option
              command['short_description'] = cmd.short_description
              command['long_description'] = cmd.long_description
              commands[n] = command
            end
            puts YAML.dump(commands)
          when :spec
            for n in names
              cmd = cmds[n]
              puts "#{n}:"
              for a in cmd.arguments
                puts " - #{a.type.name}"
              end

              opts = cmd.optional_arguments.keys.sort
              for on in opts
                opt = cmd.optional_arguments[on]
                puts " * /#{on}=#{opt.type.name}"
              end
            end
          else
            puts "Known commands:" 
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
        def edit_command(cmd, doc)
          cmd = Interpreter::command(cmd)
          if cmd
            cntx = doc ? cmd.documentation_context : cmd.context
            edit_file(*cntx)
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

        # Lists all the stylistic things, and in particular the names
        # of color sets, marker sets and the like.
        #
        # This function will hold more data with time.
        def list_styles

          puts "Available color sets:"
          sets = Graphics::Styles::CurveStyleFactory::parameters['line_color'].sets
          set_names = sets.keys.sort

          sets_by_prefix = Utils.group_by_prefix(set_names, /(.*?)\d+$/)


          for pref in sets_by_prefix.keys.sort
            vals = Utils.suffix_numeric_sort(sets_by_prefix[pref])
            puts " * #{vals.join(", ")} "
          end

          puts "\nAvailable marker sets:"
          sets = Graphics::Styles::CurveStyleFactory::parameters['marker_marker'].sets
          set_names = sets.keys.sort

          sets_by_prefix = Utils.group_by_prefix(set_names, /(.*?)\d+$/)
          for pref in sets_by_prefix.keys.sort
            vals = Utils.suffix_numeric_sort(sets_by_prefix[pref])
            puts " * #{vals.join(", ")} "
          end

          puts "\nAvailable line style sets:"
          sets = Graphics::Styles::CurveStyleFactory::parameters['line_style'].sets
          set_names = sets.keys.sort

          sets_by_prefix = Utils.group_by_prefix(set_names, /(.*?)\d+$/)
          for pref in sets_by_prefix.keys.sort
            vals = Utils.suffix_numeric_sort(sets_by_prefix[pref])
            puts " * #{vals.join(", ")} "
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

      InternalFormatRE = {
        /list|raw/i => :list,
        /default|pretty/i => :pretty,
        /spec/i => :spec,
        /yaml/i => :yaml
      }
      
      
      InternalFormatType = CmdType.new('internal-format',
                                       { :type => :re_list,
                                         :list => InternalFormatRE}, <<EOD)
Output format for internals.
EOD


      IntrospectionGroup = 
        CmdGroup.new('introspection', "Introspection",
                     <<EOD, 100)
Commands displaying information about the internals of ctioga2, such 
as known types/commands/backends...
EOD

      TypeOption = {'format' => CmdArg.new('internal-format')}
      RawOption = {'raw' => CmdArg.new('boolean')}

      ListCommandsCmd = 
        Cmd.new('list-commands', nil, '--list-commands',
                [], RawOption.dup.update(TypeOption)) do |p, opts|
        opts['format'] = :list if opts['raw']
        
        Introspection.new.list_commands(opts['format'])
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

      ListStylesCmd = 
        Cmd.new('list-styles', nil, '--list-styles',
                [], RawOption) do |p, opts|
        Introspection.new.list_styles()
      end

      ListStylesCmd.describe("List stylistic information",
                             <<EOH, IntrospectionGroup)
Lists all available color sets, marker sets and the like.
EOH

      EditCommandCmd = 
        Cmd.new('edit-command', nil, '--edit-command',
                [ CmdArg.new('text')], 
                {'doc' => CmdArg.new('boolean')}) do |plotmaker, cmd, opts|
        Introspection.new.edit_command(cmd, opts['doc'])
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

