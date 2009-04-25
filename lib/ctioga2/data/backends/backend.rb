# backend.rb : The base of the arcitecture of the Backends
# Copyright (C) 2006, 2009 Vincent Fourmond

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


require 'ctioga2/utils'
require 'ctioga2/data/backends/description'

module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')
  

  module Data

    # The Backends are in charge of acquiring DataSet from various
    # data sources.
    module Backends
      
      # This class provides the infrastructure for accessing data sets. It
      # shouldn't be used directly, but rather subclassed and reimplemented.
      # The aim of this class is to provide any software which is interested
      # to retrive data from some source with a consistent way to do so,
      # independent the kind of source accessed.
      #
      # TODO: update documentation.
      #
      # Subclasses should:
      # * provide a consistent method for creating themselves,
      #   with as much information as necessary, including options and default
      #   parameters. Actually, their initialize function should take no value
      #   but on the other side, the BackendDescription associated with it
      #   should make it easy to set all the parameters necessary to
      #   get one set of data.
      # * provide a way to fill an OptionParser with their own parameters
      # * provide a way to retrieve the data via named 'sets' (either 2D or 3D
      #   data, depending on the subclass)
      # * provide a way to obtain all meta-informations on one dataset,
      #   such as the date, the meaning of the columns (if any), and so on.
      # * provide a way to know which named sets are available, or at least
      #   a subset (or nothing if we don't know a thing).
      # * wether the actual reading of the data is done at initialization time
      #   or at query time is left to the implementor ;-) !
      #
      # TODO: adapt to the new structure.
      #
      # TODO: add back filters (with time)
      #
      # TODO: add a Cache ?
      class Backend

        # Include logging facilities...
        include CTioga2::Log

        # Import the main description functions into the appropriate
        # namespaces
        extend  BackendDescriptionExtend

        # Backend is a factory, but no autoregistering is made.
        create_factory false

        # Sets up a few things, such as the filters.
        def initialize
        end

        # Returns the BackendDescription associated with this Backend.
        def description
          return self.class.description
        end

        # Creates a description object with the given texts and
        # associates it with the class. It is necessary to have this
        # statement *before* any parameter declaration. If you don't
        # set any description, you will not be able to benefit from
        # the plugin system.  To be used in Backend subclasses, simply
        # this way:
        #
        #  describe "biniou", "Biniou backend", "A backend to deal with Binious"
        #
        def Backend.describe(name, longname, desc, register = true)
          d = BackendDescription.new(self, name, longname, desc, register)
          set_description(d)
        end

        # Returns a hash containing the description of all available
        # backends
        def Backend.list_backends
          return factory_description_hash
        end

        describe 'backend', 'The base class for backends', <<EOD, false
This is the base class for backends. It should never be used directly.
EOD

        # A hook to set a baseline:
        param_reader :base_line=, :base_line, "baseline", "Base line",
        {:type => :string, }, "Sets a baseline for subsequent data sets"


        # TODO...
        def base_line=(str)
          if str =~ /^no$/ or str.empty?
            @base_line = ""
          else
            @base_line = expand_sets(str)[0]
            # Fill the cache.
            ary = query_xy_data(@base_line)
            @base_line_cache = if ary.is_a?(Array)
                                 ary[0]
                               else
                                 ary
                               end
          end
        end

        # Returns true if the backend can provide data for the given set.
        def has_set?(set)
          return false
        end
        
        alias set? has_set?


        # Public interface to query DataSet from a Backend. Children
        # must redefine #query_dataset rather than this function. This
        # function also applies filters and does othe kinds of
        # transformations
        def dataset(set)
          return query_dataset(set)
        end


        # When converting a user input into a set, a program should
        # *always* use this function, unless it has really good
        # reasons for that.
        #
        # The default implementation is to expand 2##4 to 2, 3, 4. Can
        # be useful even for mathematical stuff.
        #
        # Another thing is recognised and expanded: #<2<i*2>,5> runs
        # the code i*2 with the values from 2 to 5 and returns the
        # result. The code in the middle is a Ruby block, and
        # therefore should be valid !
        #
        # A third expansion is now available: #<a = 2<a * sin(x)>10>
        # will expand into 2*sin(x) , 3*sin(x) ... 10*sin(x) it is
        # different than the previous in the sense that the code in
        # the middle is not a Ruby code, but a mere string, which
        # means there won't be compilation problems.
        #
        # Unless your backend can't accomodate for that, all
        # redefinitions of this function should check for their
        # specific signatures first and call this function if they
        # fail. This way, they will profit from improvements in this
        # code while keeping old stuff working.
        def expand_sets(spec)
          if m = /(\d+)##(\d+)/.match(spec)
            debug "Using expansion rule #1"
            a = m[1].to_i
            b = m[2].to_i
            ret = []
            a.upto(b) do |i|
              ret << m.pre_match + i.to_s + m.post_match
            end
            return ret
          elsif m = /\#<(\d+)<(.*?)>(\d+)>/.match(spec)
            debug "Using expansion rule #2"
            from = m[1].to_i
            to = m[3].to_i
            debug "Ruby code used for expansion: {|i| #{m[2]} }"
            code = eval "proc {|i| #{m[2]} }"
            ret = []
            from.upto(to) do |i|
              ret << m.pre_match + code.call(i).to_s + m.post_match
            end
            return ret
          elsif m = /\#<\s*(\w+)\s*=\s*(\d+)\s*<(.*?)>\s*(\d+)\s*>/.match(spec)
            debug "Using expansion rule #3"
            var = m[1]
            from = m[2].to_i
            to = m[4].to_i
            # Then we replace all occurences of the variable
            literal = '"' + m[3].gsub(/\b#{var}\b/, '#{' + var + '}') + '"'
            debug "Ruby code used for expansion: {|#{var}| #{literal} }"
            code = eval "proc {|#{var}| #{literal} }"
            ret = []
            from.upto(to) do |i|
              ret << m.pre_match + code.call(i).to_s + m.post_match
            end
            return ret
          end
          # Fallback
          return [spec]
        rescue  Exception => ex
          # In case something went wrong in the eval.
          warn "An error occured during expansion of '#{spec}': #{ex.message}"
          debug "Error backtrace: #{ex.backtrace.join "\n"}"
          warn "Ignoring, but you're nearly garanteed something will "+
            "fail later on"
          return [spec]
        end

        # Some backends have a pretty good idea of the sets available
        # for use. Some really don't. You can choose to reimplement
        # this function if you can provide a useful list of sets for
        # your backend. This list doesn't need to be exhaustive (and
        # is most unlikely to be). It can also return something that
        # would need further expansion using expand_sets.
        def sets_available
          return []
        end


        # Functions for directly setting/getting parameters

        # Directly set a named parameter
        def set_param_from_string(param, string)
          description.param_hash[param].set_from_string(self, string)
        end

        protected 

        # Returns a DataSet object for the given _set_. Must be
        # reimplemented by children. The public interface is #dataset.
        #
        # It is *strongly* *recommended* to use
        # Dataset.dataset_from_spec to create the Dataset return
        # values in reimplementations.
        def query_dataset(set)
          raise "query_dataset must be redefined by children !"
        end

        # Gets a cached entry or generate it and cache it. See
        # Cache#cache for more details. The cache's meta_data is
        # constructed as following:
        # 
        # * the current state of the backend is taken
        # * keys inside _exclude_ are removed.
        # * _supp_info_ is added
        #
        # TODO: get the implementation back again.
        def get_cached_entry(name, exclude = [], supp_info = {}, &code)
          state = save_state
          for k in exclude
            state.delete(k)
          end
          state.merge!(supp_info)
          return @cache.get_cache(name, state, &code)
        end


      end
    end
  end
end
