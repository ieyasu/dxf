require 'dxf/builder'
require 'dxf/tables'

module DXF
  class Writer
    attr_reader :tables
    attr_reader :entities

    def initialize(io)
      @io = io.is_a?(IO) ? io : File.open(io, 'w')
      @tables = DXF::TablesWriter.new
      @entities = DXF::EntitiesWriter.new
    end

    def finish
      @tables.layers.entries = @entities.layers

      DXF::Builder.new(@io) do |b|
        b.group 999, 'DXF Ruby'
        b.section 'HEADER' do
          b.group 9, '$ACADVER'
          b.group 1, 'AC1015'
        end
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

    def line(x1, y1, x2, y2, opts = nil)
      @entities << DXF::Line.new(@layer, x1, y1, x2, y2, opts)
    end

    def lwpolyline(points, opts = nil)
      @entities << DXF::LWPolyLine.new(@layer, points, opts)
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

  class Entity
    attr_reader :layer

    def initialize(layer, opts)
      @layer = layer
      @opts = opts.nil? ? {} : opts
    end

    def write(b)
      b.group 100, 'AcDbEntity'
      b.handle
      b.group 8, @layer.name
    end
  end

  class Line < DXF::Entity
    def initialize(layer, x1, y1, x2, y2, opts = nil)
      super(layer, opts)
      @coords = [x1, y1, x2, y2]
    end

    def write(b)
      b.group 0, 'LINE'
      super(b)
      b.group 100, 'AcDbLine'
      b.group(39, @opts[:thickness].to_f) if @opts[:thickness]
      b.group 10, @coords[0].to_f # x1
      b.group 20, @coords[1].to_f # y1
      b.group 30, 0.0             # z1
      b.group 11, @coords[2].to_f # x2
      b.group 21, @coords[3].to_f # y2
      b.group 31, 0.0             # z2
    end
  end

  class LWPolyLine < DXF::Entity
    def initialize(layer, points, opts = nil)
      super(layer, opts)
      @points = points
    end

    def write(b)
      b.group 0, 'LWPOLYLINE'
      super(b)
      b.group 100, 'AcDbPolyline'
      b.group 90, @points.size
      polyline_flag = @opts[:close] ? 1 : 0
      b.group 70, polyline_flag
      # vertices
      @points.each_with_index do |(x, y), n|
        b.group 91, n
        b.group 10, x
        b.group 20, y
      end
    end
  end
end
