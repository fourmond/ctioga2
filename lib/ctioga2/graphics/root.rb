# root.rb: the root object for creating a plot.
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

require 'ctioga2/graphics/elements'
require 'ctioga2/graphics/legends'

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  # This module contains all graphical elements of CTioga2
  module Graphics

    # The root object of the plot. The PlotMaker has one object like
    # that. It is the real object drawing the plot.
    class RootObject

      # The current Elements::Container of the object. 
      attr_accessor :current_container

      # The top-level Legends::LegendArea. This one gets necessarily
      # displayed on one of the sides of the graph.
      attr_accessor :legend_area

      # Whether top-level legends are part of the "real size" of the
      # graph or outside the graph (easier to align anything)
      attr_accessor :count_legend_in_page

      # The page size of the graph, a [width,height] array.
      attr_accessor :page_size


      def initialize
        @current_container = nil

        @container_stack = []

        @legend_area = Legends::LegendArea.new

        @count_legend_in_page = false
        #     @count_legend_in_page = true

        # Page size:
        set_page_size("12cmx12cm")  # Same as old ctioga
      end

      # Returns the current Elements::Container, or create an
      # Elements::Subplot if there isn't.
      #
      # This function should be used by all functions that add
      # Elements::TiogaElement to plots (or modify plot's data, such
      # as title, axes...).
      def current_plot
        if @current_container
          return @current_container
        else
          subplot = Elements::Subplot.new(nil, self, nil)
          enter_subobject(subplot)
          return subplot
        end
      end

      # Enters into a new Elements::Container, _new_object_.
      def enter_subobject(new_object)
        if @current_container
          @current_container.add_elem(new_object)
        else
          @current_container = new_object
        end
        @container_stack << @current_container
      end

      # Leaves a subobject.
      def leave_subobject
        if @container_stack.size == 1
          raise "Trying to leave top-level object"
        end
        if @container_stack.pop != @current_container
          raise "We have a serious problem here"
        end
        @current_container = @container_stack.last
      end

      # The only top-level container of the graph.
      def top_level_container
        return @container_stack.first
      end

      # Sets the page of the object, from a pure text object, such as
      # "12cmx12cm"
      def set_page_size(size)
        @page_size = size.split(/\s*x\s*/).collect {|s| 
          Tioga::Utils::tex_dimension_to_bp(s)
        }
      end


      # Sets up the page width and other parameters for the given
      # FigureMaker object. Must be within a figure object, so that
      # potential modifications to the page size due to text objects
      # (legends) can be taken into account.
      def setup_page(t)
        if @count_legend_in_page or ! draw_top_level_legend?
          effective_size = @page_size
        else
          effective_size = @legend_area.
            enlarged_page_size(t,  top_level_container, *@page_size)
        end
        t.page_setup(*effective_size)
        t.set_frame_sides(0,1,1,0) 

        # Setting label and title scale to 1
        t.title_scale = 1
        t.xlabel_scale = 1
        t.ylabel_scale = 1
        # TODO: I think this is mostly useless. Check.
      end

      # Creates a subplot of the current plot. If @current_container
      # is null, create it as a Elements::Container: this will make it
      # *easy* to create complex graphs (no need to disable axes and
      # other kinds of stuff on the main plot).
      def subplot()
        raise YetUnimplemented
      end

      # Returns true if not a single drawable object has been pushed
      # unto the RootObject yet.
      def empty?
        return @current_container.nil?
      end

      # Draws this object onto an appropriate FigureMaker object.
      def draw_root_object(t)
        setup_page(t)
        if top_level_container
          
          plot_margins, legend_margins =  
            if draw_top_level_legend?
              @legend_area.partition_frame(t, top_level_container)
            else
              [[0, 0, 0, 0], nil]
            end

          t.context do 
            t.set_subframe(plot_margins)
            top_level_container.do(t)
          end

          # Draw the legend only when applicable.
          if legend_margins
            t.context do 
              t.set_subframe(legend_margins)
              @legend_area.display_legend(t, top_level_container)
            end
          end
        else
          raise "The root object should not be drawn empty ?"
        end
      end

      # Whether we are drawing a top-level legend
      def draw_top_level_legend?
        return (! top_level_container.legend_area) && 
          ( top_level_container.legend_storage.harvest_contents.size > 0)
      end

      # Returns the legend_area in charge of the current container.
      def current_legend_area
        area = nil
        for el in @container_stack
          if el.respond_to?(:legend_area) and el.legend_area
            area = el.legend_area
          end
        end
        if ! area
          area = @legend_area
        end
        return area
      end
          
      # The group containing all commands linked to subplots and other
      # insets, frame margin selections...
      SubplotsGroup =  
        CmdGroup.new('subplots',
                     "Subplots and assimilated",
                     "Subplots and assimilated", 31)
      
      SetFrameMarginsCommand = 
        Cmd.new("frame-margins",nil,"--frame-margins", 
                [
                 CmdArg.new('frame-margins'),
                ]) do |plotmaker, margins|
        
        plotmaker.root_object.current_plot.subframe = margins
      end

      SetFrameMarginsCommand.describe('Sets the margins of the current plot',
                                        <<EOH, SubplotsGroup)
Sets the margins for the current plot. Margins are the same things as the
position (such as specified for and inset). Using this within an inset or
more complex plots might produce unexpected results. The main use of this 
function is to control the padding around simple plots.
EOH



    end
    
  end

end

