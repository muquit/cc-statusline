# Install

To install the script, run these commands.

```bash
git clone https://github.com/muquit/cc-statusline.git
cd cc-statusline
mkdir -p ~/.claude
cp statusline-command.sh ~/.claude/
chmod +x ~/.claude/statusline-command.sh
```

Add the following to `~/.claude/settings.json`.

```json
"statusLine": {
  "type": "command",
  "command": "~/.claude/statusline-command.sh"
}
```

Please restart Claude Code after making the change. A running session may
need a restart to pick it up.

Here is what my `~/.claude/settings.json` looks like.

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline-command.sh"
  },
  "enabledPlugins": {
    "gopls-lsp@claude-plugins-official": true,
    "swift-lsp@claude-plugins-official": true
  },
  "theme": "dark",
  "model": "sonnet"
}
```
