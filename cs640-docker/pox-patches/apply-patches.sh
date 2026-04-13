#!/bin/bash
# Apply all Python 3 compatibility patches to POX (fangtooth branch)
# Consolidation of every fix discovered during CS640 grading

set -e
POX=/opt/pox

echo "=== Patching POX for Python 3 compatibility ==="

# 1. Relative imports in __init__.py files
find "$POX/pox/" -name '__init__.py' | while read f; do
  dir=$(dirname "$f")
  # Fix bare imports that reference local modules
  grep -E '^(import |from )[a-zA-Z_]' "$f" 2>/dev/null | while read line; do
    mod=$(echo "$line" | sed -n 's/^import \([a-zA-Z_]*\).*/\1/p')
    if [ -n "$mod" ] && [ -f "$dir/$mod.py" ]; then
      sed -i "s/^import $mod\b/from . import $mod/" "$f"
    fi
    mod=$(echo "$line" | sed -n 's/^from \([a-zA-Z_]*\) import.*/\1/p')
    if [ -n "$mod" ] && [ -f "$dir/$mod.py" ]; then
      sed -i "s/^from $mod import/from .$mod import/" "$f"
    fi
  done
done

# 2. Fix specific known relative import issues
sed -i 's/^from recoco import \*/from .recoco import \*/' "$POX/pox/lib/recoco/__init__.py" 2>/dev/null || true

# 3. Queue → queue (Python 2 → 3)
find "$POX/pox/" -name '*.py' -exec sed -i 's/from Queue import/from queue import/g' {} +
find "$POX/pox/" -name '*.py' -exec sed -i 's/import Queue$/import queue/g' {} +
find "$POX/pox/" -name '*.py' -exec sed -i 's/import Queue\b/import queue/g' {} +

# 4. Remove Python 2 builtins that don't exist in Python 3
find "$POX/pox/" -name '*.py' -exec sed -i 's/\bbasestring\b/str/g' {} +
# Fix 'long' carefully — only in type tuples and isinstance calls
find "$POX/pox/" -name '*.py' -exec sed -i 's/(int, long,/(int, int,/g' {} +
find "$POX/pox/" -name '*.py' -exec sed -i 's/, long,/, int,/g' {} +
find "$POX/pox/" -name '*.py' -exec sed -i 's/, long)/, int)/g' {} +

# 5. Fix 'is'/'is not' with literals (SyntaxWarning in Python 3.8+)
find "$POX/pox/" -name '*.py' -exec sed -i 's/ is not "/ != "/g' {} +
find "$POX/pox/" -name '*.py' -exec sed -i 's/ is ""/ == ""/g' {} +
find "$POX/pox/" -name '*.py' -exec sed -i 's/ is 0\b/ == 0/g' {} +

# 6. except Exception, e → except Exception as e
find "$POX/pox/" -name '*.py' -exec sed -i 's/except \(.*\), \([a-zA-Z_]*\):/except \1 as \2:/g' {} +

# 7. print statement → print function
find "$POX/pox/" -name '*.py' -exec sed -i 's/^\(\s*\)print \(.*\)/\1print(\2)/g' {} +

# 8. Fix packet library relative imports
for f in "$POX/pox/lib/packet/"*.py; do
  sed -i 's/^from packet_utils import/from .packet_utils import/' "$f" 2>/dev/null || true
  sed -i 's/^from packet_base import/from .packet_base import/' "$f" 2>/dev/null || true
  sed -i 's/^from packet_utils import/from .packet_utils import/' "$f" 2>/dev/null || true
  sed -i 's/^import packet_utils/from . import packet_utils/' "$f" 2>/dev/null || true
done

# 9. Fix ord() on bytes (Python 3 iterates bytes as ints)
# Targeted fix for dns.py and rip.py where this is known to break
for f in "$POX/pox/lib/packet/dns.py" "$POX/pox/lib/packet/rip.py"; do
  if [ -f "$f" ]; then
    sed -i 's/ord(c)/c if isinstance(c, int) else ord(c)/g' "$f"
  fi
done

# 10. Fix rip.py MIN_LEN (allow RIP requests with no entries)
if [ -f "$POX/pox/lib/packet/rip.py" ]; then
  sed -i 's/MIN_LEN = 24/MIN_LEN = 4/' "$POX/pox/lib/packet/rip.py"
fi

# 11. Clean all .pyc files
find "$POX" -name "*.pyc" -delete
find "$POX" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

echo "=== POX patches applied successfully ==="
