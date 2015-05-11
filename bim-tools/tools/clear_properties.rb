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
      selection = Sketchup.active_model.selection
      ClearProperties.new(BimTools.active_BtProject, selection)
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
          

    # Function that takes an array of SketchUp elements as input, deletes all BIM properties for these elements,
    # and makes the source geometry visible and selected.
    #   parameters: array of SketchUp elements
    #   returns: array of SketchUp faces
    
    class ClearProperties
      def initialize(project, entities)
        @project = project
        @model = Sketchup.active_model
        
        entities.each do |entity|
          bt_entity = nil
          if entity.is_a?(Sketchup::Group)
            bt_entity = @project.library.geometry_to_bt_entity(@project, entity)
          elsif entity.is_a?(Sketchup::Face)
            bt_entity = @project.library.source_to_bt_entity(@project, entity)
          end
          
          if bt_entity
				
						# start undo section
						@model.start_operation("Toggle source/geometry", disable_ui=true)
        
            bt_entity.self_destruct
            #geometry = bt_entity.geometry
            #source = bt_entity.source
            #source.attribute_dictionaries.delete 'ifc'
            #geometry.attribute_dictionaries.delete 'ifc'
            #source.hidden= false    
            #bt_entity.geometry= nil
            
            #@project.library.delete(bt_entity)
            #geometry.erase!
            
            
            # update connecting entities
            
						@model.commit_operation # End of operation/undo section
						@model.active_view.refresh # Refresh model
						@model.select_tool(nil)
            
            ### Select source faces of deleted entities ###
            
            
          end
        end
      end
    end
  end # module ClearProperties
 end # module BimTools
end # module Brewsky
