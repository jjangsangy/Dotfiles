VPATH := bash:git:mpv:vim
RM := rm -rf

destdir := ~

BASH_OBJECTS := aliases bash_completion bash_env bash_functions \
                bash_logout curlrc dircolors dircolors_dark dircolors_light \
                fignore inputrc profile prompt
VIM_OBJECTS  := vimrc vimrc.plug vimrc.plug.local
GIT_OBJECTS  := git_log.sh gitconfig gitconfig.local gitignore

BASH_TARGETS := $(BASH_OBJECTS:%=$(destdir)/.%)
VIM_TARGETS  := $(VIM_OBJECTS:%=$(destdir)/.%)
GIT_TARGETS  := $(GIT_OBJECTS:%=$(destdir)/.%)

OBJECTS := $(BASH_OBJECTS) $(VIM_OBJECTS) $(GIT_OBJECTS)
TARGETS := $(BASH_TARGETS) $(VIM_TARGETS) $(GIT_TARGETS)

all: bash vim git

bash: $(BASH_OBJECTS)
$(BASH_OBJECTS): $(BASH_TARGETS)
$(BASH_TARGETS):
	ln -s $(realpath bash/$(patsubst .%,%,$(@F))) $@

vim: $(VIM_TARGETS)
$(VIM_OBJECTS): $(VIM_TARGETS)
$(VIM_TARGETS):
	ln -s $(realpath vim/$(patsubst .%,%,$(@F))) $@

git: $(GIT_TARGETS)
$(GIT_OBJECTS): $(GIT_TARGETS)
$(GIT_TARGETS):
	ln -s $(realpath git/$(patsubst .%,%,$(@F))) $@


clean:
	$(RM) $(TARGETS)


help:
	@echo "USAGE: make [all|bash|vim|git|clean|help]"
	@echo
	@echo "AUTHOR:	Sang Han"
	@echo
	@echo "DESCRIPTION:"
	@echo "	Program for automating users preferred login shell enviornment."
	@echo "	Symbolically links the startup files located within dotfiles"
	@echo "	repository and links them to to users \$$HOME"
	@echo
	@echo "HOME DIRECTORY ${HOME}"
	@echo
	@echo "OPTIONS:"
	@echo "	all [default]"
	@echo "		Link everything and overwrite any files that exist"
	@echo "	bash"
	@echo "		Link bash specific dotfiles"
	@echo "	vim"
	@echo "		Link configuration files for vim"
	@echo "	git"
	@echo "		Link files to customize git"
	@echo "	clean"
	@echo "		Clean files from ${HOME}"
	@echo "	help"
	@echo "		Outputs this message and quits"


.PHONY: all bash vim git clean help
