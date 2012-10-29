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

    describe "when reading Example 1 from the specification" do
	let(:gerber) { Gerber.read('test/gerber/two_boxes.gerber') }

	it "must create a Gerber object" do
	    gerber.must_be_instance_of(Gerber)
	end

	it "must have only 1 layer" do
	    gerber.layers.count.must_equal 1
	    gerber.layers.last.name.must_equal "BOXES"
	end
    end

    it "must read Example 2 from the specification" do
	skip "There's an error in the example"
	Gerber.read('test/gerber/example2.gerber')
    end

    it "must reject files with an M02 before the EOF" do
	lambda { Gerber.read('test/gerber/m02_not_at_end.gerber') }.must_raise Gerber::ParseError
    end
end