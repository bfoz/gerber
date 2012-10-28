require 'minitest/autorun'
require 'gerber/layer'

describe Gerber::Layer do
    Point = Gerber::Point

    let(:layer) { Gerber::Layer.new }

    it "must default to absolute mode" do
	layer.coordinate_mode.must_equal :absolute
    end

    it "must default to single quadrant mode" do
	layer.quadrant_mode.must_equal :single
    end

    describe "when parsing a D code" do
	it "must start drawing for D01" do
	    layer.parse_dcode('D01')
	    layer.draw.must_equal true
	end

	it "must stop drawing for D02" do
	    layer.parse_dcode('D02')
	    layer.draw.must_equal false
	end

	it "must flash for D03" do
	    layer.parse_dcode('D03')
	    layer.draw.must_equal :flash
	end

	it "must set the current aperture number" do
	    original_state = layer.draw
	    layer.parse_dcode('D11')
	    layer.draw.must_equal original_state
	    layer.current_aperture.must_equal 11
	    layer.geometry[11].must_be_instance_of(Array)
	end
    end

    describe "when parsing a G code" do
	it "must raise an exception if the units have not been set" do
	    lambda { layer.parse_gcode(1, 2, 3, 4, 5, 1) }.must_raise Gerber::ParseError
	end

	describe "when a G74 is parsed" do
	    before do
		layer.parse_gcode(74)
	    end

	    it "must stay in single quadrant mode" do
		layer.quadrant_mode.must_equal :single
	    end
	end

	describe "when a G75 is parsed" do
	    before do
		layer.parse_gcode(75)
	    end

	    it "must set multi quadrant mode" do
		layer.quadrant_mode.must_equal :multi
	    end

	    describe "when a G74 is parsed" do
		before do
		    layer.parse_gcode(74)
		end

		it "must return to single quadrant mode" do
		    layer.quadrant_mode.must_equal :single
		end
	    end
	end

	describe "when G90 is parsed" do
	    before do
		layer.parse_gcode(90)
	    end

	    it "must stay in absolute mode" do
		layer.coordinate_mode.must_equal :absolute
	    end
	end

	describe "when G91 is parsed" do
	    before do
		layer.parse_gcode(91)
	    end

	    it "must set incremental mode" do
		layer.coordinate_mode.must_equal :incremental
	    end

	    describe "when a G90 is parsed" do
		before do
		    layer.parse_gcode(90)
		end

		it "must return to absolute mode" do
		    layer.coordinate_mode.must_equal :absolute
		end
	    end
	end

	describe "when units have been set" do
	    before do
		layer.parse_gcode(71, nil, nil, nil, nil, nil)
	    end

	    it "must raise an exception if an aperture has not been set" do
		lambda { layer.parse_gcode(1, 2, 3, 4, 5, 1) }.must_raise Gerber::ParseError
	    end

	    it "must parse the deprecated G54 and set the current aperture" do
		layer.parse_gcode(54, nil, nil, nil, nil, 10)
		layer.current_aperture.must_equal 10
		layer.geometry[10].must_be_instance_of(Array)
	    end

	    it "must reject a G54 without a D code" do
		skip "Not relevant in the latest version of the file format"	
		lambda { layer.parse_gcode(54, nil, nil, nil, nil, nil) }.must_raise Gerber::ParseError
	    end

	    describe "when an aperture has been set" do
		before do
		    layer.current_aperture = 10
		end

		it "G1D1 must generate a Line" do
		    layer.parse_gcode(1, 2, 3, 4, 5, 1)
		    layer.geometry.last.last.must_be_kind_of(Geometry::Line)
		end

		it "G1D2 must move the current position but not generate geometry" do
		    layer.parse_gcode(1, 2, 3, 4, 5, 2)
		    layer.geometry.last.length.must_equal 0
		    layer.instance_variable_get(:@position).must_equal Geometry::Point[2.mm,3.mm]
		end

		it "G1D3 must generate a Point" do
		    layer.parse_gcode(1, 2, 3, 4, 5, 3)
		    layer.geometry.last.last.must_be_kind_of(Geometry::Point)
		end

		describe "when circular interpolation" do
		    it "must reject a dcode other than 1 or 2" do
			skip
			lambda { layer.parse_gcode(2, 1, 2, 3, 4, 5) }.must_raise Gerber::ParseError
			lambda { layer.parse_gcode(3, 1, 2, 3, 4, 5) }.must_raise Gerber::ParseError
		    end

		    describe "when in absolute mode" do
			describe "when in single quadrant mode" do
			    before do
				layer.parse_gcode(74)
				layer.parse_gcode(1, 11, 6, nil, nil, 2)    # Set the current position
			    end

			    describe "when parsing four clockwise arcs" do
				before do
				    layer.parse_gcode(2, 7, 2, 4, 0, 1)
				    layer.parse_gcode(2, 3, 6, 0, 4, nil)
				    layer.parse_gcode(nil, 7, 10, 4, 0, nil)
				    layer.parse_gcode(nil, 11, 6, 0, 4, nil)
				end

				it "must generate 4 Arcs" do
				    layer.geometry[10].length.must_equal 4
				    layer.geometry[10].all? {|a| a.kind_of?(Geometry::Arc)}.must_equal(true)
				end

				it "must generate a proper first Arc" do
				    arc = layer.geometry[10].first
				    arc.center.must_equal Point[7.mm, 6.mm]
				    arc.first.must_equal Point[7.mm, 2.mm]
				    arc.last.must_equal Point[11.mm, 6.mm]
				end

				it "must generate a proper second Arc" do
				    arc = layer.geometry[10][1]
				    arc.center.must_equal Point[7.mm, 6.mm]
				    arc.first.must_equal Point[3.mm, 6.mm]
				    arc.last.must_equal Point[7.mm, 2.mm]
				end

				it "must generate a proper third Arc" do
				    arc = layer.geometry[10][2]
				    arc.center.must_equal Point[7.mm, 6.mm]
				    arc.first.must_equal Point[7.mm, 10.mm]
				    arc.last.must_equal Point[3.mm, 6.mm]
				end

				it "must generate a proper fourth Arc" do
				    arc = layer.geometry[10].last
				    arc.center.must_equal Point[7.mm, 6.mm]
				    arc.first.must_equal Point[11.mm, 6.mm]
				    arc.last.must_equal Point[7.mm, 10.mm]
				end
			    end

			    describe "when parsing a counterclockwise arc" do
				before do
				    layer.parse_gcode(3, 7, 10, 4, 0, 1)
				end

				it "must generate an Arc" do
				    layer.geometry[10].last.must_be_kind_of(Geometry::Arc)
				    arc = layer.geometry[10].last
				    arc.center.must_equal Point[7.mm, 6.mm]
				    arc.first.must_equal Point[11.mm, 6.mm]
				    arc.last.must_equal Point[7.mm, 10.mm]
				end

				it "must set the current position to the Arc's end point" do
				    layer.position.must_equal Point[7.mm, 10.mm]
				end

				describe "when parsing another arc with a modal function number" do
				    before do
					layer.parse_gcode(nil, 3, 6, 0, 4, nil)
				    end

				    it "must generate an Arc" do
					layer.geometry[10].last.must_be_kind_of(Geometry::Arc)
					arc = layer.geometry[10].last
					arc.center.must_equal Point[7.mm, 6.mm]
					arc.first.must_equal Point[7.mm, 10.mm]
					arc.last.must_equal Point[3.mm, 6.mm]
				    end

				    it "must set the current position to the Arc's end point" do
					layer.position.must_equal Point[3.mm, 6.mm]
				    end

				    describe "when parsing a third arc" do
					before do
					    layer.parse_gcode(nil, 7, 2, 4, 0, nil)
					end

					it "must generate an Arc" do
					    layer.geometry[10].last.must_be_kind_of(Geometry::Arc)
					    arc = layer.geometry[10].last
					    arc.center.must_equal Point[7.mm, 6.mm]
					    arc.first.must_equal Point[3.mm, 6.mm]
					    arc.last.must_equal Point[7.mm, 2.mm]
					end

					it "must set the current position to the Arc's end point" do
					    layer.position.must_equal Point[7.mm, 2.mm]
					end

					describe "when parsing the final arc in the circle" do
					    before do
						layer.parse_gcode(nil, 11, 6, 0, 4, nil)
					    end

					    it "must generate an Arc" do
						layer.geometry[10].last.must_be_kind_of(Geometry::Arc)
						arc = layer.geometry[10].last
						arc.center.must_equal Point[7.mm, 6.mm]
						arc.first.must_equal Point[7.mm, 2.mm]
						arc.last.must_equal Point[11.mm, 6.mm]
					    end

					    it "must set the current position to the Arc's end point" do
						layer.position.must_equal Point[11.mm, 6.mm]
					    end
					end
				    end
				end
			    end
			end

			describe "when in multi quadrant mode" do
			    before do
				layer.parse_gcode(75)
				layer.parse_gcode(1, 3, -2, nil, nil, 2)    # Set the current position
			    end

			    describe "when parsing a clockwise arc" do
				before do
				    layer.parse_gcode(2, -3, -2, -3, 4, 1)
				end

				it "must generate an Arc" do
				    layer.geometry[10].last.must_be_kind_of(Geometry::Arc)
				    arc = layer.geometry[10].last
				    arc.center.must_equal Point[0.mm, 2.mm]
				    arc.first.must_equal Point[-3.mm, -2.mm]
				    arc.last.must_equal Point[3.mm, -2.mm]
				end

				it "must set the current position to the endpoint of the Arc" do
				    layer.position.must_equal Point[-3.mm, -2.mm]
				end
			    end

			    describe "when parsing a counterclockwise arc" do
				before do
				    layer.parse_gcode(3, -3, -2, -3, 4, 1)
				end

				it "must generate an Arc" do
				    layer.geometry[10].last.must_be_kind_of(Geometry::Arc)
				    arc = layer.geometry[10].last
				    arc.center.must_equal Point[0.mm, 2.mm]
				    arc.first.must_equal Point[3.mm, -2.mm]
				    arc.last.must_equal Point[-3.mm, -2.mm]
				end

				it "must set the current position to the endpoint of the Arc" do
				    layer.position.must_equal Point[-3.mm, -2.mm]
				end
			    end
			end
		    end

		    describe "when in incremental mode" do
			before do
			    layer.parse_gcode(91)
			end
			
			describe "when in single quadrant mode" do
			    before do
				layer.parse_gcode(74)
				layer.parse_gcode(1, 11, 6, nil, nil, 2)    # Set the current position
			    end

			    describe "when parsing four clockwise arcs" do
				before do
				    layer.parse_gcode(2, -4, -4, 4, 0, 1)
				    layer.parse_gcode(2, -4, 4, 0, 4, nil)
				    layer.parse_gcode(nil, 4, 4, 4, 0, nil)
				    layer.parse_gcode(nil, 4, -4, 0, 4, nil)
				end

				it "must generate 4 Arcs" do
				    layer.geometry[10].length.must_equal 4
				    layer.geometry[10].all? {|a| a.kind_of?(Geometry::Arc)}.must_equal(true)
				end

				it "must generate a proper first Arc" do
				    arc = layer.geometry[10].first
				    arc.center.must_equal Point[7.mm, 6.mm]
				    arc.first.must_equal Point[7.mm, 2.mm]
				    arc.last.must_equal Point[11.mm, 6.mm]
				end

				it "must generate a proper second Arc" do
				    arc = layer.geometry[10][1]
				    arc.center.must_equal Point[7.mm, 6.mm]
				    arc.first.must_equal Point[3.mm, 6.mm]
				    arc.last.must_equal Point[7.mm, 2.mm]
				end

				it "must generate a proper third Arc" do
				    arc = layer.geometry[10][2]
				    arc.center.must_equal Point[7.mm, 6.mm]
				    arc.first.must_equal Point[7.mm, 10.mm]
				    arc.last.must_equal Point[3.mm, 6.mm]
				end

				it "must generate a proper fourth Arc" do
				    arc = layer.geometry[10].last
				    arc.center.must_equal Point[7.mm, 6.mm]
				    arc.first.must_equal Point[11.mm, 6.mm]
				    arc.last.must_equal Point[7.mm, 10.mm]
				end
			    end

			    describe "when parsing a counterclockwise arc" do
				before do
				    layer.parse_gcode(3, -4, 4, 4, 0, 1)
				end

				it "must generate an Arc" do
				    layer.geometry[10].last.must_be_kind_of(Geometry::Arc)
				    arc = layer.geometry[10].last
				    arc.center.must_equal Point[7.mm, 6.mm]
				    arc.first.must_equal Point[11.mm, 6.mm]
				    arc.last.must_equal Point[7.mm, 10.mm]
				end

				it "must set the current position to the Arc's end point" do
				    layer.position.must_equal Point[7.mm, 10.mm]
				end

				describe "when parsing another arc with a modal function number" do
				    before do
					layer.parse_gcode(nil, -4, -4, 0, 4, nil)
				    end

				    it "must generate an Arc" do
					layer.geometry[10].last.must_be_kind_of(Geometry::Arc)
					arc = layer.geometry[10].last
					arc.center.must_equal Point[7.mm, 6.mm]
					arc.first.must_equal Point[7.mm, 10.mm]
					arc.last.must_equal Point[3.mm, 6.mm]
				    end

				    it "must set the current position to the Arc's end point" do
					layer.position.must_equal Point[3.mm, 6.mm]
				    end

				    describe "when parsing a third arc" do
					before do
					    layer.parse_gcode(nil, 4, -4, 4, 0, nil)
					end

					it "must generate an Arc" do
					    layer.geometry[10].last.must_be_kind_of(Geometry::Arc)
					    arc = layer.geometry[10].last
					    arc.center.must_equal Point[7.mm, 6.mm]
					    arc.first.must_equal Point[3.mm, 6.mm]
					    arc.last.must_equal Point[7.mm, 2.mm]
					end

					it "must set the current position to the Arc's end point" do
					    layer.position.must_equal Point[7.mm, 2.mm]
					end

					describe "when parsing the final arc in the circle" do
					    before do
						layer.parse_gcode(nil, 4, 4, 0, 4, nil)
					    end

					    it "must generate an Arc" do
						layer.geometry[10].last.must_be_kind_of(Geometry::Arc)
						arc = layer.geometry[10].last
						arc.center.must_equal Point[7.mm, 6.mm]
						arc.first.must_equal Point[7.mm, 2.mm]
						arc.last.must_equal Point[11.mm, 6.mm]
					    end

					    it "must set the current position to the Arc's end point" do
						layer.position.must_equal Point[11.mm, 6.mm]
					    end
					end
				    end
				end
			    end
			end
		    end
		end
	    end
	end
    end

    describe "when parsing an M code" do
	it "must ignore M00" do
	    layer.parse_mcode(0)
	end

	it "must ignore M01" do
	    layer.parse_mcode(1)
	end

	it "must reject anything after M02" do
	    skip "Not yet implemented"
	    layer.parse_mcode(2)
	    lambda { layer.parse_dcode('D11') }.must_raise Gerber::ParseError
	end
	
    end

end
