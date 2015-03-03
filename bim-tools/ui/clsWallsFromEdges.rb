#       clsWallsFromEdges.rb
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
    require 'bim-tools/ui/clsDialogSection.rb'
    
    class ClsWallsFromEdges < ClsDialogSection
      def initialize(dialog, id)
        # load default values: This should be done once in a central place ?BtProject?
        require 'bim-tools/lib/clsDefaultValues.rb'
        @default = ClsDefaultValues.new
        @width = @default.get("wall_width").to_l
        @offset = @default.get("wall_offset").to_l
        @height = @default.get("wall_height").to_l
        
        @dialog = dialog
        @id = id.to_s
        #@project = dialog.project
        @status = true
        @name = "WallsFromEdges"
        @title = "Create walls from edges"
        @buttontext = "Create walls from edges"
        @html_content = html_content
        callback
      end
    
      #action to be started on webdialog form submit
      def callback
        @dialog.webdialog.add_action_callback(@name) {|dialog, params|
          selection = Sketchup.active_model.selection
          if selection.length > 0
          
            # construct wall objects
            require "bim-tools/tools/walls_from_edges.rb"
            
            height = dialog.get_element_value("height").to_l
            width = dialog.get_element_value("width").to_l
            offset = dialog.get_element_value("offset").to_l
            
            walls_from_edges = WallsFromEdges.new(@dialog.project, selection, height, width, offset)
            
            # the tool is not started from a toolbar so it needs to be activated.
            bt_entities = walls_from_edges.activate
            
          end
          self.update(bt_entities)
        }
      end
      
      # update webdialog based on selected entities
      def update(entities)
        @html_content = html_content
        refresh_dialog
      end
      
      def html_content
        edges = false
        Sketchup.active_model.selection.each do |entity|
          if entity.is_a?(Sketchup::Edge)
            edges = true
            break
          end
        end
        if edges == false
          @status = false
          return "
    <h2>No edges selected</h2>
          "
        else
          @status = true
          return "
    <form id='" + @name + "' name='" + @name + "' action='skp:" + @name + "@true'>
    " + html_properties_editable + html_properties_fixed + "
    <input type='submit' name='submit' id='submit' value='" + @buttontext + "' />
    </form>
          "
        end
      end
    
      def html_properties_editable
        sel = @dialog.selection
        
        fheight = Sketchup.format_length( @height ).gsub("'"){"&apos;"}
        fwidth = Sketchup.format_length( @width ).gsub("'"){"&apos;"}
        foffset = Sketchup.format_length( @offset ).gsub("'"){"&apos;"}
        
        html = "
              <label for='height'>Height:</label>
              <input name='height' type='text' id='height' value='" + fheight + "' />
              <label for='width'>Width:</label>
              <input name='width' type='text' id='width' value='" + fwidth + "' />
              <label for='offset'>Offset:</label>
              <input name='offset' type='text' id='offset' value='" + foffset + "' />
              "
        return html
      end
    
      def html_properties_fixed
        sel = @dialog.selection
        html = ""
        return html
      end
    end
  end # module BimTools
end # module Brewsky
