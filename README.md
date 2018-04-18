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

You can configure global settings for your cron jobs. Add a file to your source as following. 
If you are using Rails, you can add this to something like `config/initializers/cron_kuberentes.rb`.

```ruby
CronKubernetes.configure do |config|
  config.manifest = YAML.read(File.join(Rails.root, "deploy", "kubernetes-cronjob.yml"))
  config.output -> { "2>&1" }
end
```
## Usage

Add a file to your source that defines the scheduled tasks. If you are using Rails, you can add
this to something like `config/initializers/cron_kuberentes.rb`. Or, if you are familiar with the
`whenever` gem you could add these lines to `config/schedule.rb` and then `require` that from your
initializer.

```ruby
CronKubernetes.schedule do
  runner(schedule: "30 3 * * *") { CleanSweeper.run }
  rake "audit:state", schedule: "0 20 1 * *"
end
```
## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. 

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. 

To release a new version, update the version number in `lib/cron_kubernets/version.rb` and the `CHANGELOG.md`, 
and then run `bundle exec rake release`, which will create a git tag for the version, 
push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/keylimetoolbox/cron-kubernetes.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
