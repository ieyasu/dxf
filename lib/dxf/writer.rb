require 'dxf/builder'
require 'dxf/tables'
require 'dxf/entities'

module DXF
  class Writer
    attr_reader :tables
    attr_reader :entities

    def initialize(io)
      @io = io.respond_to?(:printf) ? io : File.open(io, 'w')
      @tables = DXF::TablesWriter.new
      @entities = DXF::EntitiesWriter.new
    end

    def write_header(b)
      b.section 'HEADER' do
        b.group 9, '$ACADVER'
        b.group 1, 'AC1015'
        b.group 9, '$CLAYER'
        b.group 8, @entities.layer.name

        b.group 9, '$ANGBASE'
        b.group 50, 0.0
        b.group 9, '$ANGDIR'
        b.group 70, 1 # clockwise
      end
    end

    def finish
      @tables.layers.entries = @entities.layers

      DXF::Builder.new(@io) do |b|
        b.group 999, 'DXF Ruby'
        write_header(b)
        @tables.write(b)
        @entities.write(b)
        b.group 0, 'EOF'
      end
    end
  end

  class EntitiesWriter
    attr_accessor :layer

    def initialize
      @entities = []
      @layer = DXF::Layer.default
    end

    def point(x, y, opts = nil)
      @entities << DXF::Point.new(@layer, x, y, opts)
    end

    def line(x1, y1, x2, y2, opts = nil)
      @entities << DXF::Line.new(@layer, x1, y1, x2, y2, opts)
    end

    def lwpolyline(points, opts = nil)
      @entities << DXF::LWPolyLine.new(@layer, points, opts)
    end

    def circle(cenx, ceny, radius, opts = nil)
      @entities << DXF::Circle.new(@layer, cenx, ceny, radius, opts)
    end

    def arc(cenx, ceny, radius, start_angle, end_angle, opts = nil)
      @entities << DXF::Arc.new(@layer, cenx, ceny, radius,
                                start_angle, end_angle, opts)
    end

    def ellipse(cenx, ceny, maj_x, maj_y, min_ratio,
                start_rad = 0.0, end_rad = 360, opts = nil)
      @entities << DXF::Ellipse.new(@layer, cenx, ceny, maj_x, maj_y,
                                    min_ratio, start_rad, end_rad, opts)
    end

    def write(b)
      b.section 'ENTITIES' do |b|
        @entities.each { |e| e.write(b) }
      end
    end

    def layers
      @set = {}
      @entities.each do |entity|
        l = entity.layer
        if @set.has_key?(l.name) && @set[l.name] != l
          raise "Non-unique layer name: #{l.name.inspect}"
        else
          @set[l.name] = l
        end
      end
      @set.values
    end
  end
end
