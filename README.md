Sang Han's Dotfiles
====================

Repository for my Dotfiles as well as a collection of
useful programs I've written or found
over time.

This repository is currently organized based on application

bash
----
Programs and configurations for enviornments using the Bourne Again
shell. Most files are POSIX compliant and should operate correctly
in most cases, albeit some exceptions occur between compatability
between BSD machines. Some of those exceptions below.

### MacOSX

* MacOSX enviornments not having GNU Coreutils will need to install it
  with homebrew.

``` bash
    $ brew install coreutils
```

* Homebrew doesn't cloud BSD $PATH namespace by name mangling
  binaries prepended with `g`
* Files and directory highlighting requires coreutils `ls` and `dircolors`.
  You can either rename binaries or create a new symbolic link like so

``` bash
    # Symbolically links `gls` to `ls`

    $ ln -s "$(brew --prefix)/bin/gls" "$(brew --prefix)/bin/ls"
    $ ln -s "$(brew --prefix)/bin/gdircolors" "$(brew --prefix)/bin/dircolors"
```

### Debian or Ubuntu

* Debian based machines default to Dash and thus source .bashrc
  .bash_profile for login shells and not .profile

link_files.sh
-------------

* Will automatically create a symbolic link between Dotfiles
  into users home directory.
* Script will link all files specified by a configuration file.
  Defaults to using `link.conf` as default configuration file.
* Specify your own config file using [-f file] flag

``` bash
    # Use config file for vim files

    $ ./link_files.sh -f vim/vim.conf
```

* Use the [-t] flag at any time to run unit tests and print out
  variable scope color coded. Very useful in debugging scenarios.

``` bash
    # Run Unit tests.
    # Existing files are blue and non-existing files are red

    $ ./link_files.sh -t

           $TEST = 1
        $VERBOSE = 0
       $PROGNAME = link_files.sh
        $PROGDIR = /Users/jjangsangy/Dotfiles
    $CONFIG_FILE = link.conf

    $LINK_SOURCE      file exists at /Users/jjangsangy/Dotfiles/aliases
    $LINK_DEST        file exists at /Users/jjangsangy/.aliases

    $LINK_SOURCE      file exists at /Users/jjangsangy/Dotfiles/path
    $LINK_DEST        file exists at /Users/jjangsangy/.path

    $LINK_SOURCE      file exists at /Users/jjangsangy/Dotfiles/bash/profile
    $LINK_DEST        file exists at /Users/jjangsangy/.profile

    $LINK_SOURCE      file exists at /Users/jjangsangy/Dotfiles/bash/jump.sh
    $LINK_DEST        file exists at /Users/jjangsangy/.jump.sh

    $LINK_SOURCE      file exists at /Users/jjangsangy/Dotfiles/bash/inputrc
    $LINK_DEST        file doesnt exist at /Users/jjangsangy/.inputrc

    $LINK_SOURCE      file exists at /Users/jjangsangy/Dotfiles/bash/dircolors
    $LINK_DEST        file doesnt exit at /Users/jjangsangy/.dircolors

    $LINK_SOURCE      file exists at /Users/jjangsangy/Dotfiles/bash/dircolors_light
    $LINK_DEST        file exists at /Users/jjangsangy/.dircolors_light

    $LINK_SOURCE      file exists at /Users/jjangsangy/Dotfiles/bash/dircolors_dark
    $LINK_DEST        file exists at /Users/jjangsangy/.dircolors_dark
```

* Or run with [-v] flag for verbose mode

``` bash
    $ ./link_files.sh -v -f vim/vim.conf

           $TEST = 0
        $VERBOSE = 1
       $PROGNAME = link_files.sh
        $PROGDIR = /Users/jjangsangy/Dotfiles
    $CONFIG_FILE = vim/vim.conf

        $LINK_SOURCE      file exists at /Users/jjangsangy/Dotfiles/aliases
        $LINK_DEST        file exists at /Users/jjangsangy/.aliases

File /Users/jjangsangy/.aliases already exists, would you like to delete it?    [Yy]/[Nn]:
        $LINK_SOURCE      file exists at /Users/jjangsangy/Dotfiles/path
        $LINK_DEST        file exists at /Users/jjangsangy/.path

File /Users/jjangsangy/.path already exists, would you like to delete it?       [Yy]/[Nn]:
        $LINK_SOURCE      file exists at /Users/jjangsangy/Dotfiles/bash/profile
        $LINK_DEST        file exists at /Users/jjangsangy/.profile

File /Users/jjangsangy/.profile already exists, would you like to delete it?    [Yy]/[Nn]:
        $LINK_SOURCE      file exists at /Users/jjangsangy/Dotfiles/bash/jump.sh
        $LINK_DEST        file exists at /Users/jjangsangy/.jump.sh

File /Users/jjangsangy/.jump.sh already exists, would you like to delete it?    [Yy]/[Nn]:
        $LINK_SOURCE      file exists at /Users/jjangsangy/Dotfiles/bash/inputrc
        $LINK_DEST        file exists at /Users/jjangsangy/.inputrc

File /Users/jjangsangy/.inputrc already exists, would you like to delete it?    [Yy]/[Nn]:
        $LINK_SOURCE      file exists at /Users/jjangsangy/Dotfiles/bash/dircolors
        $LINK_DEST        file exists at /Users/jjangsangy/.dircolors

File /Users/jjangsangy/.dircolors already exists, would you like to delete it   [Yy]/[Nn]:
        $LINK_SOURCE      file exists at /Users/jjangsangy/Dotfiles/bash/dircolors_light
        $LINK_DEST        file exists at /Users/jjangsangy/.dircolors_light

```
