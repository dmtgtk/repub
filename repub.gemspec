# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{repub}
  s.version = "0.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Dmitri Goutnik"]
  s.date = %q{2009-06-28}
  s.default_executable = %q{repub}
  s.description = %q{}
  s.email = %q{dg@invisiblellama.net}
  s.executables = ["repub"]
  s.extra_rdoc_files = ["History.txt", "README.txt", "bin/repub"]
  s.files = [".gitignore", "History.txt", "README.txt", "Rakefile", "TODO", "bin/repub", "lib/repub.rb", "lib/repub/app.rb", "lib/repub/app/builder.rb", "lib/repub/app/fetcher.rb", "lib/repub/app/logger.rb", "lib/repub/app/options.rb", "lib/repub/app/parser.rb", "lib/repub/app/profile.rb", "lib/repub/app/utility.rb", "lib/repub/epub.rb", "lib/repub/epub/container.rb", "lib/repub/epub/content.rb", "lib/repub/epub/toc.rb", "repub.gemspec", "test/epub/test_container.rb", "test/epub/test_content.rb", "test/epub/test_toc.rb", "test/test_builder.rb", "test/test_fetcher.rb", "test/test_logger.rb", "test/test_parser.rb"]
  s.homepage = %q{http://github.com/invisiblellama/repub/tree/master}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{repub}
  s.rubygems_version = %q{1.3.4}
  s.summary = nil
  s.test_files = ["test/epub/test_container.rb", "test/epub/test_content.rb", "test/epub/test_toc.rb", "test/test_builder.rb", "test/test_fetcher.rb", "test/test_logger.rb", "test/test_parser.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<nokogiri>, [">= 1.3.2"])
      s.add_runtime_dependency(%q<builder>, [">= 2.1.2"])
      s.add_runtime_dependency(%q<rchardet>, [">= 1.2"])
      s.add_runtime_dependency(%q<launchy>, [">= 0.3.3"])
      s.add_development_dependency(%q<bones>, [">= 2.5.1"])
    else
      s.add_dependency(%q<nokogiri>, [">= 1.3.2"])
      s.add_dependency(%q<builder>, [">= 2.1.2"])
      s.add_dependency(%q<rchardet>, [">= 1.2"])
      s.add_dependency(%q<launchy>, [">= 0.3.3"])
      s.add_dependency(%q<bones>, [">= 2.5.1"])
    end
  else
    s.add_dependency(%q<nokogiri>, [">= 1.3.2"])
    s.add_dependency(%q<builder>, [">= 2.1.2"])
    s.add_dependency(%q<rchardet>, [">= 1.2"])
    s.add_dependency(%q<launchy>, [">= 0.3.3"])
    s.add_dependency(%q<bones>, [">= 2.5.1"])
  end
end
