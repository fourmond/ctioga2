# utils.rb: Some small utility functions
# Copyright (c) 2006-2009 by Vincent Fourmond
  
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details (in the COPYING file).

# For platform detection
require 'rbconfig'

# The version
require 'ctioga2/version'

require 'set'


module CTioga2

  # An exception to raise upon to-be-implemented-one-day features
  class YetUnimplemented < Exception
  end

  
  # A small module to deal with versions and dates
  module Version

    # The current version of the program.
    def self.version
      return GIT_VERSION
    end


    # Returns the date ctioga2 was last modified.
    def self.last_modified_date
      return GIT_DATE
    end
  end

  # Various utilities
  module Utils
    # Takes a string a returns a quoted version that should be able to
    # go through shell expansion.
    def self.shell_quote_string(str)
      if str =~ /[\s"*$()\[\]{}';\\]/
        if str =~ /'/
          a = str.gsub(/(["$\\])/) { "\\#$1" }
          return "\"#{a}\""
        else 
          return "'#{str}'"
        end
      else
        return str
      end
    end

    # Converts a number to a float while trying to stay as lenient as
    # possible
    def self.txt_to_float(txt)
      v = txt.to_f
      if v == 0.0
        return Float(txt)
      end
      return v
    end

    # Takes two arrays of the same size (vectors) and mix them
    # a * r + b * (1 - r)
    def self.mix_objects(a,b,r)
      ret = a.dup
      a.each_index do |i|
        ret[i] = a[i] * r + b[i] * (1 - r)
      end
      return ret
    end

    # Quotes a string so it can be included directly within a
    # \pdfinfo statement (for instance).
    def self.pdftex_quote_string(str)
      return str.gsub(/([%#])|([()])|([{}~_^])|\\/) do 
        if $1
          "\\#{$1}"
        elsif $2                  # Quoting (), as they can be quite nasty !!
          "\\string\\#{$2}"
        elsif $3
          "\\string#{$3}"
        else                      # Quoting \
          "\\string\\\\"
        end
      end
    end

    # Quotes a string so it can be included directly within a
    # \pdfinfo statement (for instance).
    def self.tex_quote_string(str)
      return str.gsub(/([%#])|([{}~_^])|\\/) do 
        if $1
          "\\#{$1}"
        elsif $2
          "\\string#{$2}"
        else                      # Quoting \
          "\\string\\\\"
        end
      end
    end

    # Binomial coefficients (for the smooth filter)
    def self.cnk(n,k)
      res = 1.0
      n.downto(n - k) { |i| res *= i}
      k.downto(1) {|i| res = res/i }
      return res
    end

    # This converts a text formula that can contain:
    # * any litteral thing
    # * references to columns in the form of \$1 for column 1 (ie the
    #   second one)
    # * references to named columns in the form $name$
    # * references to parameters
    #
    # The return value is ready to be passed to Dvector.compute_formula
    def self.parse_formula(formula, parameters = nil, header = nil)
      formula = formula.dup
      if parameters
        for k,v in parameters
          formula.gsub!(/\b#{k}\b/, v.to_s)
        end
      end
      formula.gsub!(/\$(\d+)/, 'column[\1]')
      if header
        for k,v in header
          formula.gsub!("$#{k}$", "column[#{v}]")
        end
      end
      if formula =~ /(\$[^$]+\$)/
        raise  "'#{$1}' looks like a column name, but there is no corresponding column of that name"
      end
      return formula
    end

    # Sorts strings according to their numeric suffix
    def self.suffix_numeric_sort(strings)
      strings.sort do |a,b|
        a =~ /.*?(\d+)$/
        a_i = $1 ? $1.to_i : nil
        b =~ /.*?(\d+)$/
        b_i = $1 ? $1.to_i : nil
        
        if a_i && b_i
          a_i <=> b_i
        else
          a <=> b
        end
      end
    end


    # Groups the given strings by prefixes

    def self.group_by_prefix(strings, pref_re)
      sets_by_prefix = {}
      for s in strings
        pref = s
        if s =~ pref_re
          pref = $1
        end
        sets_by_prefix[pref] ||= []
        sets_by_prefix[pref] << s
      end
      return sets_by_prefix
    end



    NaturalSubdivisions = [1.0, 2.0, 5.0, 10.0]

    # Returns the closest element of the correct power of ten of
    # NaturalSubdivisions above or below the given number.
    #
    # If what is :below, returns the closest below. If what is :above,
    # returns the closest above. Else, returns the one the closest
    # between the two values.
    def self.closest_subdivision(x, what = :closest)
      fact = 10**(Math.log10(x).floor)

      normed_x = x/fact
      (NaturalSubdivisions.size()-1).times do |i|
        if normed_x == NaturalSubdivisions[i]
          return x
        end
        if (normed_x > NaturalSubdivisions[i]) && 
           (normed_x < NaturalSubdivisions[i+1])
          below = NaturalSubdivisions[i]*fact
          above = NaturalSubdivisions[i+1]*fact
          if what == :below
            return below
          elsif what == :above
            return above
          else
            if x*x/(below * above) > 1
              return above
            else
              return below
            end
          end
        end
      end
      raise "Should not reach this !"
    end


    # Returns the smallest power of 10 within the given buffer
    # (excluding 0 or anything really close). That is, if you multiply
    # by 10 to the power what is returned, the smallest will be in the
    # range 1-10.
    def self.common_pow10(vect, method = :floor, tolerance = 1e-8)
      a = vect.abs
      a.sort!
      while (a.size > 1) && (a.first < tolerance * a.last)
        a.shift
      end
      if a.first == 0
        return 0
      end

      return Math.log10(a.first).send(method)
    end


    # Transcodes the given string from all encodings into the target
    # encoding until an encoding is found in which the named file
    # exists.
    #
    # Works around encoding problems on windows.
    def self.transcode_until_found(file)
      if File.exists? file
        return file
      end
      begin                     # We wrap in a begin/rescue block for
                                # Ruby 1.8
        for e in Encoding::constants
          e = Encoding.const_get(e)
          if e.is_a? Encoding
            begin
              ts = file.encode(Encoding::default_external, e)
              if File.exists? ts
                return ts
              end
            rescue
            end
          end
        end
      rescue
      end
      return file               # But that will fail later on.
    end

    # Returns the biggest vector of multiples of delta contained
    # within bot and top
    def self.integer_subdivisions(bot, top, delta)
      if bot > top
        bot, top = top, bot
      end
      tn = (top/delta).floor
      bn = (bot/delta).ceil
      ret = Dobjects::Dvector.new()
      nb = (tn - bn).to_i + 1

      nb.times do |i|
        ret << (bn + i) * delta
      end
      return ret
    end

    # Takes a vector, and splits it into a series of contiguous
    # subvectors which 
    def self.split_homogeneous_deltas(vect, tolerance = 1e-4)
      rv = []
      idx = 1
      dx = nil
      lst = nil
      while idx < vect.size
        cdx = vect[idx] - vect[idx - 1]
        if ! dx 
          dx = cdx
          lst = Dobjects::Dvector.new()
          rv << lst
          lst << vect[idx-1] << vect[idx]
        else
          if (cdx - dx).abs <= tolerance * dx
            # keep going
            lst << vect[idx]
          else
            dx = nil
          end
        end
        idx += 1
      end

      # Flush the last one if alone
      if ! dx
        nv = Dobjects::Dvector.new()
        nv << vect.last
        rv << nv
      end
      return rv
    end


    # Cross-platform way of finding an executable in the $PATH.
    #
    # This is adapted from
    # http://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
    def self.which(cmd)
      return nil unless cmd
      exts = ['']
      if ENV['PATHEXT']
        exts += ENV['PATHEXT'].split(';')
      end

      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each { |ext|
          exe = File.join(path, "#{cmd}#{ext}")
          return exe if File.executable? exe
        }
      end
      return nil
    end


    # Reliable OS detection, coming from:
    #
    # http://stackoverflow.com/questions/11784109/detecting-operating-systems-in-ruby
    def self.os
      host_os = RbConfig::CONFIG['host_os']
      case host_os
      when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
        :windows
      when /darwin|mac os/
        :macosx
      when /linux/
        :linux
      when /solaris|bsd/
        :unix
      else
        warn {"Unknown os: #{host_os.inspect}"}
        :unknown
      end
    end


    # Cluster a series of objects by the values returned by the given
    # funcall. It returns an array of arrays where the elements are in
    # the same order, and in each sub-array, the functions all return
    # the same value
    #
    # @todo with block too ?
    def self.cluster_by_value(list, funcall)
      if list.size == 0
        return []
      end
      ret = [ [list[0]] ]
      cur = ret[0]
      last = cur.first.send(funcall)

      for o in list[1..-1]
        val = o.send(funcall)
        if last == val
          cur << o
        else
          cur = [o]
          ret << cur
          last = val
        end
      end

      return ret
     end


    # Returns a hash value -> [elements] in which the elements are in
    # the same order
    def self.sort_by_value(list, funcall)
      ret = {}
      
      for el in list
        val = el.send(funcall)
        ret[val] ||= []

        ret[val] << el
      end
      return ret
    end

  end
    

  # This class implements a Hash whose values can also be retrieved by
  # pattern matching.
  class RegexpHash

    # Hash for non regexp keys
    attr_accessor :hash

    # Hash for regexp keys
    attr_accessor :regexp_hash

    def initialize()
      @hash = {}
      @regexp_kv = []
    end

    # Sets the key to the given value
    def []=(key, value)
      if Regexp === key
        @regexp_kv <<  [key, value]
      else
        @hash[key] = value
      end
    end

    # Gets the value corresponding to the key, using pattern matching
    # should the need arise.
    #
    # If there are several regexps matching a given key, the
    # implementation guarantees that the last one to have been
    # inserted that matches is taken
    def [](key)
      if @hash.key?(key)
        return @hash[key]
      else
        for k,v in @regexp_kv.reverse
          if k === key
            return v
          end
        end
      end
      return nil
    end

    def keys_for(value)
      ret = []
      for k,v in @hash
        if value == v
          ret << k
        end
      end
      return ret
    end

  end


  # This class watches over a list of named texts and can be queried
  # for size/position information.
  class TextSizeWatcher

    # Watched text names
    attr_accessor :watched_names

    # A left, bottom, right, up bounding box (in output coordinates
    # divided by 10)
    attr_accessor :bb

    def initialize
      @watched_names = Set.new
    end

    def watch(*names)
      @watched_names += names
    end

    # Given the MarginsBox with which the text was drawn, returns
    # another MarginsBox item that specifies how much the text extends
    # from the previous box. Works using the current frame
    # coordinates.
    #
    # Padding in big points
    #
    # Min is the minimum size, also in big points. 
    def update_margins(t, margins, padding = 2, min = 4)
      compute_bb(t)
      if ! @bb
        # Don't change anything if the bounding box does not exist
        return margins
      end
      left, top, right, bottom = *margins.to_frame_coordinates(t)
      
      xl = 0.1 * t.convert_page_to_output_x(t.convert_frame_to_page_x(left))
      xr = 0.1 * t.convert_page_to_output_x(t.convert_frame_to_page_x(right))
      yt = 0.1 * t.convert_page_to_output_y(t.convert_frame_to_page_y(top))
      yb = 0.1 * t.convert_page_to_output_y(t.convert_frame_to_page_y(bottom))

      vals = [ xl - @bb[0], @bb[2] - xr, @bb[3] - yt, yb - @bb[1]].map do |x|
        x += padding
        x = if x > min
              x
            else
              min
            end
        Graphics::Types::Dimension.new(:bp, x)
      end

      return Graphics::Types::MarginsBox.
        new(*vals)
    end


    def compute_bb(t)

      @bb = nil

      for w in @watched_names
        info = t.get_text_size(w)
        if info.key? 'points'
          # We need to take every single point, since for rotated
          # text, potentially all coordinates are different
          for p in info['points']
            update_bb(*p)
          end
        end
      end
    end


    protected
    
    # update the current bounding box to take into account the given point
    def update_bb(x, y)
      if ! @bb
        @bb = [x,y,x,y]
      else
        if x < @bb[0]
          @bb[0] = x
        elsif x > @bb[2]
          @bb[2] = x
        end
        if y < @bb[1]
          @bb[1] = y
        elsif y > @bb[3]
          @bb[3] = y
        end
      end
    end

    
    
  end

end

######################################################################
# Now come a few functions that add to ruby's standard classes or
# modules

module Math

  # The absolute value, but in a more easy to use way
  def abs(x)
    return x.abs
  end
end



# Here, we define an additional function in the Hash class: without
class Hash

  # Returns a copy of the hash without the given keys
  def without(*args)
    ret = self.dup
    for a in args.flatten
      ret.delete(a)
    end
    return ret
  end

  # Renames the given key
  def rename_key(old, new)
    self[new] = self[old]
    self.delete(old)
  end

  # Strip the given keys if they evaluate to false
  def strip_if_false!(keys)
    for k in keys
      if key?(k) and (not self[k])
        self.delete(k)
      end
    end
  end

end


class String
  # Splits a string into substrings at the given regexp, but only if
  # the splitting occurs at top-level with respect to parentheses.
  def split_at_toplevel(regexp)
    # Groups
    grps = {} 
    
    sz = 0
    s = self.dup
    while true
      s.gsub!(/\([^()]+\)/) do |x|
        idx = grps.size
        rep = "__#{idx}__"
        grps[rep] = x
        rep
      end
      if sz == grps.size
        break
      else
        sz = grps.size
      end
    end
    
    splitted = s.split(regexp)
    
    while grps.size > 0
      for s in splitted
        s.gsub!(/__\d+__/) do |x|
          rep = grps[x]
          grps.delete(x)
          rep
        end
      end
    end
    return splitted
  end
end


