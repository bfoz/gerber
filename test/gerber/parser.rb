require 'minitest/autorun'
require 'gerber/parser'

describe Gerber::Parser do
    let(:parser) { Gerber::Parser.new }

    describe "when parsing coordinates" do
	before do
	    parser.coordinate_format = 3,3
	    parser.parse_parameter('MOMM')
	end

	describe "with leading zero omission" do
	    before do
		parser.zero_omission = :leading
	    end

	    it "must parse positive numbers" do
		parser.parse_coordinate('12345').must_equal 12.345.mm
		parser.parse_coordinate('+12345').must_equal 12.345.mm
	    end

	    it "must parse negative numbers" do
		parser.parse_coordinate('-12345').must_equal -12.345.mm
	    end
	end

	describe "with trailing zero omission" do
	    before do
		parser.zero_omission = :trailing
	    end

	    it "must parse positive numbers" do
		parser.parse_coordinate('12345').must_equal 123.45.mm
		parser.parse_coordinate('+12345').must_equal 123.45.mm
	    end

	    it "must parse negative numbers" do
		parser.parse_coordinate('-12345').must_equal -123.45.mm
	    end
	end
    end

    describe "when parsing parameters" do
	let(:parser) { Gerber::Parser.new }

	describe "when parsing an Image Name parameter" do
	    it "must raise an Exception when the name contains a space" do
		lambda { parser.parse_parameter('INImage Name') }.must_raise Gerber::ParseError
	    end

	    it "must raise an exception when the name contains an invalid character" do
		lambda { parser.parse_parameter('INImage%Name') }.must_raise Gerber::ParseError
	    end

	    it "must accept a valid name" do
		parser.parse_parameter('INImage_Name*')
		parser.image_name.must_equal 'Image_Name'
	    end
	end

	describe "when parsing a Mode parameter" do
	    before do
		parser.parse_parameter('MOIN')
	    end

	    describe "when parsing an aperture definition" do
		describe "for a standard circle" do
		    it "without a hole" do
			parser.parse_parameter('ADD10C,0.0070*')
			parser.apertures[10].must_equal(Gerber::Aperture.new(:circle=>0.007.inch))
		    end

		    it "with a round hole" do
			parser.parse_parameter('ADD10C,0.0070X0.025*')
			parser.apertures[10].must_equal(Gerber::Aperture.new(:circle=>0.007.inch, :hole=>0.025.inch))
		    end

		    it "with a square hole" do
			parser.parse_parameter('ADD10C,0.0070X0.025X0.050*')
			parser.apertures[10].must_equal(Gerber::Aperture.new(:circle=>0.007.inch, :hole=>{:x=>0.025.inch,:y=>0.050.inch}))
		    end
		end

		describe "for a standard rectangle" do
		    it "without a hole" do
			parser.parse_parameter('ADD10R,0.020X0.040*')
			parser.apertures[10].must_equal(Gerber::Aperture.new(:rectangle=>[0.020.inch, 0.040.inch]))
		    end

		    it "with a round hole" do
			parser.parse_parameter('ADD10R,0.020X0.040X0.025*')
			parser.apertures[10].must_equal(Gerber::Aperture.new(:rectangle=>[0.020.inch, 0.040.inch], :hole=>0.025.inch))
		    end

		    it "with a square hole" do
			parser.parse_parameter('ADD10R,0.020X0.040X0.025X0.050*')
			parser.apertures[10].must_equal(Gerber::Aperture.new(:rectangle=>[0.020.inch, 0.040.inch], :hole=>{:x=>0.025.inch,:y=>0.050.inch}))
		    end
		end

		describe "for a standard obround" do
		    let(:obround) { [0.020.inch, 0.040.inch] }

		    it "without a hole" do
			parser.parse_parameter('ADD10O,0.020X0.040*')
			parser.apertures[10].must_equal(Gerber::Aperture.new(:obround=>obround))
		    end

		    it "with a round hole" do
			parser.parse_parameter('ADD10O,0.020X0.040X0.025*')
			parser.apertures[10].must_equal(Gerber::Aperture.new(:obround=>[0.020.inch, 0.040.inch], :hole=>0.025.inch))
		    end

		    it "with a square hole" do
			parser.parse_parameter('ADD10O,0.020X0.040X0.025X0.050*')
			parser.apertures[10].must_equal(Gerber::Aperture.new(:obround=>[0.020.inch, 0.040.inch], :hole=>{:x=>0.025.inch,:y=>0.050.inch}))
		    end
		end

		describe "for a standard regular polygon" do
		    describe "with rotation" do
			it "without a hole" do
			    parser.parse_parameter('ADD10P,0.030X4X90*')
			    parser.apertures[10].shape.must_be_kind_of(Geometry::RegularPolygon)
			    parser.apertures[10].must_equal(Gerber::Aperture.new(:polygon=>0.030.inch, :sides=>4, :rotation=>90.0.degrees))
			end

			it "with a round hole" do
			    parser.parse_parameter('ADD10P,0.030X4X90X0.040*')
			    parser.apertures[10].must_equal(Gerber::Aperture.new(:polygon=>0.030.inch, :sides=>4, :rotation=>90.0.degrees, :hole=>0.040.inch))
			end

			it "with a square hole" do
			    parser.parse_parameter('ADD10P,0.030X4X90X0.040X0.025*')
			    parser.apertures[10].must_equal(Gerber::Aperture.new(:polygon=>0.030.inch, :sides=>4, :rotation=>90.0.degrees, :hole=>{:x=>0.040.inch,:y=>0.025.inch}))
			end
		    end

		    describe "without rotation" do
			it "without a hole" do
			    parser.parse_parameter('ADD10P,0.030X4*')
			    parser.apertures[10].must_equal(Gerber::Aperture.new(:polygon=>0.030.inch, :sides=>4))
			end

			it "with a round hole" do
			    parser.parse_parameter('ADD10P,0.030X4X0X0.040*')
			    parser.apertures[10].must_equal(Gerber::Aperture.new(:polygon=>0.030.inch, :sides=>4, :rotation=>0.0, :hole=>0.040.inch))
			end

			it "with a square hole" do
			    parser.parse_parameter('ADD10P,0.030X4X0X0.040X0.025*')
			    parser.apertures[10].must_equal(Gerber::Aperture.new(:polygon=>0.030.inch, :sides=>4, :rotation=>0.0, :hole=>{:x=>0.040.inch,:y=>0.025.inch}))
			end
		    end
		end

		describe "for a macro" do
		    before do
			parser.parse_parameter "AMCIRC*1,1,$1,0.0000,0.0000*1,0,$2,$3,$4*"
			@circ_macro = parser.aperture_macros['CIRC']
		    end

		    it "without parameters" do
			parser.parse_parameter('ADD10CIRC')
			parser.apertures[10].must_equal(Gerber::Aperture.new(name: 'CIRC', macro: @circ_macro))
		    end

		    it "with 1 parameter" do
			parser.parse_parameter('ADD10CIRC,0.010')
			parser.apertures[10].must_equal(Gerber::Aperture.new(name: 'CIRC', macro: @circ_macro, parameters: [0.010.inch]))
		    end

		    it "with multiple parameters" do
			parser.parse_parameter('ADD10CIRC,0.010X0.020')
			parser.apertures[10].must_equal(Gerber::Aperture.new(name: 'CIRC', macro: @circ_macro, parameters: [0.010.inch,0.020.inch]))
		    end
		end
	    end
	end

	describe "when parsing a format specification" do
	    it "leading absolute" do
		parser.parse_parameter('FSLAX25Y25')
		parser.zero_omission.must_equal :leading
		parser.absolute.must_equal true
		parser.integer_places.must_equal 2
		parser.decimal_places.must_equal 5
		parser.total_places.must_equal 7
	    end

	    it "leading incremental" do
		parser.parse_parameter('FSLIX25Y25')
		parser.zero_omission.must_equal :leading
		parser.absolute.must_equal false
		parser.integer_places.must_equal 2
		parser.decimal_places.must_equal 5
		parser.total_places.must_equal 7
	    end

	    it "trailing absolute" do
		parser.parse_parameter('FSTAX25Y25')
		parser.absolute.must_equal true
		parser.zero_omission.must_equal :trailing
		parser.integer_places.must_equal 2
		parser.decimal_places.must_equal 5
		parser.total_places.must_equal 7
	    end

	    it "trailing incremental" do
		parser.parse_parameter('FSTIX25Y25')
		parser.absolute.must_equal false
		parser.zero_omission.must_equal :trailing
		parser.integer_places.must_equal 2
		parser.decimal_places.must_equal 5
		parser.total_places.must_equal 7
	    end
	end

	describe "when parsing RS-274-D formatted parameters" do
	    before do
		parser.parse_parameter 'MOIN*'
	    end

	    it "must switch modes" do
		parser.rs_274_d.must_be_nil
		parser.parse_parameter 'ADD10C, 0.0100*'
		parser.rs_274_d.wont_be_nil
	    end

	    it "must support spaces between parameters" do
		parser.parse_parameter 'ADD50R, 0.0453 X0.0354*'
		parser.rs_274_d.wont_be_nil
	    end
	end

	describe "when parsing deprecated parameters" do
	    it "IC" do
		lambda { parser.parse_parameter('ICAS*') }.must_output nil, "Use of deprecated IC parameter: ICAS\n"
	    end
	end

	describe "when parsing an Aperture Macro parameter" do
	    before do
		parser.parse_parameter('MOIN')
	    end

	    it "must parse the macro name" do
		parser.parse_parameter "AMMACRONAME0*1,1,$1,0.0000,0.0000*1,0,$2,$3,$4*"
		macro = parser.aperture_macros['MACRONAME0']
		macro.wont_be_nil
		macro.name.must_equal 'MACRONAME0'
	    end

	    it "must parse Fixed Modifier Values" do
		parser.parse_parameter 'AMDONUTFIX*1,1,0.100,0,0*1,0,0.080,0,0*'
		macro = parser.aperture_macros['DONUTFIX']
		macro.wont_be_nil
		macro.primitives.count.must_equal 2
		macro.primitives.all? {|primitive| primitive.must_be_kind_of Gerber::ApertureMacro::Circle }
		macro.primitives[0].exposure.must_equal '1'
		macro.primitives[0].diameter.must_equal '0.100'
	    end

	    it "must parse Variable Modifier Values" do
		parser.parse_parameter 'AMDONUTVAR*1,1,$1,$2,$3*1,0,$4,$2,$3*'
		macro = parser.aperture_macros['DONUTVAR']
		macro.wont_be_nil
		macro.primitives.count.must_equal 2
		macro.primitives.all? {|primitive| primitive.must_be_kind_of Gerber::ApertureMacro::Circle }
		macro.modifiers.count.must_equal 5
		macro.modifiers[0].must_be_nil
		macro.modifiers[1].must_be_kind_of Gerber::ApertureMacro::Variable
		macro.modifiers[2].must_be_kind_of Gerber::ApertureMacro::Variable
		macro.modifiers[3].must_be_kind_of Gerber::ApertureMacro::Variable
		macro.modifiers[4].must_be_kind_of Gerber::ApertureMacro::Variable
	    end
	end
    end
end