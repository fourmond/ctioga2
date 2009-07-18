# -*- mode: ruby; -*-

spec = Gem::Specification.new do |s|
  s.files = Dir["lib/**/*"]
  s.files += ["COPYING", "Changelog", "setup.rb" ]
  s.files += Dir["bin/*"]
  s.bindir = 'bin'
  s.executables =  ['ctioga2']
  s.name = 'ctioga2'
  s.version = '0.0'
  s.summary = 'CTioga2 - command-line interface for the Tioga plotting library'
  s.homepage = 'http://ctioga2.rubyforge.org'
  s.add_dependency 'tioga', '>= 1.11'
  s.author = "Vincent Fourmond <vincent.fourmond@9online.fr>"
  s.email = "vincent.fourmond@9online.fr"
  s.rubyforge_project = "ctioga2"
end
