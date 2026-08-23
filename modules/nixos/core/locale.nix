{lib, ...}: {
  i18n = {
    defaultLocale = "en_CA.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_CA.UTF-8";
      LC_IDENTIFICATION = "en_CA.UTF-8";
      LC_MEASUREMENT = "en_CA.UTF-8";
      LC_MONETARY = "en_CA.UTF-8";
      LC_NAME = "en_CA.UTF-8";
      LC_NUMERIC = "en_CA.UTF-8";
      LC_PAPER = "en_CA.UTF-8";
      LC_TELEPHONE = "en_CA.UTF-8";
      LC_TIME = "en_CA.UTF-8";
    };
  };

  time.timeZone = "America/Toronto";
  # keep the RTC in UTC; local-time RTC + hibernation leaves the clock wrong
  # on resume until NTP syncs, which breaks TLS on fresh networks. Windows
  # dual-boot hosts (vyverne) override this back to true.
  time.hardwareClockInLocalTime = lib.mkDefault false;
}
