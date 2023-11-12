# frozen_string_literal: true

require "spec_helper"
require "googleauth"

RSpec.describe CronKubernetes::KubeclientContext do
  let(:context) { CronKubernetes::KubeclientContext.context }

  context "when run from a cluster" do
    before do
      File.stubs(:exist?).returns(false)
      File.stubs(:exist?).with(CronKubernetes::Context::WellKnown::TOKEN_FILE).returns(true)
    end

    it "returns a context using the available token file" do
      expect(context.endpoint).to eq "https://kubernetes.default.svc"
      expect(context.version).to eq "v1"
      expect(context.namespace).to be_nil
      expect(context.options[:auth_options].keys).to eq %i[bearer_token_file]
      token_file = CronKubernetes::Context::WellKnown::TOKEN_FILE
      expect(context.options[:auth_options][:bearer_token_file]).to eq(token_file)
      expect(context.options[:ssl_options]).to be_empty
    end

    context "with a CA file" do
      before do
        File.stubs(:exist?).with(CronKubernetes::Context::WellKnown::CA_FILE).returns(true)
      end

      it "includes the CA in the SSL options" do
        expect(context.options[:ssl_options].keys).to eq %i[ca_file]
        ca_file = CronKubernetes::Context::WellKnown::CA_FILE
        expect(context.options[:ssl_options][:ca_file]).to eq(ca_file)
      end
    end

    context "with a namespace file" do
      before do
        File.stubs(:exist?).with(CronKubernetes::Context::WellKnown::NAMESPACE_FILE).returns(true)
        File.stubs(:read).with(CronKubernetes::Context::WellKnown::NAMESPACE_FILE).returns("name")
      end

      it "includes the namespace" do
        expect(context.namespace).to eq "name"
      end
    end
  end

  context "when run from a kubectl machine" do
    let(:kubectl_file) { CronKubernetes::Context::Kubectl.new.send(:kubeconfig) }

    before do
      File.stubs(:exist?).returns(false)
      File.stubs(:exist?).with(kubectl_file).returns(true)
      Kubeclient::Config.stubs(:read).with(kubectl_file).returns(config)
    end

    context "without Google default credentials" do
      let(:config) do
        OpenStruct.new(
          context: OpenStruct.new(
            api_endpoint: "https://127.0.0.1:8443",
            api_version:  "v1",
            namespace:    nil,
            auth_options: {bearer_token: "token"},
            ssl_options:  {ca_file: "/path/to/ca.crt"}
          )
        )
      end

      it "returns a context from the kubectl configuration" do
        expect(context.endpoint).to eq "https://127.0.0.1:8443"
        expect(context.version).to eq "v1"
        expect(context.namespace).to be_nil
        expect(context.options[:auth_options].keys).to eq %i[bearer_token]
        expect(context.options[:auth_options][:bearer_token]).to eq("token")
        expect(context.options[:ssl_options].keys).to eq %i[ca_file]
        expect(context.options[:ssl_options][:ca_file]).to eq("/path/to/ca.crt")
      end
    end

    context "with Google default credentials" do
      let(:config) do
        OpenStruct.new(
          context: OpenStruct.new(
            api_endpoint: "https://127.0.0.1:8443",
            api_version:  "v1",
            namespace:    nil,
            auth_options: {},
            ssl_options:  {}
          )
        )
      end

      it "retrieves authentication from the Google application default credentials" do
        Kubeclient::GoogleApplicationDefaultCredentials.expects(:token).returns("token")

        expect(context.endpoint).to eq "https://127.0.0.1:8443"
        expect(context.version).to eq "v1"
        expect(context.namespace).to be_nil
        expect(context.options[:auth_options].keys).to eq %i[bearer_token]
        expect(context.options[:auth_options][:bearer_token]).to eq("token")
        expect(context.options[:ssl_options].keys).to be_empty
      end
    end
  end
end
