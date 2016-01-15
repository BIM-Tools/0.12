#       slabs_from_faces.rb
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
  module ThickFaces
    extend self
    attr_accessor :name, :small_icon, :large_icon
    
    # load default values: This should be done once in a central place ?BtProject?
    require 'bim-tools/lib/clsDefaultValues.rb'
    @default = ClsDefaultValues.new
    @width = @default.get("planar_width").to_l
    @offset = @default.get("planar_offset").to_l
    @name = 'Create thick faces'
    
    @small_icon = File.join( PATH_IMAGE, 'PlanarsFromFaces_small.png' )
    @large_icon = File.join( PATH_IMAGE, 'PlanarsFromFaces_large.png' )

    # add to DIALOG
    
    @section = Menu::add_section( self )
    @section.add_textbox( :thickness, @width.to_s )
    @section.add_textbox( :offset, @offset.to_s )
    @section.add_button( 'Create thick faces' ) { |control|
      width = control.parent[:thickness].value
      if width.to_l
        @width = width.to_l
      end
      offset = control.parent[:offset].value
      if offset.to_l
        @offset = offset.to_l
      end
      create_thick_faces
    }
    
    # method that tells the window section to close/open based on the current selection
    # if the selection contains a face the section must be shown: returns true
    def show_section?
      Sketchup.active_model.selection.each do |entity|
        return true if entity.is_a?(Sketchup::Face)
      end
      false
    end
    
    # add to TOOLBAR
    cmd = UI::Command.new('Creates building elements from selected faces') {
      #Menu.open#_section( @section )
      thick_faces = create_thick_faces
    }
    cmd.small_icon = @small_icon
    cmd.large_icon = @large_icon
    cmd.tooltip = 'Creates building elements from selected faces'
    cmd.status_bar_text = 'Creates building elements from selected faces'
    BimTools.toolbar.add_item cmd
    
    # add to OBSERVERS
    
    
    
    
    
    
    
    

    # Function/Tool that takes an array of SketchUp elements as input, and creates planar objects from the faces in the array.
    #   parameters: array of SketchUp elements
    #   returns: array of planar objects

      
    def create_thick_faces
      model = Sketchup.active_model
      a_planars = Array.new
      
      #raise ArgumentError, 'No faces selected' if selection.nil? || selection.length == 0 # or ask for selection?
        
      @a_sources = model.selection
      @project = BimTools.active_BtProject
      
      # temporarily turn off observers to prevent creating geometry multiple times
      #t = Time.new
      Brewsky::BimTools::ObserverManager.suspend
      
      # start undo section
      model.start_operation("Create thick faces", disable_ui=true) # Start of operation/undo section

      # require planar class
      require "bim-tools/lib/clsPlanarElement.rb"
      
      # first; create objects 
      @a_sources.each do |source|
  
        # create planar object if source is a SketchUp face
        if source.is_a?(Sketchup::Face)
          # check if a BIM-Tools entity already exists for the source face
          unless @project.library.source_to_bt_entity(@project, source)
            a_planars << ClsPlanarElement.new(@project, source, @width.to_l, @offset.to_l)
          end
        end
      end
      
      # clear the current selection to replace the selected source faces with geometry groups
      model.selection.clear
  
      # second; create geometry for the created objects, to make sure all connections are known.
      @project.bt_entities_set_geometry(a_planars)
      
      # add thickfaces to current selection
      a_planars.each do |planar|
        model.selection.add planar.geometry
      end
      
      model.commit_operation # End of operation/undo section
      model.active_view.refresh # Refresh model
      
      # switch observers back on
      Brewsky::BimTools::ObserverManager.resume
      
      # activate select tool
      model.select_tool(nil)
      
      # update menu
      Menu.position_sections
      
      return a_planars
    end # def create_thick_faces
  end # module ThickFaces
 end # module BimTools
end # module Brewsky
