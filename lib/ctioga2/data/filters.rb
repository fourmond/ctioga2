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

  Version::register_svn_info('$Revision$', '$Date$')


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
        plotmaker.data_stack.last.sort
      end
      
      SortOperation.describe("Sorts the last dataset according to X values",
                             <<EOH, FiltersGroup)
Sorts the last dataset pushed unto the stack according to X values. Can be
used as a filter.
EOH

      SortFilter = 
        Cmd.new("sort", nil, "--sort", 
                [], {}) do |plotmaker, opts|
        plotmaker.data_stack.add_to_dataset_hook('sort-last()')
      end
      
      SortFilter.describe("Systematically sort all datasets",
                          <<EOH, FiltersGroup)
Install the {cmd: sort-last} command as a dataset hook (see {cmd:
dataset-hook}: all subsequent datasets will be sorted according to
their X values.
EOH

    end
  end
end

