##
# Makefile for cc-statusline
# docs/main.md is the README source. README.md is generated; do not edit it.
# Requires markdown-toc-go to build the docs.
##
SCRIPT := statusline-command.sh
CLAUDE_DIR := $(HOME)/.claude
MTOC := markdown-toc-go

.PHONY: all docs install uninstall check help

all: help

# generate README.md from docs/main.md
docs:
	@command -v $(MTOC) >/dev/null || { echo "$(MTOC) not found"; exit 1; }
	$(MTOC) -i docs/main.md -o README.md --glossary docs/glossary.txt -f

# copy the script to ~/.claude (settings.json must be edited by hand, see README)
install:
	mkdir -p $(CLAUDE_DIR)
	cp $(SCRIPT) $(CLAUDE_DIR)/$(SCRIPT)
	chmod +x $(CLAUDE_DIR)/$(SCRIPT)
	@echo "Installed. Now set statusLine in $(CLAUDE_DIR)/settings.json"

uninstall:
	rm -f $(CLAUDE_DIR)/$(SCRIPT)
	rm -rf $(CLAUDE_DIR)/live-sessions

# syntax check the script
check:
	bash -n $(SCRIPT)

help:
	@echo "make docs      - generate README.md from docs/main.md"
	@echo "make install   - copy $(SCRIPT) to $(CLAUDE_DIR)"
	@echo "make uninstall - remove the script and live-sessions folder"
	@echo "make check     - bash -n syntax check"
