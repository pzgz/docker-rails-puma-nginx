# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Production-ready Docker image for Rails applications with Ruby 3.4.5, Nginx, Puma, Sidekiq, and comprehensive security features including fail2ban and SSH key-only authentication.

## Key Features

- **Base**: Ruby 3.4.5 on Debian Bookworm
- **Web Server**: Latest Nginx with reverse proxy configuration
- **App Server**: Puma managed by supervisord
- **Background Jobs**: Sidekiq managed by supervisord
- **Security**: fail2ban with permanent IP banning, SSH key-only auth
- **Node.js**: v22 LTS with pnpm
- **Chinese Support**: zh_CN.UTF-8 locale, Chinese fonts, Shanghai timezone
- **Media Processing**: ImageMagick, libvips, ffmpeg, mupdf
- **Geospatial**: libgeos, libproj, GDAL
- **Process Manager**: Supervisord for managing all services

## Common Commands

### Docker Operations
```bash
# Build image
docker build -t docker-rails-app .

# Run with required capabilities for fail2ban
docker run -d \
  --cap-add=NET_ADMIN --cap-add=NET_RAW \
  -p 2222:22 -p 80:80 -p 443:443 \
  docker-rails-app

# Using docker-compose (recommended)
docker-compose up -d
docker-compose exec app bash
docker-compose logs -f app
```

### Service Management (using supervisord)
```bash
# Check all services
docker exec <container> supervisorctl status

# Restart services
docker exec <container> supervisorctl restart puma
docker exec <container> supervisorctl restart sidekiq
docker exec <container> supervisorctl restart nginx

# View service logs
docker exec <container> tail -f /var/log/supervisor/puma.stdout.log
docker exec <container> tail -f /var/log/supervisor/sidekiq.stdout.log
```

### Fail2ban Management
```bash
# Check banned IPs
docker exec <container> fail2ban-client status sshd-aggressive

# Unban IP (emergency)
docker exec <container> fail2ban-client unban --all

# View fail2ban logs
docker exec <container> tail -f /var/log/fail2ban.log
```

### Rails Operations
```bash
docker-compose exec app bundle exec rails db:migrate
docker-compose exec app bundle exec rails console
docker-compose exec app bundle exec rails test
```

## Project Structure

```
.
├── Dockerfile                 # Main container definition
├── docker-compose.yml        # Orchestration with DB and Redis
├── docker/
│   ├── supervisor/          # Process management
│   │   ├── supervisord.conf
│   │   └── conf.d/
│   │       ├── nginx.conf
│   │       ├── puma.conf
│   │       ├── sidekiq.conf
│   │       ├── sshd.conf
│   │       ├── rsyslog.conf
│   │       └── fail2ban.conf
│   ├── nginx/               # Nginx configuration
│   │   └── app.conf
│   ├── fail2ban/            # Security rules
│   │   ├── jail.local       # Permanent ban configuration
│   │   └── filter.d/        # SSH attack detection rules
│   └── ssh/                 # SSH configuration docs
│       └── README.md
└── app/                     # Rails application (mount point)
```

## Security Configuration

### SSH Access
- **Authentication**: Private key only (no passwords)
- **Root Login**: Allowed with key only
- **Port**: 22 (map to 2222 on host)
- **Protection**: fail2ban with aggressive rules

### Fail2ban Policy
- **Ban Duration**: Permanent (no auto-unban)
- **Jails**: sshd, sshd-aggressive, sshd-ddos
- **Detection**: Invalid users, failed passwords, protocol errors
- **Action**: Immediate permanent IP ban

## Running the Container

### Requirements
- Docker with capability support
- NET_ADMIN and NET_RAW capabilities for fail2ban
- Supervisord manages all services automatically

### Quick Start
```bash
# Clone repository
git clone <repo>
cd docker-rails-puma-nginx

# Build image
docker-compose build

# Add your SSH public key
echo "your-ssh-public-key" > docker/ssh/authorized_keys

# Start services
docker-compose up -d

# SSH into container
ssh -i ~/.ssh/your_key -p 2222 root@localhost
```

## Important Notes

1. **Process Management**: Supervisord automatically starts all services
2. **SSH Keys**: Mount or copy SSH public keys before deployment
3. **Fail2ban**: Bans are permanent - maintain whitelist carefully
4. **NPM Registry**: Configured to use Tencent mirror (China)
5. **App Path**: Rails app should be at `/home/app/current`
6. **Logs**: Available at `/home/app/current/log/` and `/var/log/supervisor/`

## Troubleshooting

### Container won't start
- Check Docker logs: `docker logs <container>`
- Verify supervisor configuration

### SSH connection refused
- Verify SSH keys are properly mounted
- Check fail2ban hasn't banned your IP
- Ensure port 2222 is mapped correctly

### Services not starting
- Check supervisor status: `supervisorctl status`
- Review logs in `/var/log/supervisor/`
- Ensure all dependencies are installed