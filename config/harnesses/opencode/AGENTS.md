# Drizzle migration rules
- When creating new drizzle migration manually (adding to `_journal.json`), the `when` field must be a timestamp AFTER the latest existing migration's `when` value. If set to an earlier timestamp, drizzle-kit silently skips the migration.
- Never guess timestamps. Use `Date.now()` for the current time, or take the last `when` value and add 1.
