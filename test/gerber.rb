require 'minitest/autorun'
require 'gerber'

describe Gerber do
    it "must read a file" do
	Gerber.read('test/gerber/hexapod.gerber').must_be_kind_of(Gerber)
    end

    it "must read the 4PCB.com example" do
	Gerber.read('test/gerber/sample_4pcb.gerber')
    end

    it "must read the Wikipedia example" do
	Gerber.read('test/gerber/wikipedia.gerber')
    end

    it "must read Example 1 from the specification" do
	Gerber.read('test/gerber/two_boxes.gerber')
    end

    it "must read Example 2 from the specification" do
	skip "There's an error in the example"
	Gerber.read('test/gerber/example2.gerber')
    end

    it "must reject files with an M02 before the EOF" do
	lambda { Gerber.read('test/gerber/m02_not_at_end.gerber') }.must_raise Gerber::ParseError
    end

    describe "when parsing coordinates" do
	let(:gerber) { Gerber.new }

	before do
	    gerber.coordinate_format = 3,3
	    gerber.parse_parameter('MOMM')
	end

	describe "with leading zero omission" do
	    before do
		gerber.zero_omission = :leading
	    end

	    it "must parse positive numbers" do
		gerber.parse_coordinate('12345').must_equal 12.345.mm
		gerber.parse_coordinate('+12345').must_equal 12.345.mm
	    end

	    it "must parse negative numbers" do
		gerber.parse_coordinate('-12345').must_equal -12.345.mm
	    end
	end

	describe "with trailing zero omission" do
	    before do
		gerber.zero_omission = :trailing
	    end

	    it "must parse positive numbers" do
		gerber.parse_coordinate('12345').must_equal 123.45.mm
		gerber.parse_coordinate('+12345').must_equal 123.45.mm
	    end

	    it "must parse negative numbers" do
		gerber.parse_coordinate('-12345').must_equal -123.45.mm
	    end
	end
    end

    describe "when parsing parameters" do
	let(:gerber) { Gerber.new }

	describe "when parsing a Mode parameter" do
	    before do
		gerber.parse_parameter('MOIN')
	    end

	    describe "when parsing an aperture definition" do
		describe "for a standard circle" do
		    it "without a hole" do
			gerber.parse_parameter('ADD10C,0.0070*')
			gerber.apertures[10].must_equal(Gerber::Aperture.new(:type=>:circle, :diameter=>0.007.inch))
		    end

		    it "with a round hole" do
			gerber.parse_parameter('ADD10C,0.0070X0.025*')
			gerber.apertures[10].must_equal(Gerber::Aperture.new(:type=>:circle, :diameter=>0.007.inch, :hole=>0.025.inch))
		    end

		    it "with a square hole" do
			gerber.parse_parameter('ADD10C,0.0070X0.025X0.050*')
			gerber.apertures[10].must_equal(Gerber::Aperture.new(:type=>:circle, :diameter=>0.007.inch, :hole=>{:x=>0.025.inch,:y=>0.050.inch}))
		    end
		end

		describe "for a standard rectangle" do
		    it "without a hole" do
			gerber.parse_parameter('ADD10R,0.020X0.040*')
			gerber.apertures[10].must_equal(Gerber::Aperture.new(:type=>:rectangle, :x=>0.020.inch, :y=>0.040.inch))
		    end

		    it "with a round hole" do
			gerber.parse_parameter('ADD10R,0.020X0.040X0.025*')
			gerber.apertures[10].must_equal(Gerber::Aperture.new(:type=>:rectangle, :x=>0.020.inch, :y=>0.040.inch, :hole=>0.025.inch))
		    end

		    it "with a square hole" do
			gerber.parse_parameter('ADD10R,0.020X0.040X0.025X0.050*')
			gerber.apertures[10].must_equal(Gerber::Aperture.new(:type=>:rectangle, :x=>0.020.inch, :y=>0.040.inch, :hole=>{:x=>0.025.inch,:y=>0.050.inch}))
		    end
		end

		describe "for a standard obround" do
		    it "without a hole" do
			gerber.parse_parameter('ADD10O,0.020X0.040*')
			gerber.apertures[10].must_equal(Gerber::Aperture.new(:type=>:obround, :x=>0.020.inch, :y=>0.040.inch))
		    end

		    it "with a round hole" do
			gerber.parse_parameter('ADD10O,0.020X0.040X0.025*')
			gerber.apertures[10].must_equal(Gerber::Aperture.new(:type=>:obround, :x=>0.020.inch, :y=>0.040.inch, :hole=>0.025.inch))
		    end

		    it "with a square hole" do
			gerber.parse_parameter('ADD10O,0.020X0.040X0.025X0.050*')
			gerber.apertures[10].must_equal(Gerber::Aperture.new(:type=>:obround, :x=>0.020.inch, :y=>0.040.inch, :hole=>{:x=>0.025.inch,:y=>0.050.inch}))
		    end
		end

		describe "for a standard regular polygon" do
		    describe "with rotation" do
			it "without a hole" do
			    gerber.parse_parameter('ADD10P,0.030X4X90*')
			    gerber.apertures[10].must_equal(Gerber::Aperture.new(:type=>:polygon, :diameter=>0.030.inch, :sides=>4, :rotation=>90.0.degrees))
			end

			it "with a round hole" do
			    gerber.parse_parameter('ADD10P,0.030X4X90X0.040*')
			    gerber.apertures[10].must_equal(Gerber::Aperture.new(:type=>:polygon, :diameter=>0.030.inch, :sides=>4, :rotation=>90.0.degrees, :hole=>0.040.inch))
			end

			it "with a square hole" do
			    gerber.parse_parameter('ADD10P,0.030X4X90X0.040X0.025*')
			    gerber.apertures[10].must_equal(Gerber::Aperture.new(:type=>:polygon, :diameter=>0.030.inch, :sides=>4, :rotation=>90.0.degrees, :hole=>{:x=>0.040.inch,:y=>0.025.inch}))
			end
		    end

		    describe "without rotation" do
			it "without a hole" do
			    gerber.parse_parameter('ADD10P,0.030X4*')
			    gerber.apertures[10].must_equal(Gerber::Aperture.new(:type=>:polygon, :diameter=>0.030.inch, :sides=>4))
			end

			it "with a round hole" do
			    gerber.parse_parameter('ADD10P,0.030X4X0X0.040*')
			    gerber.apertures[10].must_equal(Gerber::Aperture.new(:type=>:polygon, :diameter=>0.030.inch, :sides=>4, :rotation=>0.0, :hole=>0.040.inch))
			end

			it "with a square hole" do
			    gerber.parse_parameter('ADD10P,0.030X4X0X0.040X0.025*')
			    gerber.apertures[10].must_equal(Gerber::Aperture.new(:type=>:polygon, :diameter=>0.030.inch, :sides=>4, :rotation=>0.0, :hole=>{:x=>0.040.inch,:y=>0.025.inch}))
			end
		    end
		end

		describe "for a macro" do
		    it "without parameters" do
			gerber.parse_parameter('ADD10CIRC')
			gerber.apertures[10].must_equal(Gerber::Aperture.new(:type=>'CIRC'))
		    end

		    it "with 1 parameter" do
			gerber.parse_parameter('ADD10CIRC,0.010')
			gerber.apertures[10].must_equal(Gerber::Aperture.new(:type=>'CIRC', :parameters=>[0.010.inch]))
		    end

		    it "with multiple parameters" do
			gerber.parse_parameter('ADD10CIRC,0.010X0.020')
			gerber.apertures[10].must_equal(Gerber::Aperture.new(:type=>'CIRC', :parameters=>[0.010.inch,0.020.inch]))
		    end
		end
	    end
	end

	describe "when parsing a format specification" do
	    let(:gerber) { Gerber.new }

	    it "leading absolute" do
		gerber.parse_parameter('FSLAX25Y25')
		gerber.zero_omission.must_equal :leading
		gerber.absolute.must_equal true
		gerber.integer_places.must_equal 2
		gerber.decimal_places.must_equal 5
		gerber.total_places.must_equal 7
	    end

	    it "leading incremental" do
		gerber.parse_parameter('FSLIX25Y25')
		gerber.zero_omission.must_equal :leading
		gerber.absolute.must_equal false
		gerber.integer_places.must_equal 2
		gerber.decimal_places.must_equal 5
		gerber.total_places.must_equal 7
	    end

	    it "trailing absolute" do
		gerber.parse_parameter('FSTAX25Y25')
		gerber.absolute.must_equal true
		gerber.zero_omission.must_equal :trailing
		gerber.integer_places.must_equal 2
		gerber.decimal_places.must_equal 5
		gerber.total_places.must_equal 7
	    end

	    it "trailing incremental" do
		gerber.parse_parameter('FSTIX25Y25')
		gerber.absolute.must_equal false
		gerber.zero_omission.must_equal :trailing
		gerber.integer_places.must_equal 2
		gerber.decimal_places.must_equal 5
		gerber.total_places.must_equal 7
	    end
	end
    end
end