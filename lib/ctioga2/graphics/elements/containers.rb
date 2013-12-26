# containers.rb: drawables that contains other drawables
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

  module Graphics

    module Elements
      
      # A Container is a drawable object that contains several others, its
      # #elements.
      class Container < TiogaElement

        # All drawable Element contained in this object. It may
        # contain other Container subobjects.
        attr_accessor :elements

        # The subframe position of this element with respect to its
        # parent. It is a Types::Box object.
        attr_accessor :subframe

        # A reference to the RootObject
        attr_accessor :root_object

        # The Legends::LegendArea dedicated to the display of the
        # legend of this object and its children, or _nil_ if the
        # parent should handle the display.
        attr_accessor :legend_area

        # The Legends::LegendStorage that holds all the legends of the
        # object
        attr_accessor :legend_storage

        # The current legend container to which legend items are added.
        # Defaults to the #legend_storage, but it can be changed
        attr_accessor :legend_item_target

        # A general-purpose cache that objects may use.
        #
        # It is a hash, and its contents are reset at the beginning of
        # each invocation of #do.
        attr_accessor :gp_cache


        # @todo Add an iterator over all leaf elements (including
        # children or not ?)

        # Creates an empty new Container with the given _parent_.
        def initialize(parent = nil, root = nil)
          super()
          @parent = parent
          
          # elements to be given to tioga
          @elements = []

          # By default the frame takes up all the space.
          @subframe = Types::MarginsBox.new(0, 0, 0, 0)

          @root_object = root

          @legend_storage = Legends::LegendStorage.new
          
          @legend_item_target = @legend_storage

          # By default, don't display legends.
          @legend_area = nil
        end

        def do(t)
          # reset the cache
          @gp_cache = {}
          super
        end

        # Returns the number of child elements
        def size
          return @elements.size
        end

        # Sometimes, the value of the subframe is _nil_ and determined
        # during the plot. This function is guaranteed to return the
        # correct value. It takes a reference to a FigureMaker object.
        def actual_subframe(t)
          return @subframe
        end

        # Adds an element
        def add_element(element)
          element.parent = self
          @elements << element
          
          # If the element has a curve_style, we add it as a
          # CurveLegend
          if element.respond_to?(:curve_style) and 
              element.curve_style.has_legend?
            add_legend_item(Legends::CurveLegend.new(element.curve_style))
          elsif element.is_a? Container
            add_legend_item(element)
          end

          # We call LocationStyle#finalize! if possible
          if(self.respond_to?(:style) and element.respond_to?(:location))
            element.location.finalize!(self.style)
          end
        end


        # Adds a legend item to the current storage
        def add_legend_item(item)
          @legend_item_target.add_item(item)
        end

        # Adds a legend item to the current storage and make that item
        # the next target for legend items.
        #
        # If @a sub is nil, then switch back to the top
        def enter_legend_subcontainer(sub)
          if sub
            add_legend_item(sub)
            @legend_item_target = sub
          else
            @legend_item_target = @legend_storage
          end
        end

        def each_item(leaf_only = true, recursive = false, tl = true, &blk)
          if (!recursive && !tl)
            return              # We're at the bottom level
          end
          for el in @elements
            if el.respond_to? :each_item
              if ! leaf_only
                blk.call(el)
              end
              el.each_item(leaf_only, recursive, false, &blk)
            else
              blk.call(el)
            end
          end
        end

        # \todo provide coordinate conversion facilities...

        protected 

        # Creates the appropriate subfigure and draws all its elements
        # within.
        def real_do(t)
          t.subfigure(@subframe.to_frame_margins(t)) do 
            for el in @elements
              el.do(t)
            end
          end
        end

      end
    end
  end
end
