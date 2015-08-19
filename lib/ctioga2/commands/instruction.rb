# instruction.rb: an instruction
# copyright (c) 2015 by Vincent Fourmond
  
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

  module Commands


    # This class represents an instruction, i.e. the execution of one
    # Command. It is different in Command in that, for most of them,
    # there will be arguments
    class Instruction

      # The Command
      attr_accessor :command

      # The list of its arguments, already in the correct type.
      attr_accessor :arguments

      # The options, already in the correct type
      attr_accessor :options

      def initialize(cmd, args, opts)
        @command = cmd
        @arguments = args
        @options = opts
      end

      # Runs this instruction again
      def run(plotmaker_target)
        @command.run_command(plotmaker_target, args, opts)
      end

      def to_s
        "#{@command.name} #{@arguments.inspect} #{@options.inspect}"
      end
    end
  end
end

