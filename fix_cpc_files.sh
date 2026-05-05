#!/bin/bash
# Fix line endings for all CPC files (BASIC and config files)

echo "Fixing line endings for CPC compatibility..."
echo ""

# Fix BASIC files
for file in src/*.BAS *.BAS; do
    if [ -f "$file" ]; then
        echo "Processing: $file"
        # Check current format
        if file "$file" | grep -q "CRLF"; then
            echo "  ✓ Already has CR+LF line endings"
        else
            echo "  Converting to CR+LF..."
            perl -pi -e 's/\r?\n/\r\n/' "$file"
            echo "  ✓ Converted"
        fi
    fi
done

# Fix config files
for file in *.CFG N4C.CFG.example; do
    if [ -f "$file" ]; then
        echo "Processing: $file"
        if file "$file" | grep -q "CRLF"; then
            echo "  ✓ Already has CR+LF line endings"
        else
            echo "  Converting to CR+LF..."
            perl -pi -e 's/\r?\n/\r\n/' "$file"
            echo "  ✓ Converted"
        fi
    fi
done

echo ""
echo "Done! All files are now CPC-compatible."
echo ""
echo "Files ready to copy to CPC:"
ls -lh src/*.BAS *.CFG 2>/dev/null | awk '{print "  - "$9" ("$5")"}'
