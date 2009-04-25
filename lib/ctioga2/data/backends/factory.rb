# factory.rb : a class holdling a set of Backends
# Copyright (C) 2009 Vincent Fourmond
 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA

require 'ctioga2/utils'
require 'ctioga2/data/backends/backend'

module CTioga2

  Version::register_svn_info('$Revision: 913 $', '$Date: 2009-03-13 17:45:34 +0100 (Fri, 13 Mar 2009) $')

  module Data

    module Backends

      # This class holds an instance of all the different Backend
      # available, and features a 'current backend'.
      class BackendFactory

        # A hash name (as in Description#name) -> Backend
        attr_accessor :backends

        # The current Backend
        attr_accessor :current

        # Creates a new BackendFactory
        def initialize(default)
          @backends = {}
          @backend_descriptions = Backend.list_backends
          for backend in @backend_descriptions.keys
            reset_backend(backend)
            # Add commands
            @backend_descriptions[backend].create_backend_commands
          end
          @current = @backends[default]
        end

        # Resets the given backend to its default values.
        def reset_backend(backend)
          @backends[backend] = @backend_descriptions[backend].instantiate
        end

        # Selects the current backend
        def set_current_backend(backend)
          @current = @backends[backend]
        end

        
        # Sets the (raw) value of the parameter of the given backend
        def set_backend_parameter_value(backend, param, value)
          b = @backends[backend]
          # This is way too complicated !
          b.description.param_hash[param].set_value(b, value)
        end
        
      end

    end
  end
end
