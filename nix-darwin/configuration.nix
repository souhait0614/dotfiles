{ pkgs, lib, primaryUser, userHome, profile, isCI, self, ... }:

let
  fontsData = builtins.fromTOML (builtins.readFile ./fonts.toml);
  homebrewData = builtins.fromTOML (builtins.readFile ./homebrew.toml);
in
assert lib.assertMsg (primaryUser != "" && userHome != "")
  "Run nix-darwin through mise bootstrap so the login user and home are provided.";
assert lib.assertMsg (builtins.elem profile [ "souhait" "work_a" "work_p" ])
  "Select a machine profile through mise before applying nix-darwin.";

{
  nix = {
    enable = true;
    package = pkgs.lixPackageSets.stable.lix;
    settings.experimental-features = [ "nix-command" "flakes" ];
  };

  system = {
    configurationRevision = self.rev or self.dirtyRev or null;
    inherit primaryUser;
    stateVersion = 7;
    activationScripts.disableSpotlight.text = ''
      /usr/bin/mdutil -a -i off
    '';
  };

  users.users.${primaryUser}.home = userHome;

  fonts.packages = map (name: lib.getAttrFromPath (lib.splitString "." name) pkgs) fontsData.packages;

  homebrew = {
    enable = true;
    user = primaryUser;
    onActivation = {
      autoUpdate = false;
      cleanup = if isCI then "none" else "check";
      upgrade = false;
    };
    taps = map (name: { inherit name; trusted = true; }) homebrewData.taps;
    brews = homebrewData.brews;
    casks = homebrewData.casks;
    masApps = lib.optionalAttrs (!isCI) homebrewData.masApps;
  };

  system.defaults = {
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      ApplePressAndHoldEnabled = false;
      AppleKeyboardUIMode = 0;
    };
    dock = {
      tilesize = 32;
      "show-recents" = false;
      mineffect = "scale";
      "minimize-to-application" = true;
      showLaunchpadGestureEnabled = false;
      showDesktopGestureEnabled = true;
    };
    trackpad = {
      Clicking = false;
      TrackpadThreeFingerDrag = false;
      TrackpadRightClick = true;
      TrackpadFourFingerPinchGesture = 0;
    };
    finder = {
      ShowPathbar = true;
      ShowStatusBar = true;
      FXPreferredViewStyle = "Nlsv";
      NewWindowTarget = "Home";
    };
    CustomUserPreferences = {
      "com.apple.Spotlight".MenuItemHidden = 1;
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
      "com.apple.dock".size-immutable = true;
    };
  };

  programs.zsh.enable = true;
  security.pam.services.sudo_local.touchIdAuth = true;
}
