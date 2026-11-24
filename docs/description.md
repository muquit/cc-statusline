# Description

<img src="images/my-cc-status.png" border="1" alt="my-cc-statusline">

In the screenshot above, I have used 1% of the 5-hour limit and 11% of the
weekly limit. They reset in 4h 51m and 1d 23h, respectively. The dot is green
and the context window is 9% used. I am using Sonnet 5.5 in `cc-statusline`.
The branch is hidden because I haven't made this directory a git repo yet.
I only have one Claude Code session running, so `+N` is hidden too.

| Part | Meaning |
|------|---------|
| `●` | Color based on the higher of the session and week percentages (green below 50%, yellow at 50–79%, red at 80% or above) |
| `Session: 1% (4h 51m)` | 5-hour limit used, and time until it resets (`--` if not reported yet) |
| `Week: 11% (1d 23h)` | 7-day limit used and time until it resets (hidden until reported) |
| `Context: 9%` | context window used in this session (0% until the first response, and right after `/clear` or `/compact`) |
| `[Sonnet 5.5]` | current model |
| `cc-statusline` | working directory (last component by default) |
| `(main)` | git branch or short commit hash if HEAD is detached (hidden outside a repo) |
| `+2` | Number of other Claude Code sessions running on this machine (hidden when zero) |
| `(1 here)` | Number of those sessions in the same git repo or directory, shown in yellow (hidden when zero) |

`Session` and `Week` are the same as **Current session** and **This week**
under **Settings > Usage** in the Claude desktop app. These limits are for
your whole account. All your Claude Code terminals and the desktop app
share them.

**NOTE** Claude Code sends rate limit data only for claude.ai Pro and Max
subscribers, and only after the first response in a session. You will see
`Session: 0% (--)` when you first start a session.

The script reads JSON from Claude Code on stdin and runs `git` and `ps`
locally. It makes no network calls.

To count other sessions, the script writes one small file per session in
`~/.claude/live-sessions/`. Each file contains the Claude Code process ID,
the repo root (or directory) and the working directory. The script removes
the files for sessions that have exited. This is the only directory it writes to.
