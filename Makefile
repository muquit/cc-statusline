##
# Makefile for cc-statusline
# docs/main.md is the README source. README.md is generated; do not edit it.
# Requires markdown-toc-go to build the docs.
##
SCRIPT := statusline-command.sh
CLAUDE_DIR := $(HOME)/.claude
MTOC := markdown-toc-go
VERSION := $(shell cat VERSION)

.PHONY: all docs install uninstall check check_github_token clean_exif release help

all: help

# generate README.md from docs/main.md
docs:
	@command -v $(MTOC) >/dev/null || { echo "$(MTOC) not found"; exit 1; }
	$(MTOC) -i docs/main.md -o README.md --glossary docs/glossary.txt -f
	$(MTOC) -i docs/ChangeLog.md \
        -o ./ChangeLog.md --glossary docs/glossary.txt -f -no-credit

# copy the script to ~/.claude (settings.json must be edited by hand, see README)
install:
	mkdir -p $(CLAUDE_DIR)
	cp $(SCRIPT) $(CLAUDE_DIR)/$(SCRIPT)
	chmod +x $(CLAUDE_DIR)/$(SCRIPT)
	@echo "Installed. Now set statusLine in $(CLAUDE_DIR)/settings.json"

uninstall:
	rm -f $(CLAUDE_DIR)/$(SCRIPT)
	rm -rf $(CLAUDE_DIR)/live-sessions

# check if GITHUB_TOKEN is set and valid, fail the build otherwise
check_github_token:
	@if [ -z "$(GITHUB_TOKEN)" ]; then \
        echo "*** ERROR: GITHUB_TOKEN is not set"; \
        exit 1; \
    fi
	@status=$$(curl -s -o /tmp/check_github_token.$$$$.json -w '%{http_code}' \
        -H "Authorization: token $(GITHUB_TOKEN)" https://api.github.com/user); \
    if [ "$$status" != "200" ]; then \
        echo "*** ERROR: GITHUB_TOKEN is not valid (HTTP $$status)"; \
        cat /tmp/check_github_token.$$$$.json; \
        rm -f /tmp/check_github_token.$$$$.json; \
        exit 1; \
    fi; \
    jq '{login, name, type}' < /tmp/check_github_token.$$$$.json; \
    rm -f /tmp/check_github_token.$$$$.json
	@curl -sI -H "Authorization: token $(GITHUB_TOKEN)" \
        https://api.github.com/user | grep -i x-oauth-scopes

clean_exif:
	@echo ">>>> Removing EXIF metadata from images ..."
	exiftool -all= -overwrite_original images/*.png
	rm -f images/*_original

# tag VERSION, push the tag and create the GitHub release with release_notes.md
release: check_github_token clean_exif
	@echo "*** Releasing v$(VERSION) on github ..."
	git tag -a v$(VERSION) -m "v$(VERSION)"
	git push origin v$(VERSION)
	gh release create v$(VERSION) $(SCRIPT) --title "v$(VERSION)" --notes-file release_notes.md

# syntax check the script
check:
	bash -n $(SCRIPT)

help:
	@echo "make docs      - generate README.md from docs/main.md"
	@echo "make install   - copy $(SCRIPT) to $(CLAUDE_DIR)"
	@echo "make uninstall - remove the script and live-sessions folder"
	@echo "make check     - bash -n syntax check"
	@echo "make release   - tag v$(VERSION) and create the GitHub release"
