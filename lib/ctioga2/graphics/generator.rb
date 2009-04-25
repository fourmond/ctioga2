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

      # Creates a CurveGenerator object.
      def initialize
        @legend_provider = Legends::LegendProvider.new
        @style_factory = Styles::CurveStyleFactory.new
      end

      # Creates a Elements::TiogaElement representing the _dataset_
      # and returns it.
      #
      # TODO:
      # * coordinate transformations
      # * other kinds of curves (pseudo-3D, surfaces, histograms...)
      def curve_from_dataset(plot, dataset, options = {})
        legend = @legend_provider.dataset_legend(dataset)
        style = @style_factory.next(options)
        style.legend ||= legend # The legend specified as option to
                                # the --plot command has precedence
                                # over the one specified by --legend.

        # TODO: copy datasets here !
        plot.style.transforms.transform_2d!(dataset)
        curve = Graphics::Elements::Curve2D.new(dataset, style)
        return curve
      end
      
    end

  end
end

