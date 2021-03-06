# general-types.rb: various useful command types
# copyright (c) 2009 by Vincent Fourmond
  
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details (in the COPYING file).

require 'ctioga2/utils'

module CTioga2

  module Commands
 
    # A file name.
    FileType = CmdType.new('file', :string, <<EOD)
A file name.
EOD

    # Plain text
    TextType = CmdType.new('text', :string, <<EOD)
Plain text.
EOD

    # A series of datasets
    DatasetType = CmdType.new('dataset', :string, <<EOD)
One expandable dataset.
EOD

    # Commands
    CommandsType = CmdType.new('commands', :string, <<EOD)
ctioga2 commands, such as the ones that could be found in
command files.
EOD

    BooleanType = CmdType.new('boolean', :boolean, <<EOD)
Yes or no.
EOD



    FloatType = CmdType.new('float', :float, <<EOD)
A floating-point number.
EOD

    FloatOrFalseType = CmdType.new('float-or-false', {
                              :type => :float,
                              :shortcuts => {'none' => false }}, 
                              <<EOD)
A floating-point number, or @none@.
EOD


    FloatList = CmdType.new('float-list', 
                            {
                              :type => :array,
                              :subtype => :float,
                              :separator => /\s+|\s*,\s*/,
                              :separator_out => " "
                            }, <<EOD)
A list of space-separated or comma-separated floating point numbers.
EOD

    TextList = CmdType.new('text-list', 
                            {
                              :type => :array,
                              :subtype => :string,
                              :separator => /\s*,\s*/,
                              :alternative_separator => /\s*\|\|\s*/,
                              :separator_out => ","
                            }, <<EOD)
A list of comma-separated texts. If you must include a comma inside the
texts, then use @||@ as a separator.
EOD

    IntegerType = CmdType.new('integer', :integer, <<EOD)
An integer.
EOD

    IntegerList = CmdType.new('integer-list', 
                            {
                              :type => :array,
                              :subtype => :integer,
                              :separator => /\s+|\s*,\s*/,
                              :separator_out => " "
                            }, <<EOD)
A list of space-separated or comma-separated integers
EOD

    PartialFloatRangeType = CmdType.new('partial-float-range', 
                                        :partial_float_range, <<EOD)
A beginning:end range, where either of the endpoints can be ommitted.
EOD

    FloatRangeType = CmdType.new('float-range', 
                                 :float_range, <<EOD)
A beginning:end range.
EOD

    StringOrRegexp = CmdType.new('regexp', 
                                 :string_or_regexp, <<EOD)
A plain string or a regular expression (the latter being enclosed 
within /.../).
EOD

    # Data-point. Unlike other types, this one needs to be processed
    # afterwards, actually, since an access to a plotmaker object is
    # necessary.
    DataPointType = CmdType.new('data-point', :data_point, <<EOD)
A point from an already-loaded Dataset. You have two ways to choose the point:

 * @@13@ takes the 13th point in the last dataset;
 * @0.2@ takes the point the closest to 20% of the dataset.

If you need another dataset than the last one, give its number or
named within brackets: @{-2}0.2@ is the point closest to the 20% of
the one-before-last dataset.
EOD

    # A LaTeX font
    LaTeXFontType = CmdType.new('latex-font', :latex_font, <<EOD)
A LaTeX font.

@todo document !
EOD

    # A color map
    ColorMapType = CmdType.new('colormap', :colormap, <<EOD)
A Z color map. It takes the form @Color1--Color2--Color3...@. All
colors can optionally be followed by a number. For instance, for
@Red--Blue--Pink--Green@, the colors are evenly spaced. In the case
@Red--Blue(0.1)--Pink(0.2)--Green@, the Blue to Pink strech is located
between Z values 0.1 and 0.2.

If a prefix @hls:@ or @wheel:@ is present, then linear interpolation
is done in the HLS colorspace instead of the RGB one (the default).

If a suffix @:sym:@_value_ is present, then the colormap is symmetric
around that value.

It is also possible to directly use a {type: color-set}, in which case
eveything works as if the colors of the {type: color-set} had been
given directly, without Z values.
EOD

    # This ones get here since they mess up with syntax highlighting

    # A stored dataset.
    StoredDatasetType = CmdType.new('stored-dataset', 
                                    :string, <<EOD)
A dataset that has already been loaded. It is either:
 * A number, in which case it specifies the index inside the stack. 0
   is the first on that was pushed onto the stack (the oldest
   dataset), 1 the second, -1 the last one, -2 the one before the last
   and so on. (it works just like Ruby's arrays).
 * The name of a named dataset.
 * @#@ followed by the id of a plot element
EOD

    # Something meant to be fed to PlotStyle#get_axis_style
    AxisType = CmdType.new('axis', :string, <<EOD)
The name of the axis of a plot. It can be:
 * @left@, @top@, @bottom@ or @right@;
 * @x@, @xaxis@, @y@, @yaxis@, which return one of the above depending 
   on the preferences of the current plot (see {command: xaxis} and 
   {command: yaxis} to change them);
 * one of the named axes, such as the ones created by 
   {command: new-zaxis}.
EOD

    # Something meant to be fed to PlotStyle#get_label_style
    LabelType = CmdType.new('label', :string, <<EOD)
The name of an label. It can be:
 * @title@ to mean the current plot's title.
 * @axis_tick@ or @axis_ticks@ or simply @axis@, where @axis@ is a a valid
   {type: axis}. It designates the ticks of the named axis.
 * @axis_label@, same as above but targets the label of the named axis.
EOD

    DateType = CmdType.new('date', :date_time, <<EOD)
An date/time.
EOD

    
  end
end

