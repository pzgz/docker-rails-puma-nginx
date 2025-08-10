# Fail2ban Configuration

This container includes fail2ban with **strict security policies** for SSH protection.

## Configuration Details

### Banning Policy
- **Ban Duration**: **PERMANENT** (no automatic unban)
- **Detection Window**: 1 hour
- **Max Attempts**: Varies by jail (1-5 attempts)

### Active Jails

#### 1. sshd (Standard SSH Protection)
- Max attempts: 2
- Monitors: Failed passwords, invalid users
- Action: Permanent ban after 2 failures

#### 2. sshd-aggressive (Enhanced Protection)
- Max attempts: 1
- Monitors: All suspicious SSH activities including:
  - Invalid user attempts
  - Failed passwords
  - Failed public key authentication
  - Connection resets/closes
  - Protocol negotiation failures
  - Break-in attempts
  - **Your requested rule**: `Invalid user .* from <HOST>`
- Action: Permanent ban after 1 failure

#### 3. sshd-ddos (DDoS Protection)
- Max attempts: 5 in 60 seconds
- Monitors: Rapid connection attempts
- Action: Permanent ban after threshold

## Management Commands

### Check Banned IPs
```bash
docker exec <container> fail2ban-client status sshd
docker exec <container> fail2ban-client status sshd-aggressive
docker exec <container> fail2ban-client status sshd-ddos
```

### View All Banned IPs
```bash
docker exec <container> fail2ban-client banned
```

### Manually Ban an IP
```bash
docker exec <container> fail2ban-client set sshd banip <IP>
```

### Manually Unban an IP (Emergency Only)
```bash
docker exec <container> fail2ban-client set sshd unbanip <IP>
docker exec <container> fail2ban-client set sshd-aggressive unbanip <IP>
docker exec <container> fail2ban-client set sshd-ddos unbanip <IP>
```

### View Logs
```bash
docker exec <container> tail -f /var/log/fail2ban.log
docker exec <container> tail -f /var/log/auth.log
```

## Important Notes

1. **No Automatic Unban**: IPs are banned permanently (`bantime = -1`)
2. **Whitelist**: Only localhost (127.0.0.1/8 and ::1) is whitelisted
3. **Persistent Bans**: Bans survive container restarts (stored in fail2ban database)
4. **Manual Unban Required**: Admin must manually unban IPs if needed

## Security Best Practices

1. **Monitor Logs Regularly**: Check fail2ban logs for attack patterns
2. **Backup Ban Database**: Keep backups of `/var/lib/fail2ban/fail2ban.sqlite3`
3. **Review False Positives**: Occasionally review banned IPs for false positives
4. **Update Filters**: Regularly update filter rules based on new attack patterns
5. **Test Before Production**: Test your SSH key access before enabling fail2ban

## Troubleshooting

### If You Lock Yourself Out
1. Stop the container
2. Start with fail2ban disabled:
   ```bash
   docker run --rm -it --entrypoint /bin/bash <image>
   fail2ban-client stop
   fail2ban-client unban --all
   ```
3. Or mount a volume to modify the database:
   ```bash
   docker run -v /path/to/backup:/backup <image>
   cp /backup/fail2ban.sqlite3 /var/lib/fail2ban/
   ```

### Check Filter Matches
```bash
docker exec <container> fail2ban-regex /var/log/auth.log /etc/fail2ban/filter.d/sshd-aggressive.conf
```