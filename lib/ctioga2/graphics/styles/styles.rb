# styles.rb: commands for setting styles
# copyright (c) 2014 by Vincent Fourmond
  
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

  module Graphics

    module Styles
   
      StyleSheetGroup = CmdGroup.new('style-sheets',
                                     "Default styles", 
                                     <<EOD, 40)
Commands for defining default styles.

All commands take the name of the style to redefine. Different styles
live in a different name space, so there is no risk naming an @axis@ and
a @text@ style with the same name. All styles for a given type inherit from 
the style name @base@.

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
               ['image', ImageStyle, 'image'],
               ['line', StrokeStyle, 'lines']
              ]

      StyleSheetCommands = {}
      StyleSheetPredefinedNames = {}

      kinds.each do |k|
        name, cls, desc = *k

        StyleSheetCommands[name] = 
          Cmd.new("define-#{name}-style",nil,
                  "--define-#{name}-style", 
                  [
                   CmdArg.new('text'),
                  ], 
                  cls.options_hash
                  ) do |plotmaker, xpath, opts|
          StyleSheet.style_sheet.update_style(xpath, opts)
        end
        StyleSheetCommands[name].
          describe("Sets the default style for the given #{desc}.", 
                   <<"EOH", StyleSheetGroup)
Sets the default style for the named #{desc}.
EOH
      end
      
      StyleSheetCommands['line'].long_description = <<EOD
Sets the default style for lines. All line styles descend from the
@base@ style. Use a style different than @base@ by passing its name as
the @/base-style@ option to the {command: draw-line} command.

Meaning of the style parameters:

 * @color@: the color of the line, see {type: color}
 * @style@: the line style, see {type: line-style}
 * @width@: the line width (in points)

> --define-line-style base /color=Pink

makes all lines  pink (unless overriden by the /color option to
{command: draw-line}), while

> --define-line-style line-pink /color=Pink

only affect those to which the /base-style=line-pink style option
was given.
EOD

      StyleSheetCommands['arrow'].long_description = <<EOD
Sets the default style for arrows. All arrow styles descend from the
@base@ style. Use a style different than @base@ by passing its name as
the @/base-style@ option to the {command: draw-arrow} command.

Meaning of the style parameters:

 * @color@, @style@ and @width@: same as in {command: define-line-style}
 * @head-marker@, @tail-marker@: a {type: marker} to be used for the head 
   or for the tail
 * @head-scale@, @tail-scale@: scale of the head or tail markers
 * @head-angle@, @tail-angle@: rotate the head or the tail by that many
   degrees
 * @head-color@, @tail-color@: the {type: color} of the head or tail
EOD

      StyleSheetCommands['box'].long_description = <<EOD
Sets the default style for boxes. All box styles descend from the
@base@ style. Use a style different than @base@ by passing its name as
the @/base-style@ option to the {command: draw-box} command.

Meaning of the style parameters:

 * @color@, @style@ and @width@: same as in {command: define-line-style}
 * @fill-color@: fill color for the box
 * @fill-transparency@: the transparency for the fill, from 0 to 1
EOD

      StyleSheetCommands['text'].long_description = <<EOD
Sets the default style for texts. All text styles descend from the
@base@ style. Use a style different than @base@ by passing its name as
the @/base-style@ option to the {command: draw-text} command.

Meaning of the style parameters:

 * @alignment@: vertical alignment
 * @justification@: horizontal alignment
 * @angle@: angle in degrees to the horizontal (or default orientation in
   some cases)
 * @color@: text color
 * @scale@: text scale
EOD

      StyleSheetCommands['title'].long_description = <<EOD
Sets the style for title. All title styles descend from the
@base@ style. In addition, the title of a plot is addressed by the 
style name @title@.

Meaning of the style parameters:

 * @alignment@, @justification@, @angle@, @color@ and @scale@: 
   as in {command: define-text-style}
 * @text@: sets the title text
 * @loc@: the side on which to display the title, a {type: location}
 * @shift@: the distance away from the plot in text size units 
   (maybe a dimension should be better later)
 * @position@: shift from the center (parallel to the plot side)
EOD

      StyleSheetCommands['marker'].long_description = <<EOD
Sets the style for marker and marker strings.  All marker and marker
string styles descend from the @base@ style. Use a style different
than @base@ by passing its name as the @/base-style@ option to the
{command: draw-marker} or {command: draw-string-marker} commands.

Meaning of the style parameters:

 * @alignment@, @justification@, @angle@, @color@ and @scale@: 
   as in {command: define-text-style}
 * @fill-color@ and @stroke_color@: markers are both stroked and filled,
   you can control all colors in one go using @color@ or specifying each
   with @fill-color@ and @stroke_color@
 * @font@: is a PDF font number (from 1 to 14), only used for marker
   strings
 * @horizontal-scale@, @vertical-scale@: scales the marker only
   horizontally or vertically
EOD

      StyleSheetCommands['background'].long_description = <<EOD
Sets the style for plot background. All background styles descend from the
@base@ style. In addition, the background of a plot is change by the 
style name @background@.

Meaning of the style parameters:

 * @watermark@: the text of the watermark
 * all @watermark_@ styles have the same meaning as in 
   {command: define-text-style}, as the watermark is a string marker
 * @background_color@: the color of the background
EOD

      StyleSheetCommands['axis'].long_description = <<EOD
Sets the style for a whole axis. All axis styles descend from the
@base@ style. Horizontal and vertical axis styles descend from the 
@x@ and @y@ styles, and plot sides are styled with the @left@, @right@, 
@top@ and @bottom@ styles.

Axis styles have lots of parameters:

 * @axis-label-@ and @tick-label-@ parameters are title style parameters
   whose meaning is given in {command: define-title-style}, that affect
   ticks and axis labels
 * @decoration@: a {type: axis-decoration} that specify which ticks and 
   tick labels to draw
 * @background-lines-@ parameters define the style of background lines, 
   as in {command: define-line-style}
EOD


      # Here, a few defaults styles
      
      StyleSheet.style_sheet.
        update_style('title', {
                       'text_width' => 
                       Types::Dimension.new(:frame, 1.0, :x)
                     })
    end
  end
end
