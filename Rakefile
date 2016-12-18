#!/usr/bin/env rake

require 'bundler'
require 'rake'
require 'yaml'
require 'rspec/core/rake_task'

Bundler::GemHelper.install_tasks
RSpec::Core::RakeTask.new('spec')

namespace :repo do
  desc "push files generated with cirneco to remote"
  task :push do

    # Configure git if this is run in Travis CI
    if ENV["TRAVIS"]
      sh "git config --global user.name '#{ENV['GIT_NAME']}'"
      sh "git config --global user.email '#{ENV['GIT_EMAIL']}'"
      sh "git config --global push.default simple"
    end

    # Commit and push to github
    sh "git add --all ."
    sh "git commit -m 'Committing changed files.'"
    sh "git push https://${GH_TOKEN}@github.com/datacite/cirneco.rb master --quiet"
    puts "Pushed changed files to repo"
  end
end

# default task is running rspec tests
task :default => :spec
