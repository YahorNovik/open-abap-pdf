#!/usr/bin/env python3
"""Structural validation of a generated PDF - used by CI and the preview loop."""
import sys

try:
    import fitz
except ImportError:
    sys.exit("PyMuPDF missing: pip3 install --break-system-packages pymupdf")


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: validate.py <file.pdf> [expected_pages]")

    path = sys.argv[1]
    doc = fitz.open(path)
    errors = []

    if doc.is_repaired:
        errors.append("xref/trailer is broken - the reader had to repair the file")
    if doc.page_count == 0:
        errors.append("no pages")
    if len(sys.argv) > 2 and doc.page_count != int(sys.argv[2]):
        errors.append("expected %s pages, got %d" % (sys.argv[2], doc.page_count))

    for no in range(doc.page_count):
        try:
            doc[no].get_pixmap(dpi=36)
        except Exception as exc:
            errors.append("page %d does not render: %s" % (no + 1, exc))

    if errors:
        print("INVALID %s" % path)
        for e in errors:
            print("  - %s" % e)
        sys.exit(1)

    print("VALID %s (%d pages, %d bytes)" % (path, doc.page_count, len(open(path, "rb").read())))


if __name__ == "__main__":
    main()
