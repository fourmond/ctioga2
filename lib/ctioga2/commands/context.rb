# context.rb: parsing context (for error reports)
# copyright (c) 2012 by Vincent Fourmond
  
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details (in the COPYING file).

require 'ctioga2/utils'
require 'ctioga2/commands/type'

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Commands

    # Context of parsing, mostly for error reporting
    class ParsingContext

      # Currently parsing an option
      def parsing_option(opt, number)
        @option = opt
        @number = number
      end

      # Currently within a file
      def parsing_file(command, file, line = -1)
        @option = nil
        @command = command
        @file = file
        @number = line
      end

      def to_s
        if @option
          "option #{@option} (##{@number})"
        else
          file = @file.inspect
          if @file.respond_to?(:path)
            file = @file.path
          end
          if @command
            "command #{@command} in file '#{file}' line #{@number}"
          else
            "line #{@number} in file '#{file}'"
          end
        end
      end

    end

  end

end

