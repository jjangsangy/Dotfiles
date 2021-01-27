VPATH := bash:git:mpv:vim
RM := @rm -fv --
LINK := @ln -vns

destdir := ~

BASH_OBJECTS := bash_aliases bash_completion bash_completion.d \
                bash_functions bash_logout bash_env bash_sources \
                dircolors dircolors_dark dircolors_light \
                fignore inputrc profile pip.conf prompt
VIM_OBJECTS  := vimrc vimrc.plug vimrc.plug.local tmux.conf
GIT_OBJECTS  := git_log.sh gitconfig gitconfig.local gitignore

BASH_TARGETS := $(BASH_OBJECTS:%=$(destdir)/.%)
VIM_TARGETS  := $(VIM_OBJECTS:%=$(destdir)/.%)
GIT_TARGETS  := $(GIT_OBJECTS:%=$(destdir)/.%)

OBJECTS := $(BASH_OBJECTS) $(VIM_OBJECTS) $(GIT_OBJECTS)
TARGETS := $(BASH_TARGETS) $(VIM_TARGETS) $(GIT_TARGETS)

all: bash vim git
clean: clean_git clean_bash clean_vim

bash: $(BASH_OBJECTS)
$(BASH_OBJECTS): $(BASH_TARGETS)
$(BASH_TARGETS):
	$(LINK) $(realpath bash/$(patsubst .%,%,$(@F))) $@

vim: $(VIM_TARGETS)
$(VIM_OBJECTS): $(VIM_TARGETS)
$(VIM_TARGETS):
	$(LINK) $(realpath vim/$(patsubst .%,%,$(@F))) $@

git: $(GIT_TARGETS)
$(GIT_OBJECTS): $(GIT_TARGETS)
$(GIT_TARGETS):
	$(LINK) $(realpath git/$(patsubst .%,%,$(@F))) $@


clean_bash:
	@echo
	@echo Bash Files
	@echo ==========================
	$(RM) $(addprefix $(destdir)/,$(notdir $(BASH_TARGETS)))

clean_vim:
	@echo
	@echo Vim Files
	@echo ==========================
	$(RM) $(addprefix $(destdir)/,$(notdir $(VIM_TARGETS)))

clean_git:
	@echo
	@echo Git Files
	@echo ==========================
	$(RM) $(addprefix $(destdir)/,$(notdir $(GIT_TARGETS)))


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


.PHONY: all bash vim git clean clean_bash clean_vim clean_git help
