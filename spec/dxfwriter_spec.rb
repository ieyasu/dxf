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
end
