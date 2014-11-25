# base.rb: the base of style objects
# copyright (c) 2009, 2012 by Vincent Fourmond
  
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details (in the COPYING file).

require 'ctioga2/log'

# This module contains all the classes used by ctioga
module CTioga2

  module Graphics

    # All the styles
    module Styles

      # This style is the base class of a series of style objects that
      # share one common feature: all their attributes can be set
      # using the #set_from_hash function.
      class BasicStyle

        OldAttrAccessor = method(:attr_accessor)

        AllStyles = []

        def self.normalize_in(name)
          name = name.to_s.downcase.gsub('-', '_')
          if @aliases && @aliases.key?(name)
            name = @aliases[name]
          end
          return name
        end

        def self.normalize_out(name)
          return name.gsub('_', '-')
        end

        def self.normalize_hash(hsh)
          ret = {}
          for k,v in hsh
            ret[normalize_in(k)] = v
          end
          return ret
        end

        def self.inherited(cls)
          AllStyles << cls
        end

        # This redefinition of attr_accessor allows to track for the
        # names of the attributes, while still showing them up
        # properly documented in rdoc.
        def self.attr_accessor(symbol)
          cal = caller
          # if ! (caller[0] =~ /typed_attribute/)
          #   puts "Deprecated use at #{caller[0]}"
          # end
          @attributes ||= []
          @attributes << symbol
          OldAttrAccessor.call(symbol)
        end

        # Returns the list of attributes.
        def self.attributes
          return ( @attributes || [] ) + 
            if superclass.respond_to?(:attributes)
              superclass.attributes
            else
              []
            end
        end

        def self.defined_aliases
          return @aliases || {}
        end

        # Returns the type of all attributes (chaining to the parent
        # when applicable)
        def self.attribute_types
          return ( @attribute_types || {} ).
            merge(
                  if superclass.respond_to?(:attribute_types)
                    superclass.attribute_types
                  else
                    {}
                  end
                  )
        end

        # This function should be the main way now of declaring
        # attributes, as it allows one to automatically generate an
        # options hash for Command
        #
        # @todo There may be a reason to make some of the attributes
        # private to some extent ?
        #
        # @todo Provide a function to make attributes "aliases" of
        # others (but just on the hash side of the things), in order
        # for instance to have halign and valign as aliases for the
        # less intuitive alignment and justification.
        def self.typed_attribute(symbol, type)
          sym = symbol.to_sym
          self.attr_accessor(sym)
          # The unless type.respond_to? :string_to_type seems
          type = CmdArg.new(type) # unless type.respond_to? :string_to_type
          @attribute_types ||= {}
          @attribute_types[sym] = type
          return type
        end

        # Define an attribute to be the alias for something else.
        #
        # @todo Maybe make multiple aliases ?
        def self.alias_for(what, target, define_methods = false)
          target = self.normalize_in(target)
          what = self.normalize_in(what)
          @aliases ||= {}
          @aliases[what] = target
          if define_methods
            alias_method what.to_sym, target.to_sym
            alias_method "#{what}=".to_sym, "#{target}=".to_sym
          end
        end

        # Returns the type of an attribute, or _nil_ if there is no
        # attribute of that name. Handles sub-styles correctly.
        def self.attribute_type(symbol, fmt = "%s")
          name = self.normalize_in(symbol.to_s)

          for k,v in attribute_types
            if (fmt % k.to_s) == name
              if v.respond_to? :type
                return v.type
              else
                return v
              end
            end
          end

          if @sub_styles        # Not always present too
            for sub in @sub_styles
              sym, cls, fmt2, fc = *sub
              f = fmt % fmt2
              ret = cls.attribute_type(name, f)
              return ret if ret
            end
          end
          return nil
        end

        # Adds a deprecated typed attribute
        def self.deprecated_attribute(symbol, type, message = true)
          type = self.typed_attribute(symbol, type)
          type.option_deprecated = message
        end

        # Defines an accessor for an attribute which is a BasicStyle
        # subclass in itself.
        #
        # _fmt_ is the thing fed to the subclass for the
        # _from_hash_ function.
        #
        # if _force_create_ is on, then the corresponding sub-object
        # is created even if no property we set within. 
        def self.sub_style(symbol, cls, fmt = nil, force_create = false)
          @sub_styles ||= []    # A list of [symbol, cls, fmt]
          
          if ! fmt
            fmt = "#{symbol.to_s}_%s"
          end
          
          @sub_styles << [symbol, cls, fmt, force_create]
          # Define the accessor
          OldAttrAccessor.call(symbol)
        end

        # Returns a hash suitable for using as an options hash.
        #
        # _key_ provides tuning of the key names.
        def self.options_hash(key = "%s")
          ret = if superclass.respond_to?(:options_hash)
                  superclass.options_hash(key)
                else
                  {}
                end

          if @attribute_types   # Not always present
            for k, v in @attribute_types
              ret[key % k] = v
            end
          end
            
          if @sub_styles        # Not always present too
            for sub in @sub_styles
              sym, cls, fmt, fc = *sub
              fmt = key % fmt
              ret.merge!(cls.options_hash(fmt))
            end
          end

          # And now we expand options
          if @aliases
            for k, v in @aliases
              if ret.key?(v)
                ret[k] = ret[v]
              end
            end
          end

          return ret
        end

        def self.sub_styles
          return @sub_styles
        end

        # Sets the values of the attributes from the given
        # _hash_. Keys are looked under the form of
        # 
        #  name % key_name
        #  
        # where _key_name_ takes all the values of the attributes.
        #
        # Unspecified attributes are not removed from the
        # object. Extra keys are silently ignored.
        #
        # @todo Maybe there should be a way to detect extra attributes ?
        #
        # This function returns the number of properties that were
        # effectively set (including those set in sub-styles)
        def set_from_hash(hash, name = "%s")
          hash = self.class.normalize_hash(hash)
          nb_set = 0
          for key_name in self.class.attributes
            hash_key = name % key_name
            if hash.key? hash_key 
              self.send("#{key_name}=", hash[hash_key])
              nb_set += 1
            end
          end

          if self.class.sub_styles
            for sub in self.class.sub_styles
              sym, cls, fmt, fc = *sub
              cur_var = self.send(sym)
              if ! cur_var        # Create if not present
                cur_var = cls.new
                set_after = true
              end
              fmt = name % fmt
              nb = cur_var.set_from_hash(hash, fmt)

              # Here, this means that missing attributes do not get
              # created.
              if (nb > 0 or fc)  and set_after
                self.send("#{sym}=", cur_var)
              end
              nb_set += nb
            end
          end
          return nb_set
            
        end

        # Creates a new object from a hash specification, just as in
        # #set_from_hash.
        def self.from_hash(hash, name = "%s")
          obj = self.new
          obj.set_from_hash(hash, name)
          return obj
        end

        # We define instance_variable_defined? if Ruby does not have
        # it... Old Ruby 1.8 versions don't - that is the case for
        # those on MacOS.
        if not self.respond_to?(:instance_variable_defined?)
          def instance_variable_defined?(iv)
            a = instance_variables.index(iv)
            if a && a >= 0 
              return true
            else
              return false
            end
          end
        end

        # Converts to a hash. Does the reverse of #set_from_hash.
        #
        # _nil_ values get stripped off (but not false values, of course).
        def to_hash(name = "%s")
          retval = {}
          for attr in self.class.attributes
            if instance_variable_defined?("@#{attr}")
              val = instance_variable_get("@#{attr}")
              if ! val.nil?
                retval[name % attr] = val
              end
            end
          end
          return retval
        end

        # Updates information from another object.
        def update_from_other(other_object)
          set_from_hash(other_object.to_hash)
        end

        # Converts a hash in text format into a format suitable for
        # feeding to #set_from_hash. Only relevant keys are
        # converted. Keys that exist in the options hash but are not
        # Strings are left untouched
        def self.convert_string_hash(opts, key = "%s")
          cnv = self.options_hash(key)
          
          ret = {}
          for k,v in opts
            if cnv.key? k
              if v.is_a? String
                ret[k] = cnv[k].type.string_to_type(v)
              else
                ret[k] = v
              end
            end
          end
          return ret
        end
      end
    end
  end
end

