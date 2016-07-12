#       paint_properties.rb
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

# Copy BIM-Tools properties from selection to target object

module Brewsky
 module BimTools
  module PaintProperties
    extend self
    attr_accessor :name, :small_icon, :large_icon
    
    @name = 'Paint properties'
    @description = 'Copy properties of BIM-Tools elements'
    @small_icon = File.join( PATH_IMAGE, 'PaintProperties_small.png' )
    @large_icon = File.join( PATH_IMAGE, 'PaintProperties_large.png' )
    @cursor_icon = File.join( PATH_IMAGE, 'PaintProperties-cursor.png' )
    
    @source = nil
    @cursor_id = nil
    
    # create cursor
    if File.file?( @cursor_icon ) # check if file is really a file
      @cursor_id = UI.create_cursor( @cursor_icon, 4, 3 )
    end
    
    # The activate method is called by SketchUp when the tool is first selected.
    # it is a good place to put most of your initialization
    def activate
      @model = Sketchup.active_model
      @project = BimTools.active_BtProject
      
      self.reset(nil)
      
      
      UI.set_cursor( @cursor_id )
      
      # if a source object is already selected, use that and skip step 1
      if @model.selection.length == 1
        if @source = @project.library.geometry_to_bt_entity(@project, @model.selection[0])
          @state = 1
          Sketchup::set_status_text "Select target object", SB_PROMPT
        end
      end
    end

    # deactivate is called when the tool is deactivated because
    # a different tool was selected
    def deactivate(view)
    end

    # The onLButtonDOwn method is called when the user presses the left mouse button.
    def onLButtonDown(flags, x, y, view)
      ph = view.pick_helper
      ph.do_pick(x, y)
      bp = ph.best_picked
      
      # When the user clicks the first time, we switch to getting the
      # second point.  When they click a second time we copy properties
      if( @state == 0 )
        if bp
            @model.selection.clear
            @model.selection.add bp
          if @source = @project.library.geometry_to_bt_entity(@project, bp)
            @state = 1
            Sketchup::set_status_text "Select target object", SB_PROMPT
          end
        end
      else
        # copy properties on second and following clicks
        if bp
          if target = @project.library.geometry_to_bt_entity(@project, bp)
            self.copy_properties( @source, target )
          end
        end
      end
    end
    
    # copy all properties from source to target
    def copy_properties( source, target )
      
      # start undo section
      @model.start_operation("Paint BIM-Tools properties", disable_ui=true)
        target.width = source.width
        target.offset = source.offset
        puts source.material
        target.set_material( source.material )
        #target.update_geometry
        BimTools.active_BtProject.source_changed(target)
      @model.commit_operation # End of operation/undo section
      @model.active_view.refresh # Refresh model
    end # def copy_properties
    
    # Reset the tool back to its initial state
    def reset(view)
        # This variable keeps track of which point we are currently getting
        @state = 0
        
        # Display a prompt on the status bar
        Sketchup::set_status_text "Select source object", SB_PROMPT
        
        # clear source object
        @source = nil
        
        if( view )
            view.tooltip = nil
        end
    end # def reset

    def onSetCursor
      UI.set_cursor( @cursor_id )
    end
    
    # add to TOOLBAR
    
    cmd = UI::Command.new(@description) {
      
      # call tool
      Sketchup.active_model.select_tool( self )
    }
    cmd.small_icon = File.join( @small_icon )
    cmd.large_icon = File.join( @large_icon )
    cmd.tooltip = 'Paint properties'
    cmd.status_bar_text = 'Paint BIM-Tools properties'
    BimTools.toolbar.add_item cmd

    # add to menu-icons
    BimTools::Menu.add_icon( @large_icon, @description ) { |c, image|
      
      # call tool
      paint_properties = PaintProperties.new
      Sketchup.active_model.select_tool( paint_properties )
    }
    
    # add to OBSERVERS
          
  end # module PaintProperties
 end # module BimTools
end # module Brewsky
