{ config, pkgs, ... }:
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "hangsai"; home.homeDirectory = "/home/hangsai";
  # Fix version mismatch warning
  home.enableNixpkgsReleaseCheck = false;

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
    direnv

    # languages
    jdk23
    python3
    python3Packages.virtualenv
    python3Packages.pip
    rustup

    # nvim
    fzf
    gnumake
    libtool
    neovim
    pkg-config
    ripgrep
    jdt-language-server
    vimPlugins.telescope-fzf-native-nvim

    # Common build dependencies
    cmake
    lld
    llvm
    gcc
    openssl
    pkg-config

    git-extras
    git
    ripgrep

    #shell
    oh-my-zsh
    zsh-powerlevel10k
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;
    ".p10k.zsh".source = ~/.config/.p10k.zsh;


    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

# Configure rustfmt
  home.file.".rustfmt.toml".text = ''
    max_width = 100
    tab_spaces = 4
    edition = "2021"
  '';

  # Cargo configuration with correct linker settings
  home.file.".cargo/config.toml".text = ''
    [target.x86_64-unknown-linux-gnu]
    linker = "gcc"
    rustflags = [
      "-C", "link-arg=-fuse-ld=lld",
      "-C", "target-feature=+crt-static"
    ]

    [build]
    rustc-wrapper = "${pkgs.sccache}/bin/sccache"

    [net]
    git-fetch-with-cli = true
  '';

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/hangsai/etc/profile.d/hm-session-vars.sh

  home.sessionVariables = {
    EDITOR = "nvim";
    RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/library";
    RUSTFLAGS="-C target-cpu=native -C link-arg=-fuse-ld=lld";
    OPENSSL_DIR = "${pkgs.openssl.dev}";
    OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";
    LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
    BINDGEN_EXTRA_CLANG_ARGS = "-I${pkgs.glibc.dev}/include -I${pkgs.clang}/resource-root/include";
    LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
      pkgs.stdenv.cc.cc
      pkgs.openssl
    ];
    CC = "${pkgs.gcc}/bin/gcc";
    CXX = "${pkgs.gcc}/bin/g++";
  };

  # Let Home Manager install and manage itself.
  services = {
    ssh-agent.enable = true;
    conky.enable = true;
  };
  programs = {
    home-manager.enable = true;
    lazygit.enable = true;

    direnv = {
      enable = true;
      enableZshIntegration = true;
    };

    fastfetch.enable = true;
    fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultCommand = "rg --files --hidden --follow";
      defaultOptions = [
        "--height 40%"
        "--layout=reverse"
        "--border"
        "--preview 'cat {}'"
      ];
      historyWidgetOptions = [
        "--sort"
        "--exact"
      ];
    };

    nix-your-shell.enable = true;

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    zsh = {
      enable = true;
      autosuggestion.enable = true;
      enableCompletion = true;

      plugins = [
        {
          name = "vi-mode";
          src = pkgs.zsh-vi-mode;
        }
      ];

      history = {
        path = "${config.home.homeDirectory}/.zsh_history"; # Explicit path
        save = 50000;
        size = 50000;
        expireDuplicatesFirst = true;
        extended = true;
        share = true;  # Share history between sessions
      };

      # Aliases
      shellAliases = {
        mkdir = "mkdir -p";
      };

      initExtra = ''
        export PATH=$PATH:/home/hangsai/.cache/pokemon-icat
        pokemon-icat -q
        source $(find /nix/store -name "powerlevel10k.zsh-theme" | head -n 1)

        # To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
        [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

        nvim() {
            kitten @ set-spacing padding=0   # Set padding to 0
            command nvim "$@"                # Run Neovim with any passed arguments
            kitten @ set-spacing padding=25  # Restore padding to 25 after exiting Neovim
        }
        # FZF configuration for better history search
        export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
        export FZF_CTRL_R_OPTS="--sort --exact"

        # Ensure history is saved properly
        setopt SHARE_HISTORY
        setopt EXTENDED_HISTORY
        setopt HIST_EXPIRE_DUPS_FIRST
        setopt HIST_IGNORE_DUPS
        setopt HIST_IGNORE_SPACE
        setopt HIST_VERIFY

        # Prevent the creation of backup files
        setopt NO_CLOBBER

        # Clean up any existing .~ directories
        find . -name ".~" -type d -exec rm -rf {} +
      '';
      oh-my-zsh = {
        enable = true;
        plugins = [
          "history"
          "dirhistory"
          "git"
        ];
      };
    };
  };
}
