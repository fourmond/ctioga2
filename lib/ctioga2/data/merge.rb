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

# This module contains all the classes used by ctioga
module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')


  module Data

    # This module provides function to deal with the merging of
    # several datasets.
    module MergeDatasets

      # Merges two or more datasets so that their X values match.  If
      # _prec_ isn't _nil_, it is a Float which must not be greater
      # than the difference between two X values that should be
      # regarded as equal.
      #
      # TODO !
      def merge_datasets(prec, *datasets)
        
      end

    end
  end
end

