#       walls_from_edges.rb
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
  module WallsFromEdges
  attr_accessor :name, :small_icon, :large_icon
    extend self
      
    # load default values: This should be done once in a central place ?BtProject?
    require 'bim-tools/lib/clsDefaultValues.rb'
    @default = ClsDefaultValues.new
    @width = @default.get("wall_width").to_l
    @offset = @default.get("wall_offset").to_l
    @height = @default.get("wall_height").to_l
  
    @name = 'Create walls from edges'

    @small_icon = File.join( PATH_IMAGE, 'WallsFromEdges_small.png' )
    @large_icon = File.join( PATH_IMAGE, 'WallsFromEdges_large.png' )

    # add to DIALOG
    
    @section = Menu::add_section( self )
    @section.add_textbox( :height, @height.to_s )
    @section.add_textbox( :width, @width.to_s )
    @section.add_textbox( :offset, @offset.to_s )
    @section.add_button( 'Create walls from edges' ) {
      selection = Sketchup.active_model.selection
      create_walls_from_edges(selection)
    }
    
    # method that tells the window section to close/open based on the current selection
    # if the selection contains an edge the section must be shown: returns true
    def show_section?
      Sketchup.active_model.selection.each do |entity|
        return true if entity.is_a?(Sketchup::Edge)
      end
      false
    end
    
    # add to TOOLBAR
    
    cmd = UI::Command.new('Create walls from edges') {
      #Menu.open_section( @section )
      selection = Sketchup.active_model.selection
      create_walls_from_edges(selection)
    }
    cmd.small_icon = File.join( @small_icon )
    cmd.large_icon = File.join( @large_icon )
    cmd.tooltip = 'Create walls from edges'
    cmd.status_bar_text = 'Create walls from edges'
    BimTools.toolbar.add_item cmd
    
    def create_walls_from_edges(a_sources)
      @a_sources = a_sources
      @model = Sketchup.active_model
      @entities = @model.active_entities
      @project = BimTools.active_BtProject
      @a_planars = Array.new
      
      # temporarily turn off observers to prevent creating geometry multiple times
      #t = Time.new
      Brewsky::BimTools::ObserverManager.toggle
      
      # start undo section
      @model.start_operation("Create walls from edges", disable_ui=true) # Start of operation/undo section

      # create source faces for the walls
      a_faces = Array.new
      @a_sources.each do |source|
      
        # create wall object if source is a SketchUp edge
        if source.is_a?(Sketchup::Edge)
          bottom_start = source.start.position
          bottom_end = source.end.position
          top_start = Geom::Point3d.new(bottom_start.x, bottom_start.y, bottom_start.z + @height.to_l)
          top_end = Geom::Point3d.new(bottom_end.x, bottom_end.y, bottom_end.z + @height.to_l)
          begin
            a_faces << @entities.add_face(bottom_start, bottom_end, top_end, top_start)
          rescue
            puts "unable to create face"
          end
        end
      end
      
      # create planar objects from wall faces
      
      # require planar class
      require "bim-tools/lib/clsPlanarElement.rb"
      
      # first; create objects 
      a_faces.each do |source|
  
        ## create planar object if source is a SketchUp face
        #if source.is_a?(Sketchup::Face)
        #  # check if a BIM-Tools entity already exists for the source face
        #  unless @project.library.source_to_bt_entity(@project, source)
            @a_planars << ClsPlanarElement.new(@project, source, @width.to_l, @offset.to_l)
        #  end
        #end
      end
      
      # clear the current selection to replace the selected source faces with geometry groups
      @model.selection.clear
  
      # second; create geometry for the created objects, to make sure all connections are known.
      @project.bt_entities_set_geometry(@a_planars)
      @a_planars.each do |planar|
  
        # add the geometry group to the selection
        @model.selection.add planar.geometry
      end
      @model.commit_operation # End of operation/undo section
      @model.active_view.refresh # Refresh model
      
      # switch observers back on
      Brewsky::BimTools::ObserverManager.toggle
      
      # update menu
      Menu.position_sections
      
      return @a_planars
      
    end
    
    # this part could be merged with the same part in planar_from_faces
    def planar_from_faces(project, a_faces)
    
      # require planar class
      require "bim-tools/lib/clsPlanarElement.rb"
      
      # first; create objects 
      a_faces.each do |source|
  
        # check if a BIM-Tools entity already exists for the source face
        unless @project.library.source_to_bt_entity(@project, source)
          planar = ClsPlanarElement.new(@project, source)
          planar.width= @width
          planar.offset= @offset
          @a_planars << planar
        end
      end
      
      # clear the current selection to replace the selected source faces with geometry groups
      @model.selection.clear
  
      # second; create geometry for the created objects, to make sure all connections are known.
      @project.bt_entities_set_geometry(@a_planars)
      @a_planars.each do |planar|
  
        # add the geometry group to the selection
        @model.selection.add planar.geometry
      end
      
      # activate select tool
      Sketchup.send_action(21022)
      return @a_planars
    end
  end # module WallsFromEdges
 end # module BimTools
end # module Brewsky
