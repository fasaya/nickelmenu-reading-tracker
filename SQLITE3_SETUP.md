# Setting Up SQLite3 for Kobo

## The Problem

Your Kobo doesn't have `sqlite3` or `python` available in the PATH. This is unusual but can happen with certain Kobo models or custom firmware.

## Solutions (Choose One)

### Option 1: Download Pre-compiled Binary (Recommended)

I'll help you find a compatible sqlite3 binary for your Kobo's ARM processor.

**Automatic download:**
```bash
./download_sqlite3.sh
```

**Manual download:**
1. Download sqlite3 for ARM from one of these sources:
   - [NiLuJe's Kobo repository](https://github.com/NiLuJe/Kobo)
   - [SQLite download page](https://www.sqlite.org/download.html) (look for ARM)
   - [Kobo Stuff forum](https://www.mobileread.com/forums/forumdisplay.php?f=223)

2. Save it as `kobo-stats-sync/sqlite3`

3. Make it executable:
   ```bash
   chmod +x kobo-stats-sync/sqlite3
   ```

4. Run the installer:
   ```bash
   ./install.sh
   ```

The installer will automatically detect and copy the sqlite3 binary to your Kobo.

### Option 2: Use a Different Kobo Model Database Tool

Some Kobo models have `nickel` SQLite bindings. Let me know your exact Kobo model and I can create a model-specific solution.

### Option 3: SSH and Install Tools

If you have SSH access to your Kobo:

1. SSH into Kobo:
   ```bash
   ssh root@192.168.x.x
   ```

2. Check what's available:
   ```bash
   which sqlite3
   which python
   which python3
   ls -la /usr/bin/ | grep -i sql
   ls -la /usr/bin/ | grep -i python
   ```

3. Check Kobo model and firmware:
   ```bash
   cat /mnt/onboard/.kobo/version
   uname -a
   ```

Send me the output and I can create a targeted solution.

### Option 4: Use KFMon/NickelMenu Package Manager

If you have KOReader or other advanced tools installed, you might have access to a package manager that can install sqlite3.

## What Kobo Model Do You Have?

Different Kobo models have different tools available:
- **Kobo Clara/Libra/Sage**: Usually have Python
- **Kobo Aura/Glo**: May have limited tools
- **Kobo Touch/Mini**: Older firmware, very limited

Please tell me:
1. Your Kobo model (Settings → Device information)
2. Your firmware version
3. Any custom software installed (KOReader, Plato, etc.)

And I'll create a specific solution for your device.

## Temporary Workaround

While we figure out the sqlite3 issue, you could:

1. **Manual export**: Connect Kobo via USB, copy the entire database to your computer
2. **Query on computer**: Run the query on your Mac/PC
3. **Send to API**: Use the test script to send data manually

Would you like me to create this manual workflow?

