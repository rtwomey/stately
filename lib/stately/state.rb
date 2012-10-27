module Stately
  class State
    attr_reader :action, :name
    attr_reader :allow_from_states, :prevent_from_states
    attr_reader :after_transitions, :before_transitions, :validations

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

    def to_s
      @name.to_s
    end

    def to_sym
      @name.to_sym
    end

    private

    ACTIONS = { completed: :complete, converting: :convert, invalid: :invalidate,
      preparing: :prepare, processing: :process, refunded: :refund, reticulating: :reticulate,
      saving: :save, searching: :search, started: :start, stopped: :stop }

    def guess_action_for(name)
      ACTIONS[name.to_sym]
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
