#       ObserverManager.rb
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
  
    # The ObserverManager will keep track of all observers(create, add, remove) and the "observed" objects.
    # is needs 
    module ObserverManager
      extend self
      
      attr_reader :status, :app_observer, :model_observer, :entities_observer, :selection_observer
      
      # run manual or auto mode based on previous setting
      if (Sketchup.read_default 'bim-tools', 'on_off') == 'on'
        @status = true
      else
        @status = false
      end
      
      # This is created only once in a session
      # This observer creates additional BtProjects when new/additional
      # models are activated and will allways be running
      # ??? could disabling this observer give any trouble ???
      # ??? should any checks be done on re-enabling ???
      class BtAppObserver < Sketchup::AppObserver
        def activate
          if ObserverManager.status == true
            Sketchup.add_observer self
          end
        end
        def deactivate
          Sketchup.remove_observer self
        end
        def onNewModel(model)
          # reset observers to the new model
          ObserverManager.model_observer.activate
          ObserverManager.entities_observer.activate
          ObserverManager.selection_observer.activate
          
          # create new BtProject
          Brewsky::BimTools.new_BtProject
        end
        def onOpenModel(model)
          
          # reset observers to the new model
          ObserverManager.model_observer.activate
          ObserverManager.entities_observer.activate
          ObserverManager.selection_observer.activate
          
          # create new BtProject
          Brewsky::BimTools.new_BtProject
        end
        def onActivateModel(model)
          
          # reset observers to the new model
          ObserverManager.model_observer.activate
          ObserverManager.entities_observer.activate
          ObserverManager.selection_observer.activate
        
          # update the active project
          BimTools.set_active_BtProject
        end
        
        # (?) on close model, remove btProject?
        
      end # class BtAppObserver
      
      # This observer updates the BtEntitiesObserver
      # when the active centities collection changes
      class BtModelObserver < Sketchup::ModelObserver
        attr_accessor :observed
        def activate
          if ObserverManager.status == true && @observed != Sketchup.active_model
            @observed.remove_observer self unless @observed.nil?
            @observed = Sketchup.active_model
            @observed.add_observer self
          end
        end
        def deactivate
           observed.remove_observer self unless @observed.nil?
        end
        def onActivePathChanged(model)
          ObserverManager.entities_observer.activate
        end
      end # class BtModelObserver
      
      # create this observer once and just link/unlink it to entities collections
      # This observer auto-updates the geometry
      # on open group/component: relink entitiesobserver for possible nested bim-tools entities
      class BtEntitiesObserver < Sketchup::EntitiesObserver
        attr_accessor :observed
        def activate
          unless ObserverManager.status == false || BimTools.active_BtProject.nil? #|| @observed == Sketchup.active_model.active_entities
            
            # entities observer should only be attached when the active collection contains BT-entities
            bt_entities = BimTools.active_BtProject.library.array_remove_non_bt_entities(BimTools.active_BtProject, Sketchup.active_model.active_entities)
            unless bt_entities.length == 0
              
              # try to remove observer, deleted model also has deleted entities, ignore error
              begin
                observed.remove_observer self unless @observed.nil?
              rescue
              end
              @observed = Sketchup.active_model.active_entities
              @observed.add_observer self
            end
          end
        end
        def deactivate
          
          # try to remove observer, deleted model also has deleted entities, ignore error
          begin
            observed.remove_observer self unless @observed.nil?
          rescue
          end
        end
        
        # what to do when component is placed? cut hole if possible.
        def onElementAdded(entities, entity)

          # if cutting-component?
          # if glued?
          # if glued to cuttable object?
          # then cut hole + convert component to btObject
        end
        
        # what to do if element is changed, and check if part of BtEntity.
        def onElementModified(entities, entity)
          unless entity.deleted?
            if entity.is_a?(Sketchup::Face)
              
              # check if entity is part of a building element
              if bt_entity = BimTools.active_BtProject.library.source_to_bt_entity(BimTools.active_BtProject, entity)

                # check if a tool is active that can change geometry
                # or could the check better be reversed?
                tools = Sketchup.active_model.tools
                id = tools.active_tool_id
                if [21019, 21074, 21013, 21020, 21022, 21031, 21048, 21041, 21065, 21094, 21095, 21096, 21100, 21129, 21236, 21525].include? id
                  BimTools.active_BtProject.source_changed(bt_entity)
                end
              else
                guid = entity.get_attribute "ifc", "guid"
                unless guid.nil?
                  puts "Search for missing faces"
                  # only start this when faces are deleted?
                  BimTools.active_BtProject.source_recovery
                end
              end
            elsif entity.is_a?(Sketchup::Edge)
              
              # check if entity connects to a building element
              entity.faces.each do |face|
                if bt_entity = BimTools.active_BtProject.library.source_to_bt_entity(BimTools.active_BtProject, face)
                    
                  # check if a tool is active that can change geometry
                  # or could the check better be reversed?
                  tools = Sketchup.active_model.tools
                  id = tools.active_tool_id
                  if [21019, 21074, 21013, 21020, 21022, 21031, 21048, 21041, 21065, 21094, 21095, 21096, 21100, 21129, 21236, 21525].include? id
                    BimTools.active_BtProject.source_changed(bt_entity)
                  end
                end
              end
            elsif entity.is_a?(Sketchup::ComponentInstance)
              unless entity.glued_to.nil?
                source = entity.glued_to
                
                # run only if added entity cuts_opening
                if entity.definition.behavior.cuts_opening?
                
                  # check if entity is part of a building element
                  if bt_entity = BimTools.active_BtProject.library.source_to_bt_entity(BimTools.active_BtProject, source)
                    bt_entity.update_geometry
                  end
                end
              end
            end
        
          end
        end
      end      

      # This observer keeps the btDialog updated based on the current selection
      class BtSelectionObserver < Sketchup::SelectionObserver
        def activate
          if ObserverManager.status == true
            Sketchup.active_model.selection.add_observer self
          end
        end
        def deactivate
           Sketchup.active_model.selection.remove_observer self
        end
        def onSelectionBulkChange(selection)
          selection_changed(selection)
        end # onSelectionBulkChange
        def onSelectionCleared(selection)
          selection_changed(selection)
        end # onSelectionCleared
        def selection_changed(selection)
          if Menu.window.visible?
            Menu.update
          end
        end # selection_changed
      end # BtSelectionObserver
      
      # Create observers
      @app_observer = BtAppObserver.new
      @model_observer = BtModelObserver.new
      @entities_observer = BtEntitiesObserver.new
      @selection_observer = BtSelectionObserver.new
      
      # activate observers
      ObserverManager.app_observer.activate
      ObserverManager.model_observer.activate
      ObserverManager.entities_observer.activate
      ObserverManager.selection_observer.activate
      
      # this method activates all BIM-Tools observers
      def self.load
        Sketchup.write_default "bim-tools", "on_off", "on"
        @status = true
        @app_observer.activate
        @entities_observer.activate
        @selection_observer.activate
      end
      
      # this method will unload all BIM-Tools observers
      def self.unload
        Sketchup.write_default "bim-tools", "on_off", "off"
        @status = false
        @app_observer.deactivate
        @entities_observer.deactivate
        @selection_observer.deactivate
      end
      
      # reset entities observer (run on switch model)
      def self.update_entities_observer
        @entities_observer.activate
      end
      
      # this method toggles between load and unload
      def self.toggle
        if @status == true
          self.unload
        else
          self.load
        end
      end
    end # module ObserverManager
  end # module BimTools
end # module Brewsky
