# subplot.rb: a subplot
# copyright (c) 2006, 2007, 2008, 2009 by Vincent Fourmond
  
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

  Version::register_svn_info('$Revision: 954 $', '$Date: 2009-04-18 23:39:29 +0200 (Sat, 18 Apr 2009) $')

  module Graphics

    module Elements

      # A subplot. It features:
      # * inclusion of curves
      # * legends
      # * a way to set/get its figure boundaries.
      class Subplot < Container

        # A Boundaries object representing the boundaries imposed by
        # the user.
        attr_accessor :user_boundaries

        # A Boundaries object representing the boundaries in
        # effect. Only filled with meaningful values from within the
        # real_do function.
        attr_accessor :real_boundaries

        # Various stylistic aspects of the plot, as a
        # Styles::PlotStyle object.
        attr_accessor :style
        
        def initialize(parent, root, style)
          super(parent, root)

          @user_boundaries = Types::Boundaries.new(nil, nil, nil, nil)
          @real_boundaries = nil

          @subframe = Types::MarginsBox.new("2.8dy", "2.8dy", 
                                            "2.8dy", "2.8dy")

          @style = style || Styles::PlotStyle.new
        end

        # Returns the boundaries of the SubPlot.
        def get_boundaries
          # raw boundaries
          bounds = get_elements_boundaries
          if @style.plot_margin
            bounds.apply_margin!(@style.plot_margin)
          end
          bounds.override_boundaries(@user_boundaries)
          return bounds
        end

        protected

        # Plots all the objects inside the plot.
        def real_do(t)
          # First thing, we setup the boundaries

          @real_boundaries = get_boundaries
          
          # We wrap the call within a subplot
          t.subplot(@subframe.to_frame_margins(t)) do
            
            # Manually creating the plot:
            t.set_bounds(@real_boundaries.to_a)
            t.context do
              t.clip_to_frame
              @style.draw_all_background_lines(t)
              for element in @elements 
                element.do(t)
              end
            end
            @style.draw_all_axes(t)

            # Now drawing legends:
            if @legend_area
              a, b = @legend_area.partition_frame(t, self)
              t.context do 
                t.set_subframe(b) 
                @legend_area.display_legend(t, self)
              end
            end
          end
        end

        
        # Returns the boundaries of all the elements of this plot.
        def get_elements_boundaries
          elements_bounds = []
          for el in @elements
            if el.respond_to? :get_boundaries
              elements_bounds << el.get_boundaries
            end
          end
          return Types::Boundaries.overall_bounds(elements_bounds)
        end

      end
    end
  end
end
