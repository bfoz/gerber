require 'gerber/exceptions'

class Gerber
    class ApertureMacro
	attr_accessor :modifiers
	attr_reader :name, :primitives, :variables

	# Struct members must be in the same order as the corresponding elements of the primitives
	Circle = Struct.new :exposure, :diameter, :x, :y
	Line = Struct.new :exposure, :width, :start_x, :start_y, :end_x, :end_y, :rotation
	CenteredLine = Struct.new :exposure, :width, :height, :center_x, :center_y, :rotation
	OriginLine = Struct.new :exposure, :width, :height, :left, :bottom, :rotation
	Outline = Struct.new :exposure, :vertex_count, :points, :rotation
	Polygon = Struct.new :exposure, :vertex_count, :center_x, :center_y, :diameter, :rotation
	Moire = Struct.new :center_x, :center_y, :outer_diameter, :ring_thickness, :gap, :ring_count, :crosshair_thickness, :crosshair_length, :rotation
	Thermal = Struct.new :center_x, :center_y, :outer_diameter, :inner_diameter, :gap, :rotation

	Comment = Struct.new :text
	Definition = Struct.new :variable, :expression
	Variable = Class.new

	# @param [String] name	The name of the macro
	def initialize(*args)
	    @name = args.shift
	    @primitives = []
	end

	# Push a new comment primitive to the macro
	# @param [String] text	The comment text
	def push_comment(text)
	    text.strip!
	    @primitives.push Comment.new(text) if text && text.length
	end

	# Push a new {Variable} {Definition}
	# @param [String] text	The definition text
	def push_definition(variable, expression)
	    variable.strip!
	    expression.strip!
	    @primitives.push Definition.new(variable, expression) if [variable, expression].all? {|a| a && a.length }
	end

	# @param [Numeric,String] primitive_code    The primitive code of the Primitive to push
	# @param [Array] modifiers  The arguments to the primitive
	def push_primitive(*args)
	    primitive_code = args.shift
	    case primitive_code
		when '1', 1
		    @primitives.push Circle.new *args
		when '2', '20', 2, 20
		    @primitives.push Line.new *args
		when '21', 21
		    @primitives.push CenteredLine.new *args
		when '22', 22
		    @primitives.push OriginLine.new *args
		when '4', 4
		    @primitives.push Outline.new *args.shift(2)
		    primitive = @primitives.last
		    primitive.rotation = args.pop
		    primitive.points = [Point[*args.shift(2)]]
		    raise ParseError, "Number of vertices must match vertex count" if (2*primitive.vertex_count) != args.count
		    args.each_slice(2) {|x,y| primitive.points.push Point[x,y] }
		when '5', 5
		    _, _, center_x, center_y, _, rotation = args
		    raise ParseError, "Polygon rotation is only allowed if the center point is on the origin" if (rotation != 0) && (0 == center_x) && (0 == center_y)
		    @primitives.push Polygon.new *args
		when '6', 6
		    center_x, center_y, _, _, _, _, _, _, rotation = args
		    raise ParseError, "Moire rotation is only allowed if the center point is on the origin" if (rotation != 0) && (0 == center_x) && (0 == center_y)
		    @primitives.push Moire.new *args
		when '7', 7
		    center_x, center_y, outer_diameter, _, gap, rotation = args
		    raise ParseError, "Thermal rotation is only allowed if the center point is on the origin" if (rotation != 0) && (0 == center_x) && (0 == center_y)
		    raise ParseError, "Thermal gap thickness must be smaller than the outer diameter" unless gap < outer_diameter
		    @primitives.push Thermal.new *args
		else
		    raise ParseError, "Unrecognized primitive code #{primitive_code}"
	    end
	end

	# Converts the {ApertureMacro} to an array of blocks suitable for appending to an AM parameter
	def to_a
	    @primitives.map do |primitive|
		s = ''
		case primitive
		    when Comment
			s << '0 ' << primitive.text << '*'
		    when Definition
			s << '$' << primitive.variable << '=' << primitive.expression << '*'
		    when Circle
			s << '1,' << format_variables(*primitive.values).join(',') << '*'
		    when Line
			s << '2,' << format_variables(*primitive.values).join(',') << '*'
		    when CenteredLine
			s << '21,' << format_variables(*primitive.values).join(',') << '*'
		    when OriginLine
			s << '22,' << format_variables(*primitive.values).join(',') << '*'
		    when Outline
			s << '4,' << format_variables(primitive.exposure, primitive.vertex_count).join(',')
			s << ',' << primitive.points.map {|point| format_variables(point.x, point.y) }.flatten.join(',')
			s << ',' << format_variable(primitive.rotation) << '*'
		    when Polygon
			s << '5,' << format_variables(*primitive.values).join(',') << '*'
		    when Moire
			s << '6,' << format_variables(*primitive.values).join(',') << '*'
		    when Thermal
			s << '7,' << format_variables(*primitive.values).join(',') << '*'
		end
	    end
	end

	# Converts the {ApertureMacro} to a {String} suitable for appending to an AM parameter
	# @return [String]
	def to_s
	    self.to_a.join "\n"
	end

	private

	# Format an argument for a primitive
	def format_variable(v)
	    if v.kind_of?(Gerber::ApertureMacro::Variable)
		index = modifiers.index(v)
		index ? "$#{index}" : nil
	    else
		v.to_s
	    end
	end

	# Format an array of primitive arguments
	def format_variables(*args)
	    args.map {|v| format_variable v }
	end
    end
end
