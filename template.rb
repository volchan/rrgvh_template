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

def assert_api
  return if options['api']

  puts 'Please add "--api" flag!'
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

def clean_gemfile
  template 'Gemfile.tt', force: true
end

def devise_setup
  run 'rails g devise:install'
  run 'rails g devise model User'
  run 'rails g migration AddJtiTokenToUsers jti'
end

def graphql_setup
  run 'rails g graphql:install'
end

def gems_setup
  devise_setup
  graphql_setup
end

def copy_root_config_files
  copy_file '.rubocop.yml'
  copy_file 'Procfile'
  copy_file 'Procfile.dev'
  copy_file 'package.json'
end

def apply_template!
  assert_minimum_rails_version
  assert_pg
  assert_api
  add_template_repository_to_source_path
  clean_gemfile
  after_bundle do
    gems_setup
    copy_root_config_files
  end
end

run 'pgrep spring | xargs kill -9'
apply_template!
