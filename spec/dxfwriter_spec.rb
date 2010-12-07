require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'dxf/writer'

describe DXF::Writer do
  it "draws a line" do
    file = "line.dxf"
    dw = DXF::Writer.new(file)
    dw.entities.line(2, 2, 5, 8)
    dw.finish
    File.exist?(file).should be_true
    File.size(file).should > 0
  end

  it "draws a polyline" do
    file = "polyline.dxf"
    dw = DXF::Writer.new(file)
    dw.entities.lwpolyline([[2,1], [1,4], [5,5], [6,2]])
    dw.entities.lwpolyline([[9,3], [7,5], [9,7], [11,5]], :close => true)
    dw.finish
    File.exist?(file).should be_true
    File.size(file).should > 0
  end
end
