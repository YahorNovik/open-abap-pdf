#!/usr/bin/env python3
"""Structural pre-check for PDF/A-1b.

This is not a certified validator, use veraPDF for that. It checks the rules that
are cheap to verify and that a generator usually gets wrong: metadata, output
intent, embedded fonts, document id and forbidden entries.
"""
import re
import sys

try:
    import fitz
except ImportError:
    sys.exit("PyMuPDF missing: pip3 install --break-system-packages pymupdf")


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: pdfa_check.py <file.pdf>")

    path = sys.argv[1]
    raw = open(path, "rb").read()
    doc = fitz.open(path)
    problems = []
    checks = []

    def check(ok, text):
        checks.append(("ok  " if ok else "FAIL", text))
        if not ok:
            problems.append(text)

    check(raw.startswith(b"%PDF-1.4"), "header is PDF 1.4")
    check(not doc.is_repaired, "xref is intact")
    check(b"/Encrypt" not in raw, "not encrypted")

    # xref_xml_metadata returns the object number of the metadata stream
    meta_xref = doc.xref_xml_metadata()
    xmp = ""
    if meta_xref:
        try:
            xmp = doc.xref_stream(meta_xref).decode("utf-8", "replace")
        except Exception:
            xmp = ""
    check("pdfaid:part" in xmp, "XMP contains pdfaid:part")
    part = re.search(r"pdfaid:part>\s*(\d)", xmp)
    conf = re.search(r"pdfaid:conformance>\s*(\w)", xmp)
    check(bool(part), "conformance part is declared")
    check(bool(conf), "conformance level is declared")
    if part and conf:
        checks.append(("ok  ", "declares PDF/A-%s%s" % (part.group(1), conf.group(1).lower())))

    info = doc.metadata or {}
    title_xmp = re.search(r"<dc:title>.*?<rdf:li[^>]*>(.*?)</rdf:li>", xmp, re.S)
    check(bool(title_xmp) and title_xmp.group(1) == (info.get("title") or ""),
          "dc:title matches the Info dictionary")
    check("open-abap-pdf" in xmp and (info.get("producer") or "") == "open-abap-pdf",
          "pdf:Producer matches the Info dictionary")

    catalog = doc.xref_object(doc.pdf_catalog(), compressed=True)
    check("/OutputIntents" in catalog, "catalog has an OutputIntents array")
    check("/Metadata" in catalog, "catalog has a Metadata stream")
    check("GTS_PDFA1" in raw.decode("latin-1", "ignore"), "output intent subtype is GTS_PDFA1")
    check("/DestOutputProfile" in raw.decode("latin-1", "ignore"),
          "output intent has a destination profile")

    icc_found = False
    for xref in range(1, doc.xref_length()):
        obj = doc.xref_object(xref, compressed=True)
        if "/Alternate /DeviceRGB" in obj or "/N 3" in obj:
            try:
                data = doc.xref_stream(xref)
            except Exception:
                continue
            if data and len(data) > 128 and data[36:40] == b"acsp":
                icc_found = True
                checks.append(("ok  ", "ICC profile is a valid profile of %d bytes" % len(data)))
                break
    check(icc_found, "ICC profile stream present")

    check("/ID" in doc.xref_object(-1, compressed=True) or b"/ID" in raw,
          "trailer has a document id")

    fonts = []
    for page in doc:
        fonts.extend(page.get_fonts())
    embedded = [f for f in fonts if f[1] != "n/a"]
    check(len(fonts) > 0, "document uses fonts")
    check(len(embedded) == len(fonts),
          "all fonts are embedded (%d of %d)" % (len(embedded), len(fonts)))

    check("/NeedAppearances true" not in raw.decode("latin-1", "ignore"),
          "no NeedAppearances flag")
    widgets = sum(len(list(p.widgets())) for p in doc)
    check(widgets == 0, "no interactive widgets")

    for state, text in checks:
        print("  %s %s" % (state, text))

    if problems:
        print("\nNOT PDF/A: %d problem(s)" % len(problems))
        sys.exit(1)
    print("\nPDF/A structural checks passed for %s (%d bytes)" % (path, len(raw)))


if __name__ == "__main__":
    main()
