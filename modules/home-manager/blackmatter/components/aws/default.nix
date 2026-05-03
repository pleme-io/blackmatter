# AWS CLI configuration generator.
# Generates ~/.aws/config from typed Nix options.
# No org-specific data — pure structure.
{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.aws;

  # ── INI generation helpers ──────────────────────────────────────

  mkIniLine = key: value:
    if value != null then "${key} = ${toString value}\n" else "";

  mkSsoProfile = name: p: let
    header = if name == "default" then "[default]" else "[profile ${name}]";
  in
    header + "\n"
    + mkIniLine "cli_pager" p.pager
    + mkIniLine "region" p.region
    + mkIniLine "output" p.output
    + mkIniLine "sso_session" p.ssoSession
    + mkIniLine "sso_account_id" p.accountId
    + mkIniLine "sso_role_name" p.roleName
    + mkIniLine "role_arn" p.roleArn
    + mkIniLine "source_profile" p.sourceProfile
    + concatStringsSep "" (mapAttrsToList (k: v: mkIniLine k v) p.extraConfig);

  mkSsoSession = name: s:
    "[sso-session ${name}]\n"
    + mkIniLine "sso_start_url" s.startUrl
    + mkIniLine "sso_region" s.region
    + mkIniLine "sso_registration_scopes" s.registrationScopes;

  # ── Render full config ──────────────────────────────────────────

  profileText = concatStringsSep "\n" (
    mapAttrsToList mkSsoProfile cfg.profiles
  );

  sessionText = concatStringsSep "\n" (
    mapAttrsToList mkSsoSession cfg.ssoSessions
  );

  configText = profileText + "\n" + sessionText + "\n";

  # ── Option types ────────────────────────────────────────────────

  profileOpts = { name, ... }: {
    options = {
      accountId = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "AWS account ID for SSO profiles.";
      };

      roleName = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "IAM role name for SSO assumption.";
      };

      ssoSession = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "SSO session name (references ssoSessions entry).";
      };

      region = mkOption {
        type = types.str;
        default = "us-east-1";
        description = "AWS region.";
      };

      output = mkOption {
        type = types.str;
        default = "json";
        description = "CLI output format (text, json, yaml, table).";
      };

      pager = mkOption {
        type = types.nullOr types.str;
        default = "cat";
        description = "CLI pager command. Set to 'cat' to disable paging.";
      };

      roleArn = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "IAM role ARN for assumed-role profiles.";
      };

      sourceProfile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Source profile for assumed-role chain.";
      };

      extraConfig = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Additional key=value pairs appended to this profile section.";
        example = { credential_process = "/usr/bin/my-cred-helper"; mfa_serial = "arn:aws:iam::123:mfa/user"; };
      };
    };
  };

  ssoSessionOpts = { ... }: {
    options = {
      startUrl = mkOption {
        type = types.str;
        description = "AWS SSO start URL (e.g. https://d-xxx.awsapps.com/start).";
      };

      region = mkOption {
        type = types.str;
        default = "us-east-1";
        description = "SSO service region.";
      };

      registrationScopes = mkOption {
        type = types.str;
        default = "sso:account:access";
        description = "SSO OIDC registration scopes.";
      };
    };
  };

in {
  options.blackmatter.components.aws = {
    enable = mkEnableOption "AWS CLI configuration (~/.aws/config)";

    profiles = mkOption {
      type = types.attrsOf (types.submodule profileOpts);
      default = {};
      description = ''
        AWS CLI profiles. Each entry generates a [profile name] section
        (or [default] for the "default" key) in ~/.aws/config.
        Supports SSO profiles, assumed-role profiles, and static profiles.
      '';
      example = {
        default = {
          accountId = "123456789012";
          roleName = "AdministratorAccess";
          ssoSession = "my-sso";
          region = "us-east-1";
        };
        production = {
          accountId = "987654321098";
          roleName = "ReadOnlyAccess";
          ssoSession = "my-sso";
          region = "us-east-2";
        };
      };
    };

    ssoSessions = mkOption {
      type = types.attrsOf (types.submodule ssoSessionOpts);
      default = {};
      description = ''
        AWS SSO sessions. Each entry generates a [sso-session name]
        section in ~/.aws/config.
      '';
    };
  };

  config = mkIf (cfg.enable && (cfg.profiles != {} || cfg.ssoSessions != {})) {
    home.file.".aws/config".text = configText;
  };
}
