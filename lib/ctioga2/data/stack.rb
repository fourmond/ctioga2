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


require 'ctioga2/data/filters'

# This module contains all the classes used by ctioga
module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')


  module Data

    # This is the central class for acquisition and handling of
    # Dataset objects, retrieved from from a Backends::BackendFactory.
    #
    # TODO: provide real stack manipulation functions such as
    # 
    # * interpolation: pops the last object from the stack and add its
    #   interpolated values on the element before.
    # * mathematical functions on each column (DataColumn)
    # * other stack-based operations.
    class DataStack

      include Log

      # The array containing all the Dataset used so far.
      attr_accessor :stack

      # The BackendFactory used for retrieving data from named sets.
      attr_accessor :backend_factory

      # Named datasets
      attr_accessor :named_datasets

      # A hook executed every time a dataset is pushed unto the stack
      # using #add_dataset.
      #
      # TODO: this string is parsed for each call to
      # #add_dataset. Perhaps it would be good to provide a way to
      # record a Command call, without parsing it from scratch ???
      # 
      # Although, with variables, that could be interesting to reparse
      # everytime, since any change in the variables would be taken
      # into account.
      attr_accessor :dataset_hook

      # Creates a new DataStack object.
      def initialize
        @stack = Array.new

        @named_datasets = Hash.new

        # Defaults to the 'text' backend
        @backend_factory = Data::Backends::BackendFactory.new('text')
      end

      # Performs expansion on the given _set_ with the current
      # backend, retrieves corresponding Dataset objects, pushes them
      # onto the stack and returns them.
      def get_datasets(set)
        backend = @backend_factory.current
        retval = []
        for s in backend.expand_sets(set)
          ds = backend.dataset(s)
          add_dataset(ds)
          retval << ds
        end
        return retval
      end

      # Returns the stored dataset, either using its index in the
      # stack, or its name in the dataset.
      def stored_dataset(spec)
        if spec.is_a? Numeric or spec =~ /^\s*-?\d+\s*$/
          spec = spec.to_i
          return @stack[spec]
        else
          if @named_datasets.key? spec
            return @named_datasets[spec]
          else
            raise "Unkown named dataset from the stack: '#{spec}'"
          end
        end
      end

      # Adds a Dataset object onto the stack, running hooks if
      # necessary.
      #
      # Makes use of Plotmaker.plotmaker
      def add_dataset(dataset)
        @stack << dataset
        if @dataset_hook
          # TODO: error handling
          begin
            PlotMaker.plotmaker.interpreter.run_commands(@dataset_hook)
          rescue Exception => e
            error "There was a problem running the dataset hook '#{@dataset_hook}', disabling it"
            @dataset_hook = nil
            info "-> '#{format_exception e}'"
          end
        end
      end

      # Appends a set of commands to the dataset hook
      def add_to_dataset_hook(commands)
        if @dataset_hook
          @dataset_hook << "\n#{commands}"
        else
          @dataset_hook = commands
        end
      end

      # Writes the contents of the the given element to the given _io_
      # stream.
      def print_dataset(which, io)
        set = stored_dataset(which)
        io.puts "# #{set.name}"
        io.puts "# #{set.column_names.join("\t")}"
        set.each_values do |i, *vals|
          io.puts vals.join("\t")
        end
      end

      # Pops the last _n_ datasets off the stack
      def concatenate_datasets(n = 2)
        ds = @stack.pop
        raise "Nothing on the stack" unless ds
        (n-1).times do
          ds2 = @stack.pop
          raise "Not enough datasets on the stack" unless ds2
          ds << ds2
        end
        @stack.push(ds)
      end

      # Returns the last Dataset pushed onto the stack.
      def last
        return @stack.last
      end

      
    end

    DataStackGroup =  
      CmdGroup.new('stack', "Data stack manipulation",
                   "Commands for manipulation of the data stack", 
                   100)
    
    LoadDataCommand = 
      Cmd.new("load", '-L', "--load", 
              [ CmdArg.new('dataset'), ], 
              { 'name' => CmdArg.new('text')}) do |plotmaker, set, opts|
      plotmaker.data_stack.get_datasets(set)
      if opts['name']
        plotmaker.data_stack.named_datasets[opts['name']] = 
          plotmaker.data_stack.last
      end
    end
    
    LoadDataCommand.describe("Load given sets onto the data stack",
                             <<EOH, DataStackGroup)
Use the current backend to load the given dataset(s) onto the data stack.

If the name option is given, the last dataset loaded this way (if
dataset expansion occurs) gets named. This name can be used to further
use the dataset without remembering its number. See the type {type:
stored-dataset} for more information.
EOH


    PrintLastCommand =
      Cmd.new("print-dataset", '-P', "--print-dataset",
              [], {'which' => CmdArg.new('stored-dataset')}) do |plotmaker,opts|
      which = opts['which'] || -1
      plotmaker.data_stack.print_dataset(which, STDOUT)
    end
    
    PrintLastCommand.describe("Prints the dataset last pushed on the stack",
                              <<EOH, DataStackGroup)
Prints to standard output data contained in the last dataset pushed
onto the stack, or the given stored dataset if the which option is given.
EOH

    ConcatLastCommand = 
      Cmd.new("join-datasets", nil, "--join-datasets", 
              [], {'number' => CmdArg.new('integer')}) do |plotmaker, opts|
      nb = opts['number'] || 2
      plotmaker.data_stack.concatenate_datasets(nb)
    end
    
    ConcatLastCommand.describe("Concatenates the last datasets on the stack",
                               <<EOH, DataStackGroup)
Pops the last two (or number, if it is specified) datasets from the
stack, concatenates them (older last) and push them back onto the
stack.
EOH

    SetDatasetHookCommand = 
      Cmd.new("dataset-hook", nil, "--dataset-hook", 
              [CmdArg.new('commands')], {}) do |plotmaker, commands, opts|
      plotmaker.data_stack.dataset_hook = commands
    end
    
    SetDatasetHookCommand.describe("Sets the dataset hook",
                                   <<EOH, DataStackGroup)
The dataset hook is a series of commands such as those in the command
files that are run every time after a dataset is added onto the data
stack. Its main use is to provide automatic filtering of data, but any
arbitrary command can be used, so enjoy !
EOH

    ClearDatasetHookCommand = 
      Cmd.new("dataset-hook-clear", nil, "--dataset-hook-clear", 
              [], {}) do |plotmaker, opts|
      plotmaker.data_stack.dataset_hook = nil
    end
    
    ClearDatasetHookCommand.describe("Clears the dataset hook",
                                     <<EOH, DataStackGroup)
Clears the dataset hook. See {command: dataset-hook} for more information.
EOH

    AddDatasetHookCommand = 
      Cmd.new("dataset-hook-add", nil, "--dataset-hook-add", 
              [CmdArg.new('commands')], {}) do |plotmaker, commands, opts|
      plotmaker.data_stack.add_to_dataset_hook(commands)
    end
    
    AddDatasetHookCommand.describe("Adds commands to the dataset hook",
                                   <<EOH, DataStackGroup)
Adds the given commands to the dataset hook. See {command: dataset-hook} 
for more information about the dataset hook.
EOH

  end

end

