# Battery lifespan on laptops: kept between 20 and 80 %. Desktops without a battery (zeus) match nothing here.
{
  # Charging stops at 80 % and resumes below 70 %, set in the battery's firmware at boot, where its driver supports it
  # (geras: dell-laptop, BAT0; boreas: macsmc-battery, whose SMC keeps the start 5 below the end: 75 %). Matched by
  # type, not name; a peripheral's battery (mouse...) has no thresholds. The end first: the firmware keeps start below
  # end. Dell's thresholds only apply in its Custom mode (Adaptive by default).
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="power_supply", ATTR{type}=="Battery", ATTR{charge_control_end_threshold}=="?*", ATTR{charge_control_end_threshold}="80", ATTR{charge_control_start_threshold}="70"
    ACTION=="add", SUBSYSTEM=="power_supply", ATTR{type}=="Battery", ATTR{charge_types}=="*Custom*", ATTR{charge_types}="Custom"
  '';

  # The low battery warning at 20 %: Plasma's in modules/nixos/plasma, Cinnamon's in modules/nixos/cinnamon; GNOME's is
  # UPower's, 20 % by default.
}
