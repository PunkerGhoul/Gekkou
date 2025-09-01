{ config, pkgs, ... }:

let
  # Import bookmarks from JSON file
  bookmarksJson = builtins.fromJSON (builtins.readFile ./bookmarks.json);

  # Function to convert JSON bookmarks to Nix format
  convertBookmarks = items:
    builtins.filter (item: item != null) (builtins.map (item:
      if (item.type or "") == "text/x-moz-place-separator" then
        null  # Skip separators in nested structures - they're not supported
      else if builtins.hasAttr "children" item && item.children != [] then {
        name = item.title;
        bookmarks = convertBookmarks item.children;
      } else if builtins.hasAttr "uri" item then {
        name = item.title;
        url = item.uri;
      } else null
    ) items);

  # Convert the imported bookmarks - get the toolbar folder specifically
  toolbarFolder = builtins.head (builtins.filter
    (child: (child.root or "") == "toolbarFolder")
    bookmarksJson.children);

  # Convert toolbar bookmarks to Nix format with proper structure
  personalBookmarks = if builtins.hasAttr "children" toolbarFolder then
    let
      # Process toolbar items, handling separators only at the top level
      processToolbarItems = items:
        builtins.filter (item: item != null) (builtins.map (item:
          if (item.type or "") == "text/x-moz-place-separator" then
            "separator"  # Only at toolbar level
          else if builtins.hasAttr "children" item && item.children != [] then {
            name = item.title;
            bookmarks = convertBookmarks item.children;  # No separators in nested levels
          } else if builtins.hasAttr "uri" item then {
            name = item.title;
            url = item.uri;
          } else null
        ) items);

      toolbarBookmarks = processToolbarItems toolbarFolder.children;
    in
      # Create a single toolbar folder containing all bookmarks
      [
        {
          name = "Bookmarks Toolbar";
          toolbar = true;
          bookmarks = toolbarBookmarks;
        }
      ]
  else [];
in
  {
  programs.librewolf = {
    enable = true;

    package = (config.lib.nixGL.wrap pkgs.librewolf);

    profiles = {
      # Personal profile - default for daily use
      personal = {
        id = 0;
        isDefault = true;
        name = "Personal";

        # Personal use extensions
        extensions.force = true; # Required if using settings

        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin          # uBlock0@raymondhill.net
          bitwarden             # Password manager
        ];

        extensions.settings = {
          "uBlock0@raymondhill.net".settings = {
            userSettings = {
              advancedUserEnabled = true;
            };
            whitelist = [
              "portswigger.net"
            ];
          };
        };

        # Bookmarks configuration - imported from JSON
        bookmarks = {
          force = true;  # Force apply bookmarks
          settings = personalBookmarks;  # Use the converted bookmarks
        };

        # Personal settings migrated from your LibreWolf configuration
        settings = {
          # Browser and UI
          "browser.shell.checkDefaultBrowser" = false;
          "browser.contentblocking.category" = "strict";
          "browser.download.always_ask_before_handling_new_types" = true;
          "browser.bookmarks.defaultLocation" = "toolbar";
          "browser.theme.content-theme" = 0;
          "browser.theme.toolbar-theme" = 0;
          
          # Note: You have "firefox-compact-dark" theme active
          # To configure it in Nix, you can use:
          # "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";

          # Extensions
          "extensions.autoDisableScopes" = 0;
          "extensions.ui.extension.hidden" = false;

          "browser.uiCustomization.state" = "{\"placements\":{\"widget-overflow-fixed-list\":[],\"unified-extensions-area\":[],\"nav-bar\":[\"sidebar-button\",\"back-button\",\"forward-button\",\"stop-reload-button\",\"customizableui-special-spring1\",\"vertical-spacer\",\"urlbar-container\",\"customizableui-special-spring2\",\"save-to-pocket-button\",\"downloads-button\",\"fxa-toolbar-menu-button\",\"ublock0_raymondhill_net-browser-action\",\"_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action\",\"unified-extensions-button\"],\"toolbar-menubar\":[\"menubar-items\"],\"TabsToolbar\":[\"tabbrowser-tabs\",\"new-tab-button\",\"alltabs-button\"],\"vertical-tabs\":[],\"PersonalToolbar\":[\"import-button\",\"personal-bookmarks\"]},\"seen\":[\"_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action\",\"ublock0_raymondhill_net-browser-action\",\"developer-button\"],\"dirtyAreaCache\":[\"unified-extensions-area\",\"nav-bar\",\"vertical-tabs\",\"PersonalToolbar\",\"toolbar-menubar\",\"TabsToolbar\"],\"currentVersion\":21,\"newElementCount\":3}";

          # Privacy and security
          "privacy.donottrackheader.enabled" = true;
          "privacy.fingerprintingProtection" = true;
          "privacy.globalprivacycontrol.was_ever_enabled" = true;
          "privacy.history.custom" = true;
          "privacy.query_stripping.enabled" = true;
          "privacy.query_stripping.enabled.pbmode" = true;
          "privacy.trackingprotection.enabled" = true;
          "privacy.trackingprotection.emailtracking.enabled" = true;
          "privacy.trackingprotection.socialtracking.enabled" = true;
          "privacy.annotate_channels.strict_list.enabled" = true;
          "privacy.bounceTrackingProtection.mode" = 1;

          # Network and connectivity
          "network.captive-portal-service.enabled" = false;
          "network.connectivity-service.enabled" = false;
          "network.dns.disableIPv6" = true;
          "network.http.speculative-parallel-limit" = 0;
          ## DNS over HTTPS (DoH) settings
          "network.trr.mode" = 3; # Max Protection; 2 = Increased Protection & 1 = Default
          "network.trr.uri" = "https://dns10.quad9.net/dns-query";
          "network.trr.custom_uri" = "https://dns10.quad9.net/dns-query";
          "network.http.referer.disallowCrossSiteRelaxingDefault.top_navigation" = true;

          # Additional security
          "security.tls.enable_0rtt_data" = false;
          "dom.security.https_only_mode" = true;
          "dom.security.https_only_mode_ever_enabled" = true;
          "dom.private-attribution.submission.enabled" = false;

          # SafeBrowsing disabled (LibreWolf default)
          "browser.safebrowsing.downloads.remote.enabled" = false;
          "browser.safebrowsing.downloads.remote.block_potentially_unwanted" = false;
          "browser.safebrowsing.downloads.remote.block_uncommon" = false;

          # Forms and passwords
          "dom.forms.autocomplete.formautofill" = false;
          "signon.rememberSignons" = false; # Use Bitwarden instead
          "signon.generation.enabled" = false;
          "signon.management.page.breach-alerts.enabled" = false;

          # Developer tools
          "devtools.cache.disabled" = true;
          "devtools.debugger.remote-enabled" = false;
          "devtools.console.stdout.chrome" = false;
          "devtools.netmonitor.persistlog" = true;

          # Miscellaneous
          "findbar.highlightAll" = true;
          "intl.accept_languages" = "en-US, en";
          "javascript.use_us_english_locale" = true;
          "permissions.delegation.enabled" = false;
          "toolkit.winRegisterApplicationRestart" = false;
          "sidebar.visibility" = "hide-sidebar";
          
          # VM PERFORMANCE OPTIMIZATIONS - ENHANCED
          # Graphics rendering - disable hardware acceleration in VMs (often causes slowness)
          "gfx.webrender.all" = false; # Disable WebRender in VMs (causes lag)
          "gfx.webrender.enabled" = false;
          "layers.acceleration.force-enabled" = false;
          "layers.acceleration.disabled" = true; # Disable problematic HW acceleration
          "layers.gpu-process.enabled" = false; # Disable GPU process in VMs
          "webgl.disabled" = false; # Keep WebGL but don't force it
          "webgl.force-enabled" = false;
          "media.hardware-video-decoding.enabled" = false; # Software decoding is more stable in VMs
          
          # Habilitar códecs de video y audio
          "media.ffmpeg.vaapi.enabled" = false; # VAAPI disabled in VM
          "media.ffvpx.enabled" = true; # Enable FFmpeg VP8/VP9 decoding
          "media.av1.enabled" = true; # Enable AV1 codec
          "media.rdd-process.enabled" = true; # Enable Remote Data Decoder for media
          "media.gmp-gmpopenh264.enabled" = true; # Enable OpenH264 codec
          "media.gmp-manager.url" = "https://aus5.mozilla.org/update/3/GMP/%VERSION%/%BUILD_ID%/%BUILD_TARGET%/%LOCALE%/%CHANNEL%/%OS_VERSION%/%DISTRIBUTION%/%DISTRIBUTION_VERSION%/update.xml";
          "media.eme.enabled" = true; # Enable Encrypted Media Extensions (DRM)
          "media.gmp-widevinecdm.enabled" = true; # Enable Widevine CDM for protected content
          "media.navigator.enabled" = true;
          "media.peerconnection.enabled" = true;
          
          "gfx.canvas.azure.backends" = "skia"; # Use CPU-based rendering
          "layers.omtp.enabled" = false; # Disable off-main-thread painting
          "gfx.vsync.hw-vsync.enabled" = true; # Enable vsync for smoother rendering
          "gfx.vsync.compositor" = true; # Enable compositor vsync
          "layout.frame_rate" = 60; # 60fps for smooth experience
          "nglayout.initialpaint.delay" = 5; # Small delay for stability
          "nglayout.initialpaint.delay_in_oopif" = 5;
          
          # Memory optimizations for VMs - be more aggressive
          "browser.cache.memory.capacity" = 204800; # Increase to 200MB memory cache
          "browser.cache.memory.enable" = true;
          "browser.cache.disk.enable" = true;
          "browser.cache.disk.capacity" = 1048576; # Increase to 1GB disk cache
          "browser.cache.disk.smart_size.enabled" = false;
          "browser.cache.disk.max_entry_size" = 51200; # Max 50MB per cached item
          "browser.cache.memory.max_entry_size" = 10240; # 10MB max per item in memory
          
          # JavaScript and content process optimizations
          "javascript.options.mem.high_water_mark" = 128; # Increase from 64
          "javascript.options.mem.max" = 262144; # Increase to 256MB max JS memory
          "dom.ipc.processCount" = 4; # Allow more processes for better responsiveness
          "dom.ipc.processCount.webIsolated" = 1;
          "browser.tabs.remote.autostart" = true;
          "browser.tabs.remote.desktopbehavior" = true;
          
          # Reduce animations and visual effects
          "ui.prefersReducedMotion" = 1; # Disable animations
          "browser.tabs.animate" = false;
          "browser.fullscreen.animate" = false;
          "browser.download.animateNotifications" = false;
          "alerts.disableSlidingEffect" = true;
          "toolkit.cosmeticAnimations.enabled" = false;
          
          # Disable resource-intensive features
          "browser.pagethumbnails.capturing_disabled" = true;
          "browser.newtabpage.activity-stream.feeds.topsites" = false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          "browser.newtabpage.activity-stream.feeds.snippets" = false;
          "browser.newtabpage.activity-stream.prerender" = false;
          "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
          "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
          "accessibility.force_disabled" = 1;
          
          # Network optimizations for VMs
          "network.http.max-connections" = 256; # Increase for parallel loading
          "network.http.max-persistent-connections-per-server" = 8; # More concurrent connections
          "network.http.max-persistent-connections-per-proxy" = 8;
          "network.http.pipelining" = true;
          "network.http.pipelining.maxrequests" = 8;
          "network.http.pipelining.ssl" = true; # Enable for HTTPS
          "network.http.proxy.pipelining" = true;
          "network.buffer.cache.size" = 262144; # Increase to 256KB
          "network.buffer.cache.count" = 128;
          "network.dns.disablePrefetch" = false; # Enable DNS prefetch for faster loading
          "network.dns.disablePrefetchFromHTTPS" = false;
          "network.predictor.enabled" = true; # Enable network predictor
          "network.predictor.enable-prefetch" = true;
          "network.prefetch-next" = true; # Enable link prefetching
          
          # Scrolling performance - balanced for smooth experience
          "apz.allow_zooming" = true;
          "apz.force_disable_desktop_zooming_scrollbars" = false;
          "general.smoothScroll" = true; # Enable smooth scrolling
          "general.smoothScroll.lines.durationMaxMS" = 80;
          "general.smoothScroll.lines.durationMinMS" = 40;
          "general.smoothScroll.mouseWheel.durationMaxMS" = 120;
          "general.smoothScroll.mouseWheel.durationMinMS" = 40;
          "general.smoothScroll.pages.durationMaxMS" = 120;
          "general.smoothScroll.pages.durationMinMS" = 80;
          "general.smoothScroll.stopDecelerationWeighting" = 0.6;
          "mousewheel.default.delta_multiplier_y" = 25; # Reduce scroll distance significantly
          "mousewheel.transaction.timeout" = 300; # Reduce timeout for faster response
          "apz.overscroll.enabled" = true; # Enable overscroll for better UX
          "apz.gtk.kinetic_scroll.enabled" = false; # Disable kinetic scroll (can cause issues)
          "apz.autoscroll.enabled" = false; # Disable autoscroll delay
          
          # Touchpad/trackpad optimizations - with momentum
          "mousewheel.min_line_scroll_amount" = 3; # Reduce minimum scroll
          "mousewheel.acceleration.start" = 2; # Start acceleration after 2 scrolls
          "mousewheel.acceleration.factor" = 10; # Higher acceleration for momentum
          "mousewheel.system_scroll_override_on_root_content.enabled" = false; # Use custom settings
          "general.smoothScroll.msdPhysics.enabled" = false; # Disable physics for instant response
          "apz.gtk.touchpad_pinch.enabled" = true; # Enable pinch zoom
          "apz.allow_double_tap_zooming" = false; # Disable double-tap zoom to prevent accidents
          "apz.fling_friction" = 0.01; # Higher friction for more control
          "apz.fling_stopped_threshold" = 0.2; # Higher threshold to stop faster
          "apz.fling_min_velocity_threshold" = 0.1; # Moderate momentum detection
          "apz.velocity_bias" = 1.0; # Maximum responsiveness
          "apz.content_response_timeout" = 50; # Minimal content response timeout
          "apz.touch_start_tolerance" = 0.05; # Very sensitive touch start
          "apz.axis_lock.mode" = 2; # Free scrolling mode
          "apz.enlarge_displayport_when_clipped" = true; # Preload content while scrolling
          
          # Input event optimizations - CRITICAL for reducing CPU spikes on clicks/typing
          "dom.input_events.security.minNumTicks" = 0; # Remove input throttling
          "dom.input_events.security.minTimeElapsedInMS" = 0;
          "dom.min_background_timeout_value" = 10; # Increase background timeout
          "dom.timeout.throttling_delay" = 0; # Remove throttling delay
          "layout.css.prefixes.animations" = false; # Disable CSS animation prefixes
          "layout.css.prefixes.transitions" = false; # Disable CSS transition prefixes
          "browser.tabs.remote.warmup.enabled" = false; # Disable tab warmup (causes CPU spikes)
          "browser.tabs.remote.warmup.maxTabs" = 0;
          "browser.urlbar.speculativeConnect.enabled" = false; # Disable speculative connections
          "browser.urlbar.suggest.quicksuggest.nonsponsored" = false; # Disable suggestions causing CPU spikes
          "browser.urlbar.suggest.quicksuggest.sponsored" = false;
          "browser.urlbar.suggest.searches" = false; # Disable search suggestions
          "browser.urlbar.suggest.engines" = false;
          "browser.urlbar.update1" = false;
          "browser.urlbar.update2.engineAliasRefresh" = false;
          "browser.urlbar.maxRichResults" = 5; # Limit results to reduce CPU load
          "browser.urlbar.trimURLs" = false; # Disable URL trimming processing
          "places.frecency.updateIdleTime" = 600000; # Reduce frecency updates (10min)
          
          # Session restore optimizations
          "browser.sessionstore.interval" = 60000; # Save session every 60s instead of 15s
          "browser.sessionstore.max_tabs_undo" = 5; # Reduce from default 25
          
          # Additional VM-specific optimizations
          "browser.chrome.site_icons" = true; # Enable favicons for better UX
          "browser.chrome.favicons" = true;
          "content.notify.interval" = 120000; # Balanced content rendering (120ms)
          "content.notify.ontimer" = true;
          "content.notify.backoffcount" = 5; # More backoff for stability
          "content.switch.threshold" = 750000; # Lower threshold for faster content switch
          "image.mem.decode_bytes_at_a_time" = 65536; # 64KB chunks
          "image.mem.discardable" = false; # Don't discard images to prevent disappearance
          "image.mem.max_decoded_image_kb" = 102400; # Increase to 100MB per decoded image
          "image.cache.size" = 10485760; # 10MB image cache
          "image.mem.surfacecache.max_size_kb" = 204800; # 200MB surface cache
          "image.mem.surfacecache.min_expiration_ms" = 120000; # Keep images for 2min
          "browser.cache.check_doc_frequency" = 3; # Check cache frequency
          "toolkit.scrollbox.smoothScroll" = true; # Enable smooth scroll in UI
          "toolkit.scrollbox.verticalScrollDistance" = 3; # Smoother scroll steps
          "widget.non-native-theme.enabled" = true; # Use non-native theme (less CPU intensive in VM)
          "widget.gtk.overlay-scrollbars.enabled" = false; # Disable overlay scrollbars
        };
      };

      # Pentesting profile - for security testing
      pentesting = {
        id = 1;
        isDefault = false;
        name = "Pentesting";

        # Pentesting extensions
        extensions.force = true; # Required if using settings

        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          foxyproxy-standard     # foxyproxy@eric.h.jung - proxy management
          # Wappalyzer has a problem at build
          #wappalyzer            # wappalyzer@crunchlabz.com - technology detection
          hacktools
        ];

        containers = {
          "Zap" = {
            id = 1;
            icon = "fingerprint";
            color = "blue";
          };
          "BurpSuite" = {
            id = 2;
            icon = "dollar";
            color = "red";
          };
        };

        extensions.settings = {
          "foxyproxy@eric.h.jung".settings = {
            mode = "disable";
            sync = false;
            autoBackup = false;
            passthrough = "";
            theme = "moonlight alt";
            container = {
              incognito = "";
              "container-1" = "127.0.0.1:8081";
              "container-2" = "127.0.0.1:8080";
              "container-3" = "";
              "container-4" = "";
            };
            commands = {
              setProxy = "";
              setTabProxy = "";
              quickAdd = "";
            };
            data = [
              {
                active = true;
                title = "BurpSuite";
                type = "http";
                hostname = "127.0.0.1";
                port = "8080";
                username = "";
                password = "";
                cc = "";
                city = "";
                color = "#ff7800";
                pac = "";
                pacString = "";
                proxyDNS = true;
                include = [];
                exclude = [];
                tabProxy = [];
              }
              {
                active = true;
                title = "Zap";
                type = "http";
                hostname = "127.0.0.1";
                port = "8081";
                username = "";
                password = "";
                cc = "";
                city = "";
                color = "#3584e4";
                pac = "";
                pacString = "";
                proxyDNS = true;
                include = [];
                exclude = [];
                tabProxy = [];
              }
            ];
          };
        };

        # Pentesting-specific settings - secure but flexible for testing
        settings = {
          # Browser and UI
          "browser.shell.checkDefaultBrowser" = false;
          "browser.contentblocking.category" = "standard"; # Less strict for testing but still protected
          "browser.download.always_ask_before_handling_new_types" = true; # Keep security
          "browser.theme.content-theme" = 0;
          "browser.theme.toolbar-theme" = 0;

          # Extensions
          "extensions.autoDisableScopes" = 0;
          "extensions.ui.extension.hidden" = false;

          "browser.uiCustomization.state" = "{\"placements\":{\"widget-overflow-fixed-list\":[],\"unified-extensions-area\":[],\"nav-bar\":[\"back-button\",\"forward-button\",\"stop-reload-button\",\"customizableui-special-spring1\",\"vertical-spacer\",\"urlbar-container\",\"customizableui-special-spring2\",\"save-to-pocket-button\",\"downloads-button\",\"fxa-toolbar-menu-button\",\"unified-extensions-button\",\"foxyproxy_eric_h_jung-browser-action\",\"_f1423c11-a4e2-4709-a0f8-6d6a68c83d08_-browser-action\"],\"toolbar-menubar\":[\"menubar-items\"],\"TabsToolbar\":[\"tabbrowser-tabs\",\"new-tab-button\",\"alltabs-button\"],\"vertical-tabs\":[],\"PersonalToolbar\":[\"personal-bookmarks\"]},\"seen\":[\"foxyproxy_eric_h_jung-browser-action\",\"developer-button\",\"_f1423c11-a4e2-4709-a0f8-6d6a68c83d08_-browser-action\"],\"dirtyAreaCache\":[\"unified-extensions-area\",\"nav-bar\",\"vertical-tabs\"],\"currentVersion\":21,\"newElementCount\":2}";

          # Privacy - keep essential protections
          "privacy.donottrackheader.enabled" = false; # Don't send DNT header when testing targets
          "privacy.fingerprintingProtection" = true; # Keep for your own protection
          "privacy.globalprivacycontrol.was_ever_enabled" = true;
          "privacy.history.custom" = true;
          "privacy.query_stripping.enabled" = true; # Keep for your protection
          "privacy.query_stripping.enabled.pbmode" = true;
          "privacy.trackingprotection.enabled" = false; # Disable only for target testing
          "privacy.trackingprotection.emailtracking.enabled" = true; # Keep for your protection
          "privacy.trackingprotection.socialtracking.enabled" = true; # Keep for your protection
          "privacy.annotate_channels.strict_list.enabled" = true;
          "privacy.bounceTrackingProtection.mode" = 1;

          # Network - secure but flexible
          "network.captive-portal-service.enabled" = false; # Keep disabled for security
          "network.connectivity-service.enabled" = false; # Keep disabled for security
          "network.dns.disableIPv6" = false; # Allow IPv6 for testing
          "network.http.speculative-parallel-limit" = 0; # Keep conservative
          "network.predictor.enabled" = false; # Keep disabled for security
          "network.prefetch-next" = false; # Keep disabled for security
          "network.trr.custom_uri" = "https://dns10.quad9.net/dns-query"; # Keep secure DNS
          "network.http.referer.disallowCrossSiteRelaxingDefault.top_navigation" = true;

          # Security - maintain core protections
          "security.tls.enable_0rtt_data" = false; # Keep secure
          "dom.security.https_only_mode" = false; # Allow HTTP for testing targets
          "dom.security.https_only_mode_ever_enabled" = true;
          "dom.private-attribution.submission.enabled" = false;

          # SafeBrowsing disabled (LibreWolf default)
          "browser.safebrowsing.downloads.remote.enabled" = false;
          "browser.safebrowsing.downloads.remote.block_potentially_unwanted" = false;
          "browser.safebrowsing.downloads.remote.block_uncommon" = false;

          # Forms and passwords - enable for pentesting credentials
          "dom.forms.autocomplete.formautofill" = false;
          "signon.rememberSignons" = true; # Save test credentials in pentesting profile
          "signon.generation.enabled" = true; # Enable password generation for testing
          "signon.management.page.breach-alerts.enabled" = false;

          # Developer tools - enhanced for pentesting but secure
          "devtools.cache.disabled" = true;
          "devtools.debugger.remote-enabled" = false; # Keep disabled for security
          "devtools.console.stdout.chrome" = false; # Keep secure
          "devtools.netmonitor.persistlog" = true;
          "devtools.chrome.enabled" = true; # Enable chrome debugging for analysis

          # Miscellaneous
          "findbar.highlightAll" = true;
          "intl.accept_languages" = "en-US, en";
          "javascript.use_us_english_locale" = true;
          "permissions.delegation.enabled" = false; # Keep disabled for security
          "toolkit.winRegisterApplicationRestart" = false;
          "sidebar.visibility" = "hide-sidebar";
        };
      };
    };
  };
}
