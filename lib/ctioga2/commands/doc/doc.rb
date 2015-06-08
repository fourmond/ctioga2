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
require 'ctioga2/commands/doc/markup'

module CTioga2

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

        # The hash containing all the types, as returned
        # by Interpreter::commands.
        attr_accessor :types

        # The hash containing all the backends, as returned by
        # Data::Backends::Backend::list_backends
        attr_accessor :backends

        # Wether or not to ignore blacklisted commands
        attr_accessor :ignore_blacklisted

        # The functions
        attr_accessor :functions

        # Create a Doc object caring about the current state of
        # registered commands and such.
        def initialize
          @commands = Interpreter::commands
          @groups = Interpreter::groups
          @types = Interpreter::types
          @backends = Data::Backends::Backend::list_backends
          @functions = Function::functions

          @ignore_blacklisted = ! (ENV.key?("CT2_DEV") && 
                                   ! ENV["CT2_DEV"].empty?)
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
              if a.priority == b.priority
                a.name <=> b.name
              else
                a.priority <=> b.priority
              end
            end
          end
          if @ignore_blacklisted
            groups.delete_if {|g| g && g.blacklisted }
          end
          return [cmds, groups]
        end

        # Display command-line help.
        def display_command_line_help(options)
          CommandLineHelp.new(options).
            print_commandline_options(*self.documented_commands)
        end

        # Displays help on a given command
        def display_help_on(cmd, options)
          if ! cmd.is_a? Command
            cd = Interpreter::commands[cmd]
            raise "Unkown command '#{cmd}'" unless cd
            cmd = cd
          end
          puts text_doc(cmd)
        end

        # Returns a string that represents a plain text documentation
        def text_doc(cmd, options = {})

          size ||= 80

          str = "Synopsis: "
          str << cmd.name
          for arg in cmd.arguments
            str << " #{arg.type.name}"
          end

          os = ""
          for k,v in cmd.optional_arguments
            os << " /#{k}=#{v.type.name}"
          end
          s2 = WordWrapper.wrap(os, size-4) # 4 for the spaces
          str << "\nOptions: #{s2.join("\n    ")}"
          shrt = MarkedUpText.new(self, cmd.short_description).to_s
          mup = MarkedUpText.new(self, cmd.long_description).to_s
          s2 = WordWrapper.wrap(mup.to_s, size)
          return "#{cmd.name} -- #{shrt}\n#{str}\n#{s2.join("\n")}"
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

