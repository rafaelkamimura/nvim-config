# Neovim Configuration

My personal Neovim configuration based on [LazyVim](https://www.lazyvim.org/).

## Features

- Built on LazyVim framework for a modern Neovim experience
- Lazy loading for fast startup times
- LSP support for multiple languages
- Custom keymaps and options
- Minimal and clean configuration

## Structure

```
.
├── init.lua          # Entry point
├── lazy-lock.json    # Plugin lock file
├── lazyvim.json      # LazyVim configuration
├── lua/
│   ├── config/       # Core configuration
│   │   ├── autocmds.lua  # Auto commands
│   │   ├── keymaps.lua   # Key mappings
│   │   ├── lazy.lua      # Lazy.nvim setup
│   │   └── options.lua   # Neovim options
│   └── plugins/      # Plugin configurations
│       └── example.lua   # Example plugin config
└── stylua.toml       # Lua formatter config
```

## Installation

1. Backup your existing Neovim configuration:
```bash
mv ~/.config/nvim ~/.config/nvim.bak
```

2. Clone this repository:
```bash
git clone https://github.com/YOUR_USERNAME/nvim-config.git ~/.config/nvim
```

3. Start Neovim and let LazyVim install plugins:
```bash
nvim
```

## Requirements

- Neovim >= 0.9.0
- Git
- A [Nerd Font](https://www.nerdfonts.com/) (optional but recommended)
- ripgrep (rg) for telescope
- fd for file finding

## Key Features

- **Package Manager**: [lazy.nvim](https://github.com/folke/lazy.nvim)
- **Base Configuration**: [LazyVim](https://github.com/LazyVim/LazyVim)
- **Statusline**: Included in LazyVim
- **File Explorer**: neo-tree (included in LazyVim)
- **Fuzzy Finder**: Telescope (included in LazyVim)
- **LSP**: Native LSP with nvim-lspconfig

## Customization

- Add custom plugins in `lua/plugins/`
- Modify keymaps in `lua/config/keymaps.lua`
- Change options in `lua/config/options.lua`
- Add auto commands in `lua/config/autocmds.lua`

## License

[MIT License](LICENSE)
