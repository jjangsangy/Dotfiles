VPATH := bash:git:mpv:vim
RM := @rm -fv --
LINK := @ln -vns

destdir := ~

BASH_OBJECTS := bash_aliases bash_completion bash_completion.d \
                bash_functions bash_env bash_sources \
                dircolors dircolors_dark dircolors_light \
                fignore inputrc profile pip.conf prompt
VIM_OBJECTS  := vimrc vimrc.plug vimrc.plug.local tmux.conf
GIT_OBJECTS  := git_log.sh gitconfig gitconfig.local gitignore
FISH_FUNCS   := kindle_comic_converter.fish pack_manga.fish rename_kepub_epub.fish \
                rips_capitalize.fish zip_manga.fish zip_manga_dirs.fish

BASH_TARGETS := $(BASH_OBJECTS:%=$(destdir)/.%)
VIM_TARGETS  := $(VIM_OBJECTS:%=$(destdir)/.%)
GIT_TARGETS  := $(GIT_OBJECTS:%=$(destdir)/.%)
FISH_FUNCS_TARGETS := $(FISH_FUNCS:%=$(destdir)/.config/fish/functions/%)

OBJECTS := $(BASH_OBJECTS) $(VIM_OBJECTS) $(GIT_OBJECTS) $(FISH_FUNCS)
TARGETS := $(BASH_TARGETS) $(VIM_TARGETS) $(GIT_TARGETS) $(FISH_TARGETS)

all: bash vim git astronvim fish_funcs
clean: clean_git clean_bash clean_vim clean_fish_funcs clean_astronvim

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

fish_funcs: $(FISH_FUNCS_TARGETS)
$(FISH_FUNCS): $(FISH_FUNCS_TARGETS)
$(FISH_FUNCS_TARGETS):
	$(LINK) $(realpath fish/functions/$(patsubst .%,%,$(@F))) $@

bin: $(destdir)/bin
$(destdir)/bin:
	$(LINK) $(realpath bin) $(destdir)

astronvim: $(destdir)/.config/nvim/lua/user
$(destdir)/.config/nvim/lua/user:
	$(LINK) $(realpath astro_nvim) $(destdir)/.config/nvim/lua/user


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

clean_fish_funcs:
	@echo
	@echo Fish Functions
	@echo ==========================
	$(RM) $(addprefix $(destdir)/.config/fish/functions/,$(notdir $(FISH_FUNCS_TARGETS)))

clean_bin:
	@echo
	@echo Bin Directory
	@echo ==========================
	$(RM) $(destdir)/bin

clean_astrovim:
	@echo
	@echo Astro Vim Directory
	@echo ==========================
	$(RM) $(destdir)/.config/nvim/lua/user



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


.PHONY: all bash vim git clean clean_bash clean_vim clean_git help clean_fish_funcs
