# -*- mode: ruby; -*-

spec = Gem::Specification.new do |s|
  s.files = Dir["lib/**/*"]
  s.files += ["COPYING", "Changelog", "setup.rb" ]
  s.files += Dir["bin/*"]
  s.bindir = 'bin'
  s.executables =  ['ctioga2']
  s.name = 'ctioga2'
  s.version = '0.10'
  s.summary = 'ctioga2 - the polymorphic plotting program'
  s.description = <<EOF
ctioga2 is a command-driven plotting program that produces
high quality PDF files. It can be used both from the command-line
and using command files (at the same time).

It is based on Tioga (http://tioga.rubyforge.org).
EOF
  s.homepage = 'http://ctioga2.sourceforge.net'
  s.add_dependency 'tioga', '>= 1.18'
  s.author = "Vincent Fourmond <vincent.fourmond@9online.fr>"
  s.email = "vincent.fourmond@9online.fr"
end
