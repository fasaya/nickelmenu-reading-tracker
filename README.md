## Important: SQLite3 Requirement

The scripts need to query the Kobo database. They will automatically try (in order):
1. Bundled `sqlite3` binary (if you download it)
2. System `sqlite3` command (if available on Kobo)
3. `python3` with sqlite module
4. `python` (Python 2) with sqlite module

**If your Kobo has none of these**, you have two options:

### Option A: Sync from Your Computer Instead
```bash
./sync_from_computer.sh
```
This queries the database on your Mac and sends to API (requires Kobo connected via USB).

### Option B: Download sqlite3 Binary for Kobo
See [SQLITE3_SETUP.md](SQLITE3_SETUP.md) for detailed instructions.

## Installation

### Quick Install (Recommended)

1. Connect Kobo via USB
2. Run the installer:
```bash
./install.sh
```
3. Edit config.env with your API credentials (if not already done)
4. Eject Kobo and restart

### Manual Install

1. Connect Kobo via USB
2. Create directories:
```bash
mkdir -p /Volumes/KOBOeReader/.adds/kobo-stats-sync
mkdir -p /Volumes/KOBOeReader/.adds/nm
```

3. Copy files:
```bash
# Scripts
cp kobo-stats-sync/sync_stats.sh /Volumes/KOBOeReader/.adds/kobo-stats-sync/
cp kobo-stats-sync/sync_stats_verbose.sh /Volumes/KOBOeReader/.adds/kobo-stats-sync/
cp kobo-stats-sync/query_db.py /Volumes/KOBOeReader/.adds/kobo-stats-sync/
cp kobo-stats-sync/config.env /Volumes/KOBOeReader/.adds/kobo-stats-sync/

# NickelMenu config
cp nm/kobo-stats-sync /Volumes/KOBOeReader/.adds/nm/

# Make scripts executable
chmod +x /Volumes/KOBOeReader/.adds/kobo-stats-sync/sync_stats.sh
chmod +x /Volumes/KOBOeReader/.adds/kobo-stats-sync/sync_stats_verbose.sh
chmod +x /Volumes/KOBOeReader/.adds/kobo-stats-sync/query_db.py
```

4. Edit config.env with your actual API credentials
5. Eject Kobo and restart

Usage
After restart, you'll see these menu items:

**Sync Reading Stats** - Shows a popup dialog with sync results
**Sync Stats (Verbose)** - Logs everything to a file for debugging

The dialog will show:
- How many books were found
- The API endpoint being used
- Success/failure status
- HTTP response code

Just tap either option to sync!

## Debugging

### Test from your computer
Run the API connection test to verify your backend is working:
```bash
./tests/test_api_connection.sh
```

This will send a sample payload to your API and show if it's receiving data correctly.

### Check Kobo logs

**Regular version** saves debug files to `/tmp/`:
- `/tmp/kobo-sync-payload.json` - The actual JSON being sent
- `/tmp/kobo-sync-response.log` - Full curl output and response

**Verbose version** saves everything to:
- `/mnt/onboard/.adds/kobo-stats-sync/sync.log` - Complete log with timestamps
- `/mnt/onboard/.adds/kobo-stats-sync/last_payload.json` - Last JSON payload

To view these files:
1. Connect Kobo via USB
2. Navigate to `.adds/kobo-stats-sync/` folder
3. Open the log files with a text editor

The verbose version is especially useful for troubleshooting because it keeps a permanent log file.

### Common issues
- **No internet connection**: Make sure WiFi is connected
- **No books found**: The script only syncs books with reading progress > 0%
- **API not receiving**: Check if your backend server is running
- **Wrong endpoint**: Verify `API_ENDPOINT` in `config.env`
- **Authentication failed**: Check if `API_KEY` matches backend

Auto-sync on WiFi (Optional)
Uncomment the last line in the NickelMenu config:
```
chain_success :nickel_wifi_connected :cmd_spawn :quiet:/mnt/onboard/.adds/kobo-stats-sync/sync_stats.sh
```
This will auto-sync whenever WiFi connects!
