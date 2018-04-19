# frozen_string_literal: true

RSpec.describe CronKubernetes::CronJob do
  subject { CronKubernetes::CronJob.new }

  let(:manifest) do
    YAML.safe_load <<~MANIFEST
      apiVersion: batch/v1
      kind: Job
      spec:
        template:
          spec:
            containers:
            - name: hello
              image: busybox
            restartPolicy: OnFailure
    MANIFEST
  end

  context "initialization" do
    it "accepts no parameters" do
      expect { CronKubernetes::CronJob.new }.not_to raise_error
    end

    it "accepts schedule, command, job_manifest, name parameters" do
      job = CronKubernetes::CronJob.new(
          schedule:     "30 0 * * *",
          command:      "/bin/bash -l -c ls\\ -l",
          job_manifest: manifest,
          name:         "cron-job"
      )
      expect(job.schedule).to eq "30 0 * * *"
      expect(job.command).to eq "/bin/bash -l -c ls\\ -l"
      expect(job.job_manifest).to eq manifest
    end
  end

  context "accessors" do
    it "has a schedule accessor" do
      subject.schedule = "30 0 * * *"
      expect(subject.schedule).to eq "30 0 * * *"
    end

    it "has a command accessor" do
      subject.schedule = "/bin/bash -l -c ls\\ -l"
      expect(subject.schedule).to eq "/bin/bash -l -c ls\\ -l"
    end

    it "has a job_manifest accessor" do
      subject.job_manifest = manifest
      expect(subject.job_manifest).to eq manifest
    end

    it "has a name accessor" do
      subject.name = "cron-job"
      expect(subject.name).to eq "cron-job"
    end
  end

  context "#cron_job_manifest" do
    subject do
      CronKubernetes::CronJob.new(
          schedule:     "*/1 * * * *",
          command:      ["/bin/bash", "-l", "-c", "echo Hello from the Kubernetes cluster"],
          job_manifest: manifest,
          name:         "hello"
      )
    end

    it "generates a Kubernetes CronJob manifest for the scheduled command" do
      # rubocop:disable Layout/TrailingWhitespace
      expect(subject.cron_job_manifest.to_yaml).to eq <<~MANIFEST
        ---
        apiVersion: batch/v1beta1
        kind: CronJob
        metadata:
          name: hello
        spec:
          schedule: "*/1 * * * *"
          jobTemplate:
            metadata: 
            spec:
              template:
                spec:
                  containers:
                  - name: hello
                    image: busybox
                    command: "/bin/bash"
                    args:
                    - "-l"
                    - "-c"
                    - echo Hello from the Kubernetes cluster
                  restartPolicy: OnFailure
      MANIFEST
      # rubocop:enable Layout/TrailingWhitespace
    end

    context "when no name is provided" do
      subject do
        CronKubernetes::CronJob.new(
            schedule:     "*/1 * * * *",
            command:      ["/bin/bash", "-l", "-c", "echo Hello from the Kubernetes cluster"],
            job_manifest: manifest
        )
      end

      context "but exists in the Job template metadata" do
        let(:manifest) do
          YAML.safe_load <<~MANIFEST
            apiVersion: batch/v1
            kind: Job
            metadata:
              name: hello-job
            spec:
              template:
                spec:
                  containers:
                  - name: hello
                    image: busybox
                  restartPolicy: OnFailure
          MANIFEST
        end

        it "pulls the name from the Job metadata" do
          expect(subject.cron_job_manifest["metadata"]["name"]).to eq "hello-job"
          expect(subject.cron_job_manifest["spec"]["jobTemplate"]["metadata"]["name"]).to eq "hello-job"
        end
      end

      context "but exists in the Pod template metadata" do
        let(:manifest) do
          YAML.safe_load <<~MANIFEST
            apiVersion: batch/v1
            kind: Job
            spec:
              template:
                metadata:
                  name: hello-pod
                spec:
                  containers:
                  - name: hello
                    image: busybox
                  restartPolicy: OnFailure
          MANIFEST
        end

        it "pulls the name from the Pod metadata" do
          expect(subject.cron_job_manifest["metadata"]["name"]).to eq "hello-pod"
          job_template = subject.cron_job_manifest["spec"]["jobTemplate"]
          pod_template = job_template["spec"]["template"]
          expect(pod_template["metadata"]["name"]).to eq "hello-pod"
        end
      end
    end
  end
end
