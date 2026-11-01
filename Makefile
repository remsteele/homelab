.PHONY: check validate docs

check: docs validate

validate:
	ruby tools/validate.rb

docs:
	ruby tools/generate_docs.rb

