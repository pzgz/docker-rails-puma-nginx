FROM ruby:3.4.5-bookworm

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8 \
    TZ=Asia/Shanghai

# Update apt sources and install basic dependencies
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Add Nginx official repository for latest stable version
RUN curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor -o /usr/share/keyrings/nginx-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/debian $(lsb_release -cs) nginx" > /etc/apt/sources.list.d/nginx.list

# Add NodeSource repository for Node.js 22 LTS
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash -

# Install all required packages
RUN apt-get update && apt-get install -y \
    nginx \
    nodejs \
    imagemagick \
    libvips-dev \
    libvips-tools \
    libgeos-dev \
    libproj-dev \
    gdal-bin \
    ffmpeg \
    mupdf \
    mupdf-tools \
    openssh-server \
    fail2ban \
    iptables \
    rsyslog \
    supervisor \
    libxml2-dev \
    libxslt1-dev \
    unzip \
    git \
    vim \
    less \
    locales \
    locales-all \
    fonts-noto-cjk \
    fonts-noto-cjk-extra \
    fonts-wqy-microhei \
    fonts-wqy-zenhei \
    xfonts-wqy \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Configure locales
RUN sed -i '/zh_CN.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen zh_CN.UTF-8 && \
    update-locale LANG=zh_CN.UTF-8

# Set timezone
RUN ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata

# Install pnpm globally
RUN npm install -g pnpm@latest

# Configure npm registry for China
RUN npm config set registry https://mirrors.tencent.com/npm/ && \
    pnpm config set registry https://mirrors.tencent.com/npm/

# Create app user and directories
RUN useradd -m -s /bin/bash app && \
    mkdir -p /home/app/current && \
    chown -R app:app /home/app

# Configure SSH for key-only authentication
RUN mkdir -p /var/run/sshd /root/.ssh /home/app/.ssh && \
    chmod 700 /root/.ssh /home/app/.ssh && \
    chown app:app /home/app/.ssh && \
    sed -i 's/#PermitRootLogin .*/PermitRootLogin without-password/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication .*/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/#ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/UsePAM .*/UsePAM no/' /etc/ssh/sshd_config && \
    echo "AuthorizedKeysFile .ssh/authorized_keys" >> /etc/ssh/sshd_config

# Copy configuration files
COPY docker/nginx/app.conf /etc/nginx/conf.d/
COPY docker/fail2ban/jail.local /etc/fail2ban/
COPY docker/fail2ban/filter.d/*.conf /etc/fail2ban/filter.d/
COPY docker/supervisor/supervisord.conf /etc/supervisor/
COPY docker/supervisor/conf.d/*.conf /etc/supervisor/conf.d/

# Clean default nginx config and prepare directories
RUN rm -f /etc/nginx/conf.d/default.conf && \
    mkdir -p /var/run/fail2ban /var/log/supervisor /home/app/current/log && \
    touch /var/log/auth.log && \
    chmod 644 /var/log/auth.log && \
    chown -R app:app /home/app/current/log

# Set working directory
WORKDIR /home/app/current

# Expose ports
EXPOSE 22 80 443 3000

# Health check
# HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    # CMD curl -f http://localhost/ || exit 1

# Use supervisord to manage all services
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]