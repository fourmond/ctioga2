# containers.rb: drawables that contains other drawables
# copyright (c) 2011 by Vincent Fourmond
  
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details (in the COPYING file).


require 'ctioga2/utils'
require 'ctioga2/log'

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Graphics

    module Elements

      # A Container that redirect most of its trafic to the parents.
      class RedirectingContainer < Container

        ###########################################
        # The following functions are plain redirections to the
        # parent.
        #
        # \todo a scheme should probably be designed to allow simple
        # redirection in the form of an accessor. Using forwardable
        # should do

        def style(*a)
          return parent.style(*a)
        end

        def add_legend_item(item)
          return parent.add_legend_item(item)
        end

        def legend_area=(l)
          return parent.legend_area = l
        end

      end
    end
  end
end
