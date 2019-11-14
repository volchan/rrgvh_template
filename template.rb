require 'fileutils'
require 'shellwords'
require 'tmpdir'

def delete_app
  run "rm -rf ../#{app_name}"
end

def assert_minimum_rails_version
  minimum_rails_verion = '>= 6.0.0'.freeze
  requirement = Gem::Requirement.new(minimum_rails_verion)
  rails_version = Gem::Version.new(Rails::VERSION::STRING)
  return if requirement.satisfied_by?(rails_version)

  puts "/!\\ /!\\ Please install rails #{minimum_rails_verion} /!\\ /!\\"
  delete_app
  exit 1
end

def assert_pg
  return if options['database'] == 'postgresql'

  puts 'Please add "-d postgresql" as an option!'
  delete_app
  exit 1
end

def add_template_repository_to_source_path
  if __FILE__ =~ %r{\Ahttps?://}
    source_paths.unshift(tempdir = Dir.mktmpdir('rails-template-'))
    at_exit { FileUtils.remove_entry(tempdir) }
    git clone: [
      '--quiet',
      'https://github.com/volchan/rrgvh_template',
      tempdir
    ].map(&:shellescape).join(' ')

    if (branch = __FILE__[%r{rrgvh_template/(.+)/template.rb}, 1])
      Dir.chdir(tempdir) { git checkout: branch }
    end
  else
    source_paths.unshift(File.dirname(__FILE__))
  end
end

def apply_template!
  assert_minimum_rails_version
  assert_pg
  add_template_repository_to_source_path
end

run 'pgrep spring | xargs kill -9'
apply_template!