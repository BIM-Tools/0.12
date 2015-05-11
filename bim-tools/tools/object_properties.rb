#       object_properties.rb
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
  module ObjectProperties
    extend self
    attr_accessor :name, :small_icon, :large_icon
    
    require File.join( PATH_LIB, 'sketchup-units-and-locale.rb' )
    
    @name = 'Entity Info'
    @small_icon = File.join( PATH_IMAGE, 'bimtools_small.png' )
    @large_icon = File.join( PATH_IMAGE, 'bimtools_large.png' )

    # add to DIALOG
    
    @section = Menu::add_section( self )
    length = @section.add_textbox( :length )
    length.on( :blur ) { |control, value|
    
      model = Sketchup.active_model
      project = Brewsky::BimTools.active_BtProject
      
      # temporarily turn off observers to prevent recreating of geometry multiple times
      Brewsky::BimTools::ObserverManager.toggle
      
      # start undo section
      model.start_operation("Update length", disable_ui=true) # Start of operation/undo section
      
      bt_entities = project.library.array_remove_non_bt_entities(project, Sketchup.active_model.selection)
      
      bt_entities.each do |bt_entity|
        bt_entity.length= length.value.to_l
        bt_entity.set_planes
      end
      
      project.bt_entities_set_geometry(bt_entities)
      
      model.commit_operation # End of operation/undo section
      model.active_view.refresh # Refresh model
      
      # switch observers back on
      Brewsky::BimTools::ObserverManager.toggle
      
      # update menu
      Menu.position_sections
      
    }
    height = @section.add_textbox( :height )
    height.on( :blur ) { |control, value|
    
      model = Sketchup.active_model
      project = Brewsky::BimTools.active_BtProject
      
      # temporarily turn off observers to prevent recreating of geometry multiple times
      Brewsky::BimTools::ObserverManager.toggle
      
      # start undo section
      model.start_operation("Update height", disable_ui=true) # Start of operation/undo section
      
      bt_entities = project.library.array_remove_non_bt_entities(project, Sketchup.active_model.selection)
      
      bt_entities.each do |bt_entity|
        bt_entity.height= height.value.to_l
        bt_entity.set_planes
      end
      
      project.bt_entities_set_geometry(bt_entities)
      
      model.commit_operation # End of operation/undo section
      model.active_view.refresh # Refresh model
      
      # switch observers back on
      Brewsky::BimTools::ObserverManager.toggle
      
      # update menu
      Menu.position_sections
      
    }
    thickness = @section.add_textbox( :thickness )
    thickness.on( :blur ) { |control, value|
    
      model = Sketchup.active_model
      project = Brewsky::BimTools.active_BtProject
      
      # temporarily turn off observers to prevent recreating of geometry multiple times
      Brewsky::BimTools::ObserverManager.toggle
      
      # start undo section
      model.start_operation("Update thickness", disable_ui=true) # Start of operation/undo section
      
      bt_entities = project.library.array_remove_non_bt_entities(project, Sketchup.active_model.selection)
      
      bt_entities.each do |bt_entity|
        bt_entity.thickness= thickness.value.to_l
        bt_entity.set_planes
      end
      
      project.bt_entities_set_geometry(bt_entities)
      
      model.commit_operation # End of operation/undo section
      model.active_view.refresh # Refresh model
      
      # switch observers back on
      Brewsky::BimTools::ObserverManager.toggle
      
      # update menu
      Menu.position_sections
      
    }
    offset = @section.add_textbox( :offset )
    offset.on( :blur ) { |control, value|
    
      model = Sketchup.active_model
      project = Brewsky::BimTools.active_BtProject
      
      # temporarily turn off observers to prevent recreating of geometry multiple times
      Brewsky::BimTools::ObserverManager.toggle
      
      # start undo section
      model.start_operation("Update offset", disable_ui=true) # Start of operation/undo section
      
      bt_entities = project.library.array_remove_non_bt_entities(project, Sketchup.active_model.selection)
      
      bt_entities.each do |bt_entity|
        bt_entity.offset= offset.value.to_l
        bt_entity.set_planes
      end
      
      project.bt_entities_set_geometry(bt_entities)
      
      model.commit_operation # End of operation/undo section
      model.active_view.refresh # Refresh model
      
      # switch observers back on
      Brewsky::BimTools::ObserverManager.toggle
      
      # update menu
      Menu.position_sections
      
    }
    type = @section.add_listbox( :type )
    type.on( :change ) { |control, value|
      project = Brewsky::BimTools.active_BtProject
      bt_entities = project.library.array_remove_non_bt_entities(project, Sketchup.active_model.selection)
      bt_entities.each do | ent |
        ent.set_type(value)
      end
    }
    name = @section.add_textbox( :name )
    name.on( :blur ) { |control, value|
    
      model = Sketchup.active_model
      project = Brewsky::BimTools.active_BtProject
      
      # temporarily turn off observers to prevent recreating of geometry multiple times
      Brewsky::BimTools::ObserverManager.toggle
      
      # start undo section
      model.start_operation("Update name", disable_ui=true) # Start of operation/undo section
      
      bt_entities = project.library.array_remove_non_bt_entities(project, Sketchup.active_model.selection)
      
      bt_entities.each do |bt_entity|
        bt_entity.name= name.value
        bt_entity.set_planes
      end
      
      project.bt_entities_set_geometry(bt_entities)
      
      model.commit_operation # End of operation/undo section
      model.active_view.refresh # Refresh model
      
      # switch observers back on
      Brewsky::BimTools::ObserverManager.toggle
      
      # update menu
      Menu.position_sections
      
    }
    description = @section.add_textbox( :description )
    description.on( :blur ) { |control, value|
    
      model = Sketchup.active_model
      project = Brewsky::BimTools.active_BtProject
      
      # temporarily turn off observers to prevent recreating of geometry multiple times
      Brewsky::BimTools::ObserverManager.toggle
      
      # start undo section
      model.start_operation("Update description", disable_ui=true) # Start of operation/undo section
      
      bt_entities = project.library.array_remove_non_bt_entities(project, Sketchup.active_model.selection)
      
      bt_entities.each do |bt_entity|
        bt_entity.description= description.value
        bt_entity.set_planes
      end
      
      project.bt_entities_set_geometry(bt_entities)
      
      model.commit_operation # End of operation/undo section
      model.active_view.refresh # Refresh model
      
      # switch observers back on
      Brewsky::BimTools::ObserverManager.toggle
      
      # update menu
      Menu.position_sections
      
    }
    volume = @section.add_textbox( :volume )
    volume.readonly = true
    guid = @section.add_textbox( :guid )
    guid.readonly = true
    
    # method that tells the window section to close/open based on the current selection
    # if the selection contains a bt_entity the section must be shown: returns true
    def show_section?
      if Brewsky::BimTools.active_BtProject.library.array_remove_non_bt_entities(Brewsky::BimTools.active_BtProject, Sketchup.active_model.selection).length > 0 ### active project needs to be removed
      #Sketchup.active_model.selection.each do |entity|
        update_menu(Sketchup.active_model.selection)
        return true# if entity.is_a?(Sketchup::Edge)
      end
      false
    end
    
    
    # add to TOOLBAR
    
    cmd = UI::Command.new('Open BIM-Tools window') { ### should open the entity info section! ###
      Menu.open#_section( @section )
      # switch dialog visibility
      #BimTools.btDialog.toggle
    }
    cmd.small_icon = File.join( @small_icon )
    cmd.large_icon = File.join( @large_icon )
    cmd.tooltip = 'Open BIM-Tools window'
    cmd.status_bar_text = 'Open BIM-Tools window'
    BimTools.toolbar.add_item cmd
    
    # dialog on close not nil but just not visible better? and not re-create but just make visible?

    
    # add to OBSERVERS
    
    # Update menu sections with bt_objects from selection
    def update_menu(su_entities)
      
      if BimTools::Menu.window.visible?
      
        project = Brewsky::BimTools.active_BtProject
        bt_entities = project.library.array_remove_non_bt_entities(project, su_entities)
    
    
        # ??? hoe aangeven alleen lezen ???
        # alle values vergelijken + samenvoegen + formatten als ze geen string zijn
        # section.set value aanroepen per hash waarde
          
        # source: http://stackoverflow.com/questions/5490952/merge-array-of-hashes-to-get-hash-of-arrays-of-values
        hash = {}.tap{ |r| bt_entities.each{ |ent| ent.properties_editable.each{ |k,v| (r[k]||=[]) << v } } }

        hash.each do | k,v|
          v.uniq!
          if v.length == 1
            value = v[0]
            if value.is_a? Float
              value = value.to_l.to_s
            end
            @section.set_value( k, v[0] )
          else # listbox needs a single array (preferably unique)
            if v[0].is_a? Array # meaning multiple arrays for a listbox => merge
              v.unshift("...")
              v.flatten!
              v.uniq!
              @section.set_value( k, v )
            else # multiple strings(no listbox)
              puts "NO array!"
              @section.set_value( k, "..." )
            end
          end
        end
    
        # special properties ? not editable ?
        if bt_entities.length == 1
          @section.set_value( :volume, Volume.new( bt_entities[0].volume? ).to_s )
          @section.set_value( :guid, bt_entities[0].guid? )
        else
          @section.set_value( :volume, "..." ) # or hide?
          @section.set_value( :guid, "..." ) # or hide?
        end
      end
    end # def update_menu
          
  end # module ObjectProperties
 end # module BimTools
end # module Brewsky
