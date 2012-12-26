# sheet.rb: handling of style sheets
# copyright (c) 2012 by Vincent Fourmond
  
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details (in the COPYING file).

require 'ctioga2/utils'
require 'ctioga2/log'

require 'ctioga2/graphics/coordinates'

# This module contains all the classes used by ctioga
module CTioga2

  Version::register_svn_info('$Revision$', '$Date$')

  module Graphics

    module Styles
   
      # This is a style sheet, is a storage place for style
      # objects. It has two related functions:
      # * first, store the user-specified preferences
      # * second, provide the appropriate default style for any given
      #   object, most probably at construction time (although that
      #   may get hard some times)
      #
      # The style are cascading and scoped. A scope should begin in
      # each plot.
      #
      # Cascades happen in two ways:
      # 
      # * more specific styles inherit from less specific (axis ->
      #   yaxis -> left)
      # * children style inherit from parent style
      class StyleSheet

        # The parent of the style sheet, or nil if this is the top one.
        attr_accessor :parent

        # The styles, in form of a style name -> style object hash
        #
        # The style object is actually a hash ready to be fed to the
        # BasicStyle#set_from_hash
        attr_accessor :own_styles

        def initialize(par = nil)
          @parent = par
          @own_styles = {}
        end

        # This hash contains the parent style for each of the style
        # listed in
        @style_parent = RegexpHash.new

        # Sets the parent for the given style
        def self.set_parent(style, parent)
          @style_parent[style] = parent
        end
        
        # Returns the parent style for the style (or _nil_ should the
        # style have no parent)
        def self.get_parent(style)
          return @style_parent[style]
        end

        set_parent "xaxis",  "axis"
        set_parent "yaxis",  "axis"

        set_parent "bottom", "xaxis"
        set_parent "top",    "xaxis"
        set_parent "left",   "yaxis"
        set_parent "right",  "yaxis"


        # All arrow styles descend from the base 'arrow' style
        set_parent /^arrow./, "arrow"

        # Same thing for lines, text, markers, boxes
        set_parent /^line./, "line"
        set_parent /^text./, "text"
        set_parent /^marker./, "marker"
        set_parent /^marker-string./, "marker-string"
        set_parent /^box./, "box"


        @style_type = RegexpHash.new

        # Sets the class for the given style. It should be
        # comprehensive. 
        def self.set_type(type, *names)
          for name in names.flatten
            @style_type[name] = type
          end
        end

        def self.get_type(name)
          return @style_type[name]
        end
        
        set_type AxisStyle, %w(axis xaxis yaxis left right top bottom)
        set_type BackgroundStyle, 'background'
        set_type TextLabel, 'title'
        set_type StrokeStyle, 'line', /^line./
        set_type ArrowStyle, 'arrow', /^arrow./
        set_type FullTextStyle, 'text', /^text./
        set_type MarkerStringStyle, 'marker', 'marker-string', /^marker./
        set_type BoxStyle, 'box', /^box./





        def self.all_types()
          return @style_type
        end

        # This returns the style we have in this object for the given
        # name. Inner cascading should take place (ie object
        # hierarchy, but not scope hierarchy).
        #
        # This returns a hash that can be modified.
        def own_style_hash_for(name)
          p = self.class.get_parent(name)
          base = {}
          if p
            base = own_style_hash_for(p)
          end
          style = @own_styles[name]
          if ! style
            return base
          end
          style = style.dup
          style.merge!(base) { |key, v1, v2| v1 }
          return style
        end

        # The style for the given name, including all cascading
        def get_style_hash_for(name)
          ps = {}
          if @parent
            ps = @parent.get_style_hash_for(name);
          end
          style = own_style_hash_for(name)
          style.merge!(ps) { |key, v1, v2| v1 }
          return style
        end



        # The current sheet
        @sheet = StyleSheet.new
        
        # Returns a suitable style object for the given style name, or
        # crashes if the name isn't known.
        #
        # Additional arguments are passed to the constructor
        def self.style_for(name, *args)
          type = self.get_type(name)
          if ! type
            return nil
          end
          a = type.new(*args)
          
          a.set_from_hash(@sheet.get_style_hash_for(name))
          return a
        end

        def self.typed_style_for(name, cls)
          style = self.style_for(name)
          if ! style.is_a?(cls)
            Log::error { "Style '#{name}' is not of the appropriate type (#{cls.name})" }
            style = cls.new
          end
          return style
        end

        def self.enter_scope()
          @sheet = StyleSheet.new(@sheet)
        end

        def self.leave_scope()
          if @sheet.parent
            @sheet = @sheet.parent
          else
            warn { "Trying to leave top-level stylesheet scope" }
          end
        end

        def self.current_sheet()
          return @sheet
        end
        
      end

      StyleSheetGroup = CmdGroup.new('style-sheets',
                                     "Default styles", 
                                     <<EOD, 40)
Commands for defining default styles.

All commands take the name of the style to redefine. Depending on the
command, you may either pick from a fixed list of modifiable types or
define your own, provided they start with the right prefix.

ctioga2 does not support changing a style after its use. It may
affect only the following objects or all the ones that were created
from the beginning, depending on the context. For safety, only define
style before issueing any graphics command.

ctioga2 may support at a later time loading style files, but that is
not the case for now.

EOD
      # We create the commands programmatically
      kinds = [
               ['axis', AxisStyle, 'axis'],
               ['background', BackgroundStyle, 'plot background'],
               ['title', TextLabel, 'plot title'],
               ['text', FullTextStyle, 'text'],
               ['marker', MarkerStringStyle, 'marker'],
               ['box', BoxStyle, 'boxes'],
               ['arrow', ArrowStyle, 'arrows'],
               ['line', StrokeStyle, 'lines']
              ]

      StyleSheetCommands = {}
      StyleSheetPredefinedNames = {}

      kinds.each do |k|
        name, cls, desc = *k

        # Now, we get all the names that match the style
        all_names = StyleSheet.all_types.keys_for(cls)
        StyleSheetPredefinedNames[name] = all_names

        StyleSheetCommands[name] = 
          Cmd.new("default-#{name}-style",nil,
                  "--default-#{name}-style", 
                  [
                   CmdArg.new('text'),
                  ], 
                  cls.options_hash
                  ) do |plotmaker, what, opts|
          if StyleSheet.get_type(what) != cls
            Log::error { "Incorrect type for style #{name}" }
          else
            StyleSheet.current_sheet.own_styles[what] ||= {}
            StyleSheet.current_sheet.own_styles[what].merge!(opts)
          end
        end
        StyleSheetCommands[name].
          describe("Sets the default style for the given #{desc}.", 
                   <<"EOH", StyleSheetGroup)
Sets the default style for the named #{desc}.

Possible values for the name: #{all_names.join(', ')}.
EOH
      end
      
      StyleSheetCommands['line'].long_description = <<EOD
Sets the default style for lines. All line styles descend from the
@line@ base style, and they must all start with @line@. Use a style
different than @line@ by passing its name as the @/base-style@ option 
to the {command: draw-line} command.

Meaning of the style parameters:

 * @color@: the color of the line, see {type: color}
 * @style@: the line style, see {type: line-style}
 * @width@: the line width (in points)

> --default-line-style line /color=Pink

makes all lines drawn pink (unless overriden by the /color option to
{command: draw-line}), while

> --default-line-style line-pink /color=Pink

only affect those to which the /base-style=line-pink style option
was given.
EOD

      StyleSheetCommands['arrow'].long_description = <<EOD
Sets the default style for arrows. All arrows styles descend from the
@arrow@ base style, and they must all start with @arrow@. Use a style
different than @arrow@ by passing its name as the @/base-style@ option 
to the {command: draw-arrow} command.

Meaning of the style parameters:

 * @color@, @style@ and @width@: same as in {command: default-line-style}
 * @head_marker@, @tail_marker@: a {type: marker} to be used for the head 
   or for the tail
 * @head_scale@, @tail_scale@: scale of the head or tail markers
 * @head_angle@, @tail_angle@: rotate the head or the tail by that many
   degrees
 * @head_color@, @tail_color@: the {type: color} of the head or tail
EOD
      
    end
  end
end
