---
name: abap-pdf-generation
description: Learn when the user asks to generate a PDF or a printable form from ABAP (invoice, delivery note, purchase order, expense form, label sheet), to replace Adobe Document Services or SmartForms in a print program, to reproduce an existing PDF, or to extend the open-abap-pdf library. Covers the generate - preview - edit loop with visual feedback, the layout model (margins, cursor, cell, multi_cell, auto page break, header and footer), tables with repeating headers, images, embedded TrueType fonts, barcodes and QR codes, PDF/A-1b and PDF/A-3 with attachments, reading a filled form, wiring into NAST output determination, and the ABAP pitfalls that break PDF output.
---

## Overview

`open-abap-pdf` generates PDF documents in pure ABAP, without SAPscript, Smart Forms, Adobe
Document Services or any external service. It runs on classic ECC 7.40, Steampunk, embedded
Steampunk and, because the repository transpiles itself with the abaplint transpiler, on Node -
which is what makes a visual generate - preview - edit loop possible without an SAP system.

Repository layout:

| Path | Content |
|------|---------|
| `src/zcl_open_abap_pdf.clas.abap` | document, pages, drawing, layout, images, form fields |
| `src/zcl_open_abap_pdf_table.clas.abap` | tables |
| `src/zcl_open_abap_pdf_font.clas.abap` | text width, word wrap, PDF string escaping |
| `src/zcl_open_abap_pdf_metrics.clas.abap` | generated Base-14 glyph widths, never edit by hand |
| `src/zcl_open_abap_pdf_image.clas.abap` | JPEG and PNG parsing |
| `src/zcl_open_abap_pdf_writer.clas.abap` | byte safe output buffer, FlateDecode |
| `src/zcl_open_abap_pdf_ttf.clas.abap` | TrueType parsing, subsetting |
| `src/zcl_open_abap_pdf_barcode.clas.abap` | Code 128 |
| `src/zcl_open_abap_pdf_qr.clas.abap` | QR encoder, Reed-Solomon, masking |
| `src/zcl_open_abap_pdf_reader.clas.abap` | read form values and the page count back out |
| `preview.sh`, `tools/pdf_preview.py`, `tools/validate.py` | the preview loop |
| `tools/pdf_to_abap.py` | turn an existing PDF into ABAP that redraws it |
| `integration/` | SAP only: preview handover, pilot switch, standalone test report |

## Rules

- ALWAYS look at the rendered page image before reporting a document as finished - text metrics
  are exact, but overlapping boxes and wrong coordinates are only visible in the raster.
- The coordinate origin is the TOP LEFT corner and the unit is points (1/72 inch). `mm_to_pt( )`
  and `inch_to_pt( )` convert. A4 is 595.28 x 841.89.
- ALWAYS use `render_binary( )` when the document contains images, an embedded font or compression.
  `render( )` returns a string and is only for pure text documents, or after `set_hex_streams( )`.
- ALWAYS look at the rendered raster before claiming a barcode works. The Code 128 check digit and
  the QR error correction, mask and format bits are all silent failures - the symbol looks right and
  a scanner rejects it. Decode your own output, for example with `zxingcpp`.
- PDF/A requires every font to be embedded, so `set_font( )` with the registered TrueType font has
  to happen BEFORE `add_page( )`, because a new page states the current font. Interactive fields are
  flattened automatically, and an attachment needs `iv_part = 3`.
- NEVER put text on a page after a filled shape without stating the text colour again. A fill
  changes the non stroking colour, and `text( )` therefore restates it.
- NEVER build text with trailing blanks in `'...'` literals - ABAP trims them, which glues words
  together after a wrap. Use backtick literals `` `text ` `` or string templates.
- NEVER put an expression in `CONSTANTS ... VALUE` - a constant must be a single literal, and a
  character literal is limited to 255 characters. Return long texts from a method instead.
- Formatted amounts must be computed into a packed variable first. `|{ lv_qty * lv_price }|`
  produces a decfloat with a long tail of digits.
- PNG must be saved without an alpha channel and without interlacing, otherwise `image( )` raises
  `zcx_open_abap_pdf`. JPEG is embedded unchanged.
- In a header or footer callback the automatic page break is switched off, so a callback can never
  trigger a page break recursively. Do not call `add_page( )` there.
- Keep abaplint green (`npx abaplint`), it is part of `npm test` and mirrors the syntax check of a
  740 system.

## Procedure

1. **Set up the loop once**

   ```bash
   cd /path/to/open-abap-pdf
   npm install
   pip3 install --break-system-packages pymupdf
   ```

2. **Write a demo class in `test/`** that returns the document as base64, so it can be rendered
   outside SAP:

   ```abap
   METHOD run_base64.
     rv_base64 = cl_http_utility=>encode_x_base64( build( )->render_binary( ) ).
   ENDMETHOD.
   ```

3. **Render and rasterize**

   ```bash
   ./preview.sh ZCL_MY_DOC run_base64 my.pdf preview_my
   ```

   The script transpiles the ABAP, runs the method, writes `my.pdf`, and produces
   `preview_my/page_NN.png` plus `preview_my/text.txt`.

4. **Look at the PNG** with the image viewing tool and read `text.txt` to check the text layer.

5. **Validate the structure**: `python3 tools/validate.py my.pdf` - it fails when the xref is
   broken, when a page does not render, or when the page count is wrong.

6. **Edit the ABAP and repeat step 3.** Only the changed ABAP is needed, the transpile step is a
   few seconds.

7. **Add unit tests** next to the feature: `src/*.clas.testclasses.abap` and run `npm test`
   (abaplint + ABAP unit + PDF validation).

8. **Reproduce an existing document** when the user supplies a PDF that has to be matched. Extract
   the geometry instead of measuring pixels:

   ```bash
   python3 tools/pdf_to_abap.py original.pdf test/zcl_copy.clas.abap zcl_copy
   node test/render.mjs ZCL_COPY run_base64 copy.pdf
   ```

   Then diff the rasters page by page and only stop when the deltas are at the anti aliasing level.
   Three details decide the match: coordinates with three decimals, `line_from( )` for rules that
   the source draws with a shifted origin, and a palette PNG for an indexed image.

9. **Inspect a form** with PyMuPDF when interactive fields are involved:

   ```python
   import fitz
   doc = fitz.open("my.pdf")
   print(doc.is_form_pdf)
   for w in doc[0].widgets():
       print(w.field_type_string, w.field_name, w.field_value)
   ```

## Examples

### Good: document with layout, header and footer

```abap
CLASS zcl_my_doc DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_open_abap_pdf_layout.
ENDCLASS.

METHOD zif_open_abap_pdf_layout~header.
  io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 14 ).
  io_pdf->cell( iv_text = 'Delivery note' iv_height = 24 ).
  io_pdf->ln( 8 ).
ENDMETHOD.

METHOD zif_open_abap_pdf_layout~footer.
  DATA(lv_y) = io_pdf->get_y( ).
  io_pdf->set_y( io_pdf->get_page_height( ) - 40 ).
  io_pdf->cell(
    iv_text   = |Page { io_pdf->get_page_number( ) } of \{nb\}|
    iv_align  = zcl_open_abap_pdf=>c_align_center
    iv_border = 'T' ).
  io_pdf->set_y( lv_y ).
ENDMETHOD.

METHOD build.
  ro_pdf = zcl_open_abap_pdf=>create( ).
  ro_pdf->set_layout( NEW zcl_my_doc( ) ).
  ro_pdf->set_margins( iv_left = 40 iv_top = 40 iv_right = 40 iv_bottom = 40 ).
  ro_pdf->add_page( ).
  ro_pdf->multi_cell( iv_text = lv_long_text ).
ENDMETHOD.
```

### Good: item table that survives a page break

```abap
DATA(lo_table) = zcl_open_abap_pdf_table=>create( lo_pdf ).
lo_table->add_column( iv_header = 'Item' iv_width = 40 iv_align = zcl_open_abap_pdf=>c_align_right ).
lo_table->add_column( iv_header = 'Description' ).
lo_table->add_column( iv_header = 'Value' iv_width = 85 iv_align = zcl_open_abap_pdf=>c_align_right ).
lo_table->set_zebra( ).

LOOP AT lt_items INTO ls_item.
  lv_value = ls_item-qty * ls_item-price.        " packed, not inline
  lo_table->add_row( VALUE #(
    ( |{ ls_item-posnr }| )
    ( ls_item-text )
    ( |{ lv_value } EUR| ) ) ).
ENDLOOP.

lo_table->render( ).
```

Columns without a width share the remaining space, cells wrap, the row grows, and the header row
is repeated on every new page.

### Good: fillable form and its flattened archive copy

```abap
lo_pdf->set_flatten_form( iv_flatten ).     " abap_false = widgets, abap_true = static boxes
lo_pdf->text_field( iv_name = 'EMPLOYEE' iv_x = 190 iv_y = 100 iv_width = 250 iv_value = lv_name ).
lo_pdf->checkbox( iv_name = 'ADVANCE' iv_x = 192 iv_y = 130 iv_checked = abap_true ).
lo_pdf->radio_button( iv_name = 'LEVEL' iv_value = 'Manager' iv_x = 192 iv_y = 160 iv_selected = abap_true ).
lo_pdf->radio_button( iv_name = 'LEVEL' iv_value = 'Director' iv_x = 300 iv_y = 160 ).
```

Field names are the keys when the filled form is read back, so use the SAP field names.

### Bad: measuring text by counting characters

```abap
DATA(lv_width) = strlen( lv_text ) * 6.      " wrong for every proportional font
```

Use `lo_pdf->get_text_width( lv_text )` or `zcl_open_abap_pdf_font=>text_width( )`, and
`zcl_open_abap_pdf_font=>wrap( )` to break a text into fitting lines.

### Bad: absolute y coordinates for a list of unknown length

```abap
lv_y = 100.
LOOP AT lt_items INTO ls_item.
  lo_pdf->text( iv_x = 40 iv_y = lv_y iv_text = ls_item-text ).   " runs off the page
  lv_y = lv_y + 14.
ENDLOOP.
```

Use `multi_cell( )` or a table, both of which call `check_page_break( )` and continue on a new
page with the header repeated.
