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
require 'ctioga2/data/dataset'
require 'ctioga2/data/backends/backends'
require 'ctioga2/data/backends/factory'

require 'ctioga2/data/point'


require 'ctioga2/data/filters'

# This module contains all the classes used by ctioga
module CTioga2

  module Data

    # This is the central class for acquisition and handling of
    # Dataset objects, retrieved from from a Backends::BackendFactory.
    #
    # \todo provide real stack manipulation functions such as
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
      # This is a list of Instruction
      attr_accessor :dataset_hook

      # Creates a new DataStack object.
      def initialize
        @stack = Array.new

        @named_datasets = Hash.new

        # Defaults to the 'text' backend
        @backend_factory = Data::Backends::BackendFactory.new('text')

        @dataset_hook = []

        # Probably a bit out of place...
        csv = 
          Cmd.new('csv', nil, '--csv', []) do |plotmaker|
          plotmaker.interpreter.
            run_commands("text /separator=/[,;]/")
        end
        
        csv.describe("reads CSV files", 
                     <<"EOH", "backend-text")
Now parse the following data files as CSV. Equivalent to

# text /separator=/[,;]/
EOH
      end

      # Performs expansion on the given _set_ with the current
      # backend, retrieves corresponding Dataset objects, pushes them
      # onto the stack and returns them.
      def get_datasets(set, options = {}, add = true)
        backend = @backend_factory.specified_backend(options)
        sets = backend.expand_sets(set)
        datasets = []
        for s in sets
          begin
            datasets << backend.dataset(s)
          rescue Exception => e
            error { "Could not load dataset '#{s}' with backend '#{backend.description.name }':\n\t -> #{e}" }
            debug { "#{e.backtrace.join("\n")}" }
          end
        end
        if add
          add_datasets(datasets, options)
        end
        return datasets
      end

      # Adds a series of datasets, and perform various operations
      # according to the hash _options_:
      # 
      # * 'name' to name each element added to the stack. A %d will be
      #   replaced by the number of the dataset within the ones just
      #   added.
      #
      # Additional members of the Hash are simply ignored.
      def add_datasets(datasets, options = {})
        i = 0
        for ds in datasets
          store_dataset(ds, options['ignore_hooks'])

          # Selection
          if options['where']
            ds.select_formula!(options['where'])
          end

          if options['name']
            @named_datasets[options['name'] % [i]] = ds
          end
          i += 1
        end
      end

      # Returns the stored dataset, either using its index in the
      # stack, or its name in the dataset.
      def stored_dataset(spec)
        return dataset_xref(spec)[0]
      end


      # Returns the [dataset, index, name] of the given dataset
      def dataset_xref(spec)
        ds = nil
        index = nil
        name = nil
        if spec.is_a? Numeric or spec =~ /^\s*-?\d+\s*$/
          spec = spec.to_i
          index = spec
          name = nil
          ds = @stack[index]
          for k,v in @named_datasets
            if v == ds
              name = k
            end
          end
        else
          if spec =~ /^\s*#(.*)/
            # graph idea -> get dataset from the plot element
            eln = $1
            obj = Elements::TiogaElement.find_object(eln)
            if !obj.respond_to(:dataset)
              raise "Object '##{eln}' does not name a plot"
            end
            ds = obj.dataset
            index = @stack.index(ds)
          elsif @named_datasets.key? spec
            name = spec
            ds = @named_datasets[spec]
            i = 0
            for d in @stack
              if d == ds
                index = i
              end
              i += 1
            end
          else
            raise "Unkown named dataset from the stack: '#{spec}'"
          end
        end
        return [ds, index, name]
      end

      # Gets a dataset from the given _options_ hash. If a 'which' key
      # is present, it is used as an argument for #stored_dataset;
      # else, -1 is used.
      def specified_dataset(options, full = false)
        spec = if options && options['which']
                 options['which']
               else
                 -1
               end
        xr = dataset_xref(spec)
        return (full ? xr : xr[0])
      end

      # Adds a Dataset object onto the stack, running hooks if
      # necessary.
      #
      # Makes use of Plotmaker.plotmaker
      def store_dataset(dataset, ignore_hooks = false)
        @stack << dataset
        if @dataset_hook && (! ignore_hooks)
          for ins in @dataset_hook
            begin
              ins.run(PlotMaker.plotmaker)
            rescue Exception => e
              error { "There was a problem running the dataset hook '#{ins.to_s}', disabling it" }
              @dataset_hook.delete(ins)
              info { "-> '#{format_exception e}'" }
            end
          end
        end
      end

      # Returns a list of datasets, either a named dataset, or the
      # last datasets from the stack
      def latest_datasets(opts)
        if opts['which']
          if opts['number']
            warn { "Cannot use both which and number" }
          end
          datasets = [ specified_dataset(opts) ]
        else
          nb = opts['number'] || 2
          if @stack.size < nb
            raise "Not enough datasets on the stack"
          end
          datasets = @stack[(- nb).. -2]
          datasets.reverse!
        end
      end
        
        
      # Appends a set of commands to the dataset hook
      def add_to_dataset_hook(commands)
        if @dataset_hook
          @dataset_hook += [commands].flatten
        else
          @dataset_hook = [commands].flatten
        end
      end

      # Writes the contents of the the given _dataset_ (a DataSet
      # object) to the given _io_ stream.
      def print_dataset(dataset, io)
        errors = dataset.has_xy_errors?
        io.puts "# #{dataset.name}"
        io.puts "## #{dataset.column_names.join("\t")}"
        dataset.each_values(errors) do |i, *vals|
          io.puts vals.join("\t")
        end
      end

      # Add all the given datasets to the current one.
      def concatenate_datasets(datasets, name = nil)
        ds = @stack.pop
        raise "Nothing on the stack" unless ds

        for ds2 in datasets
          ds << ds2
        end
        @stack.push(ds)
        # Name the dataset
        @named_datasets[name] = ds if name
      end

      # Merges one or more datasets into the last one.
      #
      # The last dataset of the stack is overwritten.
      def merge_datasets_into_last(datasets, columns = [0], precision = nil)
        ds = @stack.pop
        raise "Nothing on the stack" unless ds
        ds.merge_datasets_in(datasets, columns, precision)
        @stack.push(ds)
      end

      # Returns the last Dataset pushed onto the stack.
      def last
        return @stack.last
      end

      # Displays the contents of the stack
      def show
        STDERR.puts "Stack contents"
        i = 0
        # Swap the named dataset stuff
        ## @todo Maybe a hash pair should be maintained in permanence ?
        rev = {}
        for k,v in @named_datasets
          rev[v] = k
        end

        for ds in @stack
          name = rev[ds]
          if name
            name = "(named: '#{name}')"
          else
            name = ""
          end
          
          pref = sprintf("#%-2d %-3d:", i, - @stack.size + i)
          
          STDERR.puts " * #{pref} #{ds.name} -- #{ds.ys.size + 1} columns, #{ds.x.size} points #{name}"
          i += 1
        end
      end

      # Drops the dataset corresponding to the given spec from the
      # stack
      def drop_from_stack(spec)
        xr = dataset_xref(spec)
        if xr[1]                # But that should always be the case ?
          @stack.delete_at(xr[1])
        else
          warn { "For some reason, dataset '#{spec}' is not in the stack !"}
        end
        if xr[2]
          @named_datasets.delete(xr[2])
        end
      end

      
    end

    DataStackGroup =  
      CmdGroup.new('stack', "Data stack manipulation",
                   "Commands for manipulation of the data stack", 
                   100)

    AppendDatasetOptions = { 
      'as' => CmdArg.new('text'),
      'where' => CmdArg.new('text'),
      'ignore_hooks' => CmdArg.new('boolean')
    }
    
    AppendDataCommand = 
      Cmd.new("append", nil, "--append", 
              [ CmdArg.new('dataset'), ], 
              AppendDatasetOptions) do |plotmaker, set, opts|
      datasets = plotmaker.data_stack.get_datasets(set, opts, false)
      # Now, we append them to the last dataset
      plotmaker.data_stack.concatenate_datasets(datasets)
    end
    
    AppendDataCommand.describe("Appends the datasets to the last in the stack",
                             <<EOH, DataStackGroup)
Use the current backend to load the given dataset(s) and append to the
last dataset on the stack (without creating a new dataset). Roughly
the equivalent of first running {command: load} and then 
{command: join-datasets}.
EOH
    
    LoadDatasetOptions = AppendDatasetOptions.dup.merge(
      {
        'name' => CmdArg.new('text')
      })
    
    LoadDataCommand = 
      Cmd.new("load", '-L', "--load", 
              [ CmdArg.new('dataset'), ], 
              LoadDatasetOptions) do |plotmaker, set, opts|
      plotmaker.data_stack.get_datasets(set, opts)
    end
    
    LoadDataCommand.describe("Load given sets onto the data stack",
                             <<EOH, DataStackGroup)
Use the current backend to load the given dataset(s) onto the data stack.

If the name option is given, the last dataset loaded this way (if
dataset expansion occurs) gets named, or, if it contains a %d (or
similar construct), each dataset gets named with %d replace with the
number of the dataset within the expansion (starting at 0). This name
can be used to further use the dataset without remembering its
number. See the type {type: stored-dataset} for more information.
EOH


    
    ContourOptions = LoadDatasetOptions.dup.update({
      'which' => CmdArg.new('stored-dataset'),
    })



    MakeContourCommand = 
      Cmd.new("make-contour", nil, "--make-contour", 
              [ CmdArg.new('float'), ], 
              ContourOptions) do |plotmaker, level, opts|
      ds = plotmaker.data_stack.specified_dataset(opts)
      f = ds.make_contour(level)
      name = "Level #{level} for plot '#{ds.name}'"
      newds = Dataset.new(name, [f.x, f.y])
      plotmaker.data_stack.add_datasets([newds], opts)
    end
    
    MakeContourCommand.describe("Pushes a contour on the data stack",
                                <<EOH, DataStackGroup)
EOH




    PrintLastCommand =
      Cmd.new("print-dataset", '-P', "--print-dataset",
              [], {
                'which' => CmdArg.new('stored-dataset'),
                'save' => CmdArg.new('file'),
              }) do |plotmaker,opts|
      ds = plotmaker.data_stack.specified_dataset(opts)
      if opts['save']
        # Writing
        out = open(opts['save'], 'w')
      else
        out = STDOUT
      end
      plotmaker.data_stack.print_dataset(ds, out)
      if opts['save']
        out.close
      end
    end
    
    PrintLastCommand.describe("Prints the dataset last pushed on the stack",
                              <<EOH, DataStackGroup)
Prints to standard output data contained in the last dataset pushed
onto the stack, or the given stored dataset if the which option is given.
EOH

    SetTimeReferenceCommand =
      Cmd.new("set-time-reference", nil, "--set-time-reference",
              [ CmdArg.new('date') ], {
                'which' => CmdArg.new('stored-dataset'),
                'column' => CmdArg.new('integer'),
              }) do |plotmaker,time, opts|
      ds = plotmaker.data_stack.specified_dataset(opts)
      col = opts['column'] || 1
      col -= 1
      if col == 0
        col = ds.x
      else
        col = ds.y[col - 1]
      end
      col.base_date = time
    end

    SetTimeReferenceCommand.describe("Sets the time reference for the X column (or any other)",
                              <<EOH, DataStackGroup)
Sets the time reference for the given column, which means that the column represents a date counted in *seconds* from the time reference. Use @none@ to cancel.
EOH


    DropCommand =
      Cmd.new("drop", nil, "--drop",
              [CmdArg.new('stored-dataset')], { }) do |plotmaker,spec,opts|
      plotmaker.data_stack.drop_from_stack(spec)
    end
    
    DropCommand.describe("Drops the given dataset from the stack",
                         <<EOH, DataStackGroup)
Removes the given dataset from the stack. 

Can become useful when dealing with large datasets, some of which are
only used as intermediates for {command: apply-formula} or 
{command: compute-contour}, for instance.

EOH

    ConcatLastCommand = 
      Cmd.new("join-datasets", "-j", "--join-datasets", 
              [], 
              { 
                'number' => CmdArg.new('integer'),
                'which' => CmdArg.new('stored-dataset'),
                'name' => CmdArg.new('text') 
              }) do |plotmaker, opts|
      stack = plotmaker.data_stack
      datasets = stack.latest_datasets(opts)
      stack.concatenate_datasets(datasets, opts['name'])
    end
    
    ConcatLastCommand.describe("Concatenates the last datasets on the stack",
                               <<EOH, DataStackGroup)
Pops the last two (or number, if it is specified) datasets from the
stack, concatenates them (older last) and push them back onto the
stack. The name option can be used to give a name to the new dataset. 
EOH

    ApplyLastCommand =
      Cmd.new("apply-formula", nil, "--apply-formula",
              [CmdArg.new('text')], 
              {
                'which' => CmdArg.new('stored-dataset'),
                'name' => CmdArg.new('text'),
              }) do |plotmaker, formula, opts|
      ds = plotmaker.data_stack.specified_dataset(opts)
      newds = ds.apply_formulas(formula)
      plotmaker.data_stack.add_datasets([newds], opts)
    end
    
    ApplyLastCommand.describe("Applies a formula to the last dataset",
                              <<EOH, DataStackGroup)
Applies a formula to the last dataset (or the named one)
EOH

    BinLastCommand = 
      Cmd.new("bin", nil, "--bin", 
              [], 
              { 
                'number' => CmdArg.new('integer'),
                'column' => CmdArg.new('integer'),
                'delta' => CmdArg.new('float'),
                'min' => CmdArg.new('float'),
                'max' => CmdArg.new('float'),
                'normalize' => CmdArg.new('boolean'),
                'which' => CmdArg.new('stored-dataset'),
                'name' => CmdArg.new('text') 
              }) do |plotmaker, opts|
      stack = plotmaker.data_stack
      ds = plotmaker.data_stack.specified_dataset(opts)

      cn = opts['column'] || 1
      col = ds.all_columns[cn]

      
      if opts.key? 'number'
        min = opts['min'] || col.min
        max = opts['max'] || col.max
        number = opts['number']
      elsif opts.key? 'delta'
        delta = opts['delta']
        if opts.key? 'min'
          min = opts['min']
          max = min+((col.max-min)/delta).ceil*delta
        elsif opts.key? 'max'
          max = opts['max']
          min = max-((max-col.min)/delta).floor*delta
        else
          min = (col.min/delta).floor * delta
          max = (col.max/delta).ceil * delta
        end
        number = ((max-min)/delta).to_i
      else
        raise "Must specify either the option 'number' or the option 'delta'"
      end

      newds = Dataset.new("bin", col.bin(min, max, number, opts['normalize']))
      plotmaker.data_stack.add_datasets([newds], opts)
    end
    
    BinLastCommand.describe("Bins the last dataset",
                            <<EOH, DataStackGroup)
This command bins the contents of the Y column of the last dataset on the 
stack, and pushes the results as a new dataset.
EOH

    ShowStackCommand = 
      Cmd.new("show-stack", nil, "--show-stack", 
              [], 
              { }
              ) do |plotmaker, opts|
      plotmaker.data_stack.show
    end
    
    ShowStackCommand.describe("Displays the content of the stack",
                              <<EOH, DataStackGroup)
Displays the current contents of the dataset stack. 

Mostly used for debugging when operations like {command: merge-datasets}
or {command: join-datasets} don't work as expected.
EOH


    ## @todo Add column selection ?
    MergeToLastCommand = 
      Cmd.new("merge-datasets", nil, "--merge-datasets", 
              [], 
              {
                'number' => CmdArg.new('integer'), 
                'precision' => CmdArg.new('float'), 
                'which' => CmdArg.new('stored-dataset'),
                'columns' => CmdArg.new('integer-list')
              }
              ) do |plotmaker, opts|
      stack = plotmaker.data_stack
      cols = if opts.key? 'columns'
               opts['columns'].map { |x| x - 1 }
             else
               [0]
             end
      datasets = stack.latest_datasets(opts)
      plotmaker.data_stack.merge_datasets_into_last(datasets, cols,
                                                    opts['precision'])
    end
    
    MergeToLastCommand.describe("Merge datasets based on X column",
                                <<EOH, DataStackGroup)
This commands merges data with matching X values from a dataset (by
default the one before the last) into the last one. Data points that
have no corresponding X value in the current dataset are simply
ignored. If the @columns@ option is provided, the numbered columns are
use instead of the X columns (X is 1). More than one column can be
provided this way, in which case *all* values must match.

This can be used to build 3D datasets for {command: xyz-map} or 
{command: xy-parametric}.
EOH

    XYReglinCommand = 
      Cmd.new("xy-reglin", nil, "--xy-reglin", [], {
                'which' => CmdArg.new('stored-dataset'),
                'linear' => CmdArg.new('boolean'),
              }) do |plotmaker,opts|
      stack = plotmaker.data_stack
      ds = stack.specified_dataset(opts)
      coeffs, lines = ds.reglin(opts)
      stack.store_dataset(lines, true)
      stack.store_dataset(coeffs, true)
    end
    
    XYReglinCommand.describe("....",
                             <<EOH, DataStackGroup)
...

This command will get documented some day.
EOH


    ComputeContourCommand = 
      Cmd.new("compute-contour", nil, "--compute-contour", 
              [CmdArg.new("float")], {
                'which' => CmdArg.new('stored-dataset')
              }) do |plotmaker, level, opts|
      stack = plotmaker.data_stack
      ds = stack.specified_dataset(opts)
      f = ds.make_contour(level)
      newds = Dataset.new("Contour #{level}", [f.x, f.y])
      stack.store_dataset(newds, true)
    end
    
    ComputeContourCommand.describe("computes the contour and push it to data stack",
                             <<EOH, DataStackGroup)
Computes the contour at the given level for the given dataset (or the
last on the stack if none is specified) and pushes it onto the data
stack.

You can further manipulate it as usual.
EOH

    SetDatasetHookCommand = 
      Cmd.new("dataset-hook", nil, "--dataset-hook", 
              [CmdArg.new('commands')], {}) do |plotmaker, commands, opts|
      raise 'This command is disabled as of now'
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
      raise 'This command is disabled as of now'
      plotmaker.data_stack.add_to_dataset_hook(commands)
    end
    
    AddDatasetHookCommand.describe("Adds commands to the dataset hook",
                                   <<EOH, DataStackGroup)
Adds the given commands to the dataset hook. See {command: dataset-hook} 
for more information about the dataset hook.
EOH
  
  
  end

end

