require 'dxf/builder'

module DXF
  class Writer
    def initialize(io)
      @io = io.is_a?(IO) ? io : File.open(io, 'w')
      @ew = DXF::EntitiesWriter.new
    end

    def entities
      @ew
    end

    def finish
      DXF::Builder.new(@io) do |b|
        b.group 999, 'DXF Ruby'
        @ew.write(b)
        b.group 0, 'EOF'
      end
    end
  end

  class EntitiesWriter
    def initialize
      @entities = []
    end

    def line(x1, y1, x2, y2, opts = nil)
      @entities << DXF::Line.new(x1, y1, x2, y2, opts)
    end

    def write(b)
      b.section 'ENTITIES' do |b|
        @entities.each { |e| e.write(b) }
      end
    end
  end

  # name(-1) - may be opt
  # layer(8), line weight (370)
  class Entity
    def initialize(opts)
      @opts = opts.nil? ? {} : opts
    end

    def write(b)
      b.group 100, 'AcDbEntity'
      b.handle
    end
  end

  class Line < DXF::Entity
    def initialize(x1, y1, x2, y2, opts = nil)
      super(opts)
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
end
