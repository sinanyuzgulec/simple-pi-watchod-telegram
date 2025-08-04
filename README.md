# TeleWatchdog 📡

Bash script for Linux-based systems (Raspberry Pi, Orange Pi, etc.) that sends system health reports to a Telegram bot.

## Features
- Pi-hole, cloudflared, WireGuard service monitoring
- CPU temp (multi-board compatible)
- Disk, RAM, uptime, internet connectivity
- OctoPrint API health
- Cloudflared DNS test
- Telegram message summary

## Setup
1. Edit `BOT_TOKEN` and `CHAT_ID` in `check_services.sh`
2. Make the script executable:
   ```bash
   chmod +x check_services.sh
