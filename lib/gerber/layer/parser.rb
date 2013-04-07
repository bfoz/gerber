require 'gerber/exceptions'
require 'gerber/layer'

class Gerber
    class Layer
	class Parser
	    # @!attribute name
	    #   @return [String]    The name of the current {Layer}
	    # @!attribute polarity
	    #	@return [Symbol]    The polarity setting of the current {Layer} (:dark or :clear)

	    attr_accessor   :polarity
	    attr_reader :coordinate_mode
	    attr_reader :geometry
	    attr_reader :name, :position
	    attr_reader :quadrant_mode

	    def initialize
		@aperture_number = nil
		@coordinate_mode = :absolute
		@dcode = 2	# off
		@gcode = 1	# linear interpolation
		@geometry = []
		@quadrant_mode = :single
		@repeat = Vector[1,1]
		@step = Vector[0,0]
		@units = nil
	    end

	    def is_valid_geometry(arg)
		arg.kind_of?(Line) || arg.kind_of?(Point) || arg.kind_of?(Arc)
	    end

	    def <<(arg)
		raise ParseError, "Must set an aperture before generating geometry" unless @aperture_number
		if is_valid_geometry(arg)
		    if @geometry[@aperture_number]
			@geometry[@aperture_number] << arg
		    else
			@geometry[@aperture_number] = [arg]
		    end
		end
	    end

	    # @group Accessors

	    # @return [Bool]	True if no geometry was parsed
	    def empty?
		@geometry.empty?
	    end

	    # Set the current units to inches
	    def set_inches
		@position = Point[0.inch, 0.inch] unless @position
		@units = 'inch'
	    end

	    # Set the current units to millimeters
	    def set_millimeters
		@position = Point[0.mm, 0.mm] unless @position
		@units = 'millimeters'
	    end
	    # @endgroup

	    def parse_dcode(s)
		/D(\d{2,3})/ =~ s
		dcode = $1.to_i
		case dcode
		    when 1, 2, 3
			@dcode = dcode
		    when 4..9
			raise ParseError, "Invalid D Code #{dcode}"
		    else
			@aperture_number = dcode
		end
	    end

	    def parse_gcode(gcode, x=nil, y=nil, i=nil, j=nil, dcode=nil)
		gcode = gcode ? gcode.to_i : @gcode
		dcode = dcode ? dcode.to_i : @dcode
		case gcode
		    when 1, 55  # G55 is deprecated, but behaves like G01
			parse_g1(x, y, dcode)
			@dcode = dcode
			@gcode = gcode
		    when 2
			parse_g2(x, y, i, j, dcode)
			@dcode = dcode
			@gcode = gcode
		    when 3
			parse_g3(x, y, i, j, dcode)
			@dcode = dcode
			@gcode = gcode
		    when 4  # G04 is used for single-line comments. Ignore the block and carry on.
		    when 36
			p "enable outline fill"
		    when 37
			p "disable outline fill"
		    when 54
			raise DCodeError, "G54 requires a D code (found #{x}, #{y}, #{dcode})" unless dcode
			@aperture_number = dcode.to_i
		    when 70
			set_inches
		    when 71
			set_millimeters
		    when 74
			@quadrant_mode = :single
		    when 75
			@quadrant_mode = :multi
		    when 90
			@coordinate_mode = :absolute
		    when 91
			@coordinate_mode = :incremental
		    else
			raise ParseError, "Unrecognized GCode #{gcode}"
		end
	    end

	    def parse_g1(x, y, dcode)
		point = Point[apply_units(x) || @position.x, apply_units(y) || @position.y]
		case dcode
		    when 1
			line = Geometry::Line[@position, point]
			self << line
			@position = point
		    when 2
			@position = point
		    when 3
			self << point
			@position = point
		    else
			raise DCodeError, "Invalid D parameter (#{dcode}) in G1"
		end
	    end

	    def parse_g2(x, y, i, j, dcode)
		raise DCodeError, "In G2 dcode must be either 1 or 2" unless [1, 2].include? dcode
		if 1 == dcode
		    x, y, i, j = [x, y, i, j].map {|a| apply_units(a)}
		    startPoint = if self.quadrant_mode == :single
			# start and end are swapped in clockwise mode (Geometry::Arc defaults to counterclockwise)
			# i and j should have the same signs as the x and y components of the vector from the startpoint to the endpoint
			if self.coordinate_mode == :absolute
			    delta = Point[x, y] - @position
			    i = i * (delta.x<=>0)
			    j = j * (delta.y<=>0)
			    Point[x, y]
			elsif self.coordinate_mode == :incremental
			    i = i * (x<=>0)
			    j = j * (y<=>0)
			    @position + Point[x, y]
			end
		    elsif @quadrant_mode == :multi
			Point[x, y]
		    else
			raise ParseError, "Unrecognized quadrant mode: #{self.quadrant_mode}"
		    end
		    arc = Geometry::Arc.new(@position + Point[i, j], startPoint, @position)
		    self << arc
		    @position = arc.first
		end
	    end

	    def parse_g3(x, y, i, j, dcode)
		raise DCodeError, "In G3 dcode must be either 1 or 2" unless [1, 2].include? dcode
		if 1 == dcode
		    x, y, i, j = [x, y, i, j].map {|a| apply_units(a)}
		    endPoint = if self.quadrant_mode == :single
			# i and j should have the same signs as the x and y components of the vector from the startpoint to the endpoint
			if self.coordinate_mode == :absolute
			    delta = Point[x, y] - @position
			    i = i * (delta.x<=>0)
			    j = j * (delta.y<=>0)
			    Point[x, y]
			elsif self.coordinate_mode == :incremental
			    i = i * (x<=>0)
			    j = j * (y<=>0)
			    @position + Point[x, y]
			end
		    elsif @quadrant_mode == :multi
			Point[x, y]
		    else
			raise ParseError, "Unrecognized quadrant mode: #{self.quadrant_mode}"
		    end
		    arc = Geometry::Arc.new(@position + Point[i, j], @position, endPoint)
		    self << arc
		    @position = arc.last
		end
	    end

	    def apply_units(a)
		raise ParseError, "Units must be set before specifying coordinates" unless @units
		return nil unless a
		(@units == 'inch') ? a.inch : a.mm
	    end
	end
    end
end
