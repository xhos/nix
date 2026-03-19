{config, ...}: {
  sops.secrets."wifi/aer" = {};

  networking.networkmanager = {
    enable = true;
    ensureProfiles = {
      environmentFiles = [config.sops.secrets."wifi/aer".path];
      profiles.aer = {
        connection.id = "aer";
        connection.type = "wifi";
        wifi.ssid = "aer";
        wifi-security.key-mgmt = "wpa-psk";
        wifi-security.psk = "$WIFI_AER_PSK";
      };
    };
  };
}
