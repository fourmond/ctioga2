# items.rb: individual legend items
# copyright (c) 2008,2009 by Vincent Fourmond

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details (in the COPYING file).

require 'ctioga2/utils'
require 'ctioga2/log'

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Graphics

    module Legends

      # This class is in charge of providing a legend for the given
      # dataset. Most of its job is simply to collect --legend
      # arguments from the command-line.
      class LegendProvider

        # The legend to be used for the next curve, if applicable
        attr_accessor :current_legend

        # Whether we automatically give a name to curves or not.
        attr_accessor :auto_legend

        def initialize
          @current_legend = nil
          @auto_legend = false
        end

        # Returns a legend suitable for the next curve.
        def dataset_legend(dataset)
          if @current_legend
            l = @current_legend
            @current_legend = nil
            return l
          elsif @auto_legend
            return "\\texttt{#{Utils::pdftex_quote_string(dataset.name)}}"
          else
            return nil
          end
        end
        
      end

    end
  end
end
