module DXF
  class Builder
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

    def section(name, &block)
      group 0, 'SECTION'
      group 2, name
      yield(self)
      group 0, 'ENDSEC'
    end
  end
end
