# frozen_string_literal: true

module CronKubernetes
  # Encapsulate access to Kubernetes API for different API versions.
  class KubernetesClient
    def batch_beta1_client
      @batch_beta1_client ||= client("/apis/batch", "v1beta1")
    end

    private

    def client(scope, version = nil)
      context = KubeclientContext.context
      return unless context

      Kubeclient::Client.new(
          context.api_endpoint + scope,
          version || context.api_version,
          ssl_options:  context.ssl_options,
          auth_options: context.auth_options
      )
    end
  end
end
