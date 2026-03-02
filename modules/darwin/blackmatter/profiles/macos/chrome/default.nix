# modules/darwin/blackmatter/profiles/macos/chrome/default.nix
# Declarative Chrome installation and configuration via Homebrew cask
# and macOS managed preferences (defaults write com.google.Chrome)
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.macos.chrome;

  chromeTheme = pkgs.runCommand "chrome-base16-theme" {
    nativeBuildInputs = with pkgs; [
      (python3.withPackages (p: [p.pyyaml]))
      openssl
      zip
    ];
  } ''
    mkdir -p $out
    python3 ${./build-theme.py} \
      --scheme ${cfg.theme.base16Scheme} \
      --key ${./theme-key.pem} \
      --outdir $out
  '';

  themeExtId = strings.trim (builtins.readFile "${chromeTheme}/extension-id");
in {
  options = {
    blackmatter = {
      profiles = {
        macos = {
          chrome = {
            enable = mkEnableOption "declarative Chrome installation and configuration";

            extensions = mkOption {
              type = types.listOf (types.submodule {
                options = {
                  id = mkOption {
                    type = types.str;
                    description = "Chrome Web Store extension ID";
                  };
                  updateUrl = mkOption {
                    type = types.str;
                    default = "https://clients2.google.com/service/update2/crx";
                    description = "Extension update URL";
                  };
                };
              });
              default = [];
              description = "Chrome extensions to force-install via managed policy";
            };

            preferences = mkOption {
              type = types.attrsOf types.anything;
              default = {};
              description = "Additional Chrome user preferences passed through to CustomUserPreferences";
            };

            swipeNavigation = mkOption {
              type = types.bool;
              default = false;
              description = "Enable two-finger swipe for back/forward navigation";
            };

            expandPrintDialog = mkOption {
              type = types.bool;
              default = true;
              description = "Expand the print dialog by default";
            };

            passwordManager = mkOption {
              type = types.bool;
              default = false;
              description = "Enable Chrome's built-in password manager";
            };

            translationPrompt = mkOption {
              type = types.bool;
              default = false;
              description = "Show the offer-to-translate prompt for foreign language pages";
            };

            theme = {
              enable = mkEnableOption "auto-generated Chrome theme from a base16 color scheme";

              base16Scheme = mkOption {
                type = types.path;
                description = "Path to a base16 YAML scheme file (e.g. from pkgs.base16-schemes).";
              };
            };
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # Install Chrome via Homebrew cask
    homebrew.enable = true;
    homebrew.casks = ["google-chrome"];

    # Chrome preferences + managed policies via defaults write
    system.defaults.CustomUserPreferences."com.google.Chrome" = mkMerge [
      {
        AppleEnableSwipeNavigateWithScrolls = cfg.swipeNavigation;
        PMPrintingExpandedStateForPrint2 = cfg.expandPrintDialog;
        NSNavPanelExpandedStateForSaveMode = true;
        DisablePasswordManagerReenrollment = !cfg.passwordManager;
      }
      (mkIf (!cfg.translationPrompt) {
        OfferTranslation = false;
      })
      (mkIf (cfg.extensions != []) {
        ExtensionInstallForcelist = map (e: "${e.id};${e.updateUrl}") cfg.extensions;
      })
      (mkIf cfg.theme.enable {
        ExtensionInstallForcelist = [
          "${themeExtId};file://${chromeTheme}/updates.xml"
        ];
      })
      cfg.preferences
    ];
  };
}
