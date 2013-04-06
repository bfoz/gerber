require 'geometry'
require 'gerber/parser'
require 'units'
require_relative 'gerber/layer/parser'
require_relative 'gerber/layer/unparser'

=begin
Read and write {http://en.wikipedia.org/wiki/Gerber_Format Gerber} files (RS-274X)
=end
class Gerber
    Arc = Geometry::Arc
    Line = Geometry::Line
    Point = Geometry::Point

    attr_accessor :name, :units

    attr_accessor :integer_places, :decimal_places
    attr_accessor :zero_omission

    attr_reader :apertures, :aperture_macros, :layers

    def initialize
	@apertures = []
	@aperture_macros = {}
	@layers = []
	@polarity = :positive
	@units = nil
    end

    # Set the format used for coordinates
    # @param [Number] integer_places	The number of digits to the left of the decimal point
    # @param [Number] decimal_places	The number of digits to the right of the decimal point
    def coordinate_format=(*args)
	self.integer_places, self.decimal_places = args.flatten.map {|a| a.to_i }
    end

    # Read and parse the given file into a {Gerber} object
    # @return [Gerber]	The resulting {Gerber} object, or nil on failure
    def self.read(filename)
	File.open(filename) do |f|
	    Gerber::Parser.new.parse(f)
	end
    end

    # Write the receiver to the given file
    # @param [String] filename	The path to the file to write to
    # @param [String] opt	Options to pass to File.open
    def write(filename, opt='w')
	File.open(filename) do |f|
	    unparse(f)
	end
    end

# @group Accessors
    def inch?
	@units == :inch
    end
    alias :inches? :inch?

    def set_inch
	@units = :inch
    end

    def millimeter?
	@units == :millimeter
    end
    alias :millimeters? :millimeter?
    alias :mm? :millimeter?

    def set_millimeter
	@units = :millimeter
    end
# @endgroup

# @group Geometry
    # Create and add a new {Aperture}
    # :circle => radius
    # @return [Aperture]
    def new_aperture(*args)
	aperture = Gerber::Aperture.new *args
	self.push_aperture aperture
	aperture
    end

    def new_level
	level = Gerber::Layer.new
	@layers.push level
	level
    end

    def push_aperture(aperture)
	if @apertures.count < 10
	    @apertures[10] = aperture
	else
	    @apertures.push aperture
	end
    end

# @endgroup


    # Unparse to the given IO stream
    # @param [IO] output    A writable IO-like object
    def unparse(output)
	raise StandardError, "The default units must be set" unless @units
	raise StandardError, "The Zero Omission Mode must be set" unless @zero_omission
	raise StandardError, "The coordinate format must be set" unless @decimal_places && @integer_places

	output.puts "%IN#{@name}*%" if @name

	output << '%FS'
	output << ((@zero_omission == :leading) ? 'L' : 'T')
	output << 'A'	# Always use absolute coordinates
	output.puts "X#{@integer_places}#{@decimal_places}Y#{@integer_places}#{@decimal_places}*%"

	output.puts self.mm? ? '%MOMM*%' : '%MOIN*%'

	# Image polarity should always be positive
	output.puts (@polarity == :positive) ? '%IPPOS*%' : '%IPNEG*%'

	@aperture_macros.each do |name, macro|
	    output.puts "%AM#{name}*", macro.to_a.join("\n") + "%"
	end

	@apertures.each_with_index do |aperture, i|
	    next if i < 10
	    output.puts "%ADD#{i}#{aperture}*%"
	end

	# for each layer
	@layers.each do |layer|
	    if layer.apertures.count
		layer.apertures.each do |aperture, elements|
		    aperture_number = @apertures.index(aperture)
		    unless aperture_number
			self.push_aperture aperture
			aperture_number = @apertures.count - 1
		    end
		end
	    end

	    unparser = Gerber::Layer::Unparser.new(layer, @apertures)
	    unparser.integer_places = self.integer_places
	    unparser.decimal_places = self.decimal_places
	    unparser.to_a.each {|a| output.puts a }
	end

	output.puts "M02*"
    end
end
