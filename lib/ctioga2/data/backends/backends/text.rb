# text.rb : A simple backend to deal with basic text files.
# Copyright (C) 2006 Vincent Fourmond

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

# For separated sets
require 'stringio'

module CTioga2

  Version::register_svn_info('$Revision: 917 $', '$Date: 2009-03-14 23:00:06 +0100 (Sat, 14 Mar 2009) $')


  module Data

    # A module for easy use of NaN in operations
    module NaN
      NaN = 0.0/0.0
      def nan
        return NaN
      end
    end

    module Backends

      class TextBackend < Backend

        # A constant holding a relation extension -> command to
        # decompress (to be fed to sprintf with the filename as argument)
        UNCOMPRESSORS = {
          ".gz" => "gunzip -c %s",
          ".bz2" => "bunzip2 -c %s",
          ".lzma" => "unlzma -c %s",
          ".lz" => "unlzma -c %s",
        }

        include Dobjects

        describe 'text', 'Text format', <<EOD
This backend can read text files in a format close to the one understood
by gnuplot and the like.
EOD

        # Inherit the baseline handling, can be useful !
        inherit_parameters :base_line
        
        param_accessor :skip, 'skip', "Skip lines", {:type => :integer}, 
        "Number of lines to be skipped at the beginning of the file"

        param_accessor :default_column_spec, 'col', 
        "Default column specification", {:type => :string}, 
        "Which columns to use when the @1:2 syntax is not used"

        param_accessor :split, 'split', "Split into subsets", 
        {:type => :boolean}, 
        "If true, splits files into subsets on blank/non number lines"


        param_accessor :separator, 'separator', "Data columns separator", 
        {:type => :string_or_regexp}, 
        "The columns separator. Defaults to /\s+/"


        #     param_accessor :select, 'select', "Select lines", {:type => :string},
        #     "Skips line where the code returns false"
        
        def initialize
          @dummy = nil
          @current = nil   
          # Current is the name of the last file used. Necessary for '' specs.
          @current_data = nil       # The data of the last file used.
          @skip = 0
          @included_modules = [NaN]    # to make sure we give them to
          # Dvector.compute_formula
          @default_column_spec = "1:2"

          @separator = /\s+/

          # We don't split data by default.
          @split = false

          super()

          # Override Backend's cache - for now.
          @cache = {}               # A cache file_name -> data

        end

        def extend(mod)
          super
          @included_modules << mod
        end

        # Expands specifications into few sets. This function will separate the
        # set into a file spec and a col spec. Within the col spec, the 2##6
        # keyword is used to expand to 2,3,4,5,6. 2## followed by a non-digit
        # expands to 2,...,last column in the file. For now, the expansions
        # stops on the first occurence found, and the second form doesn't
        # work yet. But soon...
        def expand_sets(spec)
          if m = /(\d+)##(\D|$)/.match(spec)
            a = m[1].to_i 
            trail = m[2]
            b = read_file(spec)
            b = (b.length - 1) 
            ret = []
            a.upto(b) do |i|
              ret << m.pre_match + i.to_s + trail + m.post_match
            end
            return ret
          else
            return super
          end
        end


        protected


        # Returns a IO object suitable to acquire data from it for
        # the given _file_, which can be one of the following:
        # * a real file name
        # * a compressed file name
        # * a pipe command.
        def get_io_object(file)
          if file == "-"
            return $stdin
          elsif file =~ /(.*?)\|\s*$/ # A pipe
            return IO.popen($1)
          elsif not File.readable?(file)
            # Try to find a compressed version
            for ext,method in UNCOMPRESSORS
              if File.readable? "#{file}#{ext}"
                info "Using compressed file #{file}#{ext} in stead of #{file}"
                return IO.popen(method % "#{file}#{ext}")
              end
            end
          else 
            for ext, method in UNCOMPRESSORS
              if file =~ /#{ext}$/ 
                info "Taking file #{file} as a compressed file"
                return IO.popen(method % file)
              end
            end
            return File::open(file)
          end
          error "Could not open #{file}"
          return nil
        end

        # A line is invalid if it is blank or starts
        # neither with a digit nor +, - or .
        #
        # Maybe to be improved later.
        InvalidLineRE = /^\s*$|^\s*[^\d+.\s-]+/

        # Returns a string corresponding to the given _set_ of the
        # given _io_ object.
        #
        # Sets are 1-based.
        def get_set_string(io, set)
          cur_set = 1
          last_line_is_invalid = true
          str = ""
          line_number = 0
          while line = io.gets
            line_number += 1
            if line =~ InvalidLineRE
              debug "Found invalid line at #{line_number}"
              if ! last_line_is_invalid
                # We begin a new set.
                cur_set += 1
                debug "Found set #{cur_set} at line #{line_number}"
                if(cur_set > set)
                  return str
                end
              end
              last_line_is_invalid = true
            else
              last_line_is_invalid = false
              if cur_set == set
                str += line
              end
            end
          end
          return str
        end

        # Returns an IO object corresponding to the given file.
        def get_io_set(file)
          if not @split
            return get_io_object(file)
          else
            file =~ /(.*?)(?:#(\d+))?$/; # ; to make ruby-mode indent correctly.
            filename = $1
            if $2
              set = $2.to_i
            else
              set = 1
            end
            debug "Trying to get set #{set} from file '#{filename}'"
            str = get_set_string(get_io_object(filename), set)
            return StringIO.new(str)
          end
        end

        # Reads data from a file. If needed, extract the file from the
        # columns specification.
        #
        # TODO: the cache really should include things such as time of
        # last modification and various parameters that influence the
        # reading of the file.
        def read_file(file)
          if file =~ /(.*)@.*/
            file = $1
          end
          name = file               # As file will be modified.
          if ! @cache.key?(file)    # Read the file if it is not cached.
            fancy_read_options = {'index_col' => true,
              'skip_first' => @skip,
              'sep' => @separator
            }
            io_set = get_io_set(file)
            debug "Fancy read '#{file}', options #{fancy_read_options.inspect}"
            @cache[name] = Dvector.fancy_read(io_set, nil, fancy_read_options)
          end
          return @cache[name]
        end


        # This is called by the architecture to get the data. It
        # splits the set name into filename@cols, reads the file if
        # necessary and calls get_data
        def query_dataset(set)
          if set =~ /(.*)@(.*)/
            col_spec = $2
            file = $1
          else
            col_spec = @default_column_spec
            file = set
          end
          if file.length > 0
            @current_data = read_file(file)
            @current = file
          end

          # Wether we need or not to compute formulas:
          if col_spec =~ /\$/
            compute_formulas = true
          else
            compute_formulas = false
          end
          
          return Dataset.dataset_from_spec(set, col_spec) do |col|
            get_data_column(col, compute_formulas)
          end
        end

        # Gets the data corresponding to the given column. If
        # _compute_formulas_ is true, the column specification is
        # taken to be a formula (in the spirit of gnuplot's)
        def get_data_column(column, compute_formulas = false)
          if compute_formulas
            formula = column.gsub(/\$(\d+)/, 'column[\1]')
            debug "Using formula #{formula} for column spec: #{column}"
            return Dvector.compute_formula(formula, 
                                           @current_data,
                                           @included_modules)
          else
            return @current_data[column.to_i].dup
          end
        end

#         # Turns a target => values specification into something usable as
#         # error bars, that is :xmin, :xmax and the like hashes. The rules
#         # are the following:
#         # * ?min/?max are passed on directly;
#         # * ?e(abs) are transformed into ?min = ? - ?eabs, ?max = ? + ?eabs
#         # * ?eu(p/?ed(own) are transformed respectively into ? +/- ?...
#         # * ?er(el) become ?min = ?*(1 - ?erel, ?max = ?(1 + ?erel)
#         # * ?erup/?erdown follow the same pattern...
#         def compute_error_bars(values)
#           target = {}
#           for key in values.keys
#             case key.to_s
#             when /^[xy](min|max)?$/
#               target[key] = values[key].dup # Just to make sure.
#             when /^(.)e(a(bs?)?)?$/
#               target["#{$1}min".to_sym] = values[$1.to_sym] - values[key]
#               target["#{$1}max".to_sym] = values[$1.to_sym] + values[key]
#             when /^(.)eu(p)?$/
#               target["#{$1}max".to_sym] = values[$1.to_sym] + values[key]
#             when /^(.)ed(o(wn?)?)?$/
#               target["#{$1}min".to_sym] = values[$1.to_sym] - values[key]
#             when /^(.)er(el?)?$/
#               target["#{$1}min".to_sym] = values[$1.to_sym] * 
#                 (values[key].neg + 1)
#               target["#{$1}max".to_sym] = values[$1.to_sym] * 
#                 (values[key] + 1)
#             when /^(.)erd(o(wn?)?)?$/
#               target["#{$1}min".to_sym] = values[$1.to_sym] * 
#                 (values[key].neg + 1)
#             when /^(.)erup?$/
#               target["#{$1}max".to_sym] = values[$1.to_sym] * 
#                 (values[key] + 1)
#             else
#               warn "Somehow, the target specification #{key} " +
#                 "didn't make it through"
#             end
#           end
#           return target
#         end

      end
      
    end

  end
end
