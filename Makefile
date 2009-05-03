# Small makefile to handle very small details of installation...

RUBY = ruby

# --diagram is way too painful.
RDOC_OPTIONS = --exclude setup.rb -m CTioga2::PlotMaker

doc:
# to avoid partial regeneration of the documentation
	rm -rf doc		
	rdoc $(RDOC_OPTIONS)


man:
	version=`rch --print-version`; cd man; ctioga2 --write-man "$$version" ctioga2.1.template > ctioga2.1

config-home:
	$(RUBY) setup.rb config --prefix=$(HOME) --siteruby=$(HOME)/lib/ruby --siterubyver=$(HOME)/lib/ruby

config:
	$(RUBY) setup.rb config

install:
	@ [ -r .config ] || (echo "Run make config or make config-home before running make install" ; false)
	$(RUBY) setup.rb install

# I'm annoyed at having to set the svn:keywords properties on
# every single file around.
propset:
	find lib -name '*.rb' \( \! -name 'utils.rb' \) | \
	xargs svn propset svn:keywords 'Date Revision'

# Get rid of emacs backup files
clean:
	find -name '*~' -print0 | xargs -0  rm


.PHONY: doc man install