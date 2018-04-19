# frozen_string_literal: true

require "cron_kubernetes/configurable"
require "cron_kubernetes/cron_job"
require "cron_kubernetes/scheduler"
require "cron_kubernetes/version"

# Configure and deploy Kubernetes CronJobs from ruby
module CronKubernetes
  extend Configurable

  # Provide a CronJob manifest as a Hash
  define_setting :manifest

  # Provide shell output redirection (e.g. "2>&1" or ">> log")
  define_setting :output

  # For RVM support, and to load PATH and such, jobs are run through a bash shell.
  # You can alter this with your own template, add `:job` where the job should go.
  # Note that the job will be treated as a single shell argument or command.
  define_setting :job_template, %w[/bin/bash -l -c :job]

  class << self
    def schedule(&block)
      CronKubernetes::Scheduler.instance.instance_eval(&block)
    end
  end
end
