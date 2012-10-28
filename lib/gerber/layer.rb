require 'gerber'
require 'units'

=begin
A Gerber information layer (not to be confused with a PCB layer)
=end
class Gerber
    class Layer < Struct.new(:draw, :eof, :geometry)
	attr_reader :current_aperture
	attr_accessor :name, :polarity, :step, :repeat
	attr_accessor :coordinate_mode
	attr_accessor :quadrant_mode

	def initialize(*args)
	    super
	    self.draw = false
	    self.eof = false
	    self.coordinate_mode = :absolute
	    self.quadrant_mode = :single
	    @dcode = 2	# off
	    @gcode = 1	# linear interpolation
	    self.geometry = []
	    @polarity = :dark
	    @position = Point[0,0]
	    @repeat = Vector[1,1]
	    @step = Vector[0,0]
	    @units = nil
	end

	def <<(arg)
	    raise ParseError, "Must set an aperture before generating geometry" unless self.current_aperture
	self.geometry[self.current_aperture] << arg if arg.kind_of?(Line) || arg.kind_of?(Point) || arg.kind_of?(Arc)
	end

	# @group Accessors
	def current_aperture=(arg)
	    @current_aperture = arg
	    unless( self.geometry[arg].is_a?(Array) )
		self.geometry[arg] = []
	    end
	end

	def empty?
	    self.geometry.empty?
	end

	def position
	    @position
	end

	def set_inches
	    @units = 'inch'
	end

	def set_millimeters
	    @units = 'millimeters'
	end
	# @endgroup

	def parse_dcode(s)
	    /D(\d{2,3})/ =~ s
	    dcode = $1.to_i
	    case dcode
		when 1
		    self.draw = true
		when 2
		    self.draw = false
		when 3
		    self.draw = :flash
		when 10...999
		    self.current_aperture = dcode
		else
		    raise ParseError, "Invalid D Code #{dcode}"
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
		    raise ParseError, "G54 requires a D code (found #{x}, #{y}, #{dcode})" unless dcode
		    self.current_aperture = dcode.to_i
		when 70
		    set_inches
		when 71
		    set_millimeters
		when 74
		    self.quadrant_mode = :single
		when 75
		    self.quadrant_mode = :multi
		when 90
		    self.coordinate_mode = :absolute
		when 91
		    self.coordinate_mode = :incremental
		else
		    raise ParseError, "Unrecognized GCode #{gcode}"
	    end
	end

	def parse_g1(x, y, d)
	    point = Point[apply_units(x) || @position.x, apply_units(y) || @position.y]
	    draw_code = self.draw ? ((:flash == self.draw) ? 3 : 1) : 2;
	    dcode = d ? d.to_i : draw_code
	    case dcode
		when 1
		    line = Geometry::Line[@position, point]
		    self << line
		    @position = point
		    self.draw = true
		when 2
		    @position = point
		    self.draw = false
		when 3
		    self << point
		    @position = point
		    self.draw = :flash
		else
		    raise ParseError, "Invalid D parameter (#{dcode}) in G1"
	    end
	end

	def parse_g2(x, y, i, j, dcode)
	    raise ParseError, "In G2 dcode must be either 1 or 2" unless [1, 2].include? dcode
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
		elsif self.quadrant_mode = :multi
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
	    raise ParseError, "In G3 dcode must be either 1 or 2" unless [1, 2].include? dcode
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
		elsif self.quadrant_mode = :multi
		    Point[x, y]
		else
		    raise ParseError, "Unrecognized quadrant mode: #{self.quadrant_mode}"
		end
		arc = Geometry::Arc.new(@position + Point[i, j], @position, endPoint)
		self << arc
		@position = arc.last
	    end
	end

	def parse_mcode(m)
	    raise ParseError, "Invalid M code: #{m}" unless m
	    self.eof = true if m.to_i == 2
	end

	def apply_units(a)
	    raise ParseError, "Units must be set before specifying coordinates" unless @units
	    return nil unless a
	    (@units == 'inch') ? a.inch : a.mm
	end
    end
end
