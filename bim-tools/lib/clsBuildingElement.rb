#       clsBuildingElement.rb
#       
#       Copyright (C) 2016 Jan Brouwer <jan@brewsky.nl>
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

    # building element basetype class
    class ClsBuildingElement
      
      # add the new element to the project library
      def add_to_lib
        @project.library.add(self)
      end
      
      # check if the building element´s geometry and source still exist
      def deleted?
        if @geometry.deleted? == true
          return true
        elsif @source.deleted? == true
          return true
        else
          return false
        end
      end
      
      # if source object is unrecoverable, self_destruct bt_entity
      def self_destruct
        @deleted = true
        unless @source.deleted?
          source.hidden= false
          
          # remove all bt properties from face
          if @source.attribute_dictionaries
            @source.attribute_dictionaries.delete 'ifc'
          end
        
          # get connecting entities for updating geometry after deletion
          edges = self.source.edges # works only for face!
          
          # update connecting bt_entities
          find_linked_elements()
        end
        
        unless @geometry.deleted?
          @geometry.erase!
        end
        
        # remobe bt_entity from library
        @project.library.entities.delete(self)
        
        @project.bt_entities_set_geometry(@linked_elements)
      end
      
      # hide OR geometry OR source
      def geometry_visibility(visibility=true)
        if visibility == true
          @geometry.hidden=false
          @source.hidden=true
        else
          @geometry.hidden=true
          @source.hidden=false
        end
      end
      def source
        #check_source
        return @source
      end
      def source=(source)
        @source = source
      end
      def geometry
        return @geometry
      end
      
      # returns the volume of the geometry
      def volume?
        unless marked_for_deletion?
          if @geometry.deleted?
            set_geometry
          end
          if defined? @geometry.volume
            return @geometry.volume
          else
            return '0'
          end
        end
      end
      
      # returns the guid of the bt_element
      def guid?
        return @guid
      end
      def possible_types
        return Array["Wall", "Floor", "Roof", "Column", "Window", "Door"]
      end
      def marked_for_deletion?
        return @deleted
      end
      def element_type?
        return @element_type
      end
      def name?
        return @name
      end
      def name=(name)
        @name = name
      end
      def description?
        return @description
      end
      def description=(description)
        @description = description
      end
      # set element type for planar, possible types is a required method for all subclasses of clsBuildingElement
      def element_type=(type)
        if possible_types.include? type
          @element_type = type
          return true
        else
          return false
        end
      end
      
      # checks if the source entity is valid, and if not searches for new source entity
      def check_source
        if @deleted == true
          self_destruct
          return false
        else
          if @source.deleted?
          
          # when to use source_recovery or find_source????????????????
            #@project.source_recovery
            if find_source == false
              self_destruct
              return false
            end
          end
        end
        return true
      end
        
      # checks if the geometry group is valid, and if not creates new geometry
      def check_geometry
        if @geometry.deleted?
          set_geometry
        end
      end
      
      # (?) search only in root entities collection?
      # if source object = renamed, find the new name
      def find_source
        entities = Sketchup.active_model.entities
        entities.each do |ent|
          if ent.is_a? Sketchup::Face # (!) only faces?
            guid = ent.get_attribute "ifc", "guid"
            if guid == @guid
              @source = ent
              return @source
            else
              return false
            end
          end
        end
      end
      
      # DEPRECATED because "toggle"tool disables observers
      # this variable is only used for the observer that checks if the source face is changed, hide/unhide is no real change.
      #def source_hidden?
      #  return @source_hidden
      #end  
      
      # DEPRECATED because "toggle"tool disables observers
      # this variable is only used for the observer that checks if the source face is changed, hide/unhide is no real change.
      #def source_hidden=(value)
      #  @source_hidden = value
      #end
    
      def set_guid
        @guid = @project.new_guid
      end
    end
  end # module BimTools
end # module Brewsky
