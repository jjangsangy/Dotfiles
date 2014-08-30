Dotfiles
==========
Config my stuff

Installation
============

## From Github

You can clone the repository wherever you want. I usually keep it in my `$HOME/Dotfiles`

```bash
    # One line install
    # Installer will warn you if it might overwrite stuff already in your home directory
    $ git clone https://github.com/jjangsangy/Dotfiles.git $HOME/Dotfiles && cd $HOME/Dotfiles/ && ./link_files.sh
```

## `link_files.sh`

* Will auto symlink default files from into your home directory prepended with a `dot`.

* Run `-h` flag to usage info

```bash
usage: link_files.sh [-h help] [-t test] [-f file]

    AUTHOR:      Sang Han
    CREATED:     01/09/2014
    REVISION:    1.4
    ...
    ...
```

* Specify your own config file using `[-f file]` flag
* Defaults to using `link.conf` as default configuration file.

``` bash
    $ ./link_files.sh -f vim/vim.conf
```

Directory
==================
* Aliases and path configurations and not OS specific.
* General automated build and linker scripts.

`./vim`
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


`./bin`
----
* Executible scripts and programs



`./bash`
--------
Programs and configurations for enviornments using the Bourne Again
shell. Most files are POSIX compliant and should operate correctly
in most cases, albeit some exceptions occur between compatability
between BSD machines. Some of those exceptions below.

`./python`
-----------
* Anacondas `.condarc` configuration files
* `ipython notebook` configs and custom `css/js`

`./osx`
--------
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


### NOTE: Debian/Ubuntu
> Ubuntu and Debian have different `.rc` naming conventions than OS X.
> 
> Use `.bash_profile` or `.bashrc` for `login shells` instead of `.profile`

