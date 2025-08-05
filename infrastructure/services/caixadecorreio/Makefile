.POSIX:
.SUFFIXES:

plan apply: init FORCE
	tofu $@

init: config.tf.json FORCE
	tofu $@

config.tf.json: config.nix
	terranix $< >$@~
	mv $@~ $@

clean: FORCE
	rm -rf .terraform* config.tf.json*

FORCE:
