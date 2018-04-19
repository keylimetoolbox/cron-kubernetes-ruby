# frozen_string_literal: true

module CronKubernetes
  # A single job to run on a given schedule.
  class CronJob
    attr_accessor :schedule, :command, :job_manifest, :name

    def initialize(schedule: nil, command: nil, job_manifest: nil, name: nil)
      @schedule     = schedule
      @command      = command
      @job_manifest = job_manifest
      @name         = name
    end

    # rubocop:disable Metrics/MethodLength
    def cron_job_manifest
      {
          "apiVersion" => "batch/v1beta1",
          "kind"       => "CronJob",
          "metadata"   => {"name" => cron_job_name},
          "spec"       => {
              "schedule"    => "*/1 * * * *",
              "jobTemplate" => {
                  "metadata" => job_metadata,
                  "spec"     => job_spec
              }
          }
      }
    end
    # rubocop:enable Metrics/MethodLength

    private

    def job_spec
      spec = job_manifest["spec"].dup
      first_container = spec["template"]["spec"]["containers"][0]
      cmd  = command.first
      args = command[1..-1]
      first_container["command"] = cmd
      first_container["args"]    = args
      spec
    end

    def job_metadata
      job_manifest["metadata"]
    end

    def cron_job_name
      return name if name
      return job_manifest["metadata"]["name"] if job_manifest["metadata"]
      pod_template_name
    end

    def pod_template_name
      return nil unless job_manifest["spec"] &&
            job_manifest["spec"]["template"] &&
            job_manifest["spec"]["template"]["metadata"]
      job_manifest["spec"]["template"]["metadata"]["name"]
    end
  end
end
