#!/usr/bin/env python3
# query_db.py - Query Kobo database using Python's built-in sqlite3 module
# This works even if sqlite3 CLI is not available

import sqlite3
import sys

DB_PATH = "/mnt/onboard/.kobo/KoboReader.sqlite"

def get_reading_stats():
    """Query the Kobo database for reading statistics"""
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        
        query = """
        SELECT 
            ContentID,
            BookID,
            BookTitle,
            Title,
            Attribution,
            DateLastRead,
            TimeSpentReading,
            LastTimeStartedReading,
            LastTimeFinishedReading,
            ReadStatus,
            ___PercentRead,
            RestOfBookEstimate,
            CurrentChapterEstimate,
            CurrentChapterProgress
        FROM content
        WHERE ContentType IN (6, 10, 16)
        AND ___PercentRead > 0
        ORDER BY DateLastRead DESC
        """
        
        cursor.execute(query)
        rows = cursor.fetchall()
        
        # Output in pipe-delimited format (same as sqlite3 CLI)
        for row in rows:
            # Convert None to empty string, handle other data types
            formatted_row = []
            for val in row:
                if val is None:
                    formatted_row.append('')
                else:
                    formatted_row.append(str(val))
            print('|'.join(formatted_row))
        
        conn.close()
        return 0
        
    except sqlite3.Error as e:
        print(f"Database error: {e}", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

if __name__ == "__main__":
    sys.exit(get_reading_stats())

