# element.rb: base class of all drawable elements
# copyright (c) 2006, 2007, 2008, 2009, 2014 by Vincent Fourmond: 
  
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

# This module contains all the classes used by ctioga
module CTioga2

  # This module contains all graphical elements of CTioga2
  module Graphics

    # All elements that can be drawn onto a FigureMaker object
    module Elements

      # The base class for every single object that is drawn on
      # Tioga's output. Each object can have a style attached to it,
      # and obtained from the StyleSheet class.
      #
      # For styling-related purposes, all subclasses of this class
      # have the following characteristics:
      #  * a style name (a "type selector")
      #  * a style class (the corresponding underlying class)
      #
      # All instances of this classes have several properties:
      #  * a (unique) id
      #  * a list of classes (specified as comma-separated stuff)
      #
      # Ideas for how the style should be used:
      #  - first create the object
      #  - then, soon afterwards, use #setup_style to give it a
      #    workable position in the style list
      #  - then, use get_style to get the style ;-)...
      class TiogaElement
        include Log

        # The parent Container.
        attr_accessor :parent

        # Details pertaining to the location of the object, as a
        # LocationStyle object
        attr_writer :location

        # Whether the object is clipped by default or not.
        attr_accessor :clipped

        
        # Depth
        attr_writer :depth

        # Style-related attributes:
        
        # The id
        attr_reader :object_id

        # The classes (order matter)
        attr_accessor :object_classes

        # The parent (in the style point of view, which may be
        # different from the rest)
        attr_accessor :object_parent

        # Wether or not the object is hidden
        attr_accessor :hidden

        StyleBaseOptions = {
          'id' => CmdArg.new('text'),
          'class' => CmdArg.new('text-list')
        }

        def self.define_style(name, cls = nil)
          @style_name = name
          @style_class = cls
          register_style(name, cls)
        end

        @@style_classes = {}

        def self.register_style(name, cls)
          # p [self, name, cls]
          if @@style_classes.key? name
            if @@style_classes[name] != cls
              raise "Trying to register different classes under the same name"
            end
          else
            @@style_classes[name] = cls
          end
        end

        def self.base_style
          if @style_name
            return self
          elsif self == TiogaElement
            return nil
          else
            return self.superclass.base_style
          end
        end

        def self.style_class
          if @style_name
            return @style_class
          else
            bs = base_style
            return (bs ? bs.style_class : nil)
          end
        end

        def self.style_name
          if @style_name
            return @style_name
          else
            bs = base_style
            return (bs ? bs.style_name : nil)
          end
        end

        def style_class
          return self.class.style_class
        end

        def style_name
          return self.class.style_name
        end

        def has_style?
          if style_class
            return true
          else
            return false
          end
        end

        def self.all_styles
          return @style_classes
        end



        def self.inherited(cls)
          # p cls
        end

        def initialize
          @clipped = true

          @depth = 50           # Hey, like xfig
          
          @gp_cache = {}
        end

        def self.register_object(obj)
          @registered_objects ||= {}
          if i = obj.object_id
            if @registered_objects.key? i
              warn { "Second object with ID #{i}, ignoring the name" }
            else
              @registered_objects[i] = obj
            end
          end
        end

        def self.find_object(obj_id)
          @registered_objects ||= {}
          if @registered_objects.key? obj_id
            return @registered_objects[obj_id]
          else
            raise "No such object: '#{obj_id}'"
          end
        end
              
        
        def setup_style(obj_parent, opts) 
          @cached_options = opts
          @object_id = opts["id"] || nil
          @object_classes = opts["class"] || []
          @object_parent = obj_parent

          TiogaElement.register_object(self)
          @style_is_setup = true
        end


        def get_style()
          check_styled()
          return Styles::StyleSheet.style_for(self)
        end

        def update_style(style)
          check_styled()
          stl = Styles::StyleSheet.style_hash_for(self)
          style.set_from_hash(stl)
        end

        def check_styled()
          if ! self.style_class
            raise "Object has no attached style class !"
          elsif ! @style_is_setup
            raise "Should have setup style before !"
          end
        end

        def depth
          @depth || 50
        end

        # Makes sure there is a location when one asks for it.
        def location
          @location ||= Styles::LocationStyle.new
          return @location
        end

        # This function must be called with a FigureMaker object to
        # draw the contents of the TiogaElement onto it. It calls
        # #real_do, which should be redefined by the children. You can
        # redefine _do_ too if you need another debugging output.
        def do(f)
          if @hidden
            debug { "not plotting hidden #{self.inspect}" }
            return 
          else
            debug { "plotting #{self.inspect}" }
          end
          @gp_cache = {}
          real_do(f)
        end

        # We plot everything but parent. If a prefix is given, it is prepended
        # to all lines but the first (for indentation)
        def inspect(prefix="")
          ret = "#<#{self.class.name}:\n"
          for i in instance_variables
            next if i == "@parent"
            var = instance_variable_get(i)
            ret += "#{prefix}  - #{i} -> "
            if var.is_a? TiogaElement
              ret += "#{var.inspect("#{prefix}  ")}\n"
            else
              ret += "#{var.inspect}\n"
            end
          end
          ret += "#{prefix}>"
          return ret
        end

        protected
        
        def real_do(t)
          raise "Should be reimplemented by children"
        end
      end 


      # The base class for all dataset-based elements
      class PlotBasedElement < TiogaElement

        # The Data::Dataset object that should get plotted.
        attr_accessor :dataset

        # A Styles::CurveStyle object saying how the curve should be
        # drawn.
        attr_accessor :curve_style

        define_style 'curve', Styles::CurveStyle

        undef :location=, :location

        # Returns the LocationStyle object of the curve. Returns the
        # one from #curve_style.
        def location
          return @curve_style.location
        end

        undef :clipped, :clipped=

        def clipped
          return @curve_style.clipped
        end

        undef :depth, :depth=

        def depth
          return @curve_style.depth
        end

        def initialize()
          super()
        end
      end

      ObjectType = 
        CmdType.new('object', {:type => :function_based,
                      :class => Elements::TiogaElement,
                      :func_name => :find_object}, <<EOD)
A named object (whose name was given using the /id= option to the
appropriate command).
EOD

      ObjectsType = 
        CmdType.new('objects', {:type => :array,
                      :subtype => {:type => :function_based,
                        :class => Elements::TiogaElement,
                        :func_name => :find_object}
                      }, <<EOD)
A list of comma-separated {type: object}s.
EOD

    end
  end
end
