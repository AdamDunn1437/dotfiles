-- ── dotfiles nvim/init.lua ───────────────────────────────────
-- Symlinked to ~/.config/nvim/init.lua via install.sh

-- Bootstrap lazy.nvim (plugin manager)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ── Basic options ──
vim.opt.number = true            -- line numbers
vim.opt.relativenumber = true    -- relative line numbers
vim.opt.tabstop = 2              -- spaces per tab
vim.opt.shiftwidth = 2           -- spaces per indent
vim.opt.expandtab = true         -- tabs → spaces
vim.opt.swapfile = false         -- no swap files
vim.opt.undofile = true          -- persistent undo
vim.opt.ignorecase = true        -- case-insensitive search
vim.opt.smartcase = true         -- ...unless uppercase used
vim.opt.termguicolors = true     -- 24-bit colour
vim.opt.updatetime = 250         -- faster updates (for gitsigns etc.)
vim.opt.signcolumn = "yes"       -- always show sign column
vim.opt.completeopt = "menu,menuone,noselect"

-- ── Lazy plugins ──
require("lazy").setup({
  -- TPope essentials
  "tpope/vim-sleuth",           -- auto-detect indent settings
  "tpope/vim-fugitive",         -- :Git inside nvim
  "tpope/vim-rhubarb",          -- :Gbrowse for GitHub

  -- Navigation & UI
  "nvim-treesitter/nvim-treesitter",      -- better syntax highlighting
  "nvim-lualine/lualine.nvim",            -- statusline
  "nvim-tree/nvim-web-devicons",          -- file icons

  -- Fuzzy finder (requires fzf from Nix dev shell)
  {
    "ibhagwan/fzf-lua",
    config = function()
      require("fzf-lua").setup({})
      vim.keymap.set("n", "<C-p>", "<cmd>FzfLua files<CR>", { desc = "Find files" })
      vim.keymap.set("n", "<C-g>", "<cmd>FzfLua grep<CR>", { desc = "Live grep" })
    end,
  },

  -- Colorscheme
  { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
})

-- ── Colorscheme ──
vim.cmd.colorscheme("catppuccin-mocha")

-- ── Keymaps ──
local map = vim.keymap.set
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit" })
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostics" })
map("n", "<leader>u", vim.cmd.UndotreeToggle, { desc = "Undo tree" })
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
