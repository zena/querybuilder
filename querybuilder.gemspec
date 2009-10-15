# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{querybuilder}
  s.version = "0.5.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Gaspard Bucher"]
  s.date = %q{2009-10-15}
  s.description = %q{QueryBuilder is an interpreter for the "pseudo sql" language. This language
can be used for two purposes:

 1. protect your database from illegal SQL by securing queries
 2. ease writing complex relational queries by abstracting table internals}
  s.email = ["gaspard@teti.ch"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.rdoc"]
  s.files = ["History.txt", "Manifest.txt", "README.rdoc", "Rakefile", "lib/query_builder.rb", "lib/querybuilder.rb", "script/console", "script/destroy", "script/generate", "test/mock/custom_queries", "test/mock/custom_queries/test.yml", "test/mock/dummy_query.rb", "test/mock/user_query.rb", "test/QueryBuilder/basic.yml", "test/QueryBuilder/errors.yml", "test/QueryBuilder/filters.yml", "test/QueryBuilder/joins.yml", "test/QueryBuilder/mixed.yml", "test/test_helper.rb", "test/test_QueryBuilder.rb"]
  s.homepage = %q{http://github.com/zena/querybuilder/tree/master}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{querybuilder}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{QueryBuilder is an interpreter for the "pseudo sql" language}
  s.test_files = ["test/test_helper.rb", "test/test_QueryBuilder.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<yamltest>, [">= 0.5.0"])
      s.add_development_dependency(%q<newgem>, [">= 1.3.0"])
      s.add_development_dependency(%q<hoe>, [">= 1.8.0"])
    else
      s.add_dependency(%q<yamltest>, [">= 0.5.0"])
      s.add_dependency(%q<newgem>, [">= 1.3.0"])
      s.add_dependency(%q<hoe>, [">= 1.8.0"])
    end
  else
    s.add_dependency(%q<yamltest>, [">= 0.5.0"])
    s.add_dependency(%q<newgem>, [">= 1.3.0"])
    s.add_dependency(%q<hoe>, [">= 1.8.0"])
  end
end
