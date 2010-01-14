## \file wordwrap.rb small word-wrapping utility
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


      # A small utility class to do word wrapping.
      #
      # \todo Maybe this belongs in Utils ?
      class WordWrapper
        
        # A regex matching word separation.
        attr_accessor :word_sep

        # What to replace the separator with
        attr_accessor :new_sep

        def initialize(ws = /\s+/, ns = " ")
          @word_sep = ws
          @new_sep = ns
        end

        # Split strings into an array of string whose length is each
        # less than _cols_
        def wrap(str, cols)
          words = str.split(@word_sep)
          lines = [words.shift]
          while w = words.shift
            if (lines.last.size + w.size + @new_sep.size) <= cols
              lines.last.concat("#{@new_sep}#{w}")
            else
              lines << w
            end
          end
          return lines
        end

        # Calls #wrap for default values of the parameters
        def self.wrap(str, cols)
          return WordWrapper.new.wrap(str, cols)
        end

      end


    end

  end

end
