# -*- encoding: utf-8 -*-
require File.dirname(__FILE__) + "/lib/ssync/version"

Gem::Specification.new do |s|
  s.name              = "ssync"
  s.version           = Ssync::VERSION
  s.date              = Date.today.to_s
  s.authors           = ["Fred Wu", "Ryan Allen"]
  s.email             = ["fred@envato.com", "ryan@envato.com"]
  s.summary           = %q{Ssync, an optimised S3 sync tool using the power of Unix!}
  s.description       = %q{Ssync, an optimised S3 sync tool using the power of Unix!}
  s.homepage          = %q{http://github.com/fredwu/ssync}
  s.extra_rdoc_files  = ["README.md"]
  s.rdoc_options      = ["--charset=UTF-8"]
  s.require_paths     = ["lib"]
  s.rubyforge_project = s.name

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency(%q<aws-s3>, ["~> 0.6.2"])
  s.add_runtime_dependency(%q<thor>, ["~> 0.14.4"])
end
