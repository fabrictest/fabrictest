.POSIX:
.SUFFIXES:

plan apply: config.tf.json FORCE
	tofu init && tofu $@

config.tf.json: config.nix
	terranix $< >$@~ && mv $@~ $@

clean: FORCE
	rm -fr .terraform* config.tf.json*

FORCE:
