.PHONY: test validate validate-%

validate: validate-lua

validate-lua:
	luackeck .

test:
	prove -v t
