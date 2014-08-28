Dotfiles
====================

Personal configurations, programming tools and and things I use on a day
to day basis.

Directory structure is split mostly into these categories

./root
-------
* Aliases and path configurations and not OS specific.
* General automated build and linker scripts.

### `link_files.sh`

* Will automatically create a symbolic link between Dotfiles
  into users home directory.
* Script will link all files specified by a configuration file.
  Defaults to using `link.conf` as default configuration file.
* Specify your own config file using [-f file] flag

``` bash

    # Use config file for vim files

    $ ./link_files.sh -f vim/vim.conf

```

* Use the `[-t]` flag at any time to run unit tests and print out
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

    ....

```

* Or run with `[-v]` flag for verbose mode

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

```




Vim
------
* Works on 7.4, 7.3 Terminal and GUI vim
* Configurations, bundles and setup scripts.
* [Vundle](https://github.com/gmarik/Vundle.vim.git) or [Plug](https://github.com/junegunn/vim-plug.git) for managing plugins. Plug is fast but requires `Vim +Ruby`.
* [YouCompleteMe](https://github.com/Valloric/YouCompleteMe) autocompletion library.

First install `vundle` or run the install `install_vundle.sh`.

Link the `vimrc` and `vimrc.bundle` files to your home, or use the `link_files.sh` tool using `vim.conf` file.

``` bash
    # Will symlink all the vimrc and bundle
    $ ./link_files.sh -f vim/vim.conf
```

Run `BundleInstal` for Vundle or `PlugInstall` to install vim packages.

> You will need to have CMake and the ability to compile C++ to successfully install the compiled components
> of the `YouCompleteMe` package. There have also been issues when using different versions of Python
> that do reference the System Python. 


bin
----
* Executible scripts and programs


bash
----
Programs and configurations for enviornments using the Bourne Again
shell. Most files are POSIX compliant and should operate correctly
in most cases, albeit some exceptions occur between compatability
between BSD machines. Some of those exceptions below.

## OSX

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

* Debian based machines default to Dash and thus source `.bashrc`
  .bash_profile for login shells and not `.profile`

