.PHONY: format lint check

SHELL_FILES := $(shell find scripts setup config -name '*.sh' 2>/dev/null)

format:
	shfmt -w -s $(SHELL_FILES)
	black scripts/
