# frozen_string_literal: true

RSpec.describe CronKubernetes::Scheduler do
  subject { CronKubernetes::Scheduler.instance }

  after do
    subject.schedule.clear
  end

  shared_examples "common" do
    context "when output is configured" do
      before do
        @output = CronKubernetes.output
        CronKubernetes.configuration do |config|
          config.output = "2>&1"
        end
      end

      after do
        CronKubernetes.configuration do |config|
          config.output = @output
        end
      end

      it "includes a redirection for the output" do
        expect(CronKubernetes.output).to eq "2>&1"

        action
        expect(subject.schedule.length).to eq 1
        command = subject.schedule.first[1]
        expect(command.join).to end_with " 2>&1"
      end
    end

    it "includes the job template" do
      expect(CronKubernetes.job_template).to eq %w[/bin/bash -l -c :job]

      action
      expect(subject.schedule.length).to eq 1
      command = subject.schedule.first[1]
      expect(command).to start_with %w[/bin/bash -l -c]
    end
  end

  context "#rake" do
    let(:action) { subject.rake("audit:state", schedule: "0 20 1 * *") }

    it "adds a rake task to the cron list" do
      action
      expect(subject.schedule.length).to eq 1
      cron, command = *subject.schedule.first
      expect(cron).to eq "0 20 1 * *"
      expect(command.join).to include "bundle exec rake audit:state"
    end

    it "properly escapes quotes in the rake task" do
      subject.rake("audit:state MAIL_TO='notice@example.com'", schedule: "0 20 1 * *")
      expect(subject.schedule.length).to eq 1
      command = subject.schedule.first[1]
      expect(command.join).to include "MAIL_TO='notice@example.com'"
    end

    context "when RAILS_ENV is defined" do
      before do
        @rails_env = ENV["RAILS_ENV"]
        ENV["RAILS_ENV"] = "production"
      end

      after do
        ENV["RAILS_ENV"] = @rails_env
      end

      it "includes the RAILS_ENV" do
        action
        expect(subject.schedule.length).to eq 1
        command = subject.schedule.first[1]
        expect(command.join).to include "RAILS_ENV=production"
      end
    end

    context "when RAILS_ENV is not defined" do
      it "does not include the RAILS_ENV" do
        action
        expect(subject.schedule.length).to eq 1
        command = subject.schedule.first[1]
        expect(command.join).not_to include "RAILS_ENV"
      end
    end

    include_examples "common"
  end

  context "#runner" do
    let(:action) { subject.runner("puts CronKubernetes.name", schedule: "30 3 * * *") }

    it "adds a runner task to the cron list that invokes the code in the block" do
      action
      expect(subject.schedule.length).to eq 1
      cron, command = *subject.schedule.first
      expect(cron).to eq "30 3 * * *"
      expect(command.join).to include "bin/rails runner 'puts CronKubernetes.name'"
    end

    context "when RAILS_ENV is defined" do
      before do
        @rails_env = ENV["RAILS_ENV"]
        ENV["RAILS_ENV"] = "production"
      end

      after do
        ENV["RAILS_ENV"] = @rails_env
      end

      it "includes the -e parameter" do
        action
        expect(subject.schedule.length).to eq 1
        command = subject.schedule.first[1]
        expect(command.join).to include " -e production "
      end
    end

    context "when RAILS_ENV is not defined" do
      it "does not include the RAILS_ENV" do
        action
        expect(subject.schedule.length).to eq 1
        command = subject.schedule.first[1]
        expect(command.join).not_to include " -e "
      end
    end

    include_examples "common"
  end

  context "#command" do
    let(:action) { subject.command("ls -l", schedule: "0 1 1 1 *") }

    it "adds any shell command to the cron list" do
      action
      expect(subject.schedule.length).to eq 1
      cron, command = *subject.schedule.first
      expect(cron).to eq "0 1 1 1 *"
      expect(command.join).to include "ls -l"
    end

    include_examples "common"
  end

end
