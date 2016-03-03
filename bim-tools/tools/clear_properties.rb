#       clear_properties.rb
#       
#       Copyright (C) 2013 Jan Brouwer <jan@brewsky.nl>
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

# Remove BIM properties from selection

module Brewsky
 module BimTools
  module ClearProperties
    extend self
    attr_accessor :name, :small_icon, :large_icon
    
    @name = 'Clear properties'
    @description = 'Remove BIM properties from selection'
    @small_icon = File.join( PATH_IMAGE, 'clear_small.png' )
    @large_icon = File.join( PATH_IMAGE, 'clear_large.png' )
    
    # Tool
    tool = Proc.new {
    
      # Takes the current selection as input, deletes all BIM properties for these elements,
      # and makes the source geometry visible and selected.
    
      entities = Sketchup.active_model.selection
      model = Sketchup.active_model
      project = BimTools.active_BtProject
      sources = Array.new
      
      # start undo section
      model.start_operation("Clear BIM-Tools properties", disable_ui=true)
      
      project.library.array_remove_non_bt_entities(project, entities).each do |entity|
        sources << entity.source
        entity.self_destruct
      end
        
      model.commit_operation # End of operation/undo section
      model.active_view.refresh # Refresh model
      model.selection.add( sources )
      model.select_tool(nil)
      
    }
    
    # add to TOOLBAR
    
    cmd = UI::Command.new(@description) { tool.call }
    cmd.small_icon = File.join( @small_icon )
    cmd.large_icon = File.join( @large_icon )
    cmd.tooltip = 'Remove BIM properties'
    cmd.status_bar_text = 'Remove BIM properties from selection'
    BimTools.toolbar.add_item cmd

    # add to menu-icons
    BimTools::Menu.add_icon( @large_icon, @description ) { |c, image|
      
      # tool
      tool.call
    }
    
    # add to OBSERVERS
          
  end # module ClearProperties
 end # module BimTools
end # module Brewsky
