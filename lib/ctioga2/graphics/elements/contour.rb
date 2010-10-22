# contour.rb: contouring code for XYZ data
# copyright (c) 2009 by Vincent Fourmond
  
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
  
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details (in the COPYING file).


require 'ctioga2/graphics/elements/primitive'

# This module contains all the classes used by ctioga
module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Graphics

    module Elements

      module Contours

        ContoursOptions = {
          'width' => 'float',
          'color' => 'color',
          'closed' => 'boolean',
        }

        ## @todo Maybe this cumbersome level/point thing along with the
        # $last_curve_style calls for a context for the primitive, ie
        # which was the state of the dataset/curve stack at the moment
        # when the primitive was drawn ?
        TiogaPrimitiveCall.
          primitive("contour", "contour", [ 'level'],
                    ContoursOptions) do |t, level,options|
          options ||= {}
          # table = PlotMaker.plotmaker.data_stack.last.indexed_table
          l, d = *level
          table = d.indexed_table
          contour = table.make_contour(t,l)
          contour << options['closed']

          ## @todo This $last_curve_style isn't beautiful.
          ##
          ## Worse, it won't work !
          options['color'] ||= $last_curve_style.line.color

          stroke_style = Styles::StrokeStyle.from_hash(options, '%s')
          

          t.context do 
            stroke_style.set_stroke_style(t)
            t.append_points_with_gaps_to_path(*contour)
            t.stroke
          end
        end
      end
      
    end
  end
end
