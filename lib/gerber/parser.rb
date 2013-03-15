require 'geometry'
require 'gerber/exceptions'
require 'units'
require_relative 'aperture'
require_relative 'layer'
require_relative 'layer/parser'

class Gerber
=begin
Read and parse {http://en.wikipedia.org/wiki/Gerber_Format Gerber} files (RS-274X)
=end
    class Parser
	attr_accessor :integer_places, :decimal_places
	attr_accessor :zero_omission, :absolute

	attr_reader :apertures, :layers
	attr_reader :eof
	attr_reader :total_places

	attr_reader :image_name

	def initialize
	    @apertures = []
	    @eof = false
	    @layers = []
	    @layer_parsers = []
	    @axis_mirror = {:a => 1, :b => 1}   # 1 => not mirrored, -1 => mirrored
	    @axis_select = {:a => :x, :b => :y}
	    @offset = Point[0,0]

	    @polarity = :positive
	    @rotation = 0.degrees
	    @scale = Vector[0,0]
	    @symbol_mirror = {:a => 1, :b => 1} # 1 => not mirrored, -1 => mirrored
	    @units = nil

	    @new_layer_polarity = :dark
	end

	# Apply the configured units to a number
	def apply_units(a)
	    raise ParseError, "Units must be set before specifying dimensions" unless @units
	    return nil unless a
	    (@units == 'inch') ? a.inch : a.mm
	end
	private :apply_units

	# Set the format used for coordinates
	# @param [Number] integer_places	The number of digits to the left of the decimal point
	# @param [Number] decimal_places	The number of digits to the right of the decimal point
	def coordinate_format=(*args)
	    self.integer_places, self.decimal_places = args.flatten.map {|a| a.to_i }
	    @total_places = self.decimal_places + self.integer_places
	end

	# The {Layer} currently being parsed
	def current_layer
	    @layer_parsers.last || new_layer
	end
	private :current_layer

	# Create and return a new {Layer::Parser}
	def new_layer
	    (@layer_parsers << Layer::Parser.new).last.polarity = @new_layer_polarity
	    ('inch' == @units) ? @layer_parsers.last.set_inches : @layer_parsers.last.set_millimeters
	    @layer_parsers.last
	end

	# Assume that all dimensions are in inches
	def set_inches
	    @units = 'inch'
	    current_layer.set_inches
	end

	# Assume that all dimensions are in millimeters
	def set_millimeters
	    @units = 'millimeters'
	    current_layer.set_millimeters
	end

	# Parse the given IO stream
	# @param [IO] input	    An IO-like object to parse
	def parse(input)
	    input.each('*') do |block|
		block.strip!
		next if !block || block.empty?
		raise ParseError, "Found blocks after M02" if self.eof
		case block
		    when /^%AM/ # Special handling for aperture macros
			parse_parameter((block + input.gets('%')).gsub(/[\n%]/,''))
		    when /^%[A-Z]{2}/
			(block + input.gets('%')).gsub(/[\n%]/,'').gsub(/\* /,'').lines('*') {|b| parse_parameter(b)}
		    when /^D(\d{2,3})/
			current_layer.parse_dcode(block)
		    when /^M0(0|1|2)/
			mcode = $1
			raise ParseError, "Invalid M code: #{m}" unless mcode
			@eof = true if mcode.to_i == 2
		    when /^G54D(\d{2,3})/	# Deprecated G54 function code
			current_layer.parse_gcode(54, nil, nil, nil, nil, $1)
		    when /^G70/
			set_inches
		    when /^G71/
			set_millimeters
		    when /^(G(\d{2}))?(X([\d\+-]+))?(Y([\d\+-]+))?(I([\d\+-]+))?(J([\d\+-]+))?(D0(1|2|3))?/
			gcode, dcode = $2, $12
			x, y, i, j = [$4, $6, $8, $10].map {|a| parse_coordinate(a) }
			current_layer.parse_gcode(gcode, x, y, i, j, dcode)
		    else
			raise ParseError,"Unrecognized block: \"#{block}\""
		end
	    end

	    # FIXME apply any @rotation

	    @layers = @layer_parsers.map {|parser| parser.layer }.select {|layer| !layer.empty? }

	    gerber = Gerber.new
	    gerber.apertures.replace @apertures
	    gerber.coordinate_format = self.integer_places, self.decimal_places
	    gerber.name = @image_name
	    gerber.layers.replace @layers
	    gerber.zero_omission = self.zero_omission
	    gerber
	end

	# Convert a string into a {Float} using the current coordinate formating setting
	# @param [String] s	The string to convert
	# @return [Float]	The resulting {Float}, or nil
	def parse_coordinate(s)
	    return nil unless s	# Ignore nil coordinates so that they can be handled later

	    sign = s.start_with?('-') ? '-' : '+'
	    s.sub!(sign,'')

	    if s.length < total_places
		if( zero_omission == :leading )
		    s = s.rjust(total_places, '0')
		elsif( zero_omission == :trailing )
		    s = s.ljust(total_places, '0')
		end
	    end

	    current_layer.apply_units((sign + s).insert(sign.length + integer_places, '.').to_f)
	end

	# Convert a string into a {Float} and apply the appropriate {Units}
	# @param [String] s	    The string to convert
	# @return [Float]	    The resulting {Float} with units, or nil
	def parse_float(s)
	    apply_units(s.to_f)
	end

	# Parse a set of parameter blocks
	def parse_parameter(s)
	    directive = s[0,2]
	    case directive
		when 'AD'	# Section 4.1
		    dcode, type = s.match(/ADD(\d{2,3})(\w+)/).captures
		    dcode = dcode.to_i
		    raise ParseError, "Invalid aperture number #{dcode}" unless dcode >= 10
		    case type
			when 'C'
			    m = s.match(/C,(?<diameter>[\d.]+)(X(?<x>[\d.]+)(X(?<y>[\d.]+))?)?/)
			    aperture = Aperture.new(:circle => parse_float(m[:diameter]))
			    if( m[:x] )
				x = parse_float(m[:x])
				aperture.hole = m[:y] ? {:x => x, :y => parse_float(m[:y])} : x
			    end

			when 'R'
			    m = s.match(/R,(?<x>[\d.]+)X(?<y>[\d.]+)(X(?<hole_x>[\d.]+)(X(?<hole_y>[\d.]+))?)?/)
			    aperture = Aperture.new(:rectangle => [parse_float(m[:x]), parse_float(m[:y])])
			    if( m[:hole_x] )
				hole_x = parse_float(m[:hole_x])
				aperture.hole = m[:hole_y] ? {:x => hole_x, :y => parse_float(m[:hole_y])} : hole_x
			    end

			when 'O'
			    m = s.match(/O,(?<x>[\d.]+)X(?<y>[\d.]+)(X(?<hole_x>[\d.]+)(X(?<hole_y>[\d.]+))?)?/)
			    aperture = Aperture.new(:obround => [parse_float(m[:x]), parse_float(m[:y])])
			    if( m[:hole_x] )
				hole_x = parse_float(m[:hole_x])
				aperture.hole = m[:hole_y] ? {:x => hole_x, :y => parse_float(m[:hole_y])} : hole_x
			    end

			when 'P'
			    m = s.match(/P,(?<diameter>[\d.]+)X(?<sides>[\d.]+)(X(?<rotation>[\d.]+)(X(?<hole_x>[\d.]+)(X(?<hole_y>[\d.]+))?)?)?/)
			    aperture = Aperture.new(:polygon => parse_float(m[:diameter]), :sides => m[:sides].to_i)
			    if( m[:rotation] )
				aperture.rotation = m[:rotation].to_i.degrees
				if( m[:hole_x] )
				    hole_x = parse_float(m[:hole_x])
				    aperture.hole = m[:hole_y] ? {:x => hole_x, :y => parse_float(m[:hole_y])} : hole_x
				end
			    end

			else    # Special Aperture
			    captures = s.match(/#{type}(,([\d.]+)(X([\d.]+))*)?/).captures
			    parameters = captures.values_at(* captures.each_index.select {|i| i.odd?}).select {|p| p }
			    aperture = Aperture.new(:name=>type)
			    aperture.parameters = parameters.map {|p| parse_float(p) } if( parameters && (0 != parameters.size ) )
		    end
		    self.apertures[dcode] = aperture

		# Section 4.2
		when 'AM'
    #		macro_name = block.match(/AM(\w*)\*/)[0]
		    primitives = s.split '*'
		    macro_name = primitives.shift.sub(/AM/,'')
		    p "Aperature Macro: #{macro_name} => #{primitives}"
		when 'SM'	# Deprecated
		    /^SM(A(0|1))?(B(0|1))?/ =~ s
		    @symbol_mirror[:a] = ('1' == $1) ? -1 : 1
		    @symbol_mirror[:b] = ('1' == $2) ? -1 : 1

		# Section 4.3 - Directive Parameters
		when 'AS'	# Deprecated
		    /^ASA(X|Y)B(X|Y)/ =~ s
		    raise ParseError, "The AS directive requires that both axes must be specified" unless $1 && $2
		    raise ParseError, "Axis Select directive can't map both data axes to the same output axis" if $1 == $2
		    @axis_select[:a] = $1.downcase.to_sym
		    @axis_select[:b] = $2.downcase.to_sym
		when 'FS'
		    /^FS(L|T)(A|I)(N\d)?(G\d)?X(\d)(\d)Y(\d)(\d)(D\d)?(M\d)?/ =~ s
		    self.absolute = ($2 == 'A')
		    self.zero_omission = ($1 == 'L') ? :leading : (($1 == 'T') ? :trailing : nil)
		    xn, xm, yn, ym = $5, $6, $7, $8
		    raise ParseError, "X and Y coordinate formats must equal" unless (xn == yn) && (xm == ym)
		    self.coordinate_format = xn, xm
		when 'MI'	# Deprecated
		    /^MIA(0|1)B(0|1)/ =~ s
		    raise ParseError, "The MI directive requires that both axes be specified" unless $1 || $2
		    @axis_mirror[:a] = ('0' == $1) ? 1 : -1
		    @axis_mirror[:b] = ('0' == $2) ? 1 : -1
		when 'MO'
		    /^MO(IN|MM)/ =~ s
		    set_inches if 'IN' == $1
		    set_millimeters if 'MM' == $1
		when 'OF'	# Deprecated
		    /^OF(A([\d.+-]+))?(B([\d.+-]+))?/ =~ s
		    @offset = Point[parse_float($2) || 0.0, parse_float($4) || 0.0]
		when 'SF'	# Deprecated
		    /^SF(A([\d.+-]+))?(B([\d.+-]+))?/ =~ s
		    @scale = Vector[parse_float($2) || 0.0, parse_float($4) || 0.0]

		# Section 5.4, revI1 - Image Name
		when 'IN'   # RS-274-D allows spaces, but RS-274X does not
		    raise ParseError, "Invalid Image Name: #{s}" unless /^IN([\w[^%*;]]+)\*$/ =~ s
		    @image_name = $1

		# Section 4.4 - Image Parameters
		when 'IJ'	# Deprecated
		when 'IP'	# Deprecated
		    /^IP(POS|NEG)/ =~ s
		    current_layer.polarity = ('NEG' == $1) ? :negative : :positive
		when 'IR'	# Deprecated
		    /^IR(0|90|180|270)/ =~ s
		    @rotation = $1.to_f.degrees

		# Section 4.5 - Layer Specific Parameters
		when 'KO'	# Deprecated
		    /^KO(C|D)?(X([\d.+-]+)Y([\d.+-]+)I([\d.+-]+)J([\d.+-]+))?/ =~ s
		    polarity, x, y, i, j = $1, $3, $4, $5, $6
		    raise ParseError, "KO not supported"
		when 'LN'
		    /^LN([[:print:]]+)\*/ =~ s
		    new_layer.name = $1
		when 'LP'
		    /^LP(C|D)/ =~ s
		    @new_layer_polarity = ('C' == $1) ? :clear : :dark
		    current_layer.polarity = @new_layer_polarity
		when 'SR'
		    /^SR(X(\d+))?(Y(\d+))?(I([\d.+-]+))?(J([\d.+-]+))?/ =~ s
		    x, y, i, j = $2, $4, parse_float($6), parse_float($8)
		    layer = new_layer
		    layer.step = Vector[i || 0, j || 0]
		    layer.repeat = Vector[x || 1, y || 1]

		when 'IC'
		    warn "Use of deprecated IC parameter: #{s.chop}"
		else
		    raise ParseError, "Unrecognized Parameter Type: '#{directive}'"
	    end
	end
    end
end
