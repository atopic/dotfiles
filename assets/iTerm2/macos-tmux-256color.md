# Installing tmux-256color for macOS

From https://gist.github.com/joshuarli/247018f8617e6715e1e0b5fd2d39bb6c

macOS has ncurses version 5.7 which doesn't ship the terminfo description for tmux.


Firstly, we need to install latest version of ncurses by using `brew`.

```
brew install ncurses
```

After that, we're going to use `infocmp` that prints a terminfo description.

```
/usr/local/opt/ncurses/bin/infocmp tmux-256color > tmux-256color.info
```

Next, we need to compile the description to our system database and set `default-terminal` into `~/.tmux.conf`.

```
sudo tic -xe tmux-256color tmux-256color.info
```

Finally, add the following to tmux.conf:

```
set-option -g default-terminal "tmux-256color"
set -ga terminal-overrides ",*256col*:Tc"
```
