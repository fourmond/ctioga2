# postprocess.rb: what happens to generated PDF files ?
# copyright (c) 2009 by Vincent Fourmond
  
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
  
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details (in the COPYING file).


require 'ctioga2/utils'
require 'ctioga2/log'

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  # What happens to generated PDF files ?
  #
  # \todo
  # * handle movie generation ? That would be fun !
  class PostProcess

    # Include logging facilities for ctioga2
    include CTioga2::Log

    # View all produced files -- or only the last one ?
    attr_accessor :view_all
    
    # The viewer command. If not _nil_, automatically spawn a viewer
    # after the final figure, or for each produced file if view_all is
    # on.
    attr_accessor :viewer

    # All files processed so far..
    attr_accessor :processed_files

    # Are we converting to SVG using pdf2svg ? 
    attr_accessor :svg

    # Are we converting to EPS using pdftops ? 
    attr_accessor :eps

    # PNG resolution
    attr_accessor :png_res

    # PNG oversampling: how many pixels are rendered for one target
    # linear pixel (take that squared for the real number).
    attr_accessor :png_oversampling

    # PNG scale: how many pixels for one postscript point ?
    attr_accessor :png_scale

    # Settings up default postprocessing
    def initialize
      @view_all = false
      @viewer = false
      @svg = false

      @png_res = nil 
      @png_oversampling = 2
      @png_scale = 1

      @processed_files = []
    end


    # Process the given _file_. If _last_ is true, things that should
    # only happen last happen.
    def process_file(file, last = false)
      @processed_files << file
      # Converts to SVG if applicable
      if @svg
        target = file.sub(/(\.pdf)?$/,'.svg')
        info { "Converting #{file} to SVG" }
        spawn("pdf2svg #{file} #{target}")
      end

      if @eps
        target = file.sub(/(\.pdf)?$/,'.eps')
        info { "Converting #{file} to EPS" }
        ## \todo provide some facility to pass options to pdftops ?
        spawn("pdftops -eps -level2 -paper match #{file} #{target}")
      end

      # Converts to PNG if applicable
      if @png_res
        target = file.sub(/(\.pdf)?$/,'.png')
        info { "Converting #{file} to PNG" }
        spawn "convert -density #{(@png_oversampling * @png_scale * 72).to_i} #{file} -resize #{@png_res.join('x')} #{target}"
      end

      # View produced PDF or PNG files...
      if (last || @view_all) && @viewer
        if @png_res
          cmd = "display #{target}"
        elsif @viewer =~ /%s/
          cmd = @viewer % file
        else
          cmd = "#{@viewer} #{file}"
        end
        info { "Spawning the viewer as requested for #{file}" }
        spawn(cmd)
      end
    end


  end

end

