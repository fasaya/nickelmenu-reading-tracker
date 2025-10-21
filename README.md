Installation

Connect Kobo via USB
Create directories:

bashmkdir -p /Volumes/KOBOeReader/.adds/kobo-stats-sync
mkdir -p /Volumes/KOBOeReader/.adds/nm

Copy files:

bash# Scripts
cp sync_stats.sh /Volumes/KOBOeReader/.adds/kobo-stats-sync/
cp config.env /Volumes/KOBOeReader/.adds/kobo-stats-sync/

# NickelMenu config

cp kobo-stats-sync /Volumes/KOBOeReader/.adds/nm/

# Make script executable

chmod +x /Volumes/KOBOeReader/.adds/kobo-stats-sync/sync_stats.sh

Edit config.env with your actual API credentials
Eject Kobo and restart

Usage
After restart, you'll see "Sync Reading Stats" in:

Main menu
Library menu

Just tap it to sync!
Auto-sync on WiFi (Optional)
Uncomment the last line in the NickelMenu config:
inichain_success :nickel_wifi_connected :cmd_spawn :quiet:/mnt/onboard/.adds/kobo-stats-sync/sync_stats.sh
This will auto-sync whenever WiFi connects!
