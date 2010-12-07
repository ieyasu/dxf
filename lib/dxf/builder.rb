module DXF
  class Builder
    @@handle = 0

    def self.next_handle
      @@handle += 1
      sprintf "%x", @@handle
    end

    def initialize(io)
      @io = io
      if block_given?
        yield(self)
        @io.close
      end
    end

    def group(code, value)
      @io.printf "%3i\r\n%s\r\n", code, value.to_s
    end

    def handle
      group 5, Builder::next_handle
    end

    def section(name, &block)
      group 0, 'SECTION'
      group 2, name
      yield(self)
      group 0, 'ENDSEC'
    end

    def table(name, num_entries, &block)
      group 0, 'TABLE'
      group 2, name
      handle
      group 100, 'AcDbSymbolTable'
      group 70, num_entries
      yield
      group 0, 'ENDTAB'
    end

    def table_item(type, subclass, name, flags = 0)
      group 0, type
      group 100, 'AcDbSymbolTableRecord'
      group 100, subclass
      group 2, name
      group 70, flags
      yield if block_given?
    end
  end
end
