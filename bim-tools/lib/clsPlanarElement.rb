#       clsPlanarElement.rb
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
    require 'bim-tools/lib/clsBuildingElement.rb'
    require 'bim-tools/lib/ObserverManager.rb'

    # building element subtype “planar” class
    # "Thick-face" linked to sketchup "face"
    class ClsPlanarElement < ClsBuildingElement
      attr_reader :element_type, :openings, :linked_elements
      def initialize(project, face, width=nil, offset=nil, guid=nil) # profilecomponent=width, offset

        # load default values: This should be done once in a central place ?BtProject?
        require 'bim-tools/lib/clsDefaultValues.rb'
        @default = ClsDefaultValues.new

        @project = project

        # check if there is a valid source face
        if face.is_a? Sketchup::Face
          @source = face
        else
          raise "No valid source face given"
        end

        @deleted = false
        @source_hidden = @project.visible_geometry? # for function in ClsBuildingElement
        @geometry
        @aPlanesHor
        
        # Array of connecting bt_entities that need updating when geometry changes
        @linked_elements = Array.new

        # Array that holds sub-arrays containing the point3d-objects from all opening-loops
        @openings = Array.new
        @element_type
        @name
        @description
        @guid = guid
        @length
        @height

        if width.nil?
          @width = @default.get("planar_width").to_l
        else
          @width = width
        end
        if offset.nil?
          @offset = @default.get("planar_offset").to_l
        else
          @offset = offset
        end

        init_type
        add_to_lib
        if @guid.nil?
          set_guid
        end
        set_attributes
        set_planes
      end

      # create the geometry for the planar element
      def set_geometry
        entities = Sketchup.active_model.active_entities
        @tops = []
        @bottoms = []

        # re-calculate all connecting elements, clear array
        @linked_elements.clear
        
        # check source face validity
        self.check_source
        
        # do not recreate geometry when marked for deletion
        if @deleted == false

          #find origin
          geometry_transformation = find_geometry_transformation
          
          # create empty component for geometry object
          if @geometry.nil? || @geometry.deleted?

            model = Sketchup.active_model
            definitions = model.definitions
            new_name = definitions.unique_name "BuildingElement"
            componentdefinition = definitions.add new_name
            @geometry = entities.add_instance componentdefinition, geometry_transformation
          else

            # gets fired furtheron in the script, just before drawing so temporary group also gets deleted
            @geometry.definition.entities.clear!
          end
          
          # set the transformation for the geometry object
          @geometry.transformation = geometry_transformation

          # array that holds the vertical-planes-array for every loop
          aLoopsVertPlanes = Array.new
          nOuterLoopNum = 0
          nLoopCount = 0
          nOuterLoopNum == 0
          
          # create empty polygonmesh for building the geometry
          pm = Geom::PolygonMesh.new
          
          #create all loops
          find_loops( @source ).each do |loops|

            loops.each do |loop|
              nLoopCount += 1
              aPlanesVert = Array.new
              aPlanesSoft = Array.new
              prev_edge = loop.last 
  
              # zoek de verticale plane voor alle edges
              loop.each do |construction_edge|# @source.outer_loop.edges.each do |edge|
                
                edge = construction_edge.source_edge
                softness = edge.soft?
  
                line = construction_edge.line # a line is represented by an array with 1 point and 1 vector
                point = construction_edge.source_edge.start.position # point on the line
                line_vector = line[1] # 2nd vector
                plane = construction_edge.plane
  
                # in case the vectors are parallel, add a helper plane in between for filling the gap
                if line_vector.parallel? prev_edge.line[1] # what if the vectors are on the same line but facing each other?
                  perp_plane = [point, prev_edge.line[1]]
                  aPlanesVert << perp_plane
                end
                prev_edge = construction_edge
                
                aPlanesVert << plane
                aPlanesSoft << softness
              end
  
              # Send both arrays to the loops array
              aPlanes = Array[aPlanesVert, aPlanesSoft]
              aLoopsVertPlanes << aPlanes
            end
  
            nLoopCount = 0
  
            # array will hold all temporary top and bottom faces(that is all exept that of the outer loop)
            aTempFaces = Array.new
  
            #placed here so temporary group also gets deleted
            @geometry.definition.entities.clear!
  
            aLoopsVertPlanes.each do |aPlanes|
  
              # get the array of planes
              aPlanesVert = aPlanes[0]
  
              # get the corresponding array with plane softness
              aPlanesSoft = aPlanes[1]
  
              # collect the needed points for the top and bottom faces in an array
              aFacePtsTop = Array.new
              aFacePtsBottom = Array.new
  
              # create side faces on every base-face edge
              i = 0
              j = aPlanesVert.length
              while i < j do
  
                # get softness
                softness = aPlanesSoft[i]
                
                plane = aPlanesVert[i]
                if i == 0
                  plane1 = aPlanesVert[j-1]
                else
                  plane1 = aPlanesVert[i-1]
                end
  
                # if both planes are parallel then there is no intersection between planes
                line_start = Geom.intersect_plane_plane(plane1, plane)
  
                if i == j - 1
                  plane2 = aPlanesVert[0]
                else
                  plane2 = aPlanesVert[i+1]
                end
                # if both planes are parallel then there is no intersection between planes
                line_end = Geom.intersect_plane_plane(plane2, plane)
  
                # separate array for top and bottom face???
                caps = []
                caps[0] = Geom.intersect_line_plane(line_start, self.planes[0])
                caps[1] = Geom.intersect_line_plane(line_start, self.planes[1])
                caps[2] = Geom.intersect_line_plane(line_end, self.planes[1])
                caps[3] = Geom.intersect_line_plane(line_end, self.planes[0])
                
                # separate array for side faces created with fill_from_mesh???
                pts = []
                pts[0] = pm.add_point(caps[0])
                pts[1] = pm.add_point(caps[1])
                pts[2] = pm.add_point(caps[2])
                pts[3] = pm.add_point(caps[3])
                
  
                # ?crude? fix for reversed faces in opening sides
                unless nOuterLoopNum == nLoopCount
                  pts.reverse!
                end
                unless aFacePtsTop.last == caps[0]
                  aFacePtsTop << caps[0]
                end
                unless aFacePtsBottom.last == caps[1]
                  aFacePtsBottom << caps[1]
                end
  
                # when 2 faces are on the same plane no perpendicular face is needed
                unless pts[1] == pts[2]
                  # check if the resulting face intersects itself
                  ########???????? Is a self intersecting face a problem? It results in a valid volume...
                  
                  #if (caps[0] - caps[1]).length < (caps[0] - caps[2]).length # not always correct...
                  
                  # create the possible line sections for the 4 points and check if they cross
                  # the rule here is that the two diagonals(cross, self intersect)
                  # added up in total have a greater length than the sides("square", not self intersect) added up.
                  vec1 = caps[0] - caps[1]
                  vec2 = caps[3] - caps[2]
                  vec3 = caps[0] - caps[2]
                  vec4 = caps[3] - caps[1]
                  if (vec1.length + vec2.length) > (vec3.length + vec4.length)
                    line1 = [caps[0], (caps[0] - caps[1])]
                    line2 = [caps[3], (caps[3] - caps[2])]
                    point = pm.add_point(Geom.intersect_line_line(line1, line2))
  
                    ## split in two triangular faces! (!) softness does not check 2 faces, only one
                    #face = group.definition.entities.add_face pts[0], point, pts[3]
                    #face = group.definition.entities.add_face pts[1], point, pts[2]
                    face = pm.add_polygon([pts[0], point, pts[3]])
                    pm.add_polygon([pts[2], point, pts[1]])
                  else # create face
                    
                    # to set softness for an edge use negative version of point-id of start and end-point
                    if softness == true
                      pts = pts.map {|pt| pt*-1}
                    end
                    face = pm.add_polygon(pts)
                  end
                end
                i += 1
              end
              @tops << aFacePtsTop
              @bottoms << aFacePtsBottom
            end
            
            # create the top and bottom faces
            @tops.each do |top|
              face_top = pm.add_polygon(top)
            end
              
            @bottoms.each do |bottom|
              bottom.reverse!
              face_bottom = pm.add_polygon(bottom)
            end
          end
          
          group = @geometry.definition.entities.add_group
          material = @source.material
          smooth_flags = Geom::PolygonMesh::HIDE_BASED_ON_INDEX
          group.entities.fill_from_mesh(pm, true, smooth_flags, material)
          group.explode

          @geometry.definition.entities.each do |ent|
            if ent.is_a? Sketchup::Edge
              if ent.faces.length == 1
                #ent.erase! (?) not needed?
              elsif ent.faces.length == 3
                ent.faces.each do |face|
                  unless face.deleted?
                    if face.normal.parallel?(@source.normal) && face.loops.length == 1
                      face.erase!
                    end
                  end
                end
              end
            end
          end

          # move group entities back in position with the inverse transformation
          a_entities = Array.new
          @geometry.definition.entities.each do |entity| # pas de transformatie toe op de volledige inhoud van de group, dit kan beter vooraf gedaan worden...
            a_entities << entity
          end
          @geometry.definition.entities.transform_entities(geometry_transformation.invert!, a_entities) # misschien kan beter transform_by_vectors gebruikt worden?

          # reset bounding box
          @geometry.definition.entities.parent.invalidate_bounds

          # check if source or geometry must be hidden
          if @project.visible_geometry? == true
            @source.hidden=true
          else
            @geometry.hidden=true
          end

          # save all properties as attributes in the group
          set_attributes
        end
      end

      def find_geometry_transformation
        
        a_Vertices = Array.new
        a_Vectors = Array.new
        x = nil
        y = nil
        z = nil

        @source.vertices.each do |vertex|
          po = vertex.position
          pn = Geom::Point3d.new(po.x, po.y, po.z)

          #find lowest value for x, y and z
          if x.nil?
            x = pn.x
          else
            if pn.x < x
              x = pn.x
            end
          end
          if y.nil?
            y = pn.y
          else
            if pn.y < y
              y = pn.y
            end
          end
          if z.nil?
            z = pn.z
          else
            if pn.z < z
              z = pn.z
            end
          end
        end

        origin = Geom::Point3d.new(x, y, z)
        zaxis = @source.normal
        
        Geom::Transformation.new(origin, zaxis)

      end
      
      # combine all defining faces and extract all merged loops
      def find_loops( source_face )
        loops_array = Array.new
        
        # if there are glued components combine loops, else just take source face loops
        if source_face.get_glued_instances.length > 0
          loops = get_glued_loops[0] # ?!!!?? DELETE THE SECOND VALUE, REDUNDANT?
          
          # copy source face into (a group inside) geometry
          base = @geometry.definition.entities.add_group
          #base.transformation = @geometry.transformation
          source_face.loops.each do |loop|
            base.entities.add_face loop.vertices# ?delete holes?
            
            ##########!!!!!!!!!!!!!!!!!! IMPORTANT METHOD FOR DELETING HOLES
            unless loop == source_face.outer_loop
              loop.face.erase!
            end
          end
          
          # generate faces from holes, and add these to a group inside geometry
          holes = @geometry.definition.entities.add_group
          temp = holes.entities.add_group
          loops.each do | loop |
          
            ########!!!!!!!!!!!!!!!!!!!!! REPLACE WITH FILL FROM MESH
            temp.entities.add_face loop.vertices
          end
          #temp cleanup edges
          temp.explode # easy intersect all edges
          holes.entities.each do |ent|
            if ent.is_a? Sketchup::Edge
              ent.find_faces
              #if ent.faces != 1
                #ent.erase!
              #end
            end
          end
          
         # base.entities.intersect_with false, base.transformation, holes.entities, holes.transformation, true, holes.entities.to_a#aEdges
          
          
          # intersect both groups, placing intersection lines inside holes-group
          
          #cutgroupentities = base.entities
          #cut_trans = base.transformation
          #basegroup = holes
         # base_trans = holes.transformation
          
          
          #cutgroupentities.intersect_with false, cut_trans, basegroup, base_trans , true, basegroup
          #base.entities.intersect_with false, base.transformation, holes, holes.transformation , true, holes
          holes.entities.intersect_with false, holes.transformation, holes, holes.transformation , true, base
          
          
          # create an array of all FACES inside the holes-group
          holes_entities = holes.entities.to_a
          
          # explode both groups
          base.explode
          holes.explode
          
          # intersect all
          # delete all objects in FACES array
          
          holes_entities.each do |ent|
            if ent.is_a? Sketchup::Face
              unless ent.deleted?
                ent.erase!
              end
            end
          end
          faces1 = []
          @geometry.definition.entities.each do |ent|
            if ent.is_a? Sketchup::Face
            faces1 << ent
            end
          end
          
          @geometry.definition.entities.each do |ent|
            if ent.is_a? Sketchup::Face
            loop_array = Array.new

              #get all non-outer_loops of the source face
              ent.loops.each do |loop|
                unless loop == ent.outer_loop
                  construction_edges = Array.new
                  loop.edges.each do |edge|
                    construction_edges << ConstructionEdge.new(@project, edge, self)
                  end
                
                  loop_array << construction_edges
                end
              end
              
              # add the outer loop on position 0
              construction_edges = Array.new
              ent.outer_loop.edges.each do |edge|
                construction_edges << ConstructionEdge.new(@project, edge, self)
              end
              loop_array.insert(0, construction_edges)
              loops_array << loop_array
            end
          end
        else
        
          #get all non-outer_loops of the source face
          loop_array = Array.new
          @source.loops.each do |loop|
            unless loop == @source.outer_loop
              construction_edges = Array.new
              loop.edges.each do |edge|
                construction_edges << ConstructionEdge.new(@project, edge, self)
              end
            
              loop_array << construction_edges
            end
          end
          # add the outer loop on position 0
          construction_edges = Array.new
          @source.outer_loop.edges.each do |edge|
            construction_edges << ConstructionEdge.new(@project, edge, self)
          end
          loop_array.insert(0, construction_edges)
          loops_array << loop_array
        end

        loops_array
      end

      # returns an array of all openings in a planar object(face-cutting instances AND normal openings(loops))
      # Make sure you delete the temporary group afterwards
      def get_glued_loops

          aLoops = Array.new
          aEdges = Array.new
          group = @geometry.definition.entities.add_group

          @source.get_glued_instances.each do |instance|

            transform = group.transformation.invert! * instance.transformation

            # copy all edges that are on the x-y plane to the new group
            instance.definition.entities.each do |entity|
              if entity.is_a?(Sketchup::Edge)
                if entity.start.position.z == 0
                  if entity.end.position.z == 0
                    new_start = entity.start.position.transform transform
                    new_end = entity.end.position.transform transform

                    edge = group.definition.entities.add_line new_start, new_end
                    aEdges << edge
                  end
                end
              end
            end
          end

          ############### ?BUGSPLAT? #######################
          group.definition.entities.intersect_with false, group.transformation, group.definition.entities, group.transformation, true, aEdges
          ############### ?BUGSPLAT? #######################

          # create all possible faces
          group.definition.entities.each do |entity|
            if entity.is_a?(Sketchup::Edge)
              entity.find_faces
            end
          end

          # delete unneccesary edges
          group.definition.entities.each do |entity|
            if entity.is_a?(Sketchup::Edge)
              if entity.faces.length != 1
                entity.erase!
              end
            end
          end

          #find all outer loops of the cutting component
          group.definition.entities.each do |entity|
            if entity.is_a?(Sketchup::Face)
              aLoops << entity.outer_loop
            end
          end

          t = @geometry.transformation.inverse

          # copy all loop-Point3d-objects to the @openings array
          # the purpose of this is that the temporary group can be erased earlier
          aLoops.each do |loop|
            opening = Array.new
            loop.vertices.each do |vert|
              point = vert.position.transform t
              opening << point
            end
            @openings << opening
          end

          return Array[aLoops, group]
      end

      def possible_types
        return Array["Wall", "Floor", "Roof"]
      end

      def length?

        # define_length here might cause unneccesary overhead
        define_length
        return @length
      end

      def height?

        # define_height here might cause unneccesary overhead
        define_height
        return @height
      end

      def width
        return @width
      end

      def width=(width)
        @width = width.to_l
        set_planes
      end
      alias :thickness= :width=

      def update_geometry
        set_planes
        set_geometry
        define_length
        define_height
      end

      def geometry=(geometry)
        @geometry = geometry
      end

      def offset
        return @offset
      end

      def offset=(offset)
        @offset = offset.to_l
        set_planes #(?)
      end

      def name=(name)
        @name = name
      end

      def description=(description)
        @description = description
      end

      def length=(length)

        # scale_source to match new length
        scale_source(length.to_l, height?)

        #set_planes
      end

      def height=(height)

        # scale_source to match new height
        scale_source(length?, height.to_l)

        #set_planes
      end

      # calculate the planar´s "length" == size in x-direction
      # (?) runs twice?
      def define_length
        
        length = nil
        min = nil
        max = nil

        #check if geometry object is valid
        if check_source == true
        
          #check_geometry
          unless @geometry.deleted?
            t = @geometry.transformation.inverse
            #(!) if @source is deleted: error!
            @source.vertices.each do |vertex|
              p = vertex.position.transform t
              if min.nil?
                min = p.x
              elsif p.x < min
                min = p.x
              end
              if max.nil?
                max = p.x
              elsif p.x > max
                max = p.x
              end
            end
            length = max - min
          end
          return @length = length.to_l
        end
      end

      # calculate the planar´s "height"  == size in y-direction
      def define_height
        height = nil
        min = nil
        max = nil

        #check if geometry object is valid, how best?
        if check_source == true
          #check_geometry
          unless @geometry.deleted?
            t = @geometry.transformation.inverse
            check_source
            @source.vertices.each do |vertex|
              p = vertex.position.transform t
              if min.nil?
                min = p.y
              elsif p.y < min
                min = p.y
              end
              if max.nil?
                max = p.y
              elsif p.y > max
                max = p.y
              end
            end
            height = max - min
          end
          return @height = height.to_l
        end
      end

      # scale @source to match a new height and length
      def scale_source(new_length, new_height)
        if new_length.nil? || new_length == 0
          x_scale = 1
        else
          x_scale = new_length / length?
        end
        if new_height.nil? || new_height == 0
          y_scale = 1
        else
          y_scale = new_height / height?
        end
        z_scale = 1

        model = Sketchup.active_model
        entities = model.active_entities

        t = @geometry.transformation
        ti = t.inverse

        ts = Geom::Transformation.scaling(x_scale, y_scale, z_scale)

        a_Vertices = Array.new
        a_Vectors = Array.new

        @source.vertices.each do |vertex|
          po = vertex.position
          pn = Geom::Point3d.new(po.x, po.y, po.z)

          pn.transform! ti
          pn.transform! ts
          pn.transform! t

          vx = pn.x - po.x
          vy = pn.y - po.y
          vz = pn.z - po.z

          v = Geom::Vector3d.new vx,vy,vz

          a_Vertices << vertex
          a_Vectors << v

        end

        entities.transform_by_vectors a_Vertices, a_Vectors

        #(?) why is @source deleted??? is moving vertices the same as scaling face???
        @project.source_recovery
      end

      # Array needed to find intersections with planes of connecting elements
      def planes
        return @aPlanesHor
      end

      # This defines the outer planes, parallel to the source face
      def set_planes
        if @source.deleted?
          check_source
        else

          # definieer het basisvlak voor het te maken element
          base_plane = @source.plane

          # maak het top-vlak, door het originele array te kopieeren en bij de offset(laatste waarde) de nieuwe afstand op te tellen.
          # Plane is een array van 4 waarden, waarvan de eerste 3 de unit-vector van het vlak beschrijven, en de laatste de loodrechte afstand van het vlak tot de oorsprong.
          top_plane = [base_plane[0], base_plane[1], base_plane[2], base_plane[3] + @width - @offset]
          bottom_plane = [base_plane[0], base_plane[1], base_plane[2], base_plane[3] - @offset]

          # Array needed to find intersections with planes of connecting elements
          @aPlanesHor = Array.new
          @aPlanesHor << bottom_plane
          @aPlanesHor << top_plane
        end
      end

      # met deze functie kun je een hash ophalen met alle informatieve eigenschappen
      def properties_fixed
        h_Properties = Hash.new
        if @geometry.volume > 0
          h_Properties["volume"] = (@geometry.volume* (25.4 **3)).round.to_s + " Millimeters ³"
        end
        h_Properties["guid"] = guid?
        return h_Properties
      end

      # met deze functie kun je een hash ophalen met alle eigenschappen die rechtstreeks te wijzigen zijn
      def properties_editable

        if @geometry.deleted?
          self_destruct
        else
          a_types = Array.new
          a_types << @element_type
          possible_types.each do |type|
            if type != @element_type
              a_types << type
            end
          end

          a_layers = Array.new
          a_layers << @geometry.layer.name
          Sketchup.active_model.layers.each do |layer|
            if layer != @geometry.layer
              a_layers << layer.name
            end
          end

          h_Properties = Hash.new
          h_Properties[:thickness] = @width
          h_Properties[:offset] = @offset
          h_Properties[:length] = length?
          h_Properties[:height] = height?
          h_Properties[:type] = a_types
          #h_Properties[:layer] = a_layers
          h_Properties[:name] = @name
          h_Properties[:description] = @description
          return h_Properties
        end
      end

      def properties=(h_Properties)

        @width = h_Properties["width"]
        @offset = h_Properties["offset"]
        length_new = h_Properties["length"]
        height_new = h_Properties["height"]
        #if length_new.nil?# || length_new == 0
        #  length_new = length?
        #end
        #if height_new.nil?
        #  height_new = height?
        #end

        # (!) only scale if length or height has changed
        unless length_new.nil? && height_new.nil?

          # check if length or height has changed
          #if length_new != length? || height_new != height?
          
          # scale_source to match new length
          scale_source(h_Properties["length"].to_l, h_Properties["height"].to_l)
        end
        @element_type = h_Properties["element_type"]
        @name = h_Properties["name"]
        @description = h_Properties["description"]
        set_planes
      end

      def set_type(value)
        if possible_types.include? value
          @element_type = value
        end
      end

      # the element_type based on the initial source state
      def init_type
        @element_type = case source.normal.z
        when 0 then "Wall"
        when 1, -1 then "Floor"
        else "Roof"
        end
      end

      # write planar attributes to geometry object
      def set_attributes
        unless @geometry.nil?
          @geometry.set_attribute "ifc", "guid", guid?
          @geometry.set_attribute "ifc", "type", element_type?
          @geometry.set_attribute "ifc", "length", length?.to_f.to_s # store values as floats! http://www.thomthom.net/thoughts/2012/08/dealing-with-units-in-sketchup/
          @geometry.set_attribute "ifc", "height", height?.to_f.to_s
          @geometry.set_attribute "ifc", "width", @width.to_f.to_s #needs to be in planarelement class
          @geometry.set_attribute "ifc", "offset", @offset.to_f.to_s #needs to be in planarelement class
          @geometry.set_attribute "ifc", "description", description?.to_s
          @geometry.set_attribute "ifc", "name", name?.to_s

          # Try to write type as a ifc classification
          if Sketchup.version_number > 14000000
            if (Sketchup.is_pro?)

              # get matching ifc type
              ifc_type = case @element_type
              when "Wall" then "IfcWall"
              when "Floor" then "IfcSlab"
              when "Roof" then "IfcSlab"
              else nil
              end
              @geometry.definition.add_classification("IFC 2x3", ifc_type) unless ifc_type.nil?
            end
          end
        end
        unless @source.nil?
          @source.set_attribute "ifc", "guid", guid?
        end
      end

      def ifc_export(exporter)
        #require 'bim-tools/lib/ifc_export/clsIfc.rb'
        if @element_type == "Wall"
          # function to figure out if both values are almost equal
          def approx(val, other, relative_epsilon=Float::EPSILON, epsilon=Float::EPSILON)
            difference = other - val
            return true if difference.abs <= epsilon
            relative_error = (difference / (val > other ? val : other)).abs
            return relative_error <= relative_epsilon
          end
          #square_area = height? * length?

          # if the area of the source face equals length*height the face is a square
          # exept when wall openings are present!!!
          # and probably a wallstandardcase

          #if approx(@source.area, square_area)

          ######################
          #BEWARE OF NESTED COMPONENTS!
          edges = @source.outer_loop.edges

          if edges.length == 4 and edges[0].line[1].parallel? edges[2].line[1] and edges[1].line[1].parallel? edges[3].line[1] and edges[0].line[1].perpendicular? edges[1].line[1] and approx(@source.normal.z, 0)
            IfcWallStandardCase.new(@project, exporter, self)
          else
            IfcWall.new(@project, exporter, self)
          end
        elsif @element_type == "Floor" || @element_type == "Roof"
          IfcSlab.new(@project, exporter, self)
        else
          IfcPlate.new(@project, exporter, self)
        end
      end
      
      def add_linked_elements(linked_elements)
        @linked_elements.concat( linked_elements )
      end
      
      # find linked planars
      def find_linked_elements()
        @linked_elements.clear
        @source.edges.each do |edge|
          unless edge.deleted?
            edge.faces.each do |face|
              # check only if this face is not the base-face
              unless face == @source
                # add only bt-source-faces to array, bt-entities must not react to "normal" faces
                bt_entity = @project.library.source_to_bt_entity(@project, face)
                unless bt_entity == false
                  @linked_elements << bt_entity
                end
              end
            end
          end
        end
      end # def find_linked_elements
    end # class ClsPlanarElement
    
    # replacement object for edge while constructing side-faces
    # due to holes source-edges can get split up
    # these construction_edges need proper connections to the source faces
    class ConstructionEdge
      attr_accessor :source_edge, :construction_edge
      attr_reader :line, :plane
      def initialize(project, construction_edge, planar)
        
        # Array to hold al connecting bt_entities
        @linked_elements = Array.new
        
        @project = project
        @planar = planar
        @construction_edge = construction_edge
        @source_face = planar.source
        @source_edge = find_source_edge(construction_edge, @source_face)
        set_line
        set_plane
        set_softness
      end
      def find_source_edge(construction_edge, source_face)
        
        # check if deleted!!!!!!!!!
        
        source_face.edges.each do |edge|
          unless edge.deleted?
            if edge.bounds.contains? construction_edge.bounds
              if construction_edge.line[0].on_line? edge.line#edge lines are the same
                if construction_edge.line[1].parallel? edge.line[1]
                  return edge
                end
              end
            end
          end
        end
        return construction_edge
      end
      def soft?
        @softness
      end
      def set_softness
        if source_edge.soft?
          @softness = true
        else
          @softness = false
        end
      end
      def set_plane

        point = @line[0] # point on line
        line_vector = @line[1] # line vector
        
        find_linked_elements()

        # check if the plane must be perpendicular to the source or must respond to connected geometry
        if @linked_elements.length == 1
          linked_entity = @linked_elements[0]
        
          # if source and connecting faces are parallel, then also create vertical end.
          if @source_face.normal.parallel? linked_entity.source.normal
            plane_vector = @source_face.normal.cross line_vector # unit vector voor plane
            plane = [point, plane_vector]
          else

            # get the line where the planes intersect
            # if one of the faces is reversed the intersecting planes need to be switched
            
            ############## unable to check for reversed in temp_face???????????
            
            if @source_edge.reversed_in?( @source_face ) == @source_edge.reversed_in?( @linked_elements[0].source)
              bottom_line = Geom.intersect_plane_plane(@planar.planes[0], linked_entity.planes[1])
              top_line = Geom.intersect_plane_plane(@planar.planes[1], linked_entity.planes[0])
            else
              bottom_line = Geom.intersect_plane_plane(@planar.planes[1], linked_entity.planes[1])
              top_line = Geom.intersect_plane_plane(@planar.planes[0], linked_entity.planes[0])
            end
            point1 = bottom_line[0]
            point2 = bottom_line[0] + bottom_line[1]
            point3 = top_line[0]
            plane = Geom.fit_plane_to_points point1, point2, point3
          end
        else
          # vertical plane
          plane_vector = @source_face.normal.cross line_vector # unit vector for plane
          plane = [point, plane_vector]
        end
        @plane = plane
      end
      def set_line
        @line = @source_edge.line
      end
      def find_bt_entity_for_face(source)
        bt_entity = nil
        @project.library.entities.each do |ent|
          if source == ent.source
            bt_entity = ent
            break
          end
        end
        bt_entity
        return bt_entity
      end
      
      # find planars for linked faces 
      def find_linked_elements()
            
        # determine the number of connecting bt-source-faces
        @source_edge.faces.each do |face|

          # check only if this face is not the base-face
          unless face == @source_face

            # add only bt-source-faces to array, bt-entities must not react to "normal" faces
            bt_entity = @project.library.source_to_bt_entity(@project, face)
            unless bt_entity == false
              @linked_elements << bt_entity
            end
          end
        end
        @planar.add_linked_elements(@linked_elements)
      end
    end # class ConstructionEdge
  end # module BimTools
end # module Brewsky
