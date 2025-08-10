# SSH Configuration

This container is configured for SSH access using **private keys only**. Password authentication is disabled for security.

## SSH Configuration Details

- **Root login**: Allowed with SSH key only
- **Password authentication**: Disabled
- **Public key authentication**: Enabled
- **PAM authentication**: Disabled

## How to Use

### 1. Generate SSH Key Pair (if you don't have one)
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_docker
```

### 2. Add Your Public Key to Container

#### Option A: Build-time (Add to Dockerfile)
```dockerfile
# Add your public key for root
COPY docker/ssh/authorized_keys /root/.ssh/authorized_keys
RUN chmod 600 /root/.ssh/authorized_keys

# Add your public key for app user
COPY docker/ssh/authorized_keys /home/app/.ssh/authorized_keys
RUN chmod 600 /home/app/.ssh/authorized_keys && \
    chown app:app /home/app/.ssh/authorized_keys
```

#### Option B: Runtime (Volume Mount)
```bash
# For root user
docker run -d \
  --privileged \
  -v ~/.ssh/id_rsa.pub:/root/.ssh/authorized_keys:ro \
  your-image

# For app user
docker run -d \
  --privileged \
  -v ~/.ssh/id_rsa.pub:/home/app/.ssh/authorized_keys:ro \
  your-image
```

#### Option C: Docker Compose
```yaml
version: '3.8'
services:
  app:
    build: .
    privileged: true
    volumes:
      - ~/.ssh/id_rsa.pub:/root/.ssh/authorized_keys:ro
      - ~/.ssh/id_rsa.pub:/home/app/.ssh/authorized_keys:ro
    ports:
      - "2222:22"
      - "80:80"
```

### 3. Connect to Container
```bash
# Connect as root
ssh -i ~/.ssh/id_rsa_docker -p 2222 root@localhost

# Connect as app user
ssh -i ~/.ssh/id_rsa_docker -p 2222 app@localhost
```

## Security Notes

1. **Never commit private keys** to your repository
2. Use different keys for different environments (dev, staging, production)
3. Regularly rotate SSH keys
4. Consider using SSH certificates for better security in production
5. Use firewall rules to restrict SSH access to trusted IPs only