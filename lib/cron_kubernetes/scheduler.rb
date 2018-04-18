# frozen_string_literal: true

require "singleton"

module CronKubernetes
  class Scheduler
    include Singleton
    attr_reader :schedule

    def initialize
      @schedule = []
    end

    def rake(task, schedule:)
      rake_command = "bundle exec rake #{task} --silent"
      rake_command = "RAILS_ENV=#{rails_env} #{rake_command}" if rails_env
      @schedule << [schedule, make_command(rake_command)]
    end

    def runner(ruby_command, schedule:)
      env = nil
      env = "-e #{rails_env} " if rails_env
      runner_command = "bin/rails runner #{env}'#{ruby_command}'"
      @schedule << [schedule, make_command(runner_command)]
    end

    def command(command, schedule:)
      @schedule << [schedule, make_command(command)]
    end

    private

    def make_command(command)
      cmd = CronKubernetes.job_template.dup
      # Use `["..."]` instead of `#sub` because sub thinks "\&" is a back-reference
      cmd[":job"] = Shellwords.escape("cd #{root} && #{command} #{CronKubernetes.output}")
      cmd
    end

    def rails_env
      ENV["RAILS_ENV"]
    end

    def root
      return Rails.root if defined? Rails
      Dir.pwd
    end
  end
end
