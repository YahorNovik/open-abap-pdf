"""Transcode a PDF page into ABAP calls for zcl_open_abap_pdf.

Reads a document that only uses Helvetica, straight lines, rectangles and one
image, and writes an ABAP class that redraws it with the same coordinates.
Text is placed by its baseline, which is what zcl_open_abap_pdf=>text expects.
"""
import sys
import base64
import struct
import zlib

import fitz

LIT = 60  # split literals so no source line gets too long


def esc(text):
    """Return an ABAP expression for a text, escaping quotes and non ASCII."""
    parts = []
    buf = ""
    for ch in text:
        if ord(ch) > 126:
            if buf:
                parts.append("'%s'" % buf.replace("'", "''"))
                buf = ""
            parts.append("cl_abap_conv_in_ce=>uccp( '%04X' )" % ord(ch))
        else:
            buf += ch
    if buf or not parts:
        parts.append("'%s'" % buf.replace("'", "''"))
    return " && ".join(parts)


def num(value):
    """ABAP literal for a coordinate, packed as a string so it stays exact."""
    return "'%s'" % round(value, 3)


def spans(page):
    out = []
    for block in page.get_text("dict")["blocks"]:
        if block["type"] != 0:
            continue
        for line in block["lines"]:
            for span in line["spans"]:
                if not span["text"].strip():
                    continue
                out.append({
                    "x": span["origin"][0],
                    "y": span["origin"][1],
                    "size": span["size"],
                    "bold": "Bold" in span["font"],
                    "text": span["text"].rstrip(),
                })
    return sorted(out, key=lambda s: (round(s["y"], 1), s["x"]))


def shapes(page):
    lines, rects = [], []
    for item in page.get_drawings():
        width = item["width"] or 0.5
        fill = item["fill"]
        for sub in item["items"]:
            if sub[0] == "l":
                p1, p2 = sub[1], sub[2]
                lines.append((p1.x, p1.y, p2.x - p1.x, p2.y - p1.y, width))
            elif sub[0] == "re":
                r = sub[1]
                grey = None
                if fill:
                    grey = round(fill[0] * 255)
                rects.append((r.x0, r.y0, r.width, r.height, width, grey))
    return lines, rects


def chunk(tag, data):
    body = tag + data
    return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)


def palette_png(doc, xref, width, height):
    """Rebuild an indexed image as a palette PNG.

    An extracted image comes back as RGB, and the library would then embed it as
    DeviceRGB. Rebuilding it with its PLTE chunk keeps the colour space of the
    source, which is what the rasterizer needs to scale it the same way.
    """
    kind, space = doc.xref_get_key(xref, "ColorSpace")
    if kind == "xref":
        space = doc.xref_object(int(space.split()[0]))
    if "Indexed" not in space:
        return None
    pal_xref = int(space.replace("]", " ").split()[-3])
    palette = doc.xref_stream(pal_xref)
    index = doc.xref_stream(xref)
    if len(index) != width * height:
        return None
    rows = b"".join(b"\x00" + index[y * width:(y + 1) * width] for y in range(height))
    return (b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 3, 0, 0, 0))
            + chunk(b"PLTE", palette[:768])
            + chunk(b"IDAT", zlib.compress(rows, 9))
            + chunk(b"IEND", b""))


def emit(doc, name):
    logo_xref = doc[0].get_images()[0][0]
    logo = doc.extract_image(logo_xref)
    logo_rect = doc[0].get_image_rects(logo_xref)[0]
    indexed = palette_png(doc, logo_xref, logo["width"], logo["height"])
    b64 = base64.b64encode(indexed if indexed else logo["image"]).decode()

    out = []
    w = out.append
    w("CLASS %s DEFINITION PUBLIC FINAL CREATE PUBLIC." % name)
    w("  PUBLIC SECTION.")
    w('    "! Redraw of a delivery note, generated from the original by')
    w('    "! tools/pdf_to_abap.py, so every coordinate is the one of the source.')
    w("    CLASS-METHODS run_base64")
    w("      RETURNING VALUE(rv_base64) TYPE string")
    w("      RAISING   zcx_open_abap_pdf.")
    w("")
    w("  PRIVATE SECTION.")
    w("    CLASS-METHODS logo")
    w("      RETURNING VALUE(rv_base64) TYPE string.")
    w("")
    for i in range(len(doc)):
        w("    CLASS-METHODS page_%d" % (i + 1))
        w("      IMPORTING io_pdf TYPE REF TO zcl_open_abap_pdf")
        w("      RAISING   zcx_open_abap_pdf.")
        w("")
    w("ENDCLASS.")
    w("")
    w("")
    w("CLASS %s IMPLEMENTATION." % name)
    w("")
    w("  METHOD run_base64.")
    w("    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).")
    w("    lo_pdf->set_compression( ).")
    w("    lo_pdf->set_auto_page_break( iv_active = abap_false ).")
    w("    lo_pdf->set_font( iv_name = 'Helvetica' iv_size = 9 ).")
    w("")
    for i in range(len(doc)):
        w("    lo_pdf->add_page( iv_width = %s iv_height = %s )." % (
            num(doc[i].rect.width), num(doc[i].rect.height)))
        w("    page_%d( lo_pdf )." % (i + 1))
    w("")
    w("    rv_base64 = cl_http_utility=>encode_x_base64( lo_pdf->render_binary( ) ).")
    w("  ENDMETHOD.")
    w("")

    for index, page in enumerate(doc):
        lines, rects = shapes(page)
        w("")
        w("  METHOD page_%d." % (index + 1))
        w("    io_pdf->image_base64(")
        w("      iv_base64 = logo( )")
        w("      iv_x      = %s" % num(logo_rect.x0))
        w("      iv_y      = %s" % num(logo_rect.y0))
        w("      iv_width  = %s" % num(logo_rect.width))
        w("      iv_height = %s )." % num(logo_rect.height))
        w("")

        if rects:
            w("    io_pdf->set_draw_color( iv_r = 0 iv_g = 0 iv_b = 0 ).")
            last_width = None
            last_grey = "none"
            for x, y, width, height, lw, grey in rects:
                if lw != last_width:
                    w("    io_pdf->set_line_width( %s )." % num(lw))
                    last_width = lw
                if grey != last_grey:
                    if grey is None:
                        pass
                    else:
                        w("    io_pdf->set_fill_color( iv_r = %d iv_g = %d iv_b = %d )." % (grey, grey, grey))
                    last_grey = grey
                # The source fills and strokes as two separate paths, and the
                # anti aliased edges only match when the redraw does the same
                if grey is not None:
                    w("    io_pdf->rect( iv_x = %s iv_y = %s iv_width = %s iv_height = %s iv_style = 'F' )." % (
                        num(x), num(y), num(width), num(height)))
                w("    io_pdf->rect( iv_x = %s iv_y = %s iv_width = %s iv_height = %s iv_style = 'D' )." % (
                    num(x), num(y), num(width), num(height)))
            w("")

        if lines:
            last_width = None
            for x, y, dx, dy, lw in lines:
                if lw != last_width:
                    w("    io_pdf->set_line_width( %s )." % num(lw))
                    last_width = lw
                # the source shifts the origin per line, and the rasterizer
                # rounds that differently, so the redraw does the same
                w("    io_pdf->line_from( iv_x = %s iv_y = %s iv_dx = %s iv_dy = %s )." % (
                    num(x), num(y), num(dx), num(dy)))
            w("")

        current = None
        for span in spans(page):
            font = "Helvetica-Bold" if span["bold"] else "Helvetica"
            key = (font, round(span["size"], 2))
            if key != current:
                w("    io_pdf->set_font( iv_name = '%s' iv_size = %s )." % (font, num(span["size"])))
                current = key
            text = esc(span["text"])
            if len(text) > LIT:
                w("    io_pdf->text( iv_x = %s iv_y = %s" % (num(span["x"]), num(span["y"])))
                w("                  iv_text = %s )." % text)
            else:
                w("    io_pdf->text( iv_x = %s iv_y = %s iv_text = %s )." % (
                    num(span["x"]), num(span["y"]), text))
        w("  ENDMETHOD.")
        w("")

    w("")
    w("  METHOD logo.")
    chunks = [b64[i:i + 100] for i in range(0, len(b64), 100)]
    w("    rv_base64 =")
    for i, chunk in enumerate(chunks):
        tail = " &&" if i < len(chunks) - 1 else "."
        w("      '%s'%s" % (chunk, tail))
    w("  ENDMETHOD.")
    w("")
    w("ENDCLASS.")
    return "\n".join(out) + "\n"


if __name__ == "__main__":
    source, target, clas = sys.argv[1], sys.argv[2], sys.argv[3]
    document = fitz.open(source)
    open(target, "w").write(emit(document, clas))
    print("%s -> %s (%d pages)" % (source, target, len(document)))
