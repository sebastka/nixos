# NixOS

[![CI](https://github.com/sebastka/nixos/actions/workflows/ci.yaml/badge.svg)](https://github.com/sebastka/nixos/actions/workflows/ci.yaml)
[![Update dependencies](https://github.com/sebastka/nixos/actions/workflows/update.yaml/badge.svg)](https://github.com/sebastka/nixos/actions/workflows/update.yaml)

NixOS configuration (flake) for my machines, with home-manager for the user environment, sops-nix for secrets and
Yubikeys for disk unlocking, SSH and signing.

## Hosts

| Host | Hardware | Role | Status |
|---|---|---|---|
| `geras` | Dell XPS 15 7590 (x86_64) | Desktop (KDE Plasma) | Installed |
| `zeus` | Tower: Gigabyte X570 AORUS XTREME, Ryzen 9 5950X, Radeon RX 6800 XT (x86_64) | Desktop (KDE Plasma), dual boot with Windows | Not installed yet (Linux Mint) |
| `boreas` | MacBook Pro 14" 2021, M1 Pro (j314s; aarch64, Asahi) | Desktop (KDE Plasma), dual boot with macOS | Not installed yet (Fedora Asahi Remix) |
| `hermes` | Raspberry Pi 4 Model B, 8 GB (aarch64) | Server: Zabbix agent, firewall (`modules/nixos/server`) | Not installed yet (Debian 13) |
| `helios` | Protectli FW6: i5-8250U, 16 GB, 6x I211 (x86_64) | Router: NAT and firewall, DHCP (Kea), DNS (Unbound, NSD) | Not installed yet (Debian 13, Ansible) |

Each host's install steps are at the top of its `hosts/<host>/default.nix`.

## Layout

```
flake.nix              Inputs, hosts (nixosConfigurations), pkgs/ as packages and checks, devShell
hosts/<host>/          Per-host configuration (hardware, disko, Secure Boot, impermanence...)
modules/nixos/
  common/              Every host: nix, boot, locale, sops-nix, users, OpenSSH server
  desktop/             Desktops: Plasma, PipeWire, NetworkManager (Wi-Fi from sops), GnuPG, SSH agent, fonts
  server/              Servers: systemd-networkd, resolved, unattended upgrades
  home-manager/        home-manager integration, modules shared by every user
modules/home/          home-manager modules: zsh, starship, git, gpg, ssh, neovim, vim, htop, readline, direnv, XDG...
users/<user>/          User account, identities (keys/, SSH, git, GnuPG), per-host and desktop additions
pkgs/                  Packages built from upstream release binaries (both architectures), updated nightly
secrets/               sops-encrypted secrets (see Secrets)
scripts/               install.sh, build.sh, update.sh, update-pkgs.sh
.github/               CI, nightly updates, Dependabot
```

## Usage

The repository includes a development shell with the tools to work on it (`sops`, `ssh-to-age`, `sbctl`, `nixfmt`,
`shellcheck`, `yamllint`), loaded automatically by direnv (`direnv allow` once), or with `nix develop`.

| Task | Command | Changes the code |
|---|---|---|
| Deploy | `scripts/build.sh` | no |
| Update dependencies | `scripts/update.sh` (also done nightly by CI) | yes |
| Check | `nix flake check`, then evaluate the hosts (see CI) | no |
| Install a host | `scripts/install.sh <host>` from the NixOS live ISO | no |

- **`scripts/build.sh`** pulls `origin/master` (fast-forward only, on `master`), then runs `nixos-rebuild switch`
  locally or over SSH (`--target-host`). It never writes `flake.lock` (`--no-update-lock-file`). For now it only
  deploys `geras`.
- **`scripts/update.sh`** runs `nix flake update`, `scripts/update-pkgs.sh` (latest release and hashes of each
  package in `pkgs/`, plus `vendorHash` for the PHP ones), and prints a Markdown summary. Locally on `master`, it pulls `origin/master` first.
- **`nix flake check`** builds `pkgs/` for the current system. It doesn't fully evaluate the NixOS configurations, so
  CI also evaluates each host's `config.system.build.toplevel.drvPath`:

  ```sh
  for host in hosts/*/; do
    nix eval --raw ".#nixosConfigurations.$(basename "$host").config.system.build.toplevel.drvPath"; echo
  done
  ```

## Automation (GitHub Actions)

| Workflow | When | What |
|---|---|---|
| `ci.yaml` | Push to `master`, pull requests | yamllint and shellcheck (devShell tools), `nix flake check` on x86_64 and aarch64, host evaluation. Merges Dependabot pull requests once everything passed. |
| `update.yaml` | Nightly (02:00 UTC), manually | `scripts/update.sh`, the same checks on both architectures, then opens a signed pull request and merges it. |
| Dependabot | Weekly | Updates the actions (pinned by commit), only releases at least 7 days old. |

Servers deploy what is merged on `master` by themselves (`system.autoUpgrade`, rebooting between 04:00 and 06:00 when
the kernel changed). Desktops are deployed with `scripts/build.sh`.

## Installing a host

Example: `geras` (disk layout in `hosts/geras/disko.nix`, Secure Boot keys and SSH host key pre-generated in
`secrets/`).

1. **Firmware:** in the Secure Boot settings (Dell: Expert Key Management, Custom Mode), delete only the **PK** to
   enter Setup Mode. Keep `dbx`, and keep Secure Boot enabled.
2. **Yubikey:** set a FIDO2 PIN if needed (`ykman fido access change-pin`), it unlocks the disk.
3. **Live ISO:** boot the NixOS ISO, then:

   ```sh
   git clone https://github.com/sebastka/nixos.git && cd nixos
   lsblk                     # check the disk in hosts/<host>/disko.nix
   scripts/install.sh geras
   ```

   The script sets up GnuPG and pcscd for the Yubikey, decrypts the host's install secrets (before touching the
   disk), wipes and partitions the disk with disko, enrolls the Yubikey (FIDO2) for LUKS, restores the SSH host key and
   Secure Boot keys, and runs `nixos-install`.
4. **First boot:** unlock the disk with the Yubikey (PIN and touch; the LUKS passphrase is the fallback). Lanzaboote
   stages the Secure Boot keys and reboots, then systemd-boot enrolls them (with Microsoft's keys, needed by the NVIDIA
   option ROM). Check with `bootctl status` (`Secure Boot: enabled (user)`) or `sudo sbctl status`.
5. **User session:** run `gpg --card-status` once per Yubikey (links the GnuPG subkeys to the cards, SSH included).

### `zeus` (dual boot with Windows)

NixOS takes the Samsung 970 EVO Plus 500 GB (Linux Mint before, wiped with its exFAT partition), with its own ESP. The
Windows disks (980 PRO 500 GB with Windows' ESP, 980 PRO 2 TB) are never touched. Differences from the steps above:

- **Before, in Windows:** save the BitLocker recovery keys of both drives (`manage-bde -protectors -get C:`), then
  suspend BitLocker on `C:` (`Suspend-BitLocker -MountPoint C: -RebootCount 0`, as administrator). Enrolling our
  Secure Boot keys changes what the TPM measures, so Windows would otherwise ask for the recovery key.
- **Firmware (Gigabyte):** CSM disabled. Secure Boot mode Custom, then in key management delete only the **PK**
  (Setup Mode). Keep `dbx`.
- **Live ISO:** `lsblk` must show the 970 EVO Plus (serial `S4EVNS0N905239P`, `hosts/zeus/disko.nix`) as the disk with
  Mint's partitions: it's the only disk disko wipes.
- **Disk unlock:** the passphrase by default (no waiting for a Yubikey). The Yubikey enrolled by `scripts/install.sh`
  still works when plugged in at boot (PIN and touch).
- **Windows:** NixOS is the default boot entry. Windows is picked in the firmware boot menu (F12), or from NixOS
  with `sudo efibootmgr --bootnext <number of "Windows Boot Manager">` and a reboot. Our Secure Boot keys include
  Microsoft's, so Windows still boots. Once it did, resume BitLocker (`Resume-BitLocker -MountPoint C:`).
- **Cleanup:** Mint left `\EFI\ubuntu` on Windows' ESP and an "Ubuntu" boot entry: `sudo efibootmgr -b <number> -B`.

## Secrets (sops-nix)

| File | Content | Encrypted for |
|---|---|---|
| `secrets/common.sops.yaml` | User password hashes | GnuPG key, every host |
| `secrets/desktop.sops.yaml` | NetworkManager Wi-Fi PSKs (`nm-wifi-env`), bws inboxcom config (`bws-inboxcom-config`) | GnuPG key, desktops |
| `secrets/ssh-work.sops.yaml` | Work SSH hosts (`ssh-work-config`, linked as `~/.ssh/config.d/work.conf`) and their keys (`ssh-work-known-hosts`, `~/.ssh/known_hosts.d/inboxcom`) | GnuPG key, desktops |
| `secrets/tern.sops.yaml` | Tern account files and signatures, names included: a `files` list of `path`/`content` (`users/sebastian/tern.nix`) | GnuPG key, desktops |
| `secrets/<host>-ssh-host-key.sops.yaml` | The host's SSH host key (also its age identity) | GnuPG key only |
| `secrets/<host>-secure-boot.sops.yaml` | The host's Secure Boot keys (PK, KEK, db) | GnuPG key only |

Recipients are defined in `.sops.yaml`. Hosts decrypt with the age key derived from their SSH host key; the host key
and Secure Boot files are only used at install time, by `scripts/install.sh`.

Plaintext copies follow the `secrets/.<name>.sops.yaml` naming (git-ignored), and encrypt to `secrets/<name>.sops.yaml`:

```sh
sops encrypt secrets/.common.sops.yaml > secrets/common.sops.yaml   # Encrypt a plaintext copy
sops edit secrets/common.sops.yaml                                  # Or edit in place (Yubikey)
for f in secrets/*.sops.yaml; do sops updatekeys "$f"; done         # After changing recipients
```

**Adding a host:** generate its SSH host key, add `ssh-to-age < ssh_host_ed25519_key.pub` as a recipient in
`.sops.yaml`, run `sops updatekeys`, store the key in `secrets/<host>-ssh-host-key.sops.yaml`, and add it to
`programs.ssh.knownHosts` (`modules/nixos/common/openssh.nix`).

## Yubikeys

Two Yubikeys: personal (`private`) and work (`inboxcom`).

| Use | Yubikey application | Details |
|---|---|---|
| Disk unlock (LUKS) | FIDO2 | PIN and touch at boot, passphrase as fallback (`crypttabExtraOpts`) |
| SSH | OpenPGP (authentication subkey) | Through gpg-agent (`SSH_AUTH_SOCK`), PIN once. Public keys in `users/sebastian/keys/*.id_ed25519_gpg.pub` |
| Commit signing, sops | OpenPGP | Personal key by default, work key in `~/Dev/Work/` (`users/sebastian/work.nix`, desktops) |

SSH, commit signing and sops all use the OpenPGP applet through gpg-agent and scdaemon: one PIN, no applet switching
(which would log the card out). GnuPG and `ykman` share the cards through pcscd.

## Per-project environment (`.envrc`)

[direnv](https://direnv.net) loads a project's `.envrc` when entering its directory (run `direnv allow` after
creating or changing it). The variables below switch tools from their default account to another one.

### Bitwarden

Two password manager (`bw`) accounts are configured (`users/sebastian/desktop.nix`, work: `users/sebastian/work.nix`), and one
Secrets Manager (`bws`) account:

| Account | Server | `bw` | `bws` |
|---|---|---|---|
| `private` | bitwarden.com | default | — |
| `inboxcom` | vault.bitwarden.eu | ✓ | ✓ |

| Variable | Tool | Value | Default |
|---|---|---|---|
| `BITWARDENCLI_APPDATA_DIR` | `bw` | `$XDG_DATA_HOME/bitwarden-cli/<account>` | `private` |
| `BWS_CONFIG_FILE` | `bws` | `$XDG_CONFIG_HOME/bws/inboxcom.config` | none: set it |
| `BWS_ACCESS_TOKEN` | `bws` | machine account access token | none: **secret** |
| `BW_SESSION` | `bw` | output of `bw unlock --raw` | none: **secret** |

Example `.envrc` for a work project:

```sh
# Bitwarden: inboxcom account
export BITWARDENCLI_APPDATA_DIR="$XDG_DATA_HOME/bitwarden-cli/inboxcom"
export BWS_CONFIG_FILE="$XDG_CONFIG_HOME/bws/inboxcom.config"

# Secrets (BWS_ACCESS_TOKEN...) never go in .envrc: keep them in an untracked file (in the project's .gitignore)
source_env_if_exists .envrc.local
```

Notes:

- Each `bw` account keeps its own login: run `bw login` once per account (with its `BITWARDENCLI_APPDATA_DIR`), then
  `export BW_SESSION="$(bw unlock --raw)"` in the shell when needed. A session only unlocks the account it was
  created for.
- `bws/inboxcom.config` is a sops secret (`bws-inboxcom-config` in `secrets/desktop.sops.yaml`); the token is always
  read from `BWS_ACCESS_TOKEN`.
- Work credentials (`BWS_ACCESS_TOKEN`, `MAILCORE_API_KEY`...) are never in this repository, not even encrypted: it is
  public. They stay in the inboxcom vault, e.g. in `.envrc.local`, with the inboxcom `BITWARDENCLI_APPDATA_DIR` and
  an unlocked session (`BW_SESSION`): `export BWS_ACCESS_TOKEN="$(bw get password <item>)"`.

## Known caveats

- **Hibernation after a kernel update:** reboot before hibernating. Otherwise the next boot starts the new kernel,
  which refuses the hibernation image of the old one, and the session is lost.
- **Hibernation and Bitwarden desktop:** while it runs, it holds `memfd_secret` memory, which disables hibernation
  (`disk` disappears from `/sys/power/state`). Quit it, or hibernation (and suspend-then-hibernate) is unavailable.
- **NVIDIA dGPU on geras:** powered off by kernel runtime PM (no driver bound, see `hosts/geras/default.nix`). Never
  combine it with bbswitch: both at boot froze the machine.
- **Impermanence** (`hosts/geras/impermanence.nix`) is prepared but disabled.
