# kubectl Configuration Module

This module provides automatic kubectl configuration for both k3s server and agent nodes.

## Architecture

### Problem
- **Server nodes**: Have admin credentials in `/etc/rancher/k3s/k3s.yaml`
- **Agent nodes**: Only have node-level credentials (NOT suitable for kubectl)

### Solution
A reusable blackmatter module with a Rust binary that configures kubectl for any node.

## Components

### 1. Nix Module (`default.nix`)

**Options:**
```nix
kubeconfigUsers = [ "user1" "user2" ];  # Users to configure kubectl for

kubeconfigSourceFile = ./path/to/admin-kubeconfig.yaml;  # Source kubeconfig
# - Server nodes: Defaults to /etc/rancher/k3s/k3s.yaml (auto)
# - Agent nodes: Must be set (assertion enforces this)
```

**Features:**
- Automatic role detection (server vs agent)
- Configurable source kubeconfig file
- Assertions to prevent misconfiguration
- Systemd service for setup
- Proper file ownership and permissions

### 2. Rust Binary (`k3s-kubeconfig-setup`)

**Purpose:** Transform source kubeconfig for user's environment

**Arguments:**
```
k3s-kubeconfig-setup <role> <server-addr> <user-home> <source-file>
```

**Transformations:**
- **Server mode**: Replace `127.0.0.1` → `localhost`
- **Agent mode**: Update server URL to point to remote API server, enable insecure-skip-tls-verify

**Output:** `~/.kube/config` with correct permissions (600)

## Usage

### Server Node (plo)

```nix
blackmatter.profiles.blizzard.k3s = {
  enable = true;
  role = "server";
  kubeconfigUsers = [ "luis" ];
  # kubeconfigSourceFile auto-defaults to /etc/rancher/k3s/k3s.yaml
};
```

### Agent Node (zek)

```nix
blackmatter.profiles.blizzard.k3s = {
  enable = true;
  serverAddr = "https://192.168.50.3:6443";
  tokenFile = "/var/lib/rancher/k3s/agent-token";
  kubeconfigUsers = [ "luis" ];

  # REQUIRED for agent nodes with kubectl users
  kubeconfigSourceFile = ./k3s-admin-kubeconfig.yaml;
};
```

## Setup Process for Agent Nodes

1. **Copy server's admin kubeconfig to agent node config:**

```bash
# On plo (or from any machine with access):
sudo cat /etc/rancher/k3s/k3s.yaml > ~/nexus/nix/nodes/zek/k3s-admin-kubeconfig.yaml

# Or use HTTP transfer:
# On plo: cd /etc/rancher/k3s && sudo python3 -m http.server 8888
# On zek: curl http://192.168.50.3:8888/k3s.yaml > ~/nexus/nix/nodes/zek/k3s-admin-kubeconfig.yaml
```

2. **Commit and rebuild:**

```bash
git add nix/nodes/zek/k3s-admin-kubeconfig.yaml
nix run .#rebuild
```

3. **Verify kubectl works:**

```bash
kubectl get nodes
```

## Security Considerations

### Current Implementation
- Kubeconfig stored in git (unencrypted)
- File permissions: 600 (readable only by owner)
- Network: Trusted LAN environment

### Production Hardening (Optional)
Use SOPS to encrypt the kubeconfig:

```bash
cd nix/nodes/zek/secrets
sops --encrypt ../k3s-admin-kubeconfig.yaml > secrets.yaml

# In configuration.nix:
sops.secrets.k3s-admin = {
  sopsFile = ./secrets/secrets.yaml;
  mode = "0600";
};

kubeconfigSourceFile = config.sops.secrets.k3s-admin.path;
```

## How It Works

1. **Build time:** Nix evaluates configuration, validates assertions
2. **Activation:** systemd service `k3s-kubeconfig-setup.service` starts
3. **Runtime:** Service waits for source kubeconfig, then for each user:
   - Runs Rust binary with appropriate parameters
   - Binary reads source, transforms based on role
   - Writes to `~/.kube/config` with correct permissions
4. **Result:** kubectl ready to use for all configured users

## Benefits

✅ **Reusable:** Same module works for server and agent nodes
✅ **Type-safe:** Assertions prevent misconfiguration
✅ **Declarative:** Everything in Nix configuration
✅ **Secure:** Proper permissions, SOPS-ready
✅ **Fast:** Rust binary for transformation logic
✅ **Maintainable:** Clear separation of concerns

## Troubleshooting

### Assertion error on rebuild
```
error: k3s agent nodes with kubectl users require kubeconfigSourceFile to be set
```
**Fix:** Set `kubeconfigSourceFile` option for agent nodes

### kubectl authentication fails
**Check:** Is the kubeconfig source file populated with real data?
```bash
cat ~/nexus/nix/nodes/zek/k3s-admin-kubeconfig.yaml
# Should contain actual certificate data, not placeholders
```

### Service fails to start
```bash
journalctl -u k3s-kubeconfig-setup.service
```
**Common issues:**
- Source file doesn't exist
- Source file has invalid YAML
- User doesn't exist
