require 'rubygems'
require 'rake'

begin
  gem 'jeweler', '~> 1.4'
  require 'jeweler'

  Jeweler::Tasks.new do |gem|
    gem.name        = 'dm-ar-finders'
    gem.summary     = 'DataMapper plugin providing ActiveRecord-style finders'
    gem.description = gem.summary
    gem.email       = 'john [a] wishVPS [d] com'
    gem.homepage    = 'http://github.com/datamapper/dm-more/tree/master/%s' % gem.name
    gem.authors     = [ 'John W Higgins' ]

    gem.rubyforge_project = 'datamapper'

    gem.add_dependency 'dm-core', '~> 0.10.3'

    gem.add_development_dependency 'rspec', '~> 1.2.9'
    gem.add_development_dependency 'yard',  '~> 0.4.0'
  end

  Jeweler::GemcutterTasks.new

  FileList['tasks/**/*.rake'].each { |task| import task }
rescue LoadError
  puts 'Jeweler (or a dependency) not available. Install it with: gem install jeweler'
end
