#       bim-tools_loader.rb
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

module Brewsky
 module BimTools
  extend self
  attr_accessor :projects, :toolbar, :btDialog, :active_BtProject
  
  PLATFORM_IS_OSX     = ( Object::RUBY_PLATFORM =~ /darwin/i ) ? true : false
  PLATFORM_IS_WINDOWS = !PLATFORM_IS_OSX
  
  require File.join( PATH, 'clsBtProject.rb' )
  require File.join( PATH, 'menu.rb' )
  require File.join( PATH, 'lib', 'ObserverManager.rb' )
  
  # create projects list
  @projects = Hash.new
  
  # create BIM-Tools toolbar
  @toolbar = UI::Toolbar.new "BIM-Tools"
  @toolbar.show # needed???

  def set_active_BtProject
    @projects.each_value do |project|
      @active_BtProject = project if project.model == Sketchup.active_model
    end
  end
  
  # create BimTools project for initial active model
  ClsBtProject.new

  def new_BtProject
    ClsBtProject.new # Closed SketchUp models must also be removed from projects!
  end
  
  # load all available tools
  Dir[TOOLS + '/*.rb'].each {|file| require file }
  Brewsky::BimTools::Menu.position_sections # This needs to change, probably better not to load automatically...
  
 end # module BimTools
end # module Brewsky
