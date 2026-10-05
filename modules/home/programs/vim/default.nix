{ config, lib, ... }:

# Minimal Vim: the full editor setup is Neovim's (modules/home/programs/neovim)
{
  programs.vim = {
    enable = true;
    extraConfig = ''
      set nocompatible
      filetype plugin indent on
      syntax enable

      " Display
      set number
      set relativenumber
      set ruler
      set showcmd
      set scrolloff=5
      set showmatch

      " Long lines extend off-screen (scrolled one column at a time). `:set wrap` wraps them at word boundaries.
      set nowrap
      set sidescroll=1
      set sidescrolloff=5
      set linebreak

      set laststatus=2

      " Encoding
      set encoding=utf-8

      " Indentation
      set autoindent
      set smartindent
      set tabstop=2
      set shiftwidth=2
      set expandtab

      " Search
      set hlsearch
      set incsearch
      set ignorecase
      set smartcase

      " Completion
      set wildmenu
      set wildmode=longest:full,full

      " Misc
      set backspace=indent,eol,start
      set hidden

      " XDG state directory (as Neovim): history, swap, backup and undo files out of ~/.
      " Paths written by Nix: $XDG_STATE_HOME may be unset (sudo vim...).
      set viminfofile=${config.xdg.stateHome}/vim/viminfo
      set directory=${config.xdg.stateHome}/vim/swap//
      set backupdir=${config.xdg.stateHome}/vim/backup//
      set undodir=${config.xdg.stateHome}/vim/undo//
      set undofile
    '';
  };

  home.activation.createVimDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ${config.xdg.stateHome}/vim/{swap,backup,undo}
  '';
}
