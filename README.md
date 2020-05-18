# CronKubernetes

Configue and deploy Kubernetes [CronJobs](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/) 
from ruby. 

## Installation

Add this line to your application's Gemfile:

```ruby
gem "cron-kubernetes"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cron_kubernetes

## Configuration

You can configure global settings for your cron jobs. Add a file to your source like the example
below. If you are using Rails, you can add this to something like `config/initializers/cron_kubernetes.rb`.

You _must_ configure the `identifier` and `manifest` settings. The other settings are optional
and default values are shown below.

```ruby
CronKubernetes.configuration do |config|
  # Required
  config.identifier   = "my-application"
  config.manifest     = YAML.load_file(File.join(Rails.root, "deploy", "kubernetes-job.yml"))

  # Optional
  config.output       = nil
  config.job_template = %w[/bin/bash -l -c :job]
end
```

### `identifier`
Provide an identifier for this schedule. For example, you might use your application name.
This is used by `CronKubernetes` to know which CronJobs are associated with this schedule
so you should make sure it's unique within your cluster.

`identifier` must be valid for a Kubernetes resource name and label value. Specifically,
lowercase alphanumeric characters (`[a-z0-9A-Z]`), `-`, and `.`, and 63 characters or less.

### `manifest`

This is a Kubernetes Job manifest used as the job template within the Kubernetes 
CronJob. That is, this is the job that's started at the specified schedule. For 
example:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: scheduled-job
spec:
  template:
    metadata:
      name: scheduled-job
    spec:
      containers:
      - name: my-shell
        image: ubuntu
      restartPolicy: OnFailure
```

In the example above we show the manifest loading a file, just to make it
simple. But you could also read use a HEREDOC, parse a template and insert
values, or anything else you want to do in the method, as long as you return
a valid Kubernetes Job manifest as a `Hash`.

When the job is run, the default command in the Docker instance is replaced with
the command specified in the cron schedule (see below). The command is run on the 
first container in the pod.

### `output`

By default no redirection is done; cron behaves as normal. If you would like you 
can specify an option here to redirect as you would on a shell command. For example,
`"2>&1` to collect STDERR in STDOUT or `>> /var/log/task.log` to append to a log file.

### `job_template`

This is a template that we use to execute your rake, rails runner, or shell command
in the container. The default template executes it in a login shell so that environment
variables (and profile) are loaded. 

You can modify this. The value should be an array with a command and arguments that will
replace both `ENTRYPOINT` and `CMD` in the Docker image. See
[Define a Command and Arguments for a Container](https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/)
for a discussion of how `command` works in Kubernetes.

### kubeclient
The gem will automatically connect to the Kubernetes server in the following cases:
- You are running this in [a standard Kubernetes cluster](https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/#accessing-the-api-from-a-pod)
- You are running on a system with `kubeclient` installed and
  - the default cluster context has credentials
  - the default cluster is GKE and your system has
    [Google application default credentials](https://developers.google.com/identity/protocols/application-default-credentials)
    installed

There are many other ways to connect and you can do so by providing your own
[configured `kubeclient`](https://github.com/abonas/kubeclient#usage):

```ruby
# config/initializers/resque-kubernetes.rb

CronKubernetes.configuration do |config|
  config.kubeclient = Kubeclient::Client.new("http://localhost:8080/apis/batch", "v1beta1")
end
```

Because this uses the `CronJob` resource, make sure to connect to the `/apis/batch` API endpoint and 
API version `v1beta1` in your client.

## Usage

### Create a Schedule
Add a file to your source that defines the scheduled tasks. If you are using Rails, you could 
put this in `config/initializers/cron_kuberentes.rb`. Or, if you want to make it work like the
`whenever` gem you could add these lines to `config/schedule.rb` and then `require` that from your
initializer.

```ruby
CronKubernetes.schedule do
  command "ls -l", schedule: "0 0 1 1 *"
  rake "audit:state", schedule: "0 20 1 * *", name: "audit-state"
  runner "CleanSweeper.run", schedule: "30 3 * * *"
end
```

For all jobs the command will change directories to either `Rails.root` if Rails is installed
or the current working directory. These are evaluated when the scheduled tasks are loaded.

For all jobs you may provide a `name` that will be used with the `identifier` to name the
CronJob. If you do not provide a name `CronKubernetes` will try to figure one out from the job and
pod templates plus a hash of the schedule and command.

#### Shell Commands

A `command` runs any arbitrary shell command on a schedule. The first argument is the command to run.

#### Rake Tasks

A `rake` call runs a `rake` task on the schedule. Rake and Bundler must be installed and on the path 
in the container. The command it executes is `bundle exec rake ...`.

#### Runners

A `runner` runs arbitrary ruby code under Rails. Rails must be installed at `bin/rails` from the
working folder. The command it executes is `bin/rails runner '...'`.

### Update Your Cluster

Once you have configuration and cluster, then you can run the `cron_kubernetes` command
to update your cluster. 

```bash
cron_kubernetes --configuration config/initializers/cron_kubernetes.rb --schedule config/schedule.rb
```

The command will read the provided configuration and current schedule, compare to any 
CronJobs already in your cluster for this project (base on the `identifier`) and then 
add/remove/update the CronJobs to bring match the schedule.

You can provide either `--configuration` or `--schedule`, as long as between the files you have 
loaded both a configuration and a schedule. For example, if they are in the same file, you would
just pass a single value:

```bash
cron_kubernetes --schedule schedule.rb
``` 

If you are running in a Rails application where the initializers are auto-loaded, and your 
schedule is defined in (or in a file required by) your initializer, you could run this within
your Rails environment:

```bash
bin/rails runner cron_kubernetes
``` 

## To Do
- In place of `schedule`, support `every`/`at` syntax:
  ```
  every: :minute, :hour, :day, :month, :year
         3.minutes, 1.hour, 1.day, 1.week, 1.month, 1.year
  at: "[H]H:mm[am|pm]"
  ```

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/keylime-toolbox/cron-kubernetes-ruby.

1. Fork it (`https://github.com/[my-github-username]/cron-kubernetes-ruby/fork`)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Test your changes with `rake`, add new tests if needed
4. Commit your changes (`git commit -am 'Add some feature'`)
6. Push to the branch (`git push origin my-new-feature`)
7. Open a new Pull Request

### Development

After checking out the repo, run `bin/setup` to install dependencies. Then,
run `bin/rake` to run the test suite.

You can run `bin/console` for an interactive prompt that will allow you to
experiment.

Write test for any code that you add. Test all changes by running `bin/rake`.
This does the following, which you can also run separately while working.
1. Run unit tests: `appraisal rake spec`
2. Make sure that your code matches the styles: `rubocop`
3. Verify if any dependent gems have open CVEs (you must update these):
   `rake bundle:audit`

## Release

To release a new version, update the version number in
`lib/cron_kubernetes/version.rb` and the `CHANGELOG.md`, then run
`bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Acknowledgments

We have used the [`whenever` gem](https://github.com/javan/whenever) for years and we love it. 
Much of the ideas for scheduling here were inspired by the great work that @javan and team 
have put into that gem.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
