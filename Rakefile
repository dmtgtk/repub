# Look in the tasks/setup.rb file for the various options that can be
# configured in this Rakefile. The .rake files in the tasks directory
# are where the options are used.

begin
  require 'bones'
  Bones.setup
rescue LoadError
  begin
    load 'tasks/setup.rb'
  rescue LoadError
    raise RuntimeError, '### please install the "bones" gem ###'
  end
end

ensure_in_path 'lib'
require 'repub'

task :default => 'test:run'

PROJ.name = 'repub'
PROJ.authors = 'Dmitri Goutnik'
PROJ.email = 'dg@invisiblellama.net'
PROJ.url = 'http://github.com/invisiblellama/repub/tree/master'
PROJ.version = Repub::VERSION
PROJ.rubyforge.name = 'repub'
PROJ.exclude = %w[tmp/ \.git/ \.DS_Store .*\.tmproj ^pkg/]

PROJ.spec.opts << '--color'

depend_on 'builder'
depend_on 'hpricot'
depend_on 'chardet'

# EOF
