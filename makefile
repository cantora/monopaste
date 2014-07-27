
.PHONY: all
all: gem

.PHONY: gem
gem: monopaste.gemspec
	gem build $<

.PHONY: install
install: gem
	gem install *.gem

.PHONY: clean
clean:
	rm -f *.gem
