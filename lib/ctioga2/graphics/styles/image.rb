# image.rb: style of images
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

# This module contains all the classes used by ctioga
module CTioga2

  module Graphics

    # All the styles
    module Styles

      AspectRatioRE = {
        /ignore/i => :ignore,
        /expand/i => :expand,
        /contract/i => :contract,
      }
      
      AspectRatioType = 
        CmdType.new('aspect-ratio', 
                    {:type => :re_list,
                      :list => AspectRatioRE}, <<EOD)
How the {command: draw-image} command respects the original image
aspect ratio:
 * @ignore@ (the default) ignores the original aspect ratio
 * @expand@ expand the original box to respect aspect ratio
 * @contract@ contract the original box to respect aspect ratio
EOD
        


      # This class represents the style for an image
      class ImageStyle < BasicStyle
        # The line style
        typed_attribute :aspect_ratio, 'aspect-ratio'

        # The line width
        typed_attribute :transparency, 'float'

        # Automatically rotate
        typed_attribute :auto_rotate, 'boolean'

        # Draws an image according to this
        def draw_image(t, file, tl, br)
          info = t.jpg_info(file)
          if ! info
            info = t.load_png(file)
          end

          r = Types::Rect.new(tl, br)
          ul, ll, lr = r.make_corners(t, (@auto_rotate == nil ? true : @auto_rotate), @aspect_ratio || :ignore,
                                      info['width']*1.0/info['height'])

          dict = info.dup
          dict.merge!('ul' => ul,
                      'll' => ll,
                      'lr' => lr)
          
          # @todo provide a way to reuse images ?
          t.context do
            if @transparency
              t.fill_opacity = 1 - @transparency
            end
            t.show_image(dict)
          end
        end
      end
    end
  end
end

