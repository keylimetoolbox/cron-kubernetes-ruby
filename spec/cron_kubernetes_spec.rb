# frozen_string_literal: true

RSpec.describe CronKubernetes do
  it "has a version number" do
    expect(CronKubernetes::VERSION).not_to be nil
  end

  context "::configuration" do
    context "job_template" do
      it "defaults nothing" do
        expect(CronKubernetes.output).to be_nil
      end

      context do
        before do
          @manifest = CronKubernetes.manifest
          CronKubernetes.configuration do |config|
            config.manifest = {spec: :template}
          end
        end

        after do
          CronKubernetes.configuration do |config|
            config.manifest = @manifest
          end
        end

        it "can be configured for anything" do
          expect(CronKubernetes.manifest).to eq(spec: :template)
        end
      end
    end

    context "output" do
      it "defaults nothing" do
        expect(CronKubernetes.output).to be_nil
      end

      context do
        before do
          @output = CronKubernetes.output
          CronKubernetes.configuration do |config|
            config.output = ">> log"
          end
        end

        after do
          CronKubernetes.configuration do |config|
            config.output = @output
          end
        end

        it "can be configured for anything" do
          expect(CronKubernetes.output).to eq(">> log")
        end
      end
    end
  end

  context "job_template" do
    it "defaults to a bash shell" do
      expect(CronKubernetes.job_template).to eq "/bin/bash -l -c :job"
    end

    context do
      before do
        @job_template = CronKubernetes.job_template
        CronKubernetes.configuration do |config|
          config.job_template = "/bin/zsh -c :job"
        end
      end

      after do
        CronKubernetes.configuration do |config|
          config.job_template = @job_template
        end
      end

      it "can be configured for anything" do
        expect(CronKubernetes.job_template).to eq("/bin/zsh -c :job")
      end
    end
  end

  context "::schedule" do
    after do
      CronKubernetes::Scheduler.instance.schedule.clear
    end

    it "invokes the block in a CronKubernetes::Scheduler instance context" do
      expect do
        CronKubernetes.schedule do
          nil
        end
      end.not_to raise_error
    end
  end
end
