# open-abap-pdf

Standalone PDF generation in ABAP

Pull requests welcome

Plan is to have the same code run on:
* Classic ECC
* Classic Steampunk
* Embedded Steampunk
* open-abap/transpiled

## Features

- Create multi-page PDF documents, byte exact xref table, no repair needed by readers
- Text with the 12 Base-14 text fonts, real AFM metrics, WinAnsi encoding for umlauts and the Euro sign
- Text measuring, word wrap, left / center / right alignment
- Layout engine: margins, cursor, `cell`, `multi_cell`, automatic page break, header and footer callbacks, total page count placeholder
- Tables with column widths, wrapping cells, zebra shading, borders, a header row that repeats after a page break, full width group and subtotal rows, and keep with next so a group header never ends a page
- Images: JPEG (DCTDecode) and PNG (FlateDecode), scaling, dpi, raw or ASCII hex streams
- Optional FlateDecode compression of content, fonts and ToUnicode maps, typically a fifth of the size
- Interactive forms (AcroForm): text fields, check boxes, radio groups, drop downs, plus a flatten mode that draws the values as static text
- Set text, draw, and fill colors (RGB)
- Draw shapes: lines, rectangles, circles
- Fluent API for method chaining
- Support for A4, Letter, and custom page sizes
- Unit conversion helpers (mm to points, inches to points)

## Classes

| Class | Purpose |
|-------|---------|
| `zcl_open_abap_pdf` | Document, pages, drawing, layout, images, form fields |
| `zcl_open_abap_pdf_table` | Tables |
| `zcl_open_abap_pdf_font` | Text width, word wrap, PDF string escaping |
| `zcl_open_abap_pdf_metrics` | Generated Base-14 glyph widths |
| `zcl_open_abap_pdf_image` | JPEG and PNG parsing |
| `zcl_open_abap_pdf_writer` | Byte safe output buffer |
| `zcl_open_abap_pdf_ttf` | TrueType font parsing |
| `zif_open_abap_pdf_layout` | Header and footer callbacks |
| `zcx_open_abap_pdf` | Exception |

## Generate, preview, edit, repeat

The repository transpiles itself to Node with the abaplint transpiler, so a document can be
rendered and inspected without an SAP system:

```bash
npm install
pip install pymupdf

./preview.sh ZCL_PDF_DEMO_TABLE run_base64 tables.pdf preview_tables
```

`preview.sh` transpiles the ABAP, runs the given class method (which must return the document as
base64), writes the PDF and rasterizes every page to `preview_tables/page_NN.png` plus a
`text.txt` with the extracted text. `tools/validate.py` additionally asserts that the file is
structurally valid, which is also part of `npm test`.

Demo classes in `test/`:

| Class | Shows |
|-------|-------|
| `ZCL_PDF_DEMO` | text, fonts, shapes |
| `ZCL_PDF_DEMO_LAYOUT` | margins, wrapped text, page break, header and footer |
| `ZCL_PDF_DEMO_TABLE` | delivery note with a long table |
| `ZCL_PDF_DEMO_IMAGE` | JPEG and PNG placement |
| `ZCL_PDF_DEMO_FORM` | fillable form and its flattened copy |
| `ZCL_PDF_DEMO_INVOICE` | replica of a Polish VAT invoice, logo, VAT summary |
| `ZCL_PDF_DEMO_TTF` | embedded TrueType font with Polish, Czech, Turkish, Cyrillic and Greek text |
| `ZCL_PDF_DEMO_COMPLEX` | order confirmation: letterhead, address window, info grid, grouped item table with subtotals over several pages, totals box, bar chart, two column terms, rotated watermark, signatures |

## Usage

### Basic Example

```abap
DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
lo_pdf->add_page( ).
lo_pdf->set_font( iv_name = 'Helvetica' iv_size = 24 ).
lo_pdf->text( iv_x = 50 iv_y = 50 iv_text = 'Hello World!' ).
DATA(lv_pdf_string) = lo_pdf->render( ).
```

### Fluent API

```abap
DATA(lv_pdf) = zcl_open_abap_pdf=>create(
  )->add_page(
  )->set_font( iv_name = 'Helvetica' iv_size = 16
  )->set_text_color( iv_r = 0 iv_g = 0 iv_b = 128
  )->text( iv_x = 100 iv_y = 100 iv_text = 'Blue Text'
  )->render( ).
```

### Drawing Shapes

```abap
DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
lo_pdf->add_page( ).

" Draw a line
lo_pdf->line( iv_x1 = 50 iv_y1 = 100 iv_x2 = 200 iv_y2 = 100 ).

" Draw a rectangle (outline)
lo_pdf->rect( iv_x = 50 iv_y = 150 iv_width = 100 iv_height = 50 iv_style = 'D' ).

" Draw a filled rectangle
lo_pdf->set_fill_color( iv_r = 200 iv_g = 200 iv_b = 255 ).
lo_pdf->rect( iv_x = 50 iv_y = 220 iv_width = 100 iv_height = 50 iv_style = 'F' ).

" Draw a circle
lo_pdf->circle( iv_x = 300 iv_y = 200 iv_radius = 40 iv_style = 'DF' ).

DATA(lv_pdf) = lo_pdf->render( ).
```

### Layout, wrapped text and pagination

```abap
DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
lo_pdf->set_margins( iv_left = 40 iv_top = 40 iv_right = 40 iv_bottom = 40 ).
lo_pdf->set_layout( NEW zcl_my_layout( ) ).   " header( ) and footer( ) callbacks
lo_pdf->add_page( ).

lo_pdf->cell( iv_text = 'Heading' iv_height = 24 ).
lo_pdf->multi_cell( iv_text = lv_long_text ).       " wraps and breaks pages
lo_pdf->cell( iv_text = 'Sum' iv_align = zcl_open_abap_pdf=>c_align_right iv_border = '1' ).
```

In a footer, `{nb}` is replaced by the total number of pages:

```abap
io_pdf->cell( iv_text = |Page { io_pdf->get_page_number( ) } of \{nb\}| ).
```

### Tables

```abap
zcl_open_abap_pdf_table=>create( lo_pdf
  )->add_column( iv_header = 'Item' iv_width = 40 iv_align = zcl_open_abap_pdf=>c_align_right
  )->add_column( iv_header = 'Description'
  )->add_column( iv_header = 'Value' iv_width = 80 iv_align = zcl_open_abap_pdf=>c_align_right
  )->set_zebra(
  )->add_row( VALUE #( ( '10' ) ( 'Ball bearing 6204-2RS' ) ( '17.85 EUR' ) )
  )->add_row( it_cells = VALUE #( ( '' ) ( 'Total' ) ( '17.85 EUR' ) ) iv_bold = abap_true
  )->render( ).
```

### Images

```abap
lo_pdf->image( iv_data = lv_jpeg_xstring iv_x = 40 iv_y = 40 iv_width = 120 ).
lo_pdf->image_base64( iv_base64 = lv_png_base64 iv_x = 40 iv_y = 40 iv_dpi = 300 ).
```

JPEG is embedded as is, PNG must be saved without an alpha channel and without interlacing.

### Interactive forms

```abap
lo_pdf->text_field( iv_name = 'EMPLOYEE' iv_x = 190 iv_y = 100 iv_width = 250 iv_value = 'Lars Hvam' ).
lo_pdf->checkbox( iv_name = 'ADVANCE' iv_x = 190 iv_y = 130 iv_checked = abap_true ).
lo_pdf->radio_button( iv_name = 'LEVEL' iv_value = 'Manager' iv_x = 190 iv_y = 160 iv_selected = abap_true ).
lo_pdf->radio_button( iv_name = 'LEVEL' iv_value = 'Director' iv_x = 300 iv_y = 160 ).
lo_pdf->dropdown(
  iv_name    = 'TRIP_TYPE'
  it_options = VALUE #( ( 'Domestic' ) ( 'International' ) )
  iv_x       = 190
  iv_y       = 190
  iv_width   = 160 ).
```

`set_flatten_form( )` draws the same layout without widgets, for the archive copy.

### Multiple Pages

```abap
DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).

lo_pdf->add_page( ).
lo_pdf->set_font( iv_name = 'Helvetica' iv_size = 24 ).
lo_pdf->text( iv_x = 50 iv_y = 50 iv_text = 'Page 1' ).

lo_pdf->add_page( ).
lo_pdf->text( iv_x = 50 iv_y = 50 iv_text = 'Page 2' ).

DATA(lv_pdf) = lo_pdf->render( ).
```

### Custom Page Size

```abap
" Letter size
lo_pdf->add_page(
  iv_width  = zcl_open_abap_pdf=>c_letter_width
  iv_height = zcl_open_abap_pdf=>c_letter_height ).

" Custom size in mm (converted to points)
lo_pdf->add_page(
  iv_width  = zcl_open_abap_pdf=>mm_to_pt( 100 )
  iv_height = zcl_open_abap_pdf=>mm_to_pt( 150 ) ).
```

## API Reference

### Class Methods

| Method | Description |
|--------|-------------|
| `create( )` | Creates a new PDF document instance |
| `mm_to_pt( iv_mm )` | Converts millimeters to points |
| `inch_to_pt( iv_inch )` | Converts inches to points |

### Instance Methods

| Method | Description |
|--------|-------------|
| `add_page( iv_width, iv_height )` | Adds a new page (default A4) |
| `set_font( iv_name, iv_size )` | Sets the current font |
| `set_text_color( iv_r, iv_g, iv_b )` | Sets text color (RGB 0-255) |
| `set_draw_color( iv_r, iv_g, iv_b )` | Sets line/stroke color |
| `set_fill_color( iv_r, iv_g, iv_b )` | Sets fill color |
| `set_line_width( iv_width )` | Sets line width |
| `text( iv_x, iv_y, iv_text )` | Draws text at position |
| `text_rotated( iv_x, iv_y, iv_text, iv_angle )` | Rotated text, for watermarks and vertical labels |
| `line( iv_x1, iv_y1, iv_x2, iv_y2 )` | Draws a line |
| `rect( iv_x, iv_y, iv_width, iv_height, iv_style )` | Draws a rectangle |
| `circle( iv_x, iv_y, iv_radius, iv_style )` | Draws a circle |
| `cell( iv_text, iv_width, iv_height, iv_align, iv_border, iv_fill, iv_ln )` | Single line text box at the cursor |
| `multi_cell( iv_text, iv_width, iv_height, iv_align, iv_border )` | Wrapped text block, breaks pages |
| `cell( ... iv_truncate = abap_true )` | Shortens the text with an ellipsis instead of overflowing |
| `set_margins( iv_left, iv_top, iv_right, iv_bottom )` | Page margins |
| `set_auto_page_break( iv_active, iv_margin )` | Automatic page break |
| `set_layout( io_layout )` | Header and footer callbacks |
| `set_alias_nb_pages( iv_alias )` | Placeholder for the total page count, default `{nb}` |
| `set_line_height( iv_height )` | Default line height |
| `set_xy( ) / set_x( ) / set_y( ) / get_x( ) / get_y( ) / ln( )` | Cursor |
| `get_content_width( )` | Width between the margins |
| `get_page_number( )` | Current page number |
| `get_text_width( iv_text, iv_font, iv_size )` | Text width in points |
| `check_page_break( iv_height )` | Break if the height does not fit |
| `image( iv_data, iv_x, iv_y, iv_width, iv_height, iv_dpi )` | Place a JPEG or PNG |
| `image_base64( iv_base64, ... )` | Place a base64 encoded image |
| `register_font( iv_name, iv_data )` | Embed a TrueType font |
| `set_hex_streams( iv_active )` | Write images and fonts as ASCII hex |
| `set_compression( iv_active )` | FlateDecode for content, fonts and ToUnicode maps |
| `text_field( )`, `checkbox( )`, `radio_button( )`, `dropdown( )` | Interactive form fields |
| `set_flatten_form( iv_active )` | Draw fields as static boxes |
| `get_field_count( )` | Number of interactive fields |
| `render( )` | Returns PDF as string, use only without raw image bytes |
| `render_binary( )` | Returns PDF as xstring, always correct |
| `get_page_count( )` | Returns number of pages |
| `get_page_width( )` | Returns current page width |
| `get_page_height( )` | Returns current page height |

### Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `c_pt_per_mm` | 2.83465 | Points per millimeter |
| `c_a4_width` | 595.28 | A4 width in points |
| `c_a4_height` | 841.89 | A4 height in points |
| `c_letter_width` | 612 | Letter width in points |
| `c_letter_height` | 792 | Letter height in points |

### Shape Styles

| Style | Description |
|-------|-------------|
| `D` | Draw outline only (default) |
| `F` | Fill only |
| `DF` or `FD` | Draw outline and fill |

## Compression

```abap
lo_pdf->set_compression( ).
```

Compresses page content, embedded fonts and the ToUnicode maps with FlateDecode. `cl_abap_gzip`
produces a raw deflate stream, so the library adds the zlib header and the Adler-32 checksum that
the filter requires. Measured with `ZCL_PDF_BENCH`:

| Document | Uncompressed | Compressed |
|----------|--------------|------------|
| 1 000 row report, 15 pages | 370 KB | 56 KB |
| 4 000 row report, 59 pages | 1 490 KB | 222 KB |
| order confirmation, 2 pages | 52 KB | 14 KB |
| page with two embedded fonts | 1 477 KB | 753 KB |

It is off by default because `render( )` then returns a binary document that can no longer be
inspected as a string. Switch it on in production and leave it off while developing.

## Embedded TrueType fonts

Any character outside WinAnsi needs an embedded font. Register the ttf once, then use the name
like a built in font:

```abap
lo_pdf->register_font( iv_name = 'CompanySans' iv_data = lv_ttf_xstring ).
lo_pdf->set_font( iv_name = 'CompanySans' iv_size = 11 ).
lo_pdf->cell( iv_text = lv_polish_text ).
```

The font is written as a Type0 font with Identity-H encoding, a CIDFontType2 descendant, the real
glyph widths from the font, and a ToUnicode map so the text stays searchable and copyable. Only
glyphs that were actually used are described.

In a real system the ttf comes from the MIME repository (SMW0), a table with a RAWSTRING field or
the ICF, never from the file system, so the same code runs on ABAP Cloud.

Limits of the current implementation:

- the font file is embedded completely, there is no subsetting yet, so a 700 KB font makes the
  document 700 KB larger, use a compact font or one subset outside ABAP
- TrueType outlines only, OpenType with CFF outlines and WOFF are rejected
- format 4 unicode cmap, which covers the Basic Multilingual Plane
- no bidi or Arabic shaping, so right to left scripts are not laid out correctly
- check the font licence before embedding a commercial corporate font

## Supported Base-14 Fonts

All widths come from the Adobe AFM metrics, so `get_text_width( )`, word wrap and table layout
are exact:

- Helvetica, Helvetica-Bold, Helvetica-Oblique, Helvetica-BoldOblique
- Times-Roman, Times-Bold, Times-Italic, Times-BoldItalic
- Courier, Courier-Bold, Courier-Oblique, Courier-BoldOblique

Text is encoded as WinAnsi, so Latin-1 characters and the typographic specials (Euro sign, dashes,
quotes) are written correctly. Unsupported characters become a question mark, which is silent data
loss, so check the data first:

```abap
DATA(lv_bad) = zcl_open_abap_pdf_font=>unsupported( ls_customer-name1 ).
IF lv_bad IS NOT INITIAL.
  " these characters cannot be printed with a Base-14 font
ENDIF.
```

Not covered by WinAnsi: Polish, Czech, Hungarian, Turkish, Baltic, Cyrillic, Greek, Hebrew, Arabic
and CJK. Those need embedded TrueType fonts, which is not implemented yet.

Regenerate the metrics with:

```bash
python3 tools/gen_font_metrics.py src/zcl_open_abap_pdf_metrics.clas.abap
```
