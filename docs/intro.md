# Introduction

**cc-statusline** is a bash script to show usage and other info in the
@CLAUDE_CODE_STATUSLINE@ status line. Here is what it looks like on my Mac
in @ITERM2@.

<img src="images/my-cc-status.png" border="1" alt="my-cc-statusline">

It shows how much of the 5-hour and weekly limits you have used, how much
of the context window is used, the model, working directory, git branch
and how many other Claude Code sessions are running. In the screenshot
above, the directory is not a git repo, so only the working directory is
shown.

<img src="images/my-cc-status-git.png" border="1" alt="my-cc-status-git">

In a git repo, the branch is shown after the directory name, here `(main)`.

<img src="images/my-cc-status-git_1.png" border="1" alt="my-cc-status-git_1">

`+1` means one other Claude Code session is running, and `(1 here)` means it
is in the same repo.

I like to see this info at a glance so I don't have to type `/usage` or
`/context`. Hope you will find it useful as well.
