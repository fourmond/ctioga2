# region.rb: draw curves-delimited fills
# copyright (c) 2010 by Vincent Fourmond
  
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

      # A Region is an object that draws filled regions among its
      # "elements". It is a fake container in the sense that all the
      # elements are actually forwarded to the parent.
      class Region < RedirectingContainer

        undef :elements
        undef :subframe

        # The curves which delimit the region
        attr_accessor :curves

        # The fill style
        attr_accessor :fill_style

        # The fill style for reversed polarity
        attr_accessor :reversed_fill_style

        # Creates a new empty region
        def initialize(parent = nil, root = nil)
          @parent = parent
          
          # elements to be given to tioga
          @curves = []

          @root_object = root

          @legend_area = nil

          @fill_style = Styles::FillStyle.new
          @fill_style.color = [0.7,0.7,0.7]

          # For reversed polarity
          @reversed_fill_style = Styles::FillStyle.new
        end

        # Adds an element. Actually forwards it to the parent.
        def add_element(element)
          parent.add_element(element)
          if element.respond_to?(:curve_style)  &&
              element.curve_style.region_position
            @curves << element
          end
        end

        # Sets the various things from hash.
        def set_from_hash(hash)
          @fill_style.set_from_hash(hash)
          # Reversed isn't what I want...
          @reversed_fill_style.set_from_hash(hash, 'reversed_%s')
        end

        protected 

        # Creates the appropriate subfigure and draws all its elements
        # within.
        #
        # \todo: attempt to work fine while mixing curves with
        # different axes. That won't be easy.
        #
        # \todo: enable to do positive and negative. The only thing to
        # do is to swap above for below and call again.
        def real_do(t)
          # This function will be called with the proper figure
          # coordinates.
          
          if @fill_style.color
            t.context do
              @fill_style.setup_fill(t)
              prepare_path(t)
              @fill_style.do_fill(t)
            end
          end

          if @reversed_fill_style.color
            t.context do
              @reversed_fill_style.setup_fill(t)
              prepare_path(t, :reversed)
              @reversed_fill_style.do_fill(t)
            end
          end
          
        end

        # Prepares the path that will be filled, according to the
        # given polarity.
        def prepare_path(t, polarity = :normal)
          # We clip the path for the given
          case polarity
          when :normal
            conversion = {
              :above => :bottom,
              :below => :top
            }
          when :reversed
            conversion = {
              :above => :top,
              :below => :bottom
            }
          end
          closer = Types::FillUntil.new
          # We clip for the first ones...
          for c in @curves[0..-2]
            closer.type = conversion[c.curve_style.region_position]
            c.make_closed_path(t, closer)
            t.clip
          end
          # We don't clip on the last one !
          c = @curves.last
          closer.type = conversion[c.curve_style.region_position]
          c.make_closed_path(t, closer)
        end

      end
    end
  end
end
