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

  Version::register_svn_info('$Revision$', '$Date$')

  module Graphics

    module Elements

      # A subplot. It features:
      # * inclusion of curves
      # * legends
      # * a way to set/get its figure boundaries.
      class Subplot < Container

        # Various stylistic aspects of the plot, as a
        # Styles::PlotStyle object.
        attr_accessor :style

        # User-specified boundaries. It is a hash axis -> SimpleRange,
        # where the axis is a valid return value of PlotStyle#get_axis_key
        attr_accessor :user_boundaries

        # Computed boundaries. It also is a hash axis -> SimpleRange,
        # just as #user_boundaries. Its value is not defined as long
        # as #real_do hasn't been entered into.
        attr_accessor :computed_boundaries

        def initialize(parent, root, style)
          super(parent, root)

          @subframe = Types::MarginsBox.new("2.8dy", "2.8dy", 
                                            "2.8dy", "2.8dy")

          @subframe = nil       # Automatic by default.

          @style = style || Styles::PlotStyle.new

          @user_boundaries = {}
        end

        # Returns the boundaries that apply for the given _curve_ --
        # it reads the curve's axes. #compute_boundaries must have
        # been called beforehand, which means that it will only work
        # from within #real_do.
        #
        # \todo This should not only apply to curves, but to any
        # object. That also means that there should be a way to
        # specify axes for them too.
        def get_el_boundaries(el)
          return get_given_boundaries(* el.location.get_axis_keys(style))
        end

        # Returns the boundaries of the *default* axes. Plotting
        # functions may safely assume that they are drawn using these
        # boundaries, unless they asked for being drawn onto different
        # axes.
        def get_boundaries
          return get_given_boundaries(style.xaxis_location, 
                                      style.yaxis_location)       
        end 

        # Sets the user boundaries for the given (named) axis:
        def set_user_boundaries(axis, bounds)
          key = @style.get_axis_key(axis)
          @user_boundaries[key] = Types::SimpleRange.new(bounds)
        end

        def actual_subframe(t)
          return @subframe || @style.estimate_margins(t)
        end

        # In general, subplot's boundaries do not count for the parent
        # plot.
        def count_boundaries?
          return false
        end

        protected

        # Makes up a Boundaries object from two axes keys
        def get_given_boundaries(horiz, vert)
          if @computed_boundaries
            return Types::Boundaries.from_ranges(@computed_boundaries[horiz],
                                                 @computed_boundaries[vert])
          else
            return nil
          end
        end

        def compute_boundaries
          # raw boundaries
          bounds = get_elements_boundaries
          if @style.plot_margin
            for k,b in bounds
              b.apply_margin!(@style.plot_margin)
            end
          end
          for k,b in @user_boundaries
            bounds[k] ||= Types::SimpleRange.new(nil,nil)
            bounds[k].override(b)
          end
          return bounds
        end



        # Plots all the objects inside the plot.
        def real_do(t)
          # First thing, we setup the boundaries
          @computed_boundaries = compute_boundaries

          real_boundaries = get_boundaries

          frames = actual_subframe(t)

          # We wrap the call within a subplot
          t.subplot(frames.to_frame_margins(t)) do

            # Setup various aspects of the figure maker object.
            @style.setup_figure_maker(t)
            
            # Manually creating the plot:
            t.set_bounds(real_boundaries.to_a)

            # Drawing the background elements:
            t.context do
              t.clip_to_frame

              @style.background.draw_background(t)

              @style.draw_all_background_lines(t)
              i = 0
              for element in @elements 
                t.context do 
                  t.set_bounds(get_el_boundaries(element).to_a)
                  element.do(t)
                end
                i += 1
              end
            end
            @style.draw_all_axes(t, @computed_boundaries)

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
          boundaries = {}
          for el in @elements
            if el.respond_to? :get_boundaries
              if el.respond_to?(:count_boundaries?) && ! (el.count_boundaries?)
                # Ignoring
              else
                bounds = el.get_boundaries
                xaxis, yaxis = *el.location.get_axis_keys(style)
                if bounds.is_a? Hash
                  ## \todo see if there will ever be a need for a hash
                  ## ?
                  raise "Not done yet"
                else
                  boundaries[xaxis] ||= Types::SimpleRange.new(nil,nil)
                  boundaries[xaxis].extend(bounds.horizontal)
                  boundaries[yaxis] ||= Types::SimpleRange.new(nil,nil)
                  boundaries[yaxis].extend(bounds.vertical)
                end
              end
            end
          end
          return boundaries
        end

      end
    end
  end
end
