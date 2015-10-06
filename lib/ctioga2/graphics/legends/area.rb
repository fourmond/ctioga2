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

  module Graphics

    # This module holds all the classes dealing with legends
    module Legends

      # This class holds a series of legends for curves.
      #
      # \todo
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
      # \todo make a subclass for a top-level area ????
      #
      # This class is a subclass of Elements::TiogaElement so that it
      # can be styled just like the rest.
      class LegendArea < Elements::TiogaElement

        # The style of the LegendStorage, a Styles::LegendStorageStyle
        # object (of course)
        attr_accessor :legend_style

        # The type of the legend. Can be :left, :right, :top, :bottom
        # or :inside
        #
        # @todo Should this move inside the style ? 
        attr_accessor :legend_type

        # The position of the LegendArea. Only significant when the
        # type is :inside. A Types::AlignedPoint instance.
        attr_accessor :legend_position

        define_style 'legend', Styles::LegendStorageStyle

        def initialize(type = :right, parent = nil, opts = {})
          setup_style(parent, opts)
          @legend_style = get_style()
          @legend_type = type
          @legend_position = Types::AlignedPoint.new(0.5,0.5,:frame)
        end


        # Draws the legend of the given container and all its
        # subobjects. It assumes that the frames have been set
        # according to the return value of #partition_frame
        #
        # \todo
        # 
        # * customization of the x and y of origin (y should match the
        #   top of the corresponding graph, if applicable)
        #
        # * add padding on the external side of the legend, if
        #   applicable ?
        #
        def display_legend(t, container)
          items = container.legend_storage.harvest_contents
          if self.hidden
            return              # Not doing anything
          end
          t.context do 

            ## @todo These two commands should join LegendStyle
            t.rescale(@legend_style.scale)
            t.rescale_text(@legend_style.text_scale)

            # We make figure coordinates frame coordinates
            t.set_bounds([0, 1, 1, 0])
            ## \todo customize this !
            x, y = initial_xy(t, container)

            w,h = *size(t, container, false)


            @legend_style.frame.
              draw_box_around(t, x, y,
                              x + w, y - h, @legend_style.frame_padding)
            
            for item in items
              ## \todo transform the 0.0 for x into a negative
              # user-specifiable stuff.
              iw, ih = *item.size(t, @legend_style)
              item.draw(t, @legend_style, x , y)
              y -= ih
            end
          end
        end

        # Returns the total size of the legend as a
        #  [ width, height ]
        # array in figure coordinates.
        #
        # It assumes that the scales are not setup yet, unless
        # _resize_ is set to false.
        def size(t, container, resize = true)
          items = container.legend_storage.harvest_contents
          width, height = 0,0

          # We apparently can't use context here, for a reason that fails me...
          if resize
            t.rescale(@legend_style.scale)
            t.rescale_text(@legend_style.text_scale)
          end
          
          for item in items
            w,h = item.size(t, @legend_style)
            
            if w > width
              width = w
            end
            
            height += h
          end
          
          if resize
            t.rescale(1/@legend_style.scale)
            t.rescale_text(1/@legend_style.text_scale)
          end

          return [ width, height ]
        end


        # Returns an enlarged page size that can accomodate for both
        # the text and the legend.
        def enlarged_page_size(t, container, width, height)
          w, h = size(t, container)
          case @legend_type
          when :left, :right
            return [width + t.convert_figure_to_output_dx(w)/t.scaling_factor, 
                    height]
          when :top, :bottom
            return [width, height + t.convert_figure_to_output_dy(h)/t.scaling_factor]
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
            l,r,top,b = container.actual_subframe(t).to_frame_margins(t)
            # Here, we take profit from the fact that frame
            # coordinates are also figure coordinates within the
            # legend.

            ## \todo that won't work in the case of labels on the
            # right-hand-side.
            return [0, 1.0 - top]
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

