module DXF
  class TablesWriter
    attr_reader :layers

    def initialize
      @layers = DXF::LayersWriter.new
    end

    def write(b)
      DXF::TableWriter.new('LTYPE', @layers.linetypes).write(b)
      @layers.write(b)
    end
  end

  class TableWriter
    attr_accessor :entries

    def initialize(name, entries = [])
      @name = name
      @entries = entries
    end

    def write(b)
      b.table(@name, @entries.length) do
        @entries.each {|e| e.write(b)}
      end
    end
  end

  class LayersWriter < TableWriter
    def initialize
      super('LAYER')
    end

    def linetypes
      @set = {}
      @entries.each do |layer|
        lt = layer.linetype
        if @set.has_key?(lt.name) && @set[lt.name] != lt
          raise "Non-unique linetype name: #{lt.name.inspect}"
        else
          @set[lt.name] = lt
        end
      end
      @set.values
    end
  end

  class Linetype
    def self.continuous
      unless @continuous
        @continuous = DXF::Linetype.new('CONTINUOUS', 'Solid line _______', [])
      end
      @continuous
    end

    def self.dot
      unless @dot
        @dot = DXF::Linetype.new('DOTTED', 'Dotted . . .', [0.0, -6.3])
      end
      @dot
    end

    def self.dash
      unless @dash
        @dash = DXF::Linetype.new('DASHED', 'Dashed __ __', [12.7, -6.3])
      end
      @dash
    end

    def self.dashdot
      unless @dashdot
        @dashdot = DXF::Linetype.new('DASHDOT', 'Dash dot __ . __ .',
                                     [12.7, -6.3, 0, -6.3])
      end
      @dashdot
    end

    def self.divide
      unless @divide
        @divide = DXF::Linetype.new('DIVIDE', 'Divide ____ . . ____ . .',
                                    [12.7, -6.3, 0, -6.3, 0, -6.3])
      end
      @divide
    end

    def self.center
      unless @center
        @center = DXF::Linetype.new('CENTER', 'Center ____ _ ____ _',
                                    [31.7, -6.3, 6.3, -6.3])
      end
      @center
    end

    def self.border
      unless @border
        @border = DXF::Linetype.new('BORDER', 'Border __ __ .',
                                    [12.7, -6.3, 12.7, -6.3, 0, -6.3])
      end
      @border
    end

    attr_reader :name

    # pattern: array of dash/dot/space lengths.  Positive lengths are drawn,
    # negative lengths are not.
    def initialize(name, description, pattern)
      @name = name
      @description = description
      @pattern = pattern
    end

    def write(b)
      b.table_item('LTYPE', 'AcDbLinetypeTableRecord', @name) do
        b.group 3, @description
        b.group 72, 65 # alignment code, always 65 according to docs
        b.group 73, @pattern.length
        b.group 40, total_length
        @pattern.each do |elem|
          b.group 49, elem.to_f
          b.group 74, 0 # no embedded shape/text
        end
      end
    end

    def total_length
      @pattern.inject(0.0) {|sum, elem| sum + elem.abs}
    end
  end

  class Layer
    attr_reader :name
    attr_accessor :linetype
    attr_accessor :frozen
    attr_accessor :locked

    def self.default
      unless @default
        @default = DXF::Layer.new('0', DXF::Linetype.continuous)
      end
      @default
    end

    def initialize(name, linetype, opts = nil)
      @name = name
      @linetype = linetype
      @opts = opts.nil? ? {} : opts
      @color = @opts.has_key?(:color) ? @opts[:color].to_i : 7
      @frozen = (@opts[:frozen] == true)
      @locked = (@opts[:locked] == true)
    end

    def write(b)
      b.table_item('LAYER', 'AcDbLayerTableRecord', @name, bit_flags) do
        b.group 6, @linetype.name
        if @opts.has_key?(:visible) && !@opts[:visible]
          @color = -(@color.abs)
        end
        b.group 62, @color
        if @opts.has_key?(:plot) && !@opts[:plot]
          b.group 290, 0 # do not plot
        end
      end
    end

    def bit_flags
      flags = 0
      flags |= 0x1 if @frozen
      flags |= 0x4 if @locked
      flags
    end
  end
end
