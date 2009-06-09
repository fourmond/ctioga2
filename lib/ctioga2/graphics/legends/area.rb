# storage.rb: an object holding legends
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
require 'ctioga2/log'

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Graphics

    # This module holds all the classes dealing with legends
    module Legends

      # This class holds a series of legends for curves.
      #
      # TODO:
      # 
      # * a legend can be plotted either inside a plot or outside the
      #   root object
      #   
      # * in case it is plotted outside the root object, the user should
      #   be able to choose whether it should be counted in the
      #   real-size or not.
      #
      # * legends should provide all the kind of things that were in the
      #   first ctioga, such as background, frames, and so on...
      #
      # * legends could be organized as columns (especially at the
      #   bottom of the graph).
      #
      # * whenever a --legend-inside is specified, we create a private
      #   @legend_area for the current Elements::Container, with the
      #   given position.
      #
      # TODO: make a subclass for a top-level area ???? 
      class LegendArea

        # The style of the LegendStorage, a Styles::LegendStorageStyle
        # object (of course)
        attr_accessor :legend_style

        # The type of the legend. Can be :left, :right, :top, :bottom
        # or :inside
        attr_accessor :legend_type

        # The position of the LegendArea. Only significant when the
        # type is :inside. A Types::AlignedPoint instance.
        attr_accessor :legend_position

        def initialize(type = :right)
          @legend_style = Styles::LegendStorageStyle.new
          @legend_type = type
          @legend_position = Types::AlignedPoint.new(0.5,0.5,:frame)
        end


        # Draws the legend of the given container and all its
        # subobjects. It assumes that the frames have been set
        # according to the return value of #partition_frame
        #
        # TODO:
        # 
        # * customization of the x and y of origin (y should match the
        #   top of the corresponding graph, if applicable)
        #
        # * add padding on the external side of the legend, if
        #   applicable ?
        #
        def display_legend(t, container)
          items = container.legend_storage.harvest_contents
          t.context do 
            t.rescale(@legend_style.scale)
            t.rescale_text(@legend_style.text_scale)

            # We make figure coordinates frame coordinates
            t.set_bounds([0, 1, 1, 0])
            # TODO: customize this !
            x, y = initial_xy(t, container)
            for item in items
              # TODO: transform the 0.0 for x into a negative
              # user-specifiable stuff.
              item.draw(t, @legend_style, x , y)
              y -= @legend_style.dy.to_figure(t,:y)
            end
          end
        end

        # Returns the total size of the legend as a
        #  [ width, height ]
        # array in figure coordinates.
        def size(t, container)
          items = container.legend_storage.harvest_contents
          width, height = 0,0
          for item in items
            w,h = item.size(t, @legend_style)
            if w > width
              width = w
            end
            # Hmmm... this is plain wrong... 
            # height += h
            height += @legend_style.dy.to_figure(t,:y) * 
              @legend_style.scale * @legend_style.text_scale
          end
          return [ width, height ]
        end


        # Returns an enlarged page size that can accomodate for both
        # the text and the legend.
        def enlarged_page_size(t, container, width, height)
          w, h = size(t, container)
          case @legend_type
          when :left, :right
            return [width + t.convert_figure_to_output_dx(w)/10, 
                    height]
          when :top, :bottom
            return [width, height + t.convert_figure_to_output_dy(h)/10]
          when :inside
            return [width, height]
          end
          raise "Unknown type: #{@legend_type}"
        end


        # Partitions the frame in two: the plot frame and the legend
        # frame, according to various parameters:
        # * the #type of the LegendArea
        # * the #size of the legend.
        #
        # It returns two arrays:
        # 
        #  [ plot_margins, legend_margins]
        #  
        # These arrays can be used as arguments for subframe_margins
        # or respectively the graph and the legends part of the plot.
        #
        # This function will *eventually* also work in the case of a
        # #legend_type :inside?
        def partition_frame(t, container)
          w,h = size(t, container)
          case @legend_type
          when :right
            w = t.convert_figure_to_frame_dx(w)
            return [ [0, w, 0, 0], [1 - w, 0, 0, 0]]
          when :left
            w = t.convert_figure_to_frame_dx(w)
            return [ [w, 0, 0, 0], [0, 1 - w, 0, 0]]
          when :inside
            return [ 
                    [0, 0, 0, 0], 
                    @legend_position.to_frame_margins(t, w, h)
                   ]
          else 
            raise "Unimplemented yet..."
          end
          
        end

        protected

        # Returns the X and Y values for the top left of the legend
        # inside the legend frame. Depends on a lot of things,
        # including the type of the legend.
        def initial_xy(t, container)
          case @legend_type
          when :right
            l,r,t,b = container.subframe.to_frame_margins(t)
            # Here, we take profit from the fact that frame
            # coordinates are also figure coordinates within the
            # legend.

            # TODO: that won't work in the case of labels on the
            # right-hand-side.
            return [- l/2, 1.0 - t]
          when :inside
            return [0.0, 1.0]
          else
            raise "Unimplemented yet..."
          end
        end
      end

    end
  end

end

