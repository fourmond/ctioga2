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

    # Are we cleaning up the PDF produced using gs (in particular, to
    # include missing markers and such, that are known to cause
    # problems from time to time).
    #
    # @todo Path to gs...
    attr_accessor :cleanup_pdf


    # @todo Maybe all the PNG stuff should be it is own class ?

    # If on, we use pdftoppm rather than imagemagick (gs, used by
    # pdftoppm is much slower than pdftoppm)
    attr_accessor :png_pdftoppm

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
      @png_pdftoppm = false

      @processed_files = []

      gs = Utils::which('gs')
      @cleanup_pdf = (gs ? true : false)
    end


    # Try to open the file with xpdf, or fallback to system defaults
    def view_pdf(pdf)
      if Utils.which("xpdf")
        spawn(["xpdf", "-z", "page", pdf])
      else
        case Utils.os
        when :windows
          # Use start
          spawn(["start", "/B", pdf])
        when :macosx
          spawn(["open", pdf])
        else
          for w in %w{evince gv mimeopen}
            if Utils.which(w)
              if w == "mimeopen"
                spawn(["mimeopen", "-n", pdf])
              else
                spawn([w, pdf])
              end
              break
            end
          end
        end
      end
    end


    # Process the given _file_. If _last_ is true, things that should
    # only happen last happen.
    def process_file(file, last = false)
      @processed_files << file


      if @cleanup_pdf
        nw_src = file.sub(/(\.pdf)?$/,'.raw.pdf')
        begin
          File::rename(file, nw_src)
          info { "Running gs to clean up the target PDF file: '#{file}'" }
          if ! system('gs', "-sOutputFile=#{file}", "-q", "-sDEVICE=pdfwrite",
                      "-dCompatibilityLevel=1.4", "-dNOPAUSE", "-dAutoRotatePages=/None", "-dBATCH", "-dPDFSETTINGS=/prepress", nw_src)
            error { "Failed to run gs to cleanup '#{nw_src}', you can disable that using --no-cleanup-pdf" }
          else
            File::unlink(nw_src)
          end
        rescue SystemCallError => e
          error { "Could not rename '#{file}' to '#{nw_src}': #{e.message}, try using --no-cleanup-pdf, or resolve the problem otherwise" }
        end
      end
      
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
        tbase = file.sub(/(\.pdf)?$/,'')
        info { "Converting #{file} to PNG" }
        
        if @png_pdftoppm
          spawn "pdftoppm -singlefile -png -r #{(@png_scale * 72).to_i} #{file} #{tbase}"
        else
          spawn "convert -density #{(@png_oversampling * @png_scale * 72).to_i} #{file} -resize #{@png_res.join('x')} #{tbase}.png"
        end
      end

      # View produced PDF or PNG files...
      if (last || @view_all) && @viewer
        if @viewer == :auto
          view_pdf(file)
        else
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

end

