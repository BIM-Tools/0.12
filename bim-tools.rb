#       bim-tools.rb
#       
#       Copyright (C) 2015 Jan Brouwer <jan@brewsky.nl>
#       
#       This program is free software: you can redistribute it and/or modify
#       it under the terms of the GNU General Public License as published by
#       the Free Software Foundation, either version 3 of the License, or
#       (at your option) any later version.
#       
#       This program is distributed in the hope that it will be useful,
#       but WITHOUT ANY WARRANTY; without even the implied warranty of
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#       GNU General Public License for more details.
#       
#       You should have received a copy of the GNU General Public License
#       along with this program.  If not, see <http://www.gnu.org/licenses/>.

# roadmap:
# columns

# roadmap 0.14:
# fix side-faces normal direction in openings
# fix project properties(different way of reading/writing properties? one at a time instead of array?)
# get rid of entitiesobservers
# improve IFC export
# speed up hidden edges

require 'sketchup.rb'
require 'extensions.rb'

module Brewsky
  PLUGIN_ROOT_PATH = File.dirname(__FILE__) unless defined? PLUGIN_ROOT_PATH
  AUTHOR_PATH = File.join(PLUGIN_ROOT_PATH, 'Brewsky') unless defined? AUTHOR_PATH
  
  module BimTools
    
    # Resource paths
    PATH  = File.join(PLUGIN_ROOT_PATH, 'bim-tools') # must be moved to author path
    TOOLS = File.join(PATH, 'tools')
    PATH_IMAGE = File.join(PATH, 'images')
    PATH_CSS = File.join(PATH, 'css')
    PATH_LIB = File.join(PATH, 'lib')

    # Create Extension
    bimtools = SketchupExtension.new "bim-tools", File.join( PATH, 'bim-tools_loader.rb' )
    bimtools.version = '0.13.3'
    bimtools.description = "Tools to create building parts and export these to IFC."
    Sketchup.register_extension bimtools, true
  end # module BimTools
end # module Brewsky
