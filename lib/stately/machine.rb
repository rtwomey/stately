module Stately
  class Machine
    attr_reader :start, :state_attr, :states

    def initialize(attr_name, start)
      @state_attr = attr_name
      @start = start
      @states = [State.new(@start)]
    end

    def state(name, opts={}, &block)
      @states.delete_if { |s| s.name == name }

      action = opts ? opts[:action] : nil
      @states << State.new(name, action, &block)
    end
  end
end
