# frozen_string_literal: true

module CronKubernetes
  # Encapsulate access to Kubernetes API for different API versions.
  class KubernetesClient
    def batch_beta1_client
      @batch_beta1_client ||= client("/apis/batch", "v1beta1")
    end

    def namespace
      context&.namespace
    end

    private

    def client(scope, version = nil)
      return CronKubernetes.kubeclient if CronKubernetes.kubeclient
      return unless context

      Kubeclient::Client.new(context.endpoint + scope, version || context.version, context.options)
    end

    def context
      return nil if CronKubernetes.kubeclient

      @context ||= KubeclientContext.context
    end
  end
end
