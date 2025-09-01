# Gekkou

Nix configuration based on [Ripper](https://github.com/PunkerGhoul/Ripper), but it uses Determinate Nix and Hyprland.

## Installation

1. Install Determinate Nix

    ```bash
    curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate --no-confirm
    ```

2. Clone the repository and apply the configuration:

    ```bash
    git clone https://github.com/PunkerGhoul/Gekkou.git
    cd gekkou
    cp env.example.nix env.nix
    nano env.nix
    ./setup.sh && nix run home-manager/master -- switch --flake $HOME/.config/Gekkou --impure -b backup
    ```

> [!TIP]
> Do not forget to **REBOOT** after the installation!
> Although you can just logout and log back in, a reboot is recommended.

## Usage

If you make changes to the configuration, you can apply them by running:

```bash
./setup.sh && nix run home-manager/master -- switch --flake $HOME/.config/Gekkou --impure -b backup
```

> [!NOTE]
> Depending on the changes you have made, you may not need to restart the system, log out, or restart Hyprland.

Para actualizarlo usar

```bash
git add . && git commit --amend --no-edit && git push -f origin main
```
