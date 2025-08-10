# Docker Rails Puma Nginx

Production-ready Docker image for Rails applications with comprehensive features and security.

## Features

* Ruby 3.4.5 on Debian Bookworm
* Nginx (latest stable) as reverse proxy
* Puma application server
* Sidekiq background job processor
* Node.js v22 LTS with pnpm
* Supervisord for process management
* SSH server with key-only authentication
* Fail2ban with permanent IP banning
* Chinese language support (zh_CN.UTF-8)
* Shanghai timezone
* Image processing: ImageMagick, libvips
* Media processing: ffmpeg, mupdf
* Geospatial libraries: libgeos-dev, libproj-dev
* Database support: PostgreSQL, MySQL
* NPM registry: Tencent mirror (China)

## Quick Start

### Build the Image

```bash
docker build -t docker-rails-app .
```

### Run with Docker

```bash
docker run -d \
  --name rails-app \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  -p 2222:22 \
  -p 80:80 \
  -p 443:443 \
  -v ./app:/home/app/current \
  docker-rails-app
```

### Run with Docker Compose

```bash
docker-compose up -d
```

## Project Structure

```
.
├── Dockerfile                    # Container definition
├── docker-compose.yml           # Orchestration configuration
├── docker/
│   ├── supervisor/              # Process management
│   │   ├── supervisord.conf    # Main supervisor config
│   │   └── conf.d/             # Service configurations
│   │       ├── nginx.conf
│   │       ├── puma.conf
│   │       ├── sidekiq.conf
│   │       ├── sshd.conf
│   │       ├── rsyslog.conf
│   │       └── fail2ban.conf
│   ├── nginx/                  # Web server
│   │   └── app.conf            # Nginx site configuration
│   ├── fail2ban/               # Security
│   │   ├── jail.local          # Jail configurations
│   │   └── filter.d/           # Filter rules
│   └── ssh/                    # SSH configuration
│       └── README.md           # SSH setup instructions
└── app/                        # Rails application (mount point)
```

## Service Management

### Supervisord Commands

```bash
# Check service status
docker exec rails-app supervisorctl status

# Restart a service
docker exec rails-app supervisorctl restart puma

# Stop a service
docker exec rails-app supervisorctl stop sidekiq

# Start a service
docker exec rails-app supervisorctl start sidekiq

# View logs
docker exec rails-app tail -f /var/log/supervisor/puma.stdout.log
```

### Available Services

- **nginx**: Reverse proxy and static file server
- **puma**: Rails application server
- **sidekiq**: Background job processor
- **sshd**: SSH server for remote access
- **rsyslog**: System logging
- **fail2ban**: Intrusion prevention

## Security Configuration

### SSH Access

- Authentication: Private key only (no passwords)
- Root login: Allowed with key only
- Port: 22 (map to 2222 on host)

Add your SSH public key:
```bash
# Mount at runtime
docker run -v ~/.ssh/id_rsa.pub:/root/.ssh/authorized_keys:ro ...

# Or copy into image during build
COPY authorized_keys /root/.ssh/authorized_keys
```

### Fail2ban Configuration

- **Ban Duration**: Permanent (no automatic unban)
- **Detection Window**: 1 hour
- **Max Attempts**: 1-5 depending on jail
- **Jails**:
  - sshd: Standard SSH protection
  - sshd-aggressive: Enhanced protection (1 attempt = ban)
  - sshd-ddos: DDoS protection

Manage banned IPs:
```bash
# Check banned IPs
docker exec rails-app fail2ban-client status sshd-aggressive

# Unban an IP (emergency)
docker exec rails-app fail2ban-client unban --all
```

## Rails Application Setup

### Directory Structure

Your Rails application should be mounted at `/home/app/current`:

```
/home/app/current/
├── Gemfile
├── Gemfile.lock
├── config/
│   ├── puma.rb          # Puma configuration
│   ├── sidekiq.yml      # Sidekiq configuration
│   └── database.yml     # Database configuration
├── public/              # Static files served by Nginx
├── tmp/
│   └── sockets/
│       └── puma.sock    # Unix socket for Puma
└── log/                 # Application logs
```

### Environment Variables

Set these in docker-compose.yml or docker run:

```yaml
environment:
  - RAILS_ENV=production
  - DATABASE_URL=postgresql://user:pass@db:5432/app_production
  - REDIS_URL=redis://redis:6379/0
  - SECRET_KEY_BASE=your_secret_key
```

## Troubleshooting

### Container won't start
- Check Docker logs: `docker logs rails-app`
- Verify supervisor logs: `docker exec rails-app tail -f /var/log/supervisor/supervisord.log`

### SSH connection refused
- Verify SSH keys are properly mounted
- Check if your IP is banned by fail2ban
- Ensure port 2222 is mapped correctly

### Services not running
- Check supervisor status: `docker exec rails-app supervisorctl status`
- Review service logs in `/var/log/supervisor/`
- Verify configuration files are properly copied

### Puma/Sidekiq not starting
- Ensure Rails app is mounted at `/home/app/current`
- Check for missing gems: `docker exec rails-app bundle check`
- Verify database connection

## License

MIT License - See LICENSE file for details