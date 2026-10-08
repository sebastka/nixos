{ ... }:

# htop's settings for every user and root (sudo htop): /etc/htoprc, which users' and root's ~/.config/htop/htoprc link
# to (modules/home/programs/htop, and below). Linked rather than absent: htop would save a copy of its own on exit,
# which would then ignore later changes here; it doesn't write a read-only one.
{
  programs.htop = {
    enable = true;
    settings = {
      # Columns
      fields = "0 48 17 18 38 39 40 2 46 47 49 1"; # PID USER PRIORITY NICE M_VIRT M_RESIDENT M_SHARE STATE CPU% MEM% TIME COMM
      highlight_megabytes = true;
      show_program_path = false;
      highlight_base_name = true;
      hide_kernel_threads = true;
      hide_userland_threads = true;

      # Sorting
      tree_view = true;
      tree_view_always_by_pid = true;
      sort_key = 46;
      sort_direction = -1;
      tree_sort_key = 46;
      tree_sort_direction = -1;

      # CPU meter details
      show_cpu_usage = true;
      show_cpu_frequency = true;
      show_cpu_temperature = true;
      degree_fahrenheit = false;
      detailed_cpu_time = true;

      # Header layout: two equal columns
      header_margin = true;
      header_layout = "two_50_50";
      column_meters_0 = "AllCPUs2 CPU";
      column_meter_modes_0 = "1 1";
      column_meters_1 = "Hostname System Uptime DateTime Blank LoadAverage LoadAverage Battery Blank MemorySwap MemorySwap Blank DiskIO DiskIO Blank NetworkIO NetworkIO";
      column_meter_modes_1 = "2 2 2 2 2 1 2 2 2 1 2 2 1 2 2 1 2";
    };
  };

  # root's (no home-manager)
  systemd.tmpfiles.rules = [
    "d /root/.config/htop 0700 root root -"
    "L+ /root/.config/htop/htoprc - - - - /etc/htoprc"
  ];
}
