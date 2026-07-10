#!/usr/bin/env bash
#
# extract_table.sh
#
# Extract a single table's definition + data from a mysqldump .sql file into a
# standalone .sql file that can be re-imported to restore just that table.
#
# Designed to work on very large dumps (tens of GB): it streams the input with
# awk and stops reading as soon as the target table has been captured, so it
# never loads the whole file into memory and doesn't scan past the table.
#
# The extracted block already contains `DROP TABLE IF EXISTS`, `CREATE TABLE`
# and the `INSERT` statements, so re-importing it will replace the (broken)
# table wholesale.
#
# Usage:
#   script/extract_table.sh <input_dump.sql> [output.sql] [table]
#
# Defaults:
#   output.sql -> <table>_restore.sql   (in the current directory)
#   table      -> settings
#
# Re-import with e.g.:
#   mysql -u <user> -p <database> < settings_restore.sql
#
set -euo pipefail

INPUT="${1:-}"
TABLE="${3:-settings}"
OUTPUT="${2:-${TABLE}_restore.sql}"

if [[ -z "$INPUT" ]]; then
  echo "Usage: $0 <input_dump.sql> [output.sql] [table]" >&2
  exit 1
fi

if [[ ! -r "$INPUT" ]]; then
  echo "Error: cannot read input file '$INPUT'" >&2
  exit 1
fi

# Write a safe preamble so the file can be applied on its own.
{
  echo "-- Restore of table \`${TABLE}\` extracted from: ${INPUT}"
  echo "-- Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo "SET FOREIGN_KEY_CHECKS=0;"
  echo "SET NAMES utf8mb4;"
  echo ""
} > "$OUTPUT"

# Stream the dump. Start capturing at the exact "Table structure for table
# `<TABLE>`" marker and stop (exit) at the next table's marker. Using an exact
# string comparison avoids matching tables whose names merely start with the
# target (e.g. settings vs settings_history).
# -v q="'"  passes a single-quote character into the awk program.
awk -v tbl="$TABLE" -v q="'" '
  # Reformat a one-line extended INSERT so that each row appears on its own
  # line. The split is quote- and paren-aware (backslash escapes honoured), so
  # a literal "),(" inside a string value is never mistaken for a row boundary.
  # Only the scan is per-character; rows are emitted with substr, so cost is
  # linear in the length of the statement.
  function reformat(line,   idx, prefix, rest, n, i, c, depth, inq, esc, np, pos, k, prev) {
    idx = index(line, " VALUES ")
    if (idx == 0) { print line; return }
    prefix = substr(line, 1, idx + 7)   # up to and including " VALUES "
    rest   = substr(line, idx + 8)
    n = length(rest); depth = 0; inq = 0; esc = 0; np = 0
    for (i = 1; i <= n; i++) {
      c = substr(rest, i, 1)
      if (inq) {
        if (esc)            esc = 0
        else if (c == "\\") esc = 1
        else if (c == q)    inq = 0
        continue
      }
      if (c == q)   { inq = 1; continue }
      if (c == "(") { depth++; continue }
      if (c == ")") { depth--; continue }
      if (c == "," && depth == 0) { np++; pos[np] = i }   # a between-row comma
    }
    printf "%s\n  ", prefix
    prev = 1
    for (k = 1; k <= np; k++) { printf "%s\n  ", substr(rest, prev, pos[k] - prev + 1); prev = pos[k] + 1 }
    printf "%s\n", substr(rest, prev)
  }

  $0 == "-- Table structure for table `" tbl "`" { grab=1; print; next }
  grab && /^-- Table structure for table `/         { exit }
  grab && /^INSERT INTO .* VALUES /                 { reformat($0); next }
  grab                                              { print }
' "$INPUT" >> "$OUTPUT"

echo "SET FOREIGN_KEY_CHECKS=1;" >> "$OUTPUT"

# Verify we actually found the table.
if ! grep -q "CREATE TABLE \`${TABLE}\`" "$OUTPUT"; then
  echo "Error: table \`${TABLE}\` not found in '$INPUT'" >&2
  rm -f "$OUTPUT"
  exit 2
fi

rows=$(grep -c "^INSERT INTO \`${TABLE}\`" "$OUTPUT" || true)
echo "Wrote $(du -h "$OUTPUT" | cut -f1) to '$OUTPUT' (${rows} INSERT statement(s) for \`${TABLE}\`)." >&2
