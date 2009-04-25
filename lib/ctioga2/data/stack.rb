# stack.rb: the data stack
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
require 'ctioga2/data/datacolumn'
require 'ctioga2/data/backends/backends'
require 'ctioga2/data/backends/factory'

# This module contains all the classes used by ctioga
module CTioga2

  Version::register_svn_info('$Revision: 933 $', '$Date: 2009-03-30 22:31:30 +0200 (Mon, 30 Mar 2009) $')


  module Data

    # This is the central class for acquisition and handling of
    # Dataset objects, retrieved from from a Backends::BackendFactory.
    #
    # Provide real stack manipulation functions such as:
    # 
    # * interpolation: pops the last object from the stack and add its
    #   interpolated values on the element before.
    # * mathematical functions on each column (DataColumn)
    # * other stack-based operations.
    class DataStack

      # The array containing all the Dataset used so far.
      attr_accessor :stack

      # The BackendFactory used for retrieving data from named sets.
      attr_accessor :backend_factory

      # Creates a new DataStack object.
      def initialize
        @stack = Array.new

        # Defaults to the 'text' backend
        @backend_factory = Data::Backends::BackendFactory.new('math')
      end

      # Performs expansion on the given _set_ with the current
      # backend, retrieves corresponding Dataset objects, pushes them
      # onto the stack and returns them.
      def get_datasets(set)
        backend = @backend_factory.current
        retval = []
        for s in backend.expand_sets(set)
          retval << backend.dataset(s)
        end
        @stack += retval
        return retval
      end

      # Writes the contents of the the given element to the given _io_
      # stream.
      def print_dataset(number, io)
        set = @stack[number]
        io.puts "# #{set.name}"
        io.puts "# #{set.column_names.join("\t")}"
        set.each_values do |i, *vals|
          io.puts vals.join("\t")
        end
      end
      
    end

    DataStackGroup =  
      CmdGroup.new("Data stack manipulation",
                                 "Commands for manipulation of the data stack", 
                                 100)
    
    LoadDataCommand = 
      Cmd.new("load", '-L', 
                            "--load", 
                            [
                             CmdArg.new(:string),
                            ]) do |plotmaker, set|
      plotmaker.data_stack.get_datasets(set)
    end
    
    LoadDataCommand.describe("Load given sets onto the data stack",
                             <<EOH, DataStackGroup)
Use the current backend to load the given dataset onto the data stack.
EOH

    PrintLastCommand = 
      Cmd.new("print-last", nil, 
                            "--print-last", 
                            [
                            ]) do |plotmaker|
      plotmaker.data_stack.print_dataset(-1, STDOUT)
    end
    
    PrintLastCommand.describe("Prints the dataset last pushed on the stack",
                             <<EOH, DataStackGroup)
Prints the dataset last pushed on the stack.
EOH



  end

end

