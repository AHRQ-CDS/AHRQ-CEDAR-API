# frozen_string_literal: true

require 'rake'
require 'rake/testtask'
require 'rubocop/rake_task'

Rake::TestTask.new do |t|
  t.pattern = 'test/**/*_test.rb'
end

RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = ['--display-cop-names']
end

task default: %i[test rubocop]
