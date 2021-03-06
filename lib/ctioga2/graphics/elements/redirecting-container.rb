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

require 'forwardable'

module CTioga2

  module Graphics

    module Elements

      # A Container that redirect most of its trafic to the parents.
      class RedirectingContainer < Container

        extend Forwardable

        ###########################################
        # The following functions are plain redirections to the
        # parent.
        #
        # \todo a scheme should probably be designed to allow simple
        # redirection in the form of an accessor. Using forwardable
        # should do

        undef :gp_cache, :gp_cache=

        def_delegators :parent, :style, :add_legend_item, :legend_area=, 
                                 :gp_cache, :gp_cache=, :set_user_boundaries

        def each_item(leaf_only = true, recursive = false, tl = true, &blk)
          if tl
            parent.each_item(leaf_only, recursive, tl, &blk)
          else
            if @elements
              super(leaf_only, recursive, true, &blk)
            end
          end
        end


      end
    end
  end
end
