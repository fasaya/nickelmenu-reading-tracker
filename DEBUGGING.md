# Debugging Guide

## Understanding the Output

### NickelMenu Actions Explained

- `:cmd_output :500:` - Shows script output in a popup dialog for 500ms after completion
- `:cmd_spawn :quiet:` - Runs silently in background (no output shown)
- `:cmd_output :0:` - Shows output and waits for user to dismiss

### What You'll See on Kobo

**Regular "Sync Reading Stats":**
```
Syncing reading stats...

Found: 3 books

Sending to: https://api.fasaya.id/api/reading-stats

✓ SUCCESS!

Synced 3 books
HTTP Status: 200
```

**If no books found:**
```
✗ No books found with reading progress

Make sure you've read at least
a few pages of a book first!
```

**If sync fails:**
```
✗ FAILED

HTTP Status: 404

Debug files saved to /tmp/
- kobo-sync-payload.json
- kobo-sync-response.log
```

## Troubleshooting Steps

### 1. Test Your API First (From Computer)

```bash
cd /path/to/kobo-stats-sync
./tests/test_api_connection.sh
```

This verifies your backend is working before testing on Kobo.

### 2. Run on Kobo

**First try:** Use **Sync Reading Stats** (regular version)
- Quick feedback in popup dialog
- Shows success/failure immediately

**If it fails:** Use **Sync Stats (Verbose)** 
- Creates detailed log file
- Easier to review later via USB

### 3. Check the Logs

**If using regular version:**
1. Connect Kobo via USB
2. Check `/tmp/kobo-sync-payload.json` - see what's being sent
3. Check `/tmp/kobo-sync-response.log` - see curl output

**If using verbose version:**
1. Connect Kobo via USB
2. Open `.adds/kobo-stats-sync/sync.log` - complete log with timestamps
3. Open `.adds/kobo-stats-sync/last_payload.json` - the JSON payload

### 4. Common Issues & Solutions

| Issue | Likely Cause | Solution |
|-------|--------------|----------|
| "sqlite3: not found" | sqlite3 CLI not installed | Scripts now auto-fallback to Python - update to latest version |
| "fbink: not found" | fbink not in PATH | Safe to ignore - notifications won't show but script works |
| "process exited with status 1" | Old version of script | Update to latest version (exits with 0 now) |
| No books found | Haven't read anything yet | Read a few pages of any book |
| No internet connection | WiFi not connected | Connect to WiFi first |
| Config missing | config.env not copied | Copy config.env.example to config.env |
| HTTP 401/403 | Wrong API key | Check `config.env` API_KEY |
| HTTP 404 | Wrong endpoint | Check `config.env` API_ENDPOINT |
| HTTP 500 | Backend error | Check your backend server logs |
| Timeout | Slow connection | Increase timeout in script |

**Note:** The scripts now exit with code 0 (success) even when encountering expected errors (no WiFi, no books, etc.) to prevent NickelMenu from showing "process exited with status 1" error. The actual error message is shown in the dialog instead.

**Database Query:** The scripts automatically detect the best method to query the SQLite database:
1. First tries `sqlite3` CLI (if available)
2. Falls back to `python3` with built-in sqlite3 module
3. Falls back to `python` (Python 2) if python3 not available
This ensures compatibility across different Kobo firmware versions.

### 5. Manual Testing on Kobo

If you have SSH access to your Kobo:

```bash
# SSH into Kobo
ssh root@192.168.x.x

# Run script manually
/mnt/onboard/.adds/kobo-stats-sync/sync_stats_verbose.sh

# View the log
cat /mnt/onboard/.adds/kobo-stats-sync/sync.log

# Check what books are in database
sqlite3 /mnt/onboard/.kobo/KoboReader.sqlite \
  "SELECT BookTitle, ___PercentRead FROM content 
   WHERE ContentType IN (6, 10, 16) 
   AND ___PercentRead > 0;"
```

## Understanding HTTP Response Codes

- **200/201** ✓ Success - Data received and saved
- **400** ✗ Bad Request - Invalid JSON or missing fields
- **401** ✗ Unauthorized - Wrong or missing API key
- **403** ✗ Forbidden - Valid key but not allowed
- **404** ✗ Not Found - Wrong API endpoint URL
- **500** ✗ Server Error - Problem with your backend
- **Timeout** ✗ No response - Connection issues or slow network

## Example Workflow

1. **Test from computer first:**
   ```bash
   ./tests/test_api_connection.sh
   ```
   If this fails, fix your backend first!

2. **Install on Kobo** (if not already done)

3. **Test on Kobo:**
   - Tap "Sync Reading Stats"
   - Look at the popup dialog
   - Note the HTTP status code

4. **If it fails:**
   - Tap "Sync Stats (Verbose)"
   - Connect Kobo via USB
   - Read `.adds/kobo-stats-sync/sync.log`
   - Check what went wrong

5. **Fix the issue** based on the log

6. **Try again!**

