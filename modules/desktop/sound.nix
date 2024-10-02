{
  # Enable sound with pipewire

  sound.enable = true;
  security.rtkit.enable = true;
  hardware.pulseaudio.enable = false;

  services.pipewire.enable = true;
  services.pipewire.alsa.enable = true;
  services.pipewire.alsa.support32Bit = true;
  services.pipewire.pulse.enable = true;
  # If you want to use JACK applications, uncomment this
  #services.pipewire.jack.enable = true;

  # use the example session manager (no others are packaged yet so this is enabled by default,
  # no need to redefine it in your config for now)
  #services.pipewire.media-session.enable = true;
}
