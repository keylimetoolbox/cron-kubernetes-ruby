# frozen_string_literal: true

require "digest/sha1"

module CronKubernetes
  # A single job to run on a given schedule.
  class CronJob
    attr_accessor :schedule, :command, :job_manifest, :name, :identifier

    def initialize(schedule: nil, command: nil, job_manifest: nil, name: nil, identifier: nil)
      @schedule     = schedule
      @command      = command
      @job_manifest = job_manifest
      @name         = name
      @identifier   = identifier
    end

    # rubocop:disable Metrics/MethodLength
    def cron_job_manifest
      {
          "apiVersion" => "batch/v1",
          "kind"       => "CronJob",
          "metadata"   => {
              "name"      => "#{identifier}-#{cron_job_name}",
              "namespace" => namespace,
              "labels"    => {"cron-kubernetes-identifier" => identifier}
          },
          "spec"       => {
              "schedule"    => schedule,
              "jobTemplate" => {
                  "metadata" => job_metadata,
                  "spec"     => job_spec
              }
          }
      }
    end
    # rubocop:enable Metrics/MethodLength

    private

    def namespace
      return job_manifest["metadata"]["namespace"] if job_manifest["metadata"] && job_manifest["metadata"]["namespace"]

      "default"
    end

    def job_spec
      spec = job_manifest["spec"].dup
      first_container = spec["template"]["spec"]["containers"][0]
      first_container["command"] = command
      spec
    end

    def job_metadata
      job_manifest["metadata"]
    end

    def cron_job_name
      return name if name
      return job_hash(job_manifest["metadata"]["name"]) if job_manifest["metadata"]

      pod_template_name
    end

    def pod_template_name
      return nil unless job_manifest["spec"] &&
          job_manifest["spec"]["template"] &&
          job_manifest["spec"]["template"]["metadata"]

      job_hash(job_manifest["spec"]["template"]["metadata"]["name"])
    end

    def job_hash(name)
      "#{name}-#{Digest::SHA1.hexdigest(schedule + command.join)[0..7]}"
    end
  end
end
