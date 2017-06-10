# Copyright 2010 by Vincent Fourmond
#
# This small script generates the data files used for ctioga2's tests
# based on reading data files.
#
# This file can be distributed under the same terms as ctioga2 itself.

File.open("3d-data.dat",'w') do |f|
  nb = 51
  nb.times do |i|
    x = 3 * (i - nb/2)/(nb/2 * 1.0)
    nb.times do |j|
      y = 3 * (j - nb/2)/(nb/2 * 1.0)
      z1 = (x**2 + y**2) * Math.exp(-x**2 - y**2)
      z3 = if z1 > 0.3
             0.0/0.0
           else
             z1
           end
      f.puts "#{x}\t#{y}\t#{z1}\t#{Math.sin(x**2 - y**2)}\t#{z3}"
    end
  end
end
