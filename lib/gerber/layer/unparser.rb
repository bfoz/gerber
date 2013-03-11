class Gerber
    class Layer
=begin
Unparse a Gerber image layer
=end
	class Unparser
	    attr_reader :layer
	    attr_reader :position

	    attr_accessor :integer_places, :decimal_places, :zero_omission

	    def initialize(layer)
		@layer = layer
		@zero_omission = :leading
	    end

	    # @param [Numeric]	The number to format as a coordinate
	    # @return [String]	The formatted coordinate
	    def format_coordinate(coordinate)
		return '0' if 0 == coordinate
		width = @integer_places + @decimal_places + 1
		if :leading == @zero_omission
		    ("%-0#{width}.#{@decimal_places}f" % coordinate).sub('.','').strip
		elsif :trailing == @zero_omission
		    ("%0#{width}.#{@decimal_places}f" % coordinate).sub('.', '').strip
		else
		    raise StandardError, "Invalid @zero_omission => #{@zero_omission}"
		end
	    end

	    def format_gcode(gcode, x, y, i, j, dcode)
	    end

	    # @return [String]	The formatted G01 command
	    def format_g1(x, y, dcode)
		s = ''
		s << 'G01' if (1 == dcode)
		s << 'X' << self.format_coordinate(x) if !@position || (x != @position.x)
		s << 'Y' << self.format_coordinate(y) if !@position || (y != @position.y)
		s << ('D%02u' % dcode)
		@gcode, @position = 1, Point[x,y]
		s << '*'
	    end

	    def line_to_array(line)
		if line.first == @position
		    [format_g1(line.last.x, line.last.y, 1)]
		elsif line.last == @position
		    [format_g1(line.first.x, line.last.y, 1)]
		else
		    [format_g1(line.first.x, line.first.y, 2), format_g1(line.last.x, line.last.y, 1)]
		end
	    end

	    # Convert the {Layer} into an {Array} of {String}s suitable for writing to a file
	    def to_a
		a = (layer.dark? ? ['%LPD%'] : ['%LPC%'])
		@layer.geometry.each_with_index do |elements, index|
		    next if index < 10
		    a << "D#{index}*"
		    elements.each do |element|
			case element
			    when Geometry::Line
				a << line_to_array(element)
			end
		    end
		end
		a.flatten
	    end
	end
    end
end
