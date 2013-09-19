# commands.rb: implementation of command-driven approach
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
require 'ctioga2/commands/arguments'
require 'ctioga2/commands/groups'

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Commands

    # An exception raised when the command is called with an insufficient
    # number of arguments.
    class ArgumentNumberMismatch < Exception
    end

    # An exception raised when an optional argument is encountered
    # that does not match an entry in Command#optional_arguments
    class CommandOptionUnkown < Exception
    end

    # One of the commands that can be used.
    #
    # \todo Write a Shortcut command that would simply be a shortcut
    # for other things. Possibly taking arguments ? It could take a
    # description, though that wouldn't be necessary.
    #
    # \todo Use this Shortcut to write DeprecatedShortcut for old
    # ctioga options.
    class Command

      # The name of the command, ie how to call it in a commands file
      attr_accessor :name

      # Its short command-line option, or _nil_ if none
      attr_accessor :short_option

      # Its long command-line option, or _nil_ if it should not be
      # called from the command-line (but you *really* don't want that).
      attr_accessor :long_option
      
      # The compulsory arguments it can take, in the form of an
      # array of CommandArgument
      attr_accessor :arguments

      # Optional arguments to a command, in the form of a Hash
      # 'option name' => CommandArgument
      attr_accessor :optional_arguments

      # A short one-line description of the command
      attr_accessor :short_description
      
      # A longer description. Typically input using a here-document.
      attr_accessor :long_description
      
      # The code that will be called. It must be a Proc object, or any
      # objects that answers a #call method.
      #
      # The corresponding block will be called with the following arguments:
      # * first, the PlotMaker instance where the command will be running
      # * second, as many arguments as there are #arguments.
      # * third, if #optional_arguments is non-empty, a hash
      #   containing the values of the optional arguments. It will be
      #   an empty hash if no optional arguments are given in the
      #   command). It *will* be empty if the command is called as
      #   an option in the command-line.
      #
      # *Few* *rules* *for* *writing* *the* *code*:
      # * code should avoid as much as possible to rely on closures.
      # * the CommandArgument framework will make sure the arguments
      #   are given with the appropriate type or raise an
      #   exception. Don't bother.
      attr_accessor :code

      # The CommandGroup to which the command belongs
      attr_accessor :group

      # The context of definition [file, line]
      attr_accessor :context

      # The context of the documentation
      attr_accessor :documentation_context

      def self.get_calling_context(id=2)
        caller[id].gsub(/.*\/ctioga2\//, 'lib/ctioga2/') =~ /(.*):(\d+)/
        return [$1, $2.to_i]
      end

      # Creates a Command, with all attributes set up. The code can be
      # set using #set_code.
      #
      # Single and double dashes are stripped from the beginning of the
      # short and long options respectively.
      def initialize(n, short, long, args = [], opts = {}, 
                     d_short = nil, d_long = nil, group = nil,
                     register = true, &code)
        @name = n
        @short_option = short && short.gsub(/^-/,'')
        @long_option = long && long.gsub(/^--/,'')
        @arguments = args
        @optional_arguments = opts
        if(@short_option and ! @long_option)
          raise "A long option must always be present if a short one is"
        end
        @code = code
        self.describe(d_short, d_long, group)

        @context = Command.get_calling_context

        # Registers automatically the command
        if register
          Commands::Interpreter.register_command(self)
        end

      end

      # Sets the code to the block given.
      def set_code(&code)
        @code = code
      end

      # Returns the number of compulsory arguments
      def argument_number
        return @arguments.size
      end

      # Sets the descriptions of the command. If the long description
      # is ommitted, the short is reused.
      def describe(short, long = nil, group = nil)
        @documentation_context = Command.get_calling_context(1)
        @short_description = short
        @long_description = long || short
        if(group)
          group = Interpreter::group(group) if group.is_a? String
          @group = group
          group.commands << self
        end
      end

      # Sets the long documentation of the given command
      def self.document_command(cmd, desc)
        tg = Commands::Interpreter.command(cmd)
        if tg
          tg.documentation_context = Command.get_calling_context(1)
          tg.long_description = desc
        end
      end

      # Returns a list of three strings:
      # * the short option
      # * the long option with arguments
      # * the description string
      #
      # Returns _nil_ if the long option is not defined.
      def option_strings
        if ! @long_option
          return nil
        end
        retval = []
        # Short option
        retval << ( @short_option ? "-#{@short_option}" : nil)
        # Long option + arguments
        if @arguments.size > 0
          retval << @arguments.first.type.
            option_parser_long_option(@long_option, 
                                      @arguments.first.displayed_name) + 
            if @arguments.size > 1
              " " + 
                @arguments[1..-1].map do |t|
              t.displayed_name.upcase
            end.join(" ")
            else
              ""
            end
        else
          retval << "--#{@long_option}"
        end
        retval << @short_description
        return retval
      end

      # Converts the Array of String given into an Array of the type
      # suitable for the #code of the Command. This deals only with
      # compulsory arguments. Returns the array.
      #
      # Any object which is not a String is left as is (useful for
      # instance for the OptionParser with boolean options)
      #
      # As a special case, if the command takes no arguments and the
      # arguments is [true], no exception is raised, and the correct
      # number of arguments is returned.
      def convert_arguments(args)
        if args.size != @arguments.size
          if(@arguments.size == 0 && args.size == 1 && args[0] == true)
            return []
          else
            raise ArgumentNumberMismatch, "Command #{@name} was called with #{args.size} arguments, but it takes #{@arguments.size}"
          end
        end
        retval = []
        @arguments.each_index do |i|
          if ! args[i].is_a? String
            retval << args[i]
          else
            retval << @arguments[i].type.string_to_type(args[i])
          end
        end
        return retval
      end

      # Converts the Hash of String given into a Hash of the type
      # suitable for the #code of the Command. Only optional
      # arguments are taken into account.
      #
      # Any object which is not a String is left as is (useful for
      # instance for the OptionParser with boolean options)
      def convert_options(options)
        target_options = {}
        conv = target_option_names()
        for k,v in options
          kn = normalize_option_name(k)
          if ! conv.key? kn
            raise CommandOptionUnkown, "Unkown option #{k} for command #{@name}"
          end
          opt = @optional_arguments[conv[kn]]
          if v.is_a? String
            v = opt.type.string_to_type(v)
          end
          target = opt.option_target || conv[kn]
          if opt.option_deprecated
            expl = ""
            if opt.option_target
              expl = " -- please use #{opt.option_target} instead"
            elsif opt.option_deprecated != true # Ie more than plain
                                                # true/false
              expl = " -- #{opt.option_deprecated}"
            end
            Log::warn { "Deprecated option #{k}#{expl}" }
          end

          target_options[target] = v
        end
        return target_options
      end

      # Returns a hash "normalized option names" => 'real option name'
      def target_option_names
        return @tg_op_names if @tg_op_names

        @tg_op_names = {}
        for k in @optional_arguments.keys
          @tg_op_names[normalize_option_name(k)] = k
        end
        return @tg_op_names
      end

      # Returns a lowercase 
      def normalize_option_name(opt)
        return opt.gsub(/_/,"-").downcase
      end

      # Whether the Command accepts the named _option_.
      def has_option?(option)
        return target_option_names.key?(normalize_option_name(option))
      end

      # Whether the Command accepts any option at all ?
      def has_options?
        return !(@optional_arguments.empty?)
      end


      # Runs the command with the given _plotmaker_target_, the
      # compulsory arguments and the optional ones. Any mismatch in
      # the number of things will result in an Exception.
      # 
      # The arguments will *not* be processed further.
      def run_command(plotmaker_target, compulsory_args, 
                      optional_args = nil)
        args = [plotmaker_target]
        if compulsory_args.size != @arguments.size
          raise ArgumentNumberMismatch, "Command #{@name} was called with #{args.size} arguments, but it takes #{@arguments.size}"
        end
        args += compulsory_args
        if has_options?
          if optional_args
            args << optional_args
          else
            args << {}
          end
        end
        @code.call(*args)
      end

    end
  end
end

