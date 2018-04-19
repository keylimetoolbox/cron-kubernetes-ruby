# frozen_string_literal: true

RSpec.describe CronKubernetes::CronTab do
  subject { CronKubernetes::CronTab.new }

  let(:client) { stub "Kubeclient::Client" }
  let(:job_manifest) do
    YAML.safe_load <<~MANIFEST
      apiVersion: batch/v1
      kind: Job
      spec:
        template:
          spec:
            containers:
            - image: ubuntu
            restartPolicy: OnFailure
    MANIFEST
  end
  let(:cron_job_manifest) do
    {
        apiVersion: "batch/v1beta1",
        kind:       "CronJob",
        metadata:   {
            name:      "spec-minutely",
            namespace: "default",
            labels:    {"cron-kubernetes-identifier": "spec"}
        },
        spec:       {
            schedule:    "*/1 * * * *",
            jobTemplate: {
                metadata: nil,
                spec:     {
                    template: {
                        spec: {
                            containers:    [{image: "ubuntu", command: "ls -l"}],
                            restartPolicy: "OnFailure"
                        }
                    }
                }
            }
        }
    }
  end
  let(:job) do
    CronKubernetes::CronJob.new(
        schedule:     "*/1 * * * *",
        command:      "ls -l",
        job_manifest: job_manifest,
        name:         "minutely",
        identifier:   "spec"
    )
  end
  let(:cron_job) do
    Kubeclient::Resource.new(cron_job_manifest)
  end

  before do
    CronKubernetes::KubernetesClient.any_instance.stubs(:batch_beta1_client).returns client
    client.stubs(:get_cron_jobs).returns existing
    CronKubernetes::Scheduler.instance.stubs(:schedule).returns schedule
  end

  context "#udpate" do
    context "when new jobs are added to the schedule" do
      let(:existing) { [] }
      let(:schedule) { [job] }

      it "creates the Kubernetes cron job" do
        client.expects(:create_cron_job).with do |resource|
          resource.kind == "CronJob" &&
              resource.metadata.name == "spec-minutely"
        end
        subject.update
      end
    end

    context "when jobs are removed from the schedule" do
      let(:existing) { [cron_job] }
      let(:schedule) { [] }

      it "removes the Kubernetes cron job" do
        client.expects(:delete_cron_job).with("spec-minutely", "default")
        subject.update
      end
    end

    context "for jobs that have not changed in the schedule" do
      let(:existing) { [cron_job] }
      let(:schedule) { [job] }

      it "updates them to ensure they are up-to-date" do
        client.expects(:update_cron_job).with do |resource|
          resource.kind == "CronJob" &&
              resource.metadata.name == "spec-minutely"
        end
        subject.update
      end
    end
  end
end
