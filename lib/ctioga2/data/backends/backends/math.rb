# math.rb :the Math backend: data based on mathematical formulas.
# Copyright (C) 2006 - 2009 Vincent Fourmond

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

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Data

    module Backends

      class MathBackend < Backend
        
        include Dobjects
        include Math
      
        describe 'math', 'Mathematical functions', <<EOD
This backend returns computations of mathematical formulas.
EOD

        # TODO: make provisions for 3-D datasets. Ideas: x(t):y(t):z(t)
        # for parametric plots ? (possibly x(t):y1(t):y2(t):...:yn(t)) ?

        param_accessor :samples, 'samples', "Samples",
        {:type => :integer}, "The number of points"
        param_accessor :x_range, 'xrange',  "X Range", 
        {:type => :float_range}, "X range (a:b)"
        param_accessor :t_range, 'trange',  "T Range", 
        {:type => :float_range}, "T range (a:b) (parametric plot)"

        param_accessor :log, 'log',  "Logarithmic scale", 
        {:type => :boolean}, "Space samples logarithmically"
        
        def initialize
          super()
          @samples = 100
          @x_range = -10.0..10.0
          @t_range = -10.0..10.0
          @log = false
        end

        # This is called by the architecture to get the data. It first
        # splits the set name into func@range.
        def query_dataset(set)
          if set =~ /(.*)@(.*)/
            set = $1
            range = $2
          end          
          name = "math: #{set}"
          if set =~ /:/         # parametric
            if range
              set_param_from_string(:t_range, range)
            end
            varname = "t"
            values = make_dvector(@t_range, @samples, @log)
          else
            if range
              set_param_from_string(:x_range, range)
            end
            varname = "x"
            values = make_dvector(@x_range, @samples, @log)
            set = "x:#{set}"
          end
          return Dataset.dataset_from_spec(name, set) do |b|
            get_data_column(b, varname, values)
          end
        end


        protected
        
        # Turns a Range and a number of points into a Dvector
        def make_dvector(range, nb_points, log = @log)
          n = nb_points -1
          a = Dvector.new(nb_points) { |i| 
            i.to_f/(n.to_f)
          }
          # a is in [0:1] inclusive...
          if log
            delta = range.last/range.first
            # delta is positive necessarily
            a *= delta.log
            a.exp!
            a *= range.first
          else
            delta = range.last - range.first
            a *= delta
            a += range.first
          end
          return a
        end

        # Uses compute_formula to get data from 
        def get_data_column(column, variable, values)
          column.gsub!(/\b#{variable}\b/, "(column[0])")
          Dvector.compute_formula(column, [values])
        end


      end
    end
  end
end
