# frozen_string_literal: true

desc 'Runs the continuous integration scripts'
task ci: %i[lint security spec]

$stdout.sync = false
