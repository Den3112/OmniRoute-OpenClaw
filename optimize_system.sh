#!/bin/bash

# Network optimizations for high-load AI Gateway
echo "[SYSTEM] Applying network and kernel optimizations..."

# Increase max open files
if ! grep -q "soft nofile 65535" /etc/security/limits.conf; then
    echo "* soft nofile 65535" | sudo tee -a /etc/security/limits.conf
    echo "* hard nofile 65535" | sudo tee -a /etc/security/limits.conf
fi

# Sysctl tweaks
cat <<EOF | sudo tee /etc/sysctl.d/99-omniroute-speed.conf
# Increase max backlog for connections
net.core.somaxconn = 4096
net.ipv4.tcp_max_syn_backlog = 4096

# Expand local port range for high concurrency
net.ipv4.ip_local_port_range = 1024 65535

# Reuse sockets in TIME_WAIT state
net.ipv4.tcp_tw_reuse = 1

# Increase memory limits for TCP buffers
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# Increase max pending connections
net.core.netdev_max_backlog = 5000

# Increase max user watches for file monitoring
fs.file-max = 2097152
fs.inotify.max_user_watches = 524288
EOF

# Apply sysctl settings
sudo sysctl -p /etc/sysctl.d/99-omniroute-speed.conf

echo "[SYSTEM] Done! High-performance settings applied."
