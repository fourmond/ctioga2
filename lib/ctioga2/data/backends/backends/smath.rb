# smath.rb :multi-dimensional math backend
# Copyright (C) 2014 Vincent Fourmond

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

  module Data

    module Backends

      class SMathBackend < Backend
        
        include Dobjects
        include Math
      
        describe 'smath', 'Mathematical functions (multi-D)', <<EOD
This backends computes mathematical formulas of two or more variables
EOD

        param_accessor :samples, 'samples',  "Sample number", 'integer', 
        "Number of samples (default, overriden by variable-specific specs)"


        param_accessor :u_range, 'urange',  "U Range", 'float-range', 
        "U range (a:b)"

        param_accessor :u_samples, 'usamples',  "U samples", 'integer', 
        "Number of U samples"

        param_accessor :v_range, 'vrange',  "V Range", 'float-range', 
        "V range (a:b)"

        param_accessor :v_samples, 'vsamples',  "V samples", 'integer', 
        "Number of V samples"

        def initialize
          super()
          @samples = 30
          @u_range = -10.0..10.0
          @v_range = -10.0..10.0
        end

        # This is called by the architecture to get the data. It first
        # splits the set name into func@range.
        def query_dataset(set)
          name = "#{set}"

          u_values = make_dvector(@u_range, @u_samples || @samples)
          v_values = make_dvector(@v_range, @v_samples || @samples)

          if ! (set.split_at_toplevel(/:/).size > 1)
            set = "u:v:#{set}"
          end

          val_u = Dvector.new
          val_v = Dvector.new
          for u in u_values
            for v in v_values
              val_u << u
              val_v << v
            end
          end

          

          return Dataset.dataset_from_spec(name, set) do |b|
            get_data_column(b, [val_u, val_v])
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
        def get_data_column(column, values)
          column.gsub!(/\b(u|v)\b/) do
            cl = if $1 == 'u'
                   0
                 else
                   1
                 end
            "(column[#{cl}])"
          end
          return Ruby.compute_formula(column, values)
        end

        
      end
    end
  end
end
