require 'gerber/exceptions'

class Gerber
    class ApertureMacro
	attr_reader :name, :primitives

	Circle = Struct.new :exposure, :diameter, :x, :y
	Line = Struct.new :exposure, :width, :start_x, :start_y, :end_x, :end_y, :rotation
	CenteredLine = Struct.new :exposure, :width, :height, :center_x, :center_y, :rotation
	OriginLine = Struct.new :exposure, :width, :height, :left, :bottom, :rotation
	Outline = Struct.new :exposure, :vertex_count, :points
	Polygon = Struct.new :exposure, :vertex_count, :center_x, :center_y, :diameter, :rotation
	Moire = Struct.new :center_x, :center_y, :outer_diameter, :ring_thickness, :gap, :ring_count, :crosshair_thickness, :crosshair_length, :rotation
	Thermal = Struct.new :center_x, :center_y, :outer_diameter, :inner_diameter, :gap, :rotation

	def initialize(*args)
	    @name = args.shift
	    @primitives = []
	end

	def push_primitive(*args)
	    primitive_code = args.shift
	    case primitive_code
		when '1'
		    @primitives.push Circle.new *args
		when '2', '20'
		    @primitives.push Line.new *args
		when '21'
		    @primitives.push CenteredLine.new *args
		when '22'
		    @primitives.push OriginLine.new *args
		when '4'
		    @primitives.push Outline.new args.shift(2)
		    primitive = @primitives.last
		    raise ParseError, "Number of vertices must match vertex count" if (2*primitive.vertex_count) != args.count
		    primitive.points = []
		    args.each_slice(2) {|x,y| primitive.points.push Point[x,y] }
		when '5'
		    _, _, center_x, center_y, _, rotation = args
		    raise ParseError, "Polygon rotation is only allowed if the center point is on the origin" if (rotation != 0) && (0 == center_x) && (0 == center_y)
		    @primitives.push Polygon.new *args
		when '6'
		    center_x, center_y, _, _, _, _, _, _, rotation = args
		    raise ParseError, "Moire rotation is only allowed if the center point is on the origin" if (rotation != 0) && (0 == center_x) && (0 == center_y)
		    @primitives.push Moire.new *args
		when '7'
		    p 'macro thermal'
		    center_x, center_y, outer_diameter, _, gap, rotation = args
		    raise ParseError, "Thermal rotation is only allowed if the center point is on the origin" if (rotation != 0) && (0 == center_x) && (0 == center_y)
		    raise ParseError, "Thermal gap thickness must be smaller than the outer diameter" unless gap < outer_diameter
		    @primitives.push Thermal.new *args
		else
		    raise ParseError, "Unrecognized primitive code #{primitive_code}"
	    end
	end
    end
end
