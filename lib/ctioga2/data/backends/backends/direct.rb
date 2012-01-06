# text.rb : A simple backend to deal with basic text files.
# Copyright (C) 2006 Vincent Fourmond

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA



require 'Dobjects/Dvector'
require 'Dobjects/Function'

# For separated sets
require 'stringio'

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')


  module Data

    module Backends

      class DirectBackend < Backend

        include Dobjects

        describe 'direct', 'Direct format', <<EOD
A backend where one enters data points directly on the command
line or in the command file
EOD

        def initialize
          @separator = /\s+/
          @line_separator = /[;,]/
          super()
        end

        protected



        # This is called by the architecture to get the data. It
        # splits the set name into filename@cols, reads the file if
        # necessary and calls get_data
        def query_dataset(set)
          str = set.gsub(@line_separator, "\n")
          io = StringIO.new(str)
          
          cols = Dvector::fancy_read(io, nil)

          return Dataset.new("direct", cols)
        end


      end
      
    end

  end
end
