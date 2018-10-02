# frozen_string_literal: true

require "kubeclient"

module CronKubernetes
  # Create a context for `Kubeclient` depending on the environment.
  class KubeclientContext
    Context = Struct.new(:endpoint, :version, :namespace, :options)

    class << self
      def context
        [
            CronKubernetes::Context::WellKnown,
            CronKubernetes::Context::Kubectl
        ].each do |context_type|
          context = context_type.new
          return context.context if context.applicable?
        end
      end
    end
  end
end
