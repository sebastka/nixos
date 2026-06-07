{ ... }:

{
  programs.htop = {
    enable = true;
    settings = {
      # Columns
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
}
