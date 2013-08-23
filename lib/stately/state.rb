module Stately
  # A Stately::State object contains the configuration and other information about a defined
  # state.
  #
  # It's made up of a name (which is saved to the parent instance's state attribute), the
  # name of an action (which is a method called to transition into this state), and a DSL to
  # define allowed transitions, callbacks, and validations.

  class State
    attr_reader :action, :name
    attr_reader :allow_from_states, :prevent_from_states
    attr_reader :after_transitions, :before_transitions, :validations

    # Sets up and returns a new Stately::State object.
    #
    # @param [String] name The name of the state
    # @param [String] action The method name that's called to transition to this state. Some method
    #   names can be inferred based on the state's name.
    def initialize(name, action=nil, &block)
      @action = (action || guess_action_for(name)).to_s
      @name = name

      @allow_from_states = []
      @prevent_from_states = []

      @before_transitions = []
      @after_transitions = []
      @validations = []

      if block_given?
        configuration = StateConfigurator.new(&block)

        @allow_from_states = configuration.allow_from_states || []
        @prevent_from_states = configuration.prevent_from_states || []

        @after_transitions = configuration.after_transitions || []
        @before_transitions = configuration.before_transitions || []
        @validations = configuration.validations || []
      end
    end

    # @return [String] The state name as a string
    def to_s
      @name.to_s
    end

    # @return [Symbol] The state name as a string
    def to_sym
      @name.to_sym
    end

    private

    ACTIONS = { :completed => :complete, :converting => :convert, :invalid => :invalidate,
      :preparing => :prepare, :processing => :process, :refunded => :refund, :reticulating => :reticulate,
      :saving => :save, :searching => :search, :started => :start, :stopped => :stop }

    def guess_action_for(name)
      ACTIONS.fetch(name.to_sym, name)
    end

    class StateConfigurator
      attr_reader :after_transitions, :before_transitions, :validations
      attr_reader :allow_from_states, :prevent_from_states

      def initialize(&block)
        instance_eval(&block)
      end

      def allow_from(*states)
        @allow_from_states ||= []
        @allow_from_states |= states.map(&:to_sym)
      end

      def before_transition(options={})
        @before_transitions ||= []
        @before_transitions << options
      end

      def after_transition(options={})
        @after_transitions ||= []
        @after_transitions << options
      end

      def prevent_from(*states)
        @prevent_from_states ||= []
        @prevent_from_states |= states.map(&:to_sym)
      end

      def validate(options={})
        @validations ||= []
        @validations << options
      end
    end
  end
end
