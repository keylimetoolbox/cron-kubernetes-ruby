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
              image: ubuntu
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
        name:         "cron-job",
        identifier:   "my-app"
      )
      expect(job.schedule).to eq "30 0 * * *"
      expect(job.command).to eq "/bin/bash -l -c ls\\ -l"
      expect(job.job_manifest).to eq manifest
      expect(job.name).to eq "cron-job"
      expect(job.identifier).to eq "my-app"
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

    it "has an identifier accessor" do
      subject.name = "my-app"
      expect(subject.name).to eq "my-app"
    end
  end

  context "#cron_job_manifest" do
    subject do
      CronKubernetes::CronJob.new(
        schedule:     "*/1 * * * *",
        command:      ["/bin/bash", "-l", "-c", "echo Hello from the Kubernetes cluster"],
        job_manifest: manifest,
        name:         "hello",
        identifier:   "my-app"
      )
    end

    it "generates a Kubernetes CronJob manifest for the scheduled command" do
      expect(subject.cron_job_manifest.to_yaml).to eq <<~MANIFEST
        ---
        apiVersion: batch/v1beta1
        kind: CronJob
        metadata:
          name: my-app-hello
          namespace: default
          labels:
            cron-kubernetes-identifier: my-app
        spec:
          schedule: "*/1 * * * *"
          jobTemplate:
            metadata:
            spec:
              template:
                spec:
                  containers:
                  - name: hello
                    image: ubuntu
                    command:
                    - "/bin/bash"
                    - "-l"
                    - "-c"
                    - echo Hello from the Kubernetes cluster
                  restartPolicy: OnFailure
      MANIFEST
    end

    context "when no name is provided" do
      subject do
        CronKubernetes::CronJob.new(
          schedule:     "*/1 * * * *",
          command:      ["/bin/bash", "-l", "-c", "echo Hello from the Kubernetes cluster"],
          job_manifest: manifest,
          identifier:   "my-app"
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
                    image: ubuntu
                  restartPolicy: OnFailure
          MANIFEST
        end

        it "pulls the name from the Job metadata" do
          expect(subject.cron_job_manifest["metadata"]["name"]).to eq "my-app-hello-job-51e2eaa4"
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
                    image: ubuntu
                  restartPolicy: OnFailure
          MANIFEST
        end

        it "pulls the name from the Pod metadata" do
          expect(subject.cron_job_manifest["metadata"]["name"]).to eq "my-app-hello-pod-51e2eaa4"
          job_template = subject.cron_job_manifest["spec"]["jobTemplate"]
          pod_template = job_template["spec"]["template"]
          expect(pod_template["metadata"]["name"]).to eq "hello-pod"
        end
      end
    end
  end
end
