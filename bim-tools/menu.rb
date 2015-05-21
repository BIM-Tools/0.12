#       dialog.rb
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

  SKUI_PATH = File.join( PATH_LIB, 'SKUI' )
  load File.join( SKUI_PATH, 'embed_skui.rb' )
  ::SKUI.embed_in( self )

  module Menu
    extend self
    attr_accessor :window
    
    @section_y = 40
    @section_margin = 4
    @sections = Array.new
    @icon_x = 4
    
    options = {
      :title           => 'BIM-Tools',
      :preferences_key => 'BIM-Tools',
      :width           => 243,
      :height          => 400,
      :resizable       => true,
      :theme           => File.join( PATH_CSS, 'theme.css' ).freeze
    }

    @window = SKUI::Window.new( options )
    @window.add_script(File.join( PATH, 'js', 'bim-tools.js' ))
    

    
    def on_off
      stored = Sketchup.read_default 'bim-tools', 'on_off'
      value = 'off'
      value = 'on' if stored == 'on'
      image = File.join( PATH_IMAGE, value + '_large.png' )
      
      # calculate relative path
      require 'pathname'; 
      return "../" + Pathname.new( image ).relative_path_from(Pathname.new( SKUI_PATH )).to_s # wrong path?

    end

    def add_icon( image, tooltip )
      c = SKUI::Button.new( "" ) { yield c, image}
      c.position( @icon_x, 4 )
      c.width = 24
      c.right = 24
      c.tooltip = tooltip
      c.css_class( 'icon' )
      
      c.background_image = image
      
      @icon_x = @icon_x + 28
      
      @window.add_control( c )
      
      return c
      
    end # def add_icon
    
    # add to menu-icons
    i = self.add_icon( File.join( on_off ), 'Toggle between manual and automatic mode' ) { |c, image|
      
      # tool
      Brewsky::BimTools::ObserverManager.toggle
      
      c.background_image = on_off
          
      #refresh all geometry
      @bimTools.active_BtProject.library.entities.each do |bt_entity|
        bt_entity.update_geometry
      end
      
    }
    
    def add_section( tool )
      sec = Section.new( tool )
      @sections << sec
      sec
    end
    
    def show( section )
      @window.show
    end
    
    def close
      @window.close
    end # def close
    
    def open
      position_sections
      #@window.width = 243
      @window.set_size( 243, 400 )
      @window.show
      @window.set_size( 243, 400 )
    end # def open
    
    def close_section( section )
      section.close
    end # def close_section
    
    def open_section( section )
      section.open
      @window.show
    end # def open_section
    
    def position_sections
      y = 32
      @sections.each do |sec|
      
        sec.set_visibility
      
        sec.set_position( y )
        y += sec.get_height
      end
    end # def position_sections
    
    def toggle_window
      if @window.visible?
        close
      else
        open
      end
    end # def toggle_window
    
    def update_sections(selection)
      position_sections
      
      
      #?????????????????????????????????????????
      
      
      
    end
    
    # update menu contents
    def update
      if @window.visible?
        position_sections
      end
    end # def update
    
    class Section
      attr_accessor :height
      def initialize( tool )
        @unit = 25
        @height = 48
        @closed = true
        @tool = tool
        
        @groupbox = SKUI::Groupbox.new( @tool.name )
        @groupbox.position( 2, 2 )
        @groupbox.right = 2
        @groupbox.height = @height
        Brewsky::BimTools::Menu::window.add_control( @groupbox )
        
        @controls = @groupbox.controls
        
        
        # add icon next to title
        if tool.small_icon.nil?
          image = File.join( PATH_IMAGE, 'bimtools_small.png')
        else
          image = tool.small_icon
        end
        @icon = SKUI::Image.new( image )
        @icon.position( 6, 6 )
        @icon.size( 16, 16 )
        
        @groupbox.add_control( @icon )
        
      end
      def add_button( name )
        control = SKUI::Button.new( name ) { yield control}
        control.position( 10, @groupbox.height - 22 )
        control.width = 203
        control.right = 10 # (!) Currently ignored by browser.
        #control.tooltip = 'Click me!'
        control.visible = false
        @groupbox.add_control( control )
      
        increase_height
      end
      def add_textbox( symbol, value="-" )
        
        txt = SKUI::Textbox.new( value )
        txt.name = symbol
        txt.position( 90, @groupbox.height - 22 )
        txt.right = 10 # (!) Currently ignored by browser.
        txt.visible = false
        @groupbox.add_control( txt )
        
        # create formatted title from symbol
        title = symbol.capitalize.to_s.gsub('_', ' ')
    
        lbl = SKUI::Label.new( title + ':', txt )
        lbl.position( 10, @groupbox.height - 19 )
        lbl.width = 50
        lbl.visible = false
        @groupbox.add_control( lbl )
    
        increase_height
        
        return txt
      end
      def add_listbox( symbol, list=["none"] )
        
        lst = SKUI::Listbox.new( list )
        lst.name = symbol
        lst.position( 90, @groupbox.height - 22 )
        lst.right = 10
        lst.visible = false
        lst.value = lst.items.first
        @groupbox.add_control( lst )
        
        # create formatted title from symbol
        title = symbol.capitalize.to_s.gsub('_', ' ')
    
        lbl = SKUI::Label.new( title + ':', lst )
        lbl.position( 10, @groupbox.height - 19 )
        lbl.width = 50
        lbl.visible = false
        @groupbox.add_control( lbl )
        
        increase_height
        
        return lst
      end
      def get_height
        if @closed == true
          return 30
        else
          return @height
        end
      end # get_height
      def increase_height
        @groupbox.height += @unit
        @height = @groupbox.height - 20
      end
      def set_position( position )
        @groupbox.position( 2, position )
        @groupbox.right = 2
      end
      def close
        @closed = true
        @groupbox.controls.each do |control|
          control.visible = false
        end
        @icon.visible = true
      end # def close
      def open
        @closed = false
        @groupbox.controls.each do |control|
          control.visible = true
        end
      end # def open
      def set_value(symbol, value)
        if @groupbox[symbol].is_a? SKUI::Listbox # is this the right place to select between types?
          @groupbox[symbol].clear
          if value.is_a? Array
            value.each do |val|
              @groupbox[symbol].add_item val
            end
          else
            @groupbox[symbol].add_item value.to_s
          end
        elsif @groupbox[symbol].is_a? SKUI::Textbox
          @groupbox[symbol].value = value
        end
      end # def set_value
      def set_visibility
        if @tool.show_section?
          open
        else
          close
        end
      end # def set_visibility
    end # class Section
    
  end # module Menu
 end # module BimTools
end # module Brewsky
