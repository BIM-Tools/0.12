#       toggle_geometry.rb
#       
#       Copyright (C) 2014 Jan Brouwer <jan@brewsky.nl>
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
  module ToggleGeometry
    extend self
    attr_accessor :name, :small_icon, :large_icon
    
    @name = 'Create thick faces'
    @description = 'Toggle between sources and geometry'
    @small_icon = File.join( PATH_IMAGE, 'ToggleGeometry_small.png' )
    @large_icon = File.join( PATH_IMAGE, 'ToggleGeometry_large.png' )
    
    # Tool
    tool = Proc.new {
      toggle_geometry = ToggleGeometry.new(BimTools.active_BtProject)
      Sketchup.active_model.select_tool(toggle_geometry)
    }
    
    # add to TOOLBAR
    cmd = UI::Command.new(@description) { tool.call }
    cmd.small_icon = File.join( @small_icon )
    cmd.large_icon = File.join( @large_icon )
    cmd.tooltip = 'Toggle between sources and geometry'
    cmd.status_bar_text = 'Toggle between sources and geometry'
    BimTools.toolbar.add_item cmd

    # add to menu-icons
    BimTools::Menu.add_icon( @large_icon, @description ) { |c, image|
      
      # tool
      tool.call
      
    }
    
    # add to OBSERVERS

    # Function that switches the visibility(hidden-status) between source faces and geometry.
    #   parameters: current bim-tools project
    
    class ToggleGeometry
      def initialize(project)
        @project = project
        @model = Sketchup.active_model
			end
      
      def activate
				
				# temporarily turn off observers to prevent creating geometry multiple times
				Brewsky::BimTools::ObserverManager.toggle
				
        # start undo section
        @model.start_operation("Toggle source/geometry", disable_ui=true)
        
        # toggle boolean value from true to false and vice versa
        @project.visible_geometry ^= true
        
        # store the value in the model
        @model.set_attribute "bim-tools", "visible_geometry", @project.visible_geometry        
        
        # switch visibility for all bt-entities
        @project.library.entities.each do |entity|
          unless entity.deleted?
            entity.geometry_visibility(@project.visible_geometry)
          end
        end
        @model.commit_operation # End of operation/undo section
        @model.active_view.refresh # Refresh model
        
				# switch observers back on
				Brewsky::BimTools::ObserverManager.toggle
        
        @model.select_tool(nil)
      end
    end # class ToggleGeometry
  end # module ToggleGeometry
 end # module BimTools
end # module Brewsky
