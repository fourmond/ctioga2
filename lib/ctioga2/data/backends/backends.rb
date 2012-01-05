# backends.rb: all the backends

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301
# USA


require 'ctioga2/data/backends/backend'
require 'ctioga2/log'

# We try to look for all files under a ctioga2/metabuilder/types
# directory anywhere on the $: path

files = []
for dir in $:
  Dir[dir + '/ctioga2/data/backends/backends/**/*'].each do |f|
    f =~ /ctioga2\/data\/backends\/backends\/(.*)\.[^.]+$/
    files << $1
  end
end

for file in files.uniq
  begin
    require "ctioga2/data/backends/backends/#{file}"
  rescue Exception => e
    CTioga2::Log::warn { "There was a problem trying to load 'ctioga2/data/backends/backends/#{file}': "  }
    CTioga2::Log::warn { "#{e.inspect}" }
  end
end
