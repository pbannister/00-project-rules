#
#	Makefile for 00-project-rules.
#
#	This repository owns the shared rules that every project pins. The two
#	commands that matter:
#
#		test:     run this repository's suite, including the end-to-end check
#		          that vendors this version into 00-project-skeleton and runs
#		          the shared validator there.
#		release:  gate the version and tag it. A tag is the only thing a
#		          project can pin, so nothing reaches a project without this.
#
#	Vendoring into a project is not a make target here, on purpose: it happens
#	in a task, against one named project, and it is recorded.
#	  sh tools/rules-vendor.sh <project> [--dry-run] [--force]

.PHONY: all test release release-same-day dry-run next manifest

all: test

test:
	sh tools/rules-test.sh

dry-run:
	sh tools/rules-release.sh --dry-run

next:
	@sh tools/rules-release.sh --next

manifest:
	@echo "MANIFEST ($(shell grep -c . MANIFEST) files), version $(shell cat VERSION)"
	@cat MANIFEST

release:
	sh tools/rules-release.sh

# The exception, not the habit: initial build-out and corrections only.
release-same-day:
	sh tools/rules-release.sh --same-day
