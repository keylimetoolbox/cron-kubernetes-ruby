# frozen_string_literal: true

module CronKubernetes
  # The "table" of Kubernetes CronJobs that we manage in the cluster.
  class CronTab
    attr_reader :client
    private :client

    def initialize
      @client = CronKubernetes::KubernetesClient.new.batch_beta1_client
    end

    # "Apply" the new configuration
    #   - remove from cluster any cron_jobs that are no longer in the schedule
    #   - add new jobs
    #   - update cron_jobs that exist (deleting a cron_job deletes the job and pod)
    def update(schedule = nil)
      schedule ||= CronKubernetes::Scheduler.instance.schedule
      add, change, remove = diff_schedules(schedule, current_cron_jobs)
      remove.each { |job| remove_cron_job(job) }
      add.each { |job| add_cron_job(job) }
      change.each { |job| update_cron_job(job) }
    end

    private

    # Define a label for our jobs based on an identifier
    def label_selector
      {"cron-kubernetes-identifier" => CronKubernetes.identifier}
    end

    # Find all k8s CronJobs by our label for the identifier
    def current_cron_jobs
      client.get_cron_jobs(label_selector)
    end

    def diff_schedules(new, existing)
      new_index = index_cron_jobs(new)
      existing_index = index_kubernetes_cron_jobs(existing)
      add_keys    = new_index.keys - existing_index.keys
      remove_keys = existing_index.keys - new_index.keys
      change_keys = new_index.keys & existing_index.keys

      [
          new_index.values_at(*add_keys),
          new_index.values_at(*change_keys),
          existing_index.values_at(*remove_keys)
      ]
    end

    # Remove a Kubeclient::Resource::CronJob from the Kubernetes cluster
    def remove_cron_job(job)
      client.delete_cron_job(job.metadata.name, job.metadata.namespace)
    end

    # Add a CronKubernetes::CronJob to the Kubernetes cluster
    def add_cron_job(job)
      client.create_cron_job(Kubeclient::Resource.new(job.cron_job_manifest))
    end

    def update_cron_job(job)
      client.update_cron_job(Kubeclient::Resource.new(job.cron_job_manifest))
    end

    def index_cron_jobs(jobs)
      jobs.map { |job| ["#{job.identifier}-#{job.name}", job] }.to_h
    end

    def index_kubernetes_cron_jobs(jobs)
      jobs.map { |job| [job.metadata.name, job] }.to_h
    end
  end
end
