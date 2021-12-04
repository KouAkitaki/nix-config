{ pkgs, ... }:
let
  port = 16160;
  highlighter = pkgs.writers.writePython3Bin "highlighter" {
    libraries = [ pkgs.python3Packages.pygments ];
  } (builtins.readFile ./highlighter.py);
in {
  # cgit server
  services.lighttpd = {
    inherit port;

    enable = true;
    cgit = {
      enable = true;
      subdir = "";
      configText = ''
        source-filter=${highlighter}/bin/highlighter
        about-filter=${pkgs.cgit}/lib/cgit/filters/about-formatting.sh
        cache-size=1000
        root-title=code.akitaki.tk
        root-desc=Akitaki's personal repos
        scan-path=/var/lib/gitolite/repositories
      '';
    };
  };
  users.users.lighttpd.extraGroups = [ "git" ];

  # gitolite server
  services.gitolite = {
    enable = true;
    dataDir = "/var/lib/gitolite";
    user = "git";
    group = "git";
    extraGitoliteRc = ''
      $RC{UMASK} = 0027;
    '';
    adminPubkey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCiYMcZU/6ypxuUkfaTs4nX2s5rXTZ15VSbz/ftMvUPrkX0wOAwg5DXEguQgQ4xtf/qLzsjb0W48mPB18dpqGyFYsP6tdty6wKZLjp2+INOoySApHmE0QuL3UtzF53jizsinwbBKFwe/hmRBcWIBtYaj0TJt8/a3I00nQJ/RmQiw930CE7n33UqjCePDJfiZltdRIHOh0SB9B0gPHO2R3U6HbXT4bKKav8ZuKcTswuGwPNwr4VAJ3q12Kl0qFCHJQ5JuHUYTYAUGE/JHaAjtrPIktUK2ElmATxhfFNm+AEd7YDypZlYT6kb6OMisjjVYwrOg/pkFtIl+zw8SgA8zBY493rKiw87yA/v/so6+W84uoNAfJfcq+DnQliCNWxWJTgdptYrMUeNsswX4oMXgmTx4TQ/qCxmqY/bXLnGOT+mg98XQcDMlhwizzRtlJ5NH3A8BwHCArtDnjGaQb9PS5vJjk3wNFfw4Ngmxv6wDW0a88TYsJUC7Myirnw557Kl4is= akitaki@rx570-nixos";
  };

  # nginx as reverse proxy
  security.acme.acceptTerms = true;
  security.acme.email = "robinhuang123@gmail.com";
  security.acme.certs."akitaki.tk".extraDomainNames = [
    "code.akitaki.tk"
  ];
  services.nginx = {
    enable = true;
    virtualHosts."akitaki.tk" = {
      addSSL = true;
      enableACME = true;
      root = "/var/www/akitaki.tk";
    };
    virtualHosts."code.akitaki.tk" = {
      forceSSL = true;
      useACMEHost = "akitaki.tk";
      locations."/" = {
        proxyPass = "http://localhost:${builtins.toString port}";
      };
    };
  };
}

