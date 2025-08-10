# Docker Configuration Files

This directory contains configuration files for the Docker image.

## Process Management

This image uses **Supervisord** for process management, which is the recommended approach for Docker containers.

**Features:**
- Works out of the box in Docker
- No special privileges required
- Easy to manage via supervisorctl
- RAILS_ENV is read from environment variable (defaults to 'production')
- Automatic restart of failed services
- Centralized logging in /var/log/supervisor/

**Usage:**
```bash
# Set RAILS_ENV at runtime
docker run -e RAILS_ENV=development ...

# Check service status
docker exec <container> supervisorctl status

# Restart a service
docker exec <container> supervisorctl restart puma

# View logs
docker exec <container> tail -f /var/log/supervisor/puma.stdout.log
```

## Configuration Files

### supervisor/
- `supervisord.conf`: Main supervisord configuration
- `conf.d/`: Service-specific configurations
  - `nginx.conf`: Web server configuration
  - `puma.conf`: Rails application server
  - `sidekiq.conf`: Background job processor
  - `sshd.conf`: SSH daemon
  - `rsyslog.conf`: System logging
  - `fail2ban.conf`: Intrusion prevention

### nginx/
- `app.conf`: Nginx site configuration for Rails app

### fail2ban/
- `jail.local`: Fail2ban jail configurations (permanent bans)
- `filter.d/`: Custom filter rules for SSH protection

### ssh/
- Configuration documentation for SSH key-only authentication

## Environment Variables

The supervisord configuration supports the following:

- `RAILS_ENV`: Rails environment (defaults to 'production')
  - Can be set to: production, development, staging, test
  - Set via docker run -e or docker-compose environment section

## Security Notes

1. **SSH Keys**: Never commit actual SSH keys to the repository
2. **Fail2ban**: Configured for permanent IP bans - be careful!
3. **Passwords**: All password authentication is disabled