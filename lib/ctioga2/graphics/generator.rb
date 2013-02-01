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

require 'ctioga2/graphics/coordinates'

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Graphics



    # This class is in charge of generating Elements::TiogaElement,
    # such as Elements::Curve2D, from a dataset. It takes care of
    # generating the appropriate style and of transforming the
    # coordinates.
    class CurveGenerator

      # A Styles::CurveStyleFactory object that handles the
      # styles for every single curve that will be drawn.
      attr_accessor :style_factory

      # The provider of legends, a Legends::LegendProvider
      # object.
      attr_accessor :legend_provider

      # The current kind of generated. It is a symbol
      attr_accessor :current_curves

      # Creates a CurveGenerator object.
      def initialize
        @legend_provider = Legends::LegendProvider.new
        @style_factory = Styles::CurveStyleFactory.new
        @current_curves = :xy_plot
      end

      PlotOptions = { 
        'bypass-transforms' => CmdArg.new('boolean')
      }


      # Creates a Elements::TiogaElement representing the _dataset_
      # and returns it.
      #
      # \todo
      # * other kinds of coordinate transformations
      # * other kinds of curves (pseudo-3D, surfaces, histograms...)
      def curve_from_dataset(plot, dataset, options = {})
        # Does coordinate transforms first ?
        # @todo copy datasets here rather than overwriting them !
        #   -> this should be an option !
        if ! options['bypass-transforms']
          plot.style.apply_transforms!(dataset)
        end

        # Now, we trim options unrelated to the plotting
        options.delete_if { |k,v|
          ! Graphics::Styles::
          CurveStyleFactory::PlotCommandOptions.key?(k)
        }

        curve = send(@current_curves, plot, dataset, options)
        curve.curve_style.target = curve
        return curve
      end

      private
      
      ## \name Available kinds of curves
      # 
      # @{
      # 
      # The "classical" 2D plots.
      def xy_plot(plot, dataset, options = {})
        legend = @legend_provider.dataset_legend(dataset)
        style = @style_factory.next(options)
        style.legend ||= legend # The legend specified as option to
                                # the --plot command has precedence
                                # over the one specified by --legend.
        curve = Graphics::Elements::Curve2D.new(dataset, style)
        return curve
      end

      # XYZ plots formerly known as "parametric plots"
      def xy_parametric(plot, dataset, options = {})
        legend = @legend_provider.dataset_legend(dataset)
        style = @style_factory.next(options)
        style.legend ||= legend # The legend specified as option to
                                # the --plot command has precedence
                                # over the one specified by --legend.
        curve = Graphics::Elements::Parametric2D.new(dataset, style)
        style
        return curve
      end

      # XYZ maps
      def xyz_map(plot, dataset, options = {})
        legend = @legend_provider.dataset_legend(dataset)
        style = @style_factory.next(options)
        style.legend ||= legend # The legend specified as option to
                                # the --plot command has precedence
                                # over the one specified by --legend.
        style.legend = false    # No legend for XYZ maps
        curve = Graphics::Elements::XYZMap.new(dataset, style)
        return curve
      end


      ## @}
      
    end


    # The group for chosing plot types.
    PlotTypesGroup =  
      CmdGroup.new('plot-types',
                   "Switch between different kinds of plots",
                   "How to switch between different kinds of plot types", 01)
    

    XYParametricPlotCommand = 
      Cmd.new("xy-parametric",nil,"--xy-parametric") do |plotmaker|
      plotmaker.curve_generator.current_curves = :xy_parametric
    end
    
    XYParametricPlotCommand.describe('select XY parametric plots', 
                                     <<EOH, PlotTypesGroup)
Switch to XY parametric plots, that is standard XY plots whose appearance
(such as color, marker color, and, potentially, marker kinds and more)
are governed by one (or more ?) Z values.
EOH

    XYPlotCommand = 
      Cmd.new("xy-plot",nil,"--xy-plot") do |plotmaker|
      plotmaker.curve_generator.current_curves = :xy_plot
    end
    
    XYPlotCommand.describe('select XY plots', 
                           <<EOH, PlotTypesGroup)
Switch (back) to standard XY plots (ctioga\'s default)
EOH

    XYZMapCommand = 
      Cmd.new("xyz-map",nil,"--xyz-map") do |plotmaker|
      plotmaker.curve_generator.current_curves = :xyz_map
    end
    
    XYZMapCommand.describe('select XYZ maps', 
                            <<EOH, PlotTypesGroup)
Switch to XYZ maps, ie plots where the color at a XY location is given by 
its Z value.
EOH


  end
end

