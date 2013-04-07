require 'geometry'

=begin
An Aperture definition for an Extended {Gerber} file
=end
class Gerber
    class Aperture
	attr_reader :macro, :name, :shape
	attr_accessor :hole, :parameters, :rotation

	Circle = Geometry::Circle
	Obround = Geometry::Obround
	Polygon = Geometry::RegularPolygon
	Rectangle = Geometry::Rectangle
	Size = Geometry::Size

	def initialize(parameters)
	    raise ArgumentError unless parameters.is_a? Hash

	    if parameters.has_key? :circle
		@shape = Geometry::Circle.new [0,0], :diameter => parameters[:circle]
		parameters.delete :circle
	    elsif parameters.has_key? :obround
		@shape = Geometry::Obround.new [0,0], parameters[:obround]
		parameters.delete :obround
	    elsif parameters.has_key? :polygon
		@shape = Geometry::RegularPolygon.new parameters[:sides], [0,0], :diameter => parameters[:polygon]
		parameters.delete :polygon
	    elsif parameters.has_key? :rectangle
		@shape = Geometry::Rectangle.new [0,0], parameters[:rectangle]
		parameters.delete :rectangle
	    end
	    parameters.each {|k| self.instance_variable_set("@#{k.first}", k.last) }
	end

	def ==(other)
	    (self.hole == other.hole) && (self.parameters == other.parameters) && ((self.rotation || 0.degrees) == (other.rotation || 0.degrees)) && (self.shape == other.shape) && (self.macro == other.macro)
	end

	# @return [Rectangle]	A bounding box for the {Aperture}
	def bounds
	    Rectangle.new self.size
	end

	# @return [Size]    The size of the {Aperture}
	def size
	    case @shape
		when Circle
		    Size[@shape.diameter, @shape.diameter]
		when Obround, Rectangle
		    Size[@shape.width, @shape.height]
		when Polygon
		    Size[2*@shape.radius, 2*@shape.radius]
	    end
	end

	# Converts the {Aperture} to a {String} suitable for appending to an AD parameter
	# @return [String]
	def to_s
	    s = ''
	    case @shape
		when Geometry::Circle
		    s = "C,#{@shape.diameter}"
		when Geometry::Obround
		    s = "O,#{@shape.width}X#{@shape.height}"
		when Geometry::Polygon
		    s = "P,#{@shape.diameter}X#{@shape.edge_count}"
		    if !@rotation || (0 == @rotation)
			s << 'X0' if @hole
		    else
			s << 'X' << @rotation.to_s
		    end
		when Geometry::Rectangle
		    s = "R,#{@shape.width}X#{@shape.height}"
	    end

	    case @hole
		when Numeric
		    s << "X#{@hole}"
		when Hash
		    s << 'X' << @hole.values.join('X')
	    end

	    s
	end
    end
end
