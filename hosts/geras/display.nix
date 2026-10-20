{ config, lib, ... }:

# The 4K screen at 150 %, with Cinnamon (modules/nixos/cinnamon): its settings and Muffin's monitor configuration, only
# read by Cinnamon, so only set with it.
lib.mkIf config.services.xserver.desktopManager.cinnamon.enable {
  # Fractional scaling (experimental, X11: through xrandr), as System Settings > Display sets it, by default for every
  # user...
  programs.dconf.profiles.user.databases = [
    {
      settings."org/cinnamon/muffin".experimental-features = [
        "scale-monitor-framebuffer"
        "x11-randr-fractional-scaling"
      ];
    }
  ];

  # ... and the scale, in Muffin's system monitor configuration (/etc/xdg/monitors.xml): used when the screens match it
  # (the built-in one alone, here), unless the user's ~/.config/cinnamon-monitors.xml has its own (Display settings).
  environment.etc."xdg/monitors.xml".text = ''
    <monitors version="2">
      <configuration>
        <logicalmonitor>
          <x>0</x>
          <y>0</y>
          <scale>1.5</scale>
          <primary>yes</primary>
          <monitor>
            <monitorspec>
              <connector>eDP-1</connector>
              <vendor>SDC</vendor>
              <product>0xa029</product>
              <serial>0x00000000</serial>
            </monitorspec>
            <mode>
              <width>3840</width>
              <height>2160</height>
              <rate>60.000205993652344</rate>
            </mode>
          </monitor>
        </logicalmonitor>
      </configuration>
    </monitors>
  '';
}
