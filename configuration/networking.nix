{ pkgs, ... }:

{
  # Configurar DNS del sistema usando systemd-resolved
  home.file.".config/systemd-resolved.conf" = {
    text = ''
      [Resolve]
      DNS=9.9.9.9 149.112.112.112 1.1.1.1
      FallbackDNS=8.8.8.8
      DNSOverTLS=yes
      DNSSEC=allow-downgrade
      DNSStubListener=yes
      Cache=yes
    '';
  };

  # Script para aplicar configuración DNS al iniciar sesión
  home.activation.setupDNS = ''
    # Crear directorio para systemd-resolved si no existe
    $DRY_RUN_CMD mkdir -p ~/.config/systemd/

    # Copiar configuración a la ubicación del sistema (requiere sudo)
    if command -v sudo >/dev/null 2>&1; then
      $DRY_RUN_CMD sudo cp -f ~/.config/systemd-resolved.conf /etc/systemd/resolved.conf 2>/dev/null || true
      $DRY_RUN_CMD sudo systemctl restart systemd-resolved 2>/dev/null || true
    fi
    
    # También crear /etc/resolv.conf directo como fallback
    if command -v sudo >/dev/null 2>&1; then
      $DRY_RUN_CMD sudo tee /etc/resolv.conf > /dev/null <<EOF || true
nameserver 9.9.9.9
nameserver 149.112.112.112
nameserver 1.1.1.1
options timeout:2 attempts:3 rotate
EOF
    fi
  '';
}
