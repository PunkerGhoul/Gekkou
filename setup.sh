#!/bin/env bash
set -euo pipefail

USERNAME=$(/bin/id -un)
ARCHITECTURE="x86_64-linux"
SRC_DIR=$(pwd)
REPO_NAME=$(/bin/basename "$SRC_DIR")
DEST="$HOME/.config/Gekkou"

TMP_BACKUP="/tmp/gekkou-backup-$$"
CREATED_DIRS=()
MODIFIED_FILES=()
PERMISSIONS_BACKUP="$TMP_BACKUP/perms.txt"
CREATED_GROUP=false
ADDED_TO_GROUP=false

EXCLUTIONS=(
  ".git" ".gitignore" ".github" ".devcontainer"
  "README.md" "CONTRIBUTING.md" "LICENSE"
  "env.example.nix" "setup.sh"
)
EXC_ARGS=()
for EXCLUTION in "${EXCLUTIONS[@]}"; do
  EXC_ARGS+=(--exclude="$EXCLUTION")
done

/bin/mkdir -p "$TMP_BACKUP"

RED=$(/bin/tput setaf 1)
GREEN=$(/bin/tput setaf 2)
YELLOW=$(/bin/tput setaf 3)
BLUE=$(/bin/tput setaf 4)
RESET=$(/bin/tput sgr0)

error_exit() {
    echo "${RED}[ERROR]${RESET} $1"
    exit 1
}

rollback() {
    echo "${YELLOW}[ROLLBACK]${RESET} Reverting changes..."
    for f in "${MODIFIED_FILES[@]}"; do
        backup_file="$TMP_BACKUP/$(/bin/basename "$f")"
        [ -f "$backup_file" ] && /bin/cp -f "$backup_file" "$f"
    done
    if [ -f "$PERMISSIONS_BACKUP" ]; then
        while read -r perm owner group file; do
            [ -e "$file" ] && /bin/chmod "$perm" "$file" && /bin/chown "$owner:$group" "$file"
        done < "$PERMISSIONS_BACKUP"
    fi
    for d in "${CREATED_DIRS[@]}"; do
        [ -d "$d" ] && /bin/rm -rf "$d"
    done
    if [ "$CREATED_GROUP" = true ]; then
        /bin/sudo /sbin/groupdel gekkou || true
    elif [ "$ADDED_TO_GROUP" = true ]; then
        /bin/sudo gpasswd -d "$USERNAME" gekkou || true
    fi
    /bin/rm -rf "$TMP_BACKUP" || true
    echo "${YELLOW}[ROLLBACK]${RESET} Done"
}

trap rollback ERR

check_root() {
    if [ "$(/bin/id -u)" -eq 0 ]; then
        error_exit "This script shouldn't be executed as root"
    fi
}

check_env_file() {
    if [ ! -f "$SRC_DIR/env.nix" ] || [ "$SRC_DIR/env.nix" = "$SRC_DIR/env.example.nix" ]; then
        error_exit "File env.nix doesn't exist or has the same content as env.example.nix"
    fi
}

install_dependencies() {
    echo "${BLUE}[INFO]${RESET} Installing dependencies..."
    if command -v /bin/apt >/dev/null; then
        /bin/sudo /bin/apt update -qq
        /bin/sudo /bin/apt install -y curl git passwd sudo xz-utils rsync
    elif command -v /bin/pacman >/dev/null; then
        /bin/sudo /bin/pacman -Sy --noconfirm --needed curl git shadow sudo xz rsync
    else
        error_exit "Unsupported package manager. Install curl, git, passwd, sudo, xz, rsync manually."
    fi
}

backup_file() {
    local file="$1"
    [ -f "$file" ] || return
    /bin/cp "$file" "$TMP_BACKUP/$(/bin/basename "$file")"
    MODIFIED_FILES+=("$file")
}

backup_permissions() {
    if [ -d "$DEST" ]; then
        /bin/find "$DEST" -exec stat -c "%a %U %G %n" {} \; > "$PERMISSIONS_BACKUP" 2>/dev/null || true
    fi
}

update_flake_vars() {
    backup_file "$SRC_DIR/flake.nix"
    /bin/sed -i "s/USERNAME_VAR/$USERNAME/" "$SRC_DIR/flake.nix"
    /bin/sed -i "s/ARCHITECTURE_VAR/$ARCHITECTURE/" "$SRC_DIR/flake.nix"
}

sync_files() {
    if [ -d "$DEST" ]; then
        while IFS= read -r file; do
            /bin/cp --parents "$file" "$TMP_BACKUP/" || true
        done < <(find "$DEST" -type f)
    fi
    /bin/mkdir -p "$DEST"
    CREATED_DIRS+=("$DEST")
    backup_permissions
    /bin/sudo /bin/rsync -av --delete "${EXC_ARGS[@]}" "$SRC_DIR/" "$DEST/"
}

setup_group() {
    if /bin/getent group gekkou >/dev/null; then
        CREATED_GROUP=false
    else
        /bin/sudo /sbin/groupadd gekkou
        CREATED_GROUP=true
    fi
    if /bin/id -nG "$USERNAME" | /bin/grep -qw gekkou; then
        ADDED_TO_GROUP=false
    else
        /bin/sudo /sbin/usermod -aG gekkou "$USERNAME"
        ADDED_TO_GROUP=true
    fi
}

set_permissions() {
    /bin/sudo /bin/find "$DEST" -type f ! -name "flake.lock" -exec /bin/chmod 640 {} \; -exec /bin/chown root:gekkou {} \;
    if [ -f "$DEST/flake.lock" ]; then
        /bin/sudo /bin/chown root:gekkou "$DEST/flake.lock"
        /bin/sudo /bin/chmod 660 "$DEST/flake.lock"
    fi
    /bin/sudo /bin/find "$DEST" -type d -exec /bin/chmod 750 {} \; -exec /bin/chown root:gekkou {} \;
}

finish() {
    if [ -f "$TMP_BACKUP/flake.nix" ]; then
        /bin/cp -f "$TMP_BACKUP/flake.nix" "$SRC_DIR/flake.nix"
    fi
    /bin/rm -rf "$TMP_BACKUP"
    echo "${GREEN}[DONE]${RESET} Files copied from $SRC_DIR to $DEST, excluding some files."
    echo "${GREEN}[DONE]${RESET} Run '/nix/var/nix/profiles/default/bin/nix run home-manager/master -- switch --flake $DEST --impure -b backup'"
    if [ "$ADDED_TO_GROUP" = true ]; then
        echo "${BLUE}[INFO]${RESET} Switching to new group immediately..."
        exec su -l "$USERNAME"
    fi
}

check_root
install_dependencies
check_env_file
update_flake_vars
sync_files
setup_group
set_permissions
finish

