# frozen_string_literal: true

module CronKubernetes
  module Context
    # Kubeclient Context from well-known locations within a Kubernetes cluster.
    class WellKnown
      TOKEN_FILE     = "/var/run/secrets/kubernetes.io/serviceaccount/token"
      CA_FILE        = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
      NAMESPACE_FILE = "/var/run/secrets/kubernetes.io/serviceaccount/namespace"

      def applicable?
        File.exist?(TOKEN_FILE)
      end

      def context
        CronKubernetes::KubeclientContext::Context.new(
          "https://kubernetes.default.svc",
          "v1",
          namespace,
          auth_options: {bearer_token_file: TOKEN_FILE},
          ssl_options:
        )
      end

      private

      def namespace
        return nil unless File.exist?(NAMESPACE_FILE)

        File.read(NAMESPACE_FILE)
      end

      def ssl_options
        return {} unless File.exist?(CA_FILE)

        {ca_file: CA_FILE}
      end
    end
  end
end
