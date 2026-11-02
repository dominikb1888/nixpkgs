{ config, pkgs, lib, ... }:

{
  system.primaryUser = "dominikb1888";

  # ---------------------------------------------------------------------
  # 1. GLOBAL SYSTEM SETTINGS & PROCESS REDUCTION
  # ---------------------------------------------------------------------
  system.defaults.NSGlobalDomain = {
    "com.apple.trackpad.scaling" = 3.0;
    AppleICUForce24HourTime = true;
    AppleInterfaceStyleSwitchesAutomatically = true;
    AppleMeasurementUnits = "Centimeters";
    AppleMetricUnits = 1;
    AppleShowScrollBars = "Automatic";
    AppleTemperatureUnit = "Celsius";
    InitialKeyRepeat = 15;
    KeyRepeat = 2;
    NSAutomaticCapitalizationEnabled = false;
    NSAutomaticDashSubstitutionEnabled = false;
    NSAutomaticPeriodSubstitutionEnabled = false;
    NSAutomaticQuoteSubstitutionEnabled = true;
    _HIHideMenuBar = false;

    # Aggressive Process Trim additions:
    # Disable background window animations and resizing math loops
    NSAutomaticWindowAnimationsEnabled = false;
    # Kill "smooth scrolling" calculus when rendering documents/web pages
    NSScrollAnimationEnabled = false;
    # Prevent background text-parsing daemons (auto-correct/spellcheck engine loops)
    NSAutomaticSpellingCorrectionEnabled = false;
    # Stop localized dictionaries from updating or downloading in the background
    NSAutomaticInlinePredictionEnabled = false;
  };

  # ---------------------------------------------------------------------
  # 2. NETWORKING & SECURITY
  # ---------------------------------------------------------------------
  networking.applicationFirewall = {
    enable = true;
    allowSigned = true;
    allowSignedApp = true;
    enableStealthMode = true;
  };

  # ---------------------------------------------------------------------
  # 3. DOCK, MISSION CONTROL & GRAPHICS LOOPS
  # ---------------------------------------------------------------------
  system.defaults.dock = {
    autohide = true;
    autohide-delay = 0.0;
    autohide-time-modifier = 0.0; # Zeroed out to completely kill transition timer threads
    expose-group-apps = false;
    mru-spaces = false;
    tilesize = 64;
    wvous-bl-corner = 1;
    wvous-br-corner = 1;
    wvous-tl-corner = 1;
    wvous-tr-corner = 1;

    # Aggressive Process Trim additions:
    # Stop rendering recent app caches in the background
    show-recents = false;
    # Kill the bouncing animation thread when apps launch
    launchanim = false;
    # Stop calculating Mission Control grouping logic automatically
    expose-animation-duration = 0.0;
  };

  # ---------------------------------------------------------------------
  # 4. CUSTOM PREFERENCES & CLOUD DEACTIVATION
  # ---------------------------------------------------------------------
  system.defaults.CustomUserPreferences = {
    "com.apple.desktopservices" = {
      DSDontWriteNetworkStores = true;
      DSDontWriteUSBStores = true;
    };
    # Kill Content Caching services (stops your Mac from acting as a local update server)
    "com.apple.AssetCache" = {
      Activated = false;
    };
    # Stop Universal Clipboard and Handoff discovery wireless polling
    "com.apple.coreservices.useractivityd" = {
      ActivityAdvertisingAllowed = false;
      ActivityReceivingAllowed = false;
    };
    # Turn off Siri completely to kill speech parsing and audio recording daemons
    "com.apple.assistant.support" = {
      "Assistant Enabled" = false;
    };
    # Disable Spotlight Indexing UI backend references
    "com.apple.spotlight" = {
      orderedItems = [];
    };
    # Shut down Apple Watch proximity & device unlock frameworks
    "com.apple.sharingd" = {
      WatchUnlockEnabled = false;
      AutoUnlockEnabled = false;
    };
    # Telemetry and diagnostics preferences
    "com.apple.CrashReporter" = {
      DiagnosticMessagesEnabled = false;
    };
    # Custom Finder preferences
    "com.apple.finder" = {
      DisableAllAnimations = true;
    };
  };

  # ---------------------------------------------------------------------
  # 5. USER SESSION & INTERFACE ENVIRONMENT
  # ---------------------------------------------------------------------
  system.defaults.loginwindow = {
    GuestEnabled = false;
    DisableConsoleAccess = true;
  };

  system.defaults.spaces.spans-displays = false;

  system.defaults.trackpad = {
    Clicking = false;
    TrackpadRightClick = true;
  };

  system.defaults.finder = {
    AppleShowAllExtensions = true;
    FXEnableExtensionChangeWarning = false; # Prevent warning math loops when editing extensions
    NewWindowTarget = "Home";
    ShowPathbar = true;
  };

  # ---------------------------------------------------------------------
  # 6. MASKING SYSTEM DAEMONS NATIVELY VIA LAUNCHD KEYS
  # ---------------------------------------------------------------------
  # This uses valid nix-darwin parameters to drop these targets into a disabled state.
  launchd.user.agents = {
    # Layer 1 (Already added)
    "com.apple.speech.speechsynthesisd".serviceConfig.Disabled = true;
    "com.apple.cloudd".serviceConfig.Disabled = true;
    "com.apple.sharingd".serviceConfig.Disabled = true;
    "com.apple.rapportd".serviceConfig.Disabled = true;
    "com.apple.Spotlight".serviceConfig.Disabled = true;
    "com.apple.gamed".serviceConfig.Disabled = true;
    "com.apple.locationd".serviceConfig.Disabled = true;
    "com.apple.geod".serviceConfig.Disabled = true;
    "com.apple.akd".serviceConfig.Disabled = true;

    # NEW: Layer 2 - Accessibility, Automation, and Audio Engines
    "com.apple.Siri.agent".serviceConfig.Disabled = true;
    "com.apple.assistivetouchd".serviceConfig.Disabled = true;
    "com.apple.VoiceOver".serviceConfig.Disabled = true;

    # NEW: Layer 3 - Media Sharing, HomeKit, and Ecosystem Casting
    "com.apple.homed".serviceConfig.Disabled = true;
    "com.apple.mediaanalysisd".serviceConfig.Disabled = true;
    "com.apple.sidecar-display-agent".serviceConfig.Disabled = true;

    # NEW: Layer 4 - Core Printing and Scanner Modules
    "com.apple.printtoolagent".serviceConfig.Disabled = true;
  };
}

