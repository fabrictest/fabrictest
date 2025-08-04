.POSIX:
.SUFFIXES:

plan apply: config.tf.json FORCE
	tofu init && tofu $@

config.tf.json: config.nix FORCE
	terranix --show-trace $< >$@~ && mv $@~ $@

clean: FORCE
	rm -fr .terraform* config.tf.json*

FORCE:
