#!/bin/bash
# Script to append public keys to authorized_keys
KEYS_DIR="/app/ssh_keys"  # Diretório onde as chaves públicas serão armazenadas
if [ -d "$KEYS_DIR" ]; then
  for key in "$KEYS_DIR"/*.pub; do
    if [ -f "$key" ]; then
      cat "$key" >> /root/.ssh/authorized_keys
      echo "Added SSH key from $key"
    fi
  done
  # Remove duplicatas
  sort -u /root/.ssh/authorized_keys -o /root/.ssh/authorized_keys
fi
