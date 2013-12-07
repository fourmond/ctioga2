# histogram.rb: a histogram
# copyright (c) 2013 by Vincent Fourmond

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details (in the COPYING file).

require 'ctioga2/utils'
require 'ctioga2/log'
require 'ctioga2/graphics/elements/curve2d'

require 'Dobjects/Function'


module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Graphics

    module Elements

      # A histogram
      class Histogram < Curve2D
          

        include Log
        include Dobjects

        # The drawing code will have to depend both on the current
        # "histogram style" (just like the xy-parametric style) and the
        # overall number of histograms in the parent container.
        #
        # For that, one needs an iterator overall all leaf elements in
        # a container.

      end
    end
  end
end
