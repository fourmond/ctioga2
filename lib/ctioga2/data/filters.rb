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

  module Data

    # A series of commands that can be used as "filters", as they act
    # upon the last Dataset pushed unto the stack.
    module Filters

      FiltersGroup =  
        CmdGroup.new('filter', "Filters",
                     "The commands in this group act upon the last 
dataset pushed unto the data stack: they can be viewed as filters.", 
                     101)
      
      SortOperation = 
        Cmd.new("sort-last", nil, "--sort-last", 
                [], {}) do |plotmaker, opts|
        plotmaker.data_stack.last.sort!
      end
      
      SortOperation.describe("Sorts the last dataset according to X values",
                             <<EOH, FiltersGroup)
Sorts the last dataset pushed unto the stack according to X values. Can be
used as a filter.

See also {command: sort}.
EOH

      SortFilter = 
        Cmd.new("sort", nil, "--sort", 
                [], {}) do |plotmaker, opts|
        plotmaker.data_stack.add_to_dataset_hook('sort-last()')
      end
      
      SortFilter.describe("Systematically sort subsequent datasets",
                          <<EOH, FiltersGroup)
Install the {command: sort-last} command as a dataset hook (see {command:
dataset-hook}): all subsequent datasets will be sorted according to
their X values.
EOH

      TrimOperation = 
        Cmd.new("trim-last", nil, "--trim-last", 
                [CmdArg.new('integer')], {}) do |plotmaker, number, opts|
        plotmaker.data_stack.last.trim!(number)
      end
      
      TrimOperation.describe("Only keeps every n points in the last dataset",
                             <<EOH, FiltersGroup)
Only keeps one every ? data point on the last dataset pushed unto the
data stack. Useful when data have too many points to avoid creating
heavy PDF files that take ages to display with no additional benefits.

This operation is very crude and does not average data.

See also {command: trim}.
EOH

      TrimFilter = 
        Cmd.new("trim", nil, "--trim", 
                [CmdArg.new('integer')], {}) do |plotmaker, number, opts|
        ## @todo There should be a way to add commands in a type-safe
        ## way, without having to convert to string first.
        plotmaker.data_stack.add_to_dataset_hook("trim-last(#{number})")
      end
      
      TrimFilter.describe("Systematically trim subsequent datasets",
                          <<EOH, FiltersGroup)
Install the {command: trim-last} command as a dataset hook (see {command:
dataset-hook}): all subsequent datasets will be trimmed to keep only
every n point.
EOH


      CherryPickOperation = 
        Cmd.new("cherry-pick-last", nil, "--cherry-pick-last", 
                [CmdArg.new('text')], {}) do |plotmaker, formula|
        plotmaker.data_stack.last.select_formula!(formula)
      end
      
      CherryPickOperation.describe("Removes data from the last dataset for which the formula is false",
                                   <<EOH, FiltersGroup)

Removes the data from the last dataset in the data stack for which the
formula returns false.

See also the {command: cherry-pick} command to apply the selection to
all datasets.

You might find it much easier to use the /where option of the
{command: plot} or {command: load} commands.
EOH

      CherryPickFilter = 
        Cmd.new("cherry-pick", nil, "--cherry-pick", 
                [CmdArg.new('text')], {}) do |plotmaker, formula|
        plotmaker.data_stack.add_to_dataset_hook("cherry-pick-last(#{formula})")
      end
      
      CherryPickFilter.describe("Systematicallly remove data for which the formula is false",
                                <<EOH, FiltersGroup)
Install the {command: cherry-pick-last} command as a dataset hook (see
{command: dataset-hook}): all points for which the formula returns
false for subsequent datasets will be removed.
EOH

      AVGDupModeRE = {
        /naive|avg|average/i => :avg,
        /stddev/i => :stddev,
      }
      
      AVGDupMode = 
        CmdType.new('average-mode', 
                    {:type => :re_list,
                     :list => AVGDupModeRE}, <<EOD)
How the {command: avg-dup-last} command :

 * @naive@ or @average@ (the default) treats all columns (values and
   error bars) the same way, and average everythin
 * @stddev@ ignores the original errors, and sets the new errors to the 
   standard deviation of the values
EOD
        


      AverageDupOperation = 
        Cmd.new("avg-dup-last", nil, "--avg-dup-last", 
                [], {'mode' => CmdArg.new('average-mode')}) do |plotmaker, opts|
        mode = opts['mode'] || :avg
        plotmaker.data_stack.last.average_duplicates!(mode)
      end
      
      AverageDupOperation.describe("Average successive elements with identical X values",
                                   <<EOH, FiltersGroup)
Averages successive points with identical X values. This algorithm is
naive with respect to the min/max values and averages them just as
well, whereas one might expect something more clever.

To average over all X values when they are not successive in the
dataset, you should use {command: sort-last} first.
EOH

      AverageDupFilter = 
        Cmd.new("avg-dup", nil, "--avg-dup", 
                [], {}) do |plotmaker, formula|
        plotmaker.data_stack.add_to_dataset_hook("avg-dup-last()")
      end
      
      AverageDupFilter.describe("Systematicallly average successive elements with identical X values",
                                <<EOH, FiltersGroup)
Install the {command: avg-dup-last} command as a dataset hook (see
{command: dataset-hook}): all datasets acquired after this is on will
be averaged if they have identical successive values of X.
EOH


      SmoothOperation = 
        Cmd.new("smooth-last", nil, "--smooth-last", 
                [CmdArg.new('integer')], {}) do |plotmaker, number|
        plotmaker.data_stack.last.naive_smooth!(number)
      end
      
      SmoothOperation.describe("Smooths data using a gaussian filter",
                               <<EOH, FiltersGroup)
Smooth the data using a simple (naive even) gaussian filter. Good for
producing 'lines to guide the eye'
EOH





    end
  end
end

