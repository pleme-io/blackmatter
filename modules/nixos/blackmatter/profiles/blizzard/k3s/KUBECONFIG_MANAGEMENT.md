# Unified Kubeconfig Management

**Single source of truth for kubeconfig across all nodes via blackmatter module.**

## Architecture

All kubeconfig management is handled by the `blackmatter.profiles.blizzard.k3s` module with two modes:

### Mode 1: Local K3s Cluster (Server/Agent Nodes)

For nodes running K3s locally (like `plo`):

```nix
blackmatter.profiles.blizzard.k3s = {
  enable = true;
  role = "server";  # or "agent"
  kubeconfigUsers = ["luis"];
};
```

**What happens:**
- K3s generates certificates in `/etc/rancher/k3s/k3s.yaml`
- Systemd service `k3s-kubeconfig-setup` copies them to `~/.kube/config`
- Users get automatic access to the local cluster

### Mode 2: Remote Cluster Access (Client Nodes)

For nodes that need to access a remote cluster (like `zek` accessing `plo`):

```nix
blackmatter.profiles.blizzard.k3s = {
  enable = false;  # No local K3s
  kubeconfigUsers = ["luis"];

  remoteCluster = {
    enable = true;
    clusterName = "plo";
    server = "https://192.168.50.3:6443";
    kubeconfig = /path/to/plo-kubeconfig.yaml;
  };
};
```

**What happens:**
- Systemd service `remote-kubeconfig-setup` copies the remote kubeconfig to `~/.kube/config`
- Users get automatic access to the remote cluster
- No K3s service runs locally

## Setup Guide

### Step 1: Configure plo (K3s Server)

`plo` automatically exports its kubeconfig to `/etc/k3s-admin-kubeconfig` (world-readable).

### Step 2: Copy plo's kubeconfig to other nodes

**Option A: Manual copy (simple)**
```bash
# On plo
scp /etc/k3s-admin-kubeconfig user@zek:/path/to/kubeconfig.yaml
```

**Option B: Store in git (for automation)**
```bash
# On plo
cp /etc/k3s-admin-kubeconfig ~/code/github/pleme-io/nexus/nix/nodes/common/plo-kubeconfig.yaml
cd ~/code/github/pleme-io/nexus
git add nix/nodes/common/plo-kubeconfig.yaml
git commit -m "Add plo kubeconfig for remote access"
```

**Option C: Use sops-nix (most secure)**
```bash
# Encrypt the kubeconfig
sops -e /etc/k3s-admin-kubeconfig > nix/secrets/plo-kubeconfig.yaml
```

### Step 3: Configure remote nodes

Example for `zek`:

```nix
# nix/nodes/zek/configuration.nix
{
  blackmatter.profiles.blizzard.k3s = {
    enable = false;  # No local K3s on zek
    kubeconfigUsers = ["luis"];

    remoteCluster = {
      enable = true;
      clusterName = "plo";
      server = "https://192.168.50.3:6443";
      kubeconfig = /path/to/plo-kubeconfig.yaml;
    };
  };
}
```

## Benefits

✅ **Single source of truth**: One module for all kubeconfig management
✅ **No ad-hoc scripts**: No more custom kubeconfig files in user configs
✅ **Automatic updates**: Systemd services handle setup on boot
✅ **Consistent**: Same approach for all nodes
✅ **Simple**: Just configure the module, no manual setup

## Migration Guide

### Remove old kubeconfig files

1. **plo**: Remove `nix/users/luis/plo/kubeconfig.nix` (already disabled)
2. **zek**: Remove `nix/nodes/zek/kubectl.nix` and `nix/nodes/zek/k3s.nix`
3. **Any other nodes**: Remove custom kubeconfig scripts

### Use blackmatter module only

Replace all custom kubeconfig setup with the unified blackmatter approach above.

## Troubleshooting

### Check service status
```bash
# Local K3s
systemctl status k3s-kubeconfig-setup

# Remote cluster
systemctl status remote-kubeconfig-setup
```

### Verify kubeconfig
```bash
cat ~/.kube/config
kubectl get nodes
```

### Force regeneration
```bash
# Local K3s
sudo systemctl restart k3s-kubeconfig-setup

# Remote cluster
sudo systemctl restart remote-kubeconfig-setup
```
