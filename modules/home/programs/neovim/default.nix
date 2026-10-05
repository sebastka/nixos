{ pkgs, ... }:

# Neovim: the full editor setup (Vim stays minimal, see modules/home/programs/vim). EDITOR: modules/nixos/common.
# History (shada), swap and undo files: ~/.local/state/nvim, Neovim's default.
{
  programs.neovim = {
    enable = true;
    # No Python, Ruby or Node.js plugin hosts: no plugin here needs them
    withPython3 = false;
    withRuby = false;
    withNodeJs = false;

    plugins = with pkgs.vimPlugins; [
      # VS Code's Dark+ theme, with Tree-sitter highlight groups (closer to VS Code than Vim syntax files)
      vscode-nvim
      # Tree-sitter grammars (Neovim bundles c, lua, markdown, query, vim and vimdoc)
      (nvim-treesitter.withPlugins (
        p: with p; [
          bash
          css
          diff
          dockerfile
          git_config
          git_rebase
          gitcommit
          go
          hcl
          html
          ini
          javascript
          json
          make
          nix
          php
          python
          rust
          sql
          terraform
          toml
          tsx
          typescript
          xml
          yaml
        ]
      ))
    ];

    initLua = ''
      -- Display
      vim.o.number = true
      vim.o.relativenumber = true
      vim.o.scrolloff = 5
      vim.o.showmatch = true

      -- Long lines extend off-screen (scrolled one column at a time). `:set wrap` wraps them at word boundaries.
      vim.o.wrap = false
      vim.o.sidescroll = 1
      vim.o.sidescrolloff = 5
      vim.o.linebreak = true

      -- Indentation
      vim.o.smartindent = true
      vim.o.tabstop = 2
      vim.o.shiftwidth = 2
      vim.o.expandtab = true

      -- Search
      vim.o.ignorecase = true
      vim.o.smartcase = true

      -- Completion
      vim.o.wildmode = "longest:full,full"

      -- Undo history kept across sessions
      vim.o.undofile = true

      -- System clipboard on demand only (yanks and deletes stay in Vim's registers): <leader>y, <leader>p
      vim.keymap.set({ "n", "x" }, "<leader>y", '"+y', { desc = "Yank to the system clipboard" })
      vim.keymap.set({ "n", "x" }, "<leader>p", '"+p', { desc = "Paste from the system clipboard" })

      -- Status line: full path, modified, file type, read-only | character code, row, column, percentage
      vim.o.statusline = " %F %M %Y %R%= ascii: %b hex: 0x%B row: %l col: %c percent: %p%% "

      -- Cursor line in the active window only
      vim.o.cursorline = true
      local cursorline = vim.api.nvim_create_augroup("cursorline_active_window", {})
      vim.api.nvim_create_autocmd("WinEnter", { group = cursorline, command = "setlocal cursorline" })
      vim.api.nvim_create_autocmd("WinLeave", { group = cursorline, command = "setlocal nocursorline" })

      -- Trailing whitespace in blue, in file buffers (not terminals, help...), but not while typing at the end of a
      -- line. Defined again after a :colorscheme, which clears highlight groups.
      local whitespace = vim.api.nvim_create_augroup("trailing_whitespace", {})
      local function highlight_whitespace()
        vim.api.nvim_set_hl(0, "ExtraWhitespace", { bg = "blue", ctermbg = "blue" })
      end
      local function match_whitespace(pattern)
        return function()
          vim.cmd.match(vim.bo.buftype == "" and { "ExtraWhitespace", pattern } or "none")
        end
      end
      vim.api.nvim_create_autocmd("ColorScheme", { group = whitespace, callback = highlight_whitespace })
      vim.api.nvim_create_autocmd({ "BufWinEnter", "InsertLeave" }, {
        group = whitespace,
        callback = match_whitespace([[/\s\+$/]]),
      })
      vim.api.nvim_create_autocmd("InsertEnter", {
        group = whitespace,
        callback = match_whitespace([[/\s\+\%#\@<!$/]]),
      })
      highlight_whitespace()

      -- Colors: VS Code Dark+, with Tree-sitter highlighting wherever a grammar exists (Vim syntax files otherwise)
      require("vscode").setup({})
      vim.cmd.colorscheme("vscode")
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("treesitter_highlight", {}),
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
      })
    '';
  };
}
