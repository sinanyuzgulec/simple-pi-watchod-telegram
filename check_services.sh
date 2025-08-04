#!/bin/bash

# === AYARLAR ===
BOT_TOKEN="token"
CHAT_ID="id"
SERVICES=("pihole-FTL" "cloudflared")
REPORT=()

# === ZAMAN ===
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')
REPORT+=("📅 Saat: $DATETIME")

# === SERVİS DURUMLARI ===
for service in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "$service"; then
        REPORT+=("✅ $service çalışıyor")
    else
        REPORT+=("❌ $service çalışmıyor")
    fi
done

# === WireGuard özel kontrol ===
if command -v wg &>/dev/null; then
    HANDSHAKES=$(wg show | grep -c "latest handshake")
    if [ "$HANDSHAKES" -gt 0 ]; then
        REPORT+=("✅ WireGuard bağlı ($HANDSHAKES peer)")
        PEER_INFO=$(wg show | awk '/peer:/{gsub("peer: ","");p=$0} /latest handshake:/{h=$3" "$4" "$5} /transfer:/{t=$0; print "✔️ "p" | "h" | "t"}')
        REPORT+=("$PEER_INFO")
    else
        REPORT+=("⚠️ WireGuard açık ama bağlantı yok (no handshake)")
    fi
else
    REPORT+=("❌ WireGuard komutu bulunamadı (wg)")
fi

# === SSH PORTU AÇIK MI ===
if nc -z 127.0.0.1 22; then
    REPORT+=("✅ SSH portu açık")
else
    REPORT+=("🔒 SSH portu kapalı")
fi

# === DISK DOLULUK ===
DISK_USAGE=$(df / | awk 'NR==2 {gsub("%",""); print $5}')
REPORT+=("💽 Disk kullanımı: %${DISK_USAGE}")

# === RAM DURUMU ===
MEM_FREE=$(free -m | awk '/^Mem/ {print $4}')
REPORT+=("🧠 RAM boş: ${MEM_FREE}MB")

# === CPU SICAKLIĞI (çoklu sistem desteği) ===
if command -v vcgencmd &>/dev/null; then
    TEMP=$(vcgencmd measure_temp | grep -o '[0-9.]*')
elif [ -f /etc/armbianmonitor/datasources/soctemp ]; then
    RAW=$(cat /etc/armbianmonitor/datasources/soctemp)
    TEMP=$(awk "BEGIN {printf \"%.1f\", $RAW/1000}")
elif [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    RAW=$(cat /sys/class/thermal/thermal_zone0/temp)
    TEMP=$(awk "BEGIN {printf \"%.1f\", $RAW/1000}")
else
    TEMP="bilinmiyor"
fi
REPORT+=("🌡️ CPU sıcaklığı: ${TEMP}°C")

# === INTERNET VAR MI ===
if ping -q -c 1 -W 2 1.1.1.1 >/dev/null; then
    REPORT+=("🌐 İnternet bağlantısı var")
else
    REPORT+=("🌐 İnternet bağlantısı yok (1.1.1.1 ping başarısız)")
fi

# === DÜŞÜK VOLTAJ KONTROLÜ ===
if command -v vcgencmd &>/dev/null; then
    if vcgencmd get_throttled | grep -q "0x50000"; then
        REPORT+=("⚡ Düşük voltaj tespit edildi (adaptör yetersiz olabilir)")
    else
        REPORT+=("⚡ Güç durumu normal")
    fi
fi

# === OCTOPRINT API CEVAP VERİYOR MU ===
if curl -s http://127.0.0.1:5000/api/version | grep -q "server"; then
    REPORT+=("🧩 OctoPrint API yanıt veriyor")
else
    REPORT+=("🛑 OctoPrint API cevap vermiyor")
fi

# === SISTEM UPTIME ===
UPTIME_MIN=$(awk '{print int($1/60)}' /proc/uptime)
REPORT+=("🕒 Uptime: ${UPTIME_MIN} dk")

# === cloudflared DNS çözüm testi ===
if command -v dig &>/dev/null; then
    if dig +short google.com @127.0.0.1 -p 5053 | grep -qE '^[0-9]+\.'; then
        REPORT+=("🧠 cloudflared DNS çözüyor (google.com)")
    else
        REPORT+=("❌ cloudflared DNS çözüm hatası → 127.0.0.1#5053")
    fi
else
    REPORT+=("⚠️ dig komutu yok → DNS testi atlandı")
fi

# === TELEGRAM BİLDİRİMİ ===
MESSAGE="🧭 Sistem Durum Özeti

$(printf '%s\n' "${REPORT[@]}")"

curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
    --data-urlencode "chat_id=$CHAT_ID" \
    --data-urlencode "text=$MESSAGE"
