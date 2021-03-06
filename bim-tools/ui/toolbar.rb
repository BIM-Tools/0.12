#       toolbar.rb
#       
#       Copyright (C) 2012 Jan Brouwer <jan@brewsky.nl>
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
    class BtToolbar
      def initialize(bimTools)
        
        @bimTools = bimTools
        bt_toolbar = UI::Toolbar.new "BIM-Tools"
        @active_model = Sketchup.active_model
        
        cmd_bimtools = UI::Command.new("Open BIM-Tools window") {
    
    
          # dialog on close not nil but just not visible better? and not re-create but just make visible?
          #if @dialog.nil?
          #  require 'bim-tools/ui/bt_dialog.rb'
          #  @dialog = Bt_dialog.new(bimTools)
          #  #bim_tools.dialog = @dialog
          #else
          #  #if the webdialog is closed using the X-button, the dialog value will be nil
          #  if @dialog.dialog.nil?
          #    require 'bim-tools/ui/bt_dialog.rb'
          #    @dialog = Bt_dialog.new(bimTools)
          #    #bim_tools.dialog = @dialog
          #  else
          #    @dialog.close
          #    @dialog = nil
          #  end
          #end
          
          # switch dialog visibility
          @bimTools.btDialog.toggle
          
        }
    
        cmd_planars_from_selection = UI::Command.new("Creates building elements from selected faces") {
          selection = Sketchup.active_model.selection
          if selection.length > 0
            require "bim-tools/tools/planars_from_faces.rb"
            
            planars_from_faces = PlanarsFromFaces.new(@bimTools.active_BtProject, selection)
            Sketchup.active_model.select_tool planars_from_faces
            
            #planars_from_faces(@project, selection)
          end
        }
        
        # switch between source and geometry visibility
        cmd_toggle_geometry = UI::Command.new("Toggle between sources and geometry") {
          require "bim-tools/tools/toggle_geometry.rb"
          
          toggle_geometry = ToggleGeometry.new(@bimTools.active_BtProject)
					Sketchup.active_model.select_tool(toggle_geometry)
					#toggle_geometry.activate
          
          #@bimTools.active_BtProject.toggle_geometry()
        }
        
        # Remove BIM properties from selection
        cmd_clear = UI::Command.new("Remove BIM properties from selection") {
          require "bim-tools/tools/clear_properties.rb"
          selection = Sketchup.active_model.selection
          ClearProperties.new(@bimTools.active_BtProject, selection)
        }
    
        cmd_bimtools.small_icon = "../images/bimtools_small.png"
        cmd_bimtools.large_icon = "../images/bimtools_large.png"
        cmd_bimtools.tooltip = "Open BIM-Tools window"
        cmd_bimtools.status_bar_text = "Open BIM-Tools window"
        # cmd_bimtools.menu_text = "Test"
        bt_toolbar = bt_toolbar.add_item cmd_bimtools
    
        cmd_planars_from_selection.small_icon = "../images/PlanarsFromFaces_small.png"
        cmd_planars_from_selection.large_icon = "../images/PlanarsFromFaces_large.png"
        cmd_planars_from_selection.tooltip = "Creates building elements from selected faces"
        cmd_planars_from_selection.status_bar_text = "Creates building elements from selected faces"
        bt_toolbar = bt_toolbar.add_item cmd_planars_from_selection
        
        cmd_toggle_geometry.small_icon = "../images/ToggleGeometry_small.png"
        cmd_toggle_geometry.large_icon = "../images/ToggleGeometry_large.png"
        cmd_toggle_geometry.tooltip = "Toggle between sources and geometry"
        cmd_toggle_geometry.status_bar_text = "Toggle between sources and geometry"
        bt_toolbar = bt_toolbar.add_item cmd_toggle_geometry
        
        cmd_clear.small_icon = "../images/clear_small.png"
        cmd_clear.large_icon = "../images/clear_large.png"
        cmd_clear.tooltip = "Remove BIM properties"
        cmd_clear.status_bar_text = "Remove BIM properties from selection"
        bt_toolbar = bt_toolbar.add_item cmd_clear
    
        bt_toolbar.show
      end
    end
  end # module BimTools
end # module Brewsky
