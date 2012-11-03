module Stately
  # A Stately::Machine is a container for Stately::States.
  class Machine
    attr_reader :start, :state_attr, :states

    # Sets up a new instance of Stately::Machine
    def initialize(attr_name, start)
      @state_attr = attr_name
      @start = start
      @states = [State.new(@start)]
    end

    # Define a new Stately::State and add it to this Stately::Machine.
    #
    # @param [String] name The name of the state. This is also stored in the instance object's
    #   state attribute.
    # @param [Hash] opts Optionally, a method name can be defined as this state's action, if it
    #   can't be inferred from the name.
    def state(name, opts={}, &block)
      @states.delete_if { |s| s.name == name }

      action = opts ? opts[:action] : nil
      @states << State.new(name, action, &block)
    end
  end
end
