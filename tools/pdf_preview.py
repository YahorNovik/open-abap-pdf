#!/usr/bin/env python3
"""Render a PDF to PNG pages plus a text dump, for agent-driven visual review."""
import argparse
import json
import os
import shutil
import sys

try:
    import fitz
except ImportError:
    sys.exit("PyMuPDF missing: pip3 install --break-system-packages pymupdf")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("pdf")
    ap.add_argument("--out", default="preview")
    ap.add_argument("--dpi", type=int, default=110)
    ap.add_argument("--pages", default="", help="1-based list, e.g. 1,3")
    args = ap.parse_args()

    if os.path.isdir(args.out):
        shutil.rmtree(args.out)
    os.makedirs(args.out)

    doc = fitz.open(args.pdf)
    wanted = [int(p) for p in args.pages.split(",") if p.strip()] or range(1, doc.page_count + 1)

    report = {"pdf": args.pdf, "pages": doc.page_count, "files": [], "text": {}}
    for no in wanted:
        page = doc[no - 1]
        png = os.path.join(args.out, "page_%02d.png" % no)
        page.get_pixmap(dpi=args.dpi).save(png)
        report["files"].append(png)
        report["text"][no] = page.get_text()

    with open(os.path.join(args.out, "text.txt"), "w") as f:
        for no, txt in report["text"].items():
            f.write("=== page %d ===\n%s\n" % (no, txt))

    print(json.dumps({k: v for k, v in report.items() if k != "text"}, indent=1))


if __name__ == "__main__":
    main()
