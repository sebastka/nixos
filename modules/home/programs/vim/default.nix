{ config, lib, ... }:

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
      set laststatus=2
      set scrolloff=5
      set wrap
      set linebreak
      set showmatch

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

      " XDG: move all runtime files out of ~/
      set viminfofile=$XDG_DATA_HOME/vim/viminfo
      set directory=$XDG_DATA_HOME/vim/swap//
      set backupdir=$XDG_DATA_HOME/vim/backup//
      set undodir=$XDG_DATA_HOME/vim/undo//
      set undofile
    '';
  };

  home.activation.createVimDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ${config.xdg.dataHome}/vim/{swap,backup,undo}
  '';
}
