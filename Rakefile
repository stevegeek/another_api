# frozen_string_literal: true

require "rake/testtask"

# Each entry is [dir, gemspec filename].
GEMS = [
  ["api_serializer", "api_serializer.gemspec"],
  ["api_query_language", "api_query_language.gemspec"],
  ["api_query_language_active_record", "api_query_language-active_record.gemspec"],
  ["another_api", "another_api.gemspec"]
].freeze

desc "Run tests for all gems"
task :test do
  GEMS.each do |dir, _|
    Dir.chdir(File.join(__dir__, dir)) { sh "bundle exec rake test" }
  end
end

desc "Build all gems into pkg/"
task :build do
  GEMS.each do |dir, gemspec|
    Dir.chdir(File.join(__dir__, dir)) do
      sh "gem build #{gemspec}"
      mkdir_p File.join(__dir__, "pkg")
      Dir["*.gem"].each { |f| mv f, File.join(__dir__, "pkg", File.basename(f)) }
    end
  end
end

desc "Run standardrb across all gems"
task :lint do
  sh "bundle exec standardrb"
end

task default: [:test, :lint]
