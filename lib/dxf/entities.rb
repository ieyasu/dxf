module DXF
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

  class Point < DXF::Entity
    def initialize(layer, x, y, opts = nil)
      super(layer, opts)
      @x = x
      @y = y
    end

    def write(b)
      b.group 0, 'POINT'
      super(b)
      b.group 100, 'AcDbPoint'
      b.group(39, @opts[:thickness].to_f) if @opts[:thickness]
      b.group 10, @x.to_f # x
      b.group 20, @y.to_f # y
      b.group 30, 0.0     # z
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

  class Circle < DXF::Entity
    def initialize(layer, cenx, ceny, radius, opts = nil)
      super(layer, opts)
      @cenx = cenx
      @ceny = ceny
      @radius = radius
    end

    def write(b)
      b.group 0, 'CIRCLE'
      super(b)
      b.group 100, 'AcDbCircle'
      b.group 10, @cenx.to_f
      b.group 20, @ceny.to_f
      b.group 40, @radius.to_f
    end
  end

  class Arc < DXF::Entity
    def initialize(layer, cenx, ceny, radius, start_angle, end_angle,
                   opts = nil)
      super(layer, opts)
      @cenx = cenx
      @ceny = ceny
      @radius = radius
      @start_angle = start_angle
      @end_angle = end_angle
    end

    def write(b)
      b.group 0, 'ARC'
      super(b)
      b.group 100, 'AcDbCircle'
      b.group 10, @cenx.to_f
      b.group 20, @ceny.to_f
      b.group 40, @radius.to_f
      b.group 50, @start_angle
      b.group 51, @end_angle
    end
  end

  class Ellipse < DXF::Entity
    def initialize(layer, cenx, ceny, maj_x, maj_y, min_ratio,
                   start_deg = 0, end_deg = 360, opts = nil)
      super(layer, opts)
      @cenx = cenx
      @ceny = ceny
      @maj_x = maj_x
      @maj_y = maj_y
      @min_ratio = min_ratio
      @start_deg = start_deg
      @end_deg = end_deg
    end

    def write(b)
      b.group 0, 'ELLIPSE'
      super(b)
      b.group 100, 'AcDbEllipse'
      b.group 10, @cenx.to_f
      b.group 20, @ceny.to_f
      b.group 11, @maj_x.to_f
      b.group 21, @maj_y.to_f
      b.group 40, @min_ratio.to_f
      b.group 41, deg2rad(@start_deg)
      b.group 42, deg2rad(@end_deg)
    end

    def deg2rad(deg)
      Math::PI * deg / 180.0
    end
  end
end
