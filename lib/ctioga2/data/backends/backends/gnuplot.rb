# gnuplot.rb: a backend to extract plots from gnuplot's files
# Copyright (C) 2007,2009 Vincent Fourmond

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA



require 'Dobjects/Dvector'
require 'Dobjects/Function'

# To feed data to fancyread
require 'stringio'

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')


  module Data

    module Backends

      class GnuplotBackend < Backend

        include Dobjects
        include Log
        
        describe 'gnuplot', 'Gnuplot files', <<EOD
This backend hijacks gnuplot files to make extract data which they plot.
No information is taken about the style !
EOD

        param_accessor :variables_overrides, 'vars', 
        "Variable overrides", 'text', <<EOD
A colon-separated override of local variables, such as a=1;b=3;c=5
EOD

        param_accessor :range, 'range', 
        "Plotting X range", 'float-range', 
        "The plotting X range, such as 0:2"

        param_accessor :samples, 'samples', 
        "The number of samples", 'text', 
        "The number of samples"
        
        # This is called by the architecture to get the data. It splits
        # the set name into filename@cols, reads the file if necessary and
        # calls get_data
        def query_dataset(set)
          set =~ /^(.*?)(?:@(\d+))?(?::(.*))?$/
          filename = $1
          if $2
            number = $2.to_i - 1
          else
            number = 0
          end
          if $3
            overrides = "#{@variable_overrides};#{$3}"
          else
            overrides = @variable_overrides
          end
          plots = run_gnuplot(filename, overrides)
          return Dataset.new(set,plots[number])
        end

        # Runs gnuplot on the file, and returns all datasets found
        # inside it. 
        def run_gnuplot(filename, overrides = @variables_overrides)
          date = File::mtime(filename)
          # Get it from the cache !
          debug { "Running gnuplot on file #{filename}" }
          f = File.open(filename)
          # We open a bidirectionnal connection to gnuplot:
          gnuplot = IO.popen("gnuplot", "r+")
          output = ""
          ## \todo determine gnuplot version for choosing which one we
          ## want to use.
          # gnuplot.puts "set term table"
          gnuplot.puts "set table"
          if @samples
            overrides ||= ""
            overrides += ";set samples #{@samples}"
          end
          for line in f
            next if line =~ /set\s+term/
            if overrides and line =~ /plot\s+/
              debug { 
                "Found a plot, inserting variable overrides: #{overrides}" 
              }
              line.gsub!(/plot\s+/, "#{overrides};plot ")
            end
            if @range and line =~ /plot\s+/
              debug { 
                "Found a plot, inserting range: #{@range}" 
              }
              line.gsub!(/plot\s+(\[[^\]]+\])?/, 
                         "plot [#{@range}]")
            end
            gnuplot.print line 
            gnuplot.flush
            output += slurp(gnuplot)
          end
          
          # Output a "\n" in the end.
          
          gnuplot.puts ""
          gnuplot.flush
          gnuplot.close_write
          # Then we get all that is remaining:
          output += gnuplot.read
          gnuplot.close
          
          # Now, interaction with gnuplot is finished, and we want to
          # parse that:
          outputs = output.split("\n\n")
          plots = []
          for data in outputs
            plots << Dvector.fancy_read(StringIO.new(data), [0,1])
          end
          # This block evaluates to plots:
          return plots
        end

        # Gets all data from the given file until it blocks, and returns it.
        def slurp(f, size = 10240)
          str = ""
          begin
            while IO::select([f],[],[],0)
              ret = f.readpartial(size)
              if ret.empty?
                return str
              end
              str << ret 
            end
          end
          return str
        end

      end

    end
  end
end
