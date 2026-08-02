CLASS zcl_open_abap_pdf DEFINITION PUBLIC.
  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_font,
        name   TYPE string,
        id     TYPE i,
        obj_id TYPE i,
        is_ttf TYPE abap_bool,
      END OF ty_font,
      ty_fonts TYPE STANDARD TABLE OF ty_font WITH DEFAULT KEY,

      BEGIN OF ty_object,
        id        TYPE i,
        content   TYPE string,
        stream    TYPE xstring,
        is_stream TYPE abap_bool,
      END OF ty_object,
      ty_objects TYPE STANDARD TABLE OF ty_object WITH DEFAULT KEY,

      BEGIN OF ty_image,
        id     TYPE i,
        obj_id TYPE i,
        pal_id TYPE i,
        info   TYPE zcl_open_abap_pdf_image=>ty_info,
      END OF ty_image,
      ty_images TYPE STANDARD TABLE OF ty_image WITH DEFAULT KEY,

      BEGIN OF ty_field,
        kind     TYPE string,
        name     TYPE string,
        value    TYPE string,
        options  TYPE string,
        rect     TYPE string,
        page_id  TYPE i,
        flags    TYPE i,
        max_len  TYPE i,
        quadding TYPE i,
        size     TYPE f,
        checked  TYPE abap_bool,
        obj_id   TYPE i,
      END OF ty_field,
      ty_fields TYPE STANDARD TABLE OF ty_field WITH DEFAULT KEY,

      BEGIN OF ty_page,
        id         TYPE i,
        obj_id     TYPE i,
        content_id TYPE i,
        width      TYPE f,
        height     TYPE f,
        content    TYPE string,
      END OF ty_page,
      ty_pages TYPE STANDARD TABLE OF ty_page WITH DEFAULT KEY.

    CONSTANTS:
      c_pt_per_mm     TYPE f VALUE '2.83465',
      c_a4_width      TYPE f VALUE '595.28',  " 210mm in points
      c_a4_height     TYPE f VALUE '841.89',  " 297mm in points
      c_letter_width  TYPE f VALUE '612',
      c_letter_height TYPE f VALUE '792',
      c_pi            TYPE f VALUE '3.14159265358979'.

    CONSTANTS:
      c_align_left    TYPE string VALUE 'L',
      c_align_center  TYPE string VALUE 'C',
      c_align_right   TYPE string VALUE 'R',
      c_align_justify TYPE string VALUE 'J'.

    "! Create a new PDF document
    CLASS-METHODS create
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    "! Add a new page to the document
    "! @parameter iv_width | Page width in points (default A4)
    "! @parameter iv_height | Page height in points (default A4)
    METHODS add_page
      IMPORTING iv_width      TYPE f DEFAULT '595.28'
                iv_height     TYPE f DEFAULT '841.89'
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    "! Embed a TrueType font and make it available for set_font under iv_name.
    "! The font file is embedded completely, so prefer a compact font.
    "! @parameter iv_name | Name used in set_font and for /BaseFont
    "! @parameter iv_data | Content of the ttf file
    "! @raising zcx_open_abap_pdf | Unsupported font file
    METHODS register_font
      IMPORTING iv_name       TYPE string
                iv_data       TYPE xstring
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf
      RAISING   zcx_open_abap_pdf.

    "! Set the current font
    "! @parameter iv_name | Base-14 name (Helvetica, Times-Roman, Courier) or a registered TrueType font
    "! @parameter iv_size | Font size in points
    METHODS set_font
      IMPORTING iv_name       TYPE string DEFAULT 'Helvetica'
                iv_size       TYPE f DEFAULT 12
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    "! Set the current text color (RGB 0-255)
    METHODS set_text_color
      IMPORTING iv_r          TYPE i DEFAULT 0
                iv_g          TYPE i DEFAULT 0
                iv_b          TYPE i DEFAULT 0
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    "! Set the current draw color for lines and shapes (RGB 0-255)
    METHODS set_draw_color
      IMPORTING iv_r          TYPE i DEFAULT 0
                iv_g          TYPE i DEFAULT 0
                iv_b          TYPE i DEFAULT 0
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    "! Set the current fill color (RGB 0-255)
    METHODS set_fill_color
      IMPORTING iv_r          TYPE i DEFAULT 255
                iv_g          TYPE i DEFAULT 255
                iv_b          TYPE i DEFAULT 255
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    "! Set line width
    METHODS set_line_width
      IMPORTING iv_width      TYPE f DEFAULT 1
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    "! Draw text at position (x, y from top-left)
    METHODS text
      IMPORTING iv_x          TYPE f
                iv_y          TYPE f
                iv_text       TYPE string
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    "! Draw text stretched to exactly iv_width by widening the gaps between words
    METHODS text_justified
      IMPORTING iv_x          TYPE f
                iv_y          TYPE f
                iv_text       TYPE string
                iv_width      TYPE f
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    "! Draw text rotated around its anchor point
    "! @parameter iv_angle | Counter clockwise degrees, 90 writes bottom up
    METHODS text_rotated
      IMPORTING iv_x          TYPE f
                iv_y          TYPE f
                iv_text       TYPE string
                iv_angle      TYPE f
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    "! Draw a line from (x1, y1) to (x2, y2)
    METHODS line
      IMPORTING iv_x1         TYPE f
                iv_y1         TYPE f
                iv_x2         TYPE f
                iv_y2         TYPE f
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    "! Draw a rectangle
    "! @parameter iv_style | D=Draw, F=Fill, DF=Both
    METHODS rect
      IMPORTING iv_x          TYPE f
                iv_y          TYPE f
                iv_width      TYPE f
                iv_height     TYPE f
                iv_style      TYPE string DEFAULT 'D'
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    "! Draw a circle
    METHODS circle
      IMPORTING iv_x          TYPE f
                iv_y          TYPE f
                iv_radius     TYPE f
                iv_style      TYPE string DEFAULT 'D'
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    "! Render the PDF and return as string
    METHODS render
      RETURNING VALUE(rv_pdf) TYPE string.

    "! Render the PDF and return as xstring (binary)
    METHODS render_binary
      RETURNING VALUE(rv_pdf) TYPE xstring.

    "! Get current page number
    METHODS get_page_count
      RETURNING VALUE(rv_count) TYPE i.

    "! Get page width of current page
    METHODS get_page_width
      RETURNING VALUE(rv_width) TYPE f.

    "! Get page height of current page
    METHODS get_page_height
      RETURNING VALUE(rv_height) TYPE f.

    "! Width of a text in points, using the current or the given font
    METHODS get_text_width
      IMPORTING iv_text         TYPE string
                iv_font         TYPE string OPTIONAL
                iv_size         TYPE f DEFAULT 0
      RETURNING VALUE(rv_width) TYPE f.

    "! Set the page margins in points
    METHODS set_margins
      IMPORTING iv_left       TYPE f DEFAULT '28.35'
                iv_top        TYPE f DEFAULT '28.35'
                iv_right      TYPE f DEFAULT '28.35'
                iv_bottom     TYPE f DEFAULT '28.35'
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    "! Switch the automatic page break on or off
    "! @parameter iv_margin | Distance from the bottom of the page that triggers a break
    METHODS set_auto_page_break
      IMPORTING iv_active     TYPE abap_bool DEFAULT abap_true
                iv_margin     TYPE f DEFAULT '42.52'
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    "! Register header and footer callbacks
    METHODS set_layout
      IMPORTING io_layout     TYPE REF TO zif_open_abap_pdf_layout
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    "! Write binary streams, that is images and embedded fonts, as ASCII hex.
    "! Doubles their size, but keeps the whole file 7 bit ASCII, which makes
    "! render( ) usable for such documents.
    METHODS set_hex_streams
      IMPORTING iv_active     TYPE abap_bool DEFAULT abap_true
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    "! Deprecated, use set_hex_streams
    METHODS set_hex_images
      IMPORTING iv_active     TYPE abap_bool DEFAULT abap_true
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    "! Produce a PDF/A-1b document. This changes several rules:
    "! every font has to be an embedded TrueType font, interactive form fields are
    "! not allowed and are therefore flattened, and an ICC profile is required for
    "! the output intent. Render with render_pdfa( ) so the rules are checked.
    "! @parameter iv_icc | sRGB ICC profile, in a real system read from SMW0 or a table
    "! @parameter iv_part | 1 for PDF/A-1b, 3 for PDF/A-3b, which allows attachments
    METHODS set_pdfa
      IMPORTING iv_icc        TYPE xstring
                iv_title      TYPE string DEFAULT ''
                iv_author     TYPE string DEFAULT ''
                iv_part       TYPE i DEFAULT 1
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    "! Attach a file to the document, which PDF/A-3 allows. This is how a hybrid
    "! electronic invoice works: the readable invoice plus its XML, for example
    "! ZUGFeRD or Factur-X with the file name factur-x.xml.
    "! @parameter iv_relation | Data, Source, Alternative, Supplement or Unspecified
    METHODS attach_file
      IMPORTING iv_name       TYPE string
                iv_data       TYPE xstring
                iv_mime       TYPE string DEFAULT 'text/xml'
                iv_relation   TYPE string DEFAULT 'Alternative'
                iv_text       TYPE string DEFAULT ''
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    "! Describe why the document does not fulfil the PDF/A rules, empty when it does
    METHODS check_pdfa
      RETURNING VALUE(rv_problem) TYPE string.

    "! Render as PDF/A, refusing documents that break the rules
    "! @raising zcx_open_abap_pdf | PDF/A rule violated
    METHODS render_pdfa
      RETURNING VALUE(rv_pdf) TYPE xstring
      RAISING   zcx_open_abap_pdf.

    "! Embed only the glyphs that the document uses. On by default, because a full
    "! font adds its complete file size to every document. Switch it off to embed
    "! the original font file.
    METHODS set_subset_fonts
      IMPORTING iv_active     TYPE abap_bool DEFAULT abap_true
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    "! Compress page content, embedded fonts and the ToUnicode maps with FlateDecode.
    "! Typically shrinks a text heavy document to a fifth and an embedded font to a half.
    "! Images keep their own compression. Not compatible with set_hex_streams.
    METHODS set_compression
      IMPORTING iv_active     TYPE abap_bool DEFAULT abap_true
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    "! Placeholder that is replaced by the total number of pages while rendering
    METHODS set_alias_nb_pages
      IMPORTING iv_alias      TYPE string DEFAULT '{nb}'
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    "! Default height of a text line, used by cell and multi_cell
    METHODS set_line_height
      IMPORTING iv_height     TYPE f DEFAULT 14
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    "! Move the cursor to the given position, measured from the top left corner
    METHODS set_xy
      IMPORTING iv_x          TYPE f
                iv_y          TYPE f
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    METHODS set_x
      IMPORTING iv_x          TYPE f
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    METHODS set_y
      IMPORTING iv_y          TYPE f
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    METHODS get_x
      RETURNING VALUE(rv_x) TYPE f.

    METHODS get_y
      RETURNING VALUE(rv_y) TYPE f.

    "! Move the cursor down and back to the left margin
    METHODS ln
      IMPORTING iv_height     TYPE f DEFAULT 0
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    "! Width between the left and the right margin
    METHODS get_content_width
      RETURNING VALUE(rv_width) TYPE f.

    "! Number of the page that is currently being written
    METHODS get_page_number
      RETURNING VALUE(rv_number) TYPE i.

    "! Write a single line text box at the cursor and advance the cursor
    "! @parameter iv_width | Box width, 0 means up to the right margin
    "! @parameter iv_align | L, C or R
    "! @parameter iv_border | Any combination of L, T, R, B or 1 for all sides
    "! @parameter iv_fill | Fill the box with the current fill color
    "! @parameter iv_ln | abap_true moves the cursor to the next line, else to the right
    METHODS cell
      IMPORTING iv_text       TYPE string
                iv_width      TYPE f DEFAULT 0
                iv_height     TYPE f DEFAULT 0
                iv_align      TYPE string DEFAULT 'L'
                iv_border     TYPE string DEFAULT ''
                iv_fill       TYPE abap_bool DEFAULT abap_false
                iv_ln         TYPE abap_bool DEFAULT abap_true
                iv_padding    TYPE f DEFAULT 2
                iv_truncate   TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    "! Write a wrapped text block, breaking pages when needed
    METHODS multi_cell
      IMPORTING iv_text       TYPE string
                iv_width      TYPE f DEFAULT 0
                iv_height     TYPE f DEFAULT 0
                iv_align      TYPE string DEFAULT 'L'
                iv_border     TYPE string DEFAULT ''
                iv_fill       TYPE abap_bool DEFAULT abap_false
                iv_padding    TYPE f DEFAULT 2
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    "! Add a page break if iv_height does not fit on the current page
    METHODS check_page_break
      IMPORTING iv_height        TYPE f
      RETURNING VALUE(rv_broken) TYPE abap_bool.

    "! Place a JPEG or PNG image, position and size in points
    "! @parameter iv_width | 0 keeps the aspect ratio of iv_height, both 0 uses the pixel size
    "! @parameter iv_dpi | Resolution used when no size is given, 72 means one pixel per point
    "! @raising zcx_open_abap_pdf | Unsupported or broken image
    METHODS image
      IMPORTING iv_data       TYPE xstring
                iv_x          TYPE f
                iv_y          TYPE f
                iv_width      TYPE f DEFAULT 0
                iv_height     TYPE f DEFAULT 0
                iv_dpi        TYPE f DEFAULT 72
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf
      RAISING   zcx_open_abap_pdf.

    "! Interactive text input field
    "! @parameter iv_name | Field name, also used as the key when the form is read back
    "! @parameter iv_align | 0 left, 1 center, 2 right
    METHODS text_field
      IMPORTING iv_name       TYPE string
                iv_x          TYPE f
                iv_y          TYPE f
                iv_width      TYPE f
                iv_height     TYPE f DEFAULT 18
                iv_value      TYPE string DEFAULT ''
                iv_multiline  TYPE abap_bool DEFAULT abap_false
                iv_required   TYPE abap_bool DEFAULT abap_false
                iv_readonly   TYPE abap_bool DEFAULT abap_false
                iv_password   TYPE abap_bool DEFAULT abap_false
                iv_max_len    TYPE i DEFAULT 0
                iv_align      TYPE i DEFAULT 0
                iv_size       TYPE f DEFAULT 10
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    "! Interactive check box
    METHODS checkbox
      IMPORTING iv_name       TYPE string
                iv_x          TYPE f
                iv_y          TYPE f
                iv_size       TYPE f DEFAULT 12
                iv_checked    TYPE abap_bool DEFAULT abap_false
                iv_readonly   TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    "! One button of a radio group, all buttons of a group share iv_name
    METHODS radio_button
      IMPORTING iv_name       TYPE string
                iv_value      TYPE string
                iv_x          TYPE f
                iv_y          TYPE f
                iv_size       TYPE f DEFAULT 12
                iv_selected   TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    "! Interactive drop down list
    METHODS dropdown
      IMPORTING iv_name       TYPE string
                it_options    TYPE zcl_open_abap_pdf_font=>ty_lines
                iv_x          TYPE f
                iv_y          TYPE f
                iv_width      TYPE f
                iv_height     TYPE f DEFAULT 18
                iv_value      TYPE string DEFAULT ''
                iv_editable   TYPE abap_bool DEFAULT abap_false
                iv_size       TYPE f DEFAULT 10
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    "! Draw form fields as static boxes with their value instead of interactive widgets
    METHODS set_flatten_form
      IMPORTING iv_active     TYPE abap_bool DEFAULT abap_true
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    "! Number of interactive fields in the document
    METHODS get_field_count
      RETURNING VALUE(rv_count) TYPE i.

    "! Draw a Code 128 barcode, character set B, including the quiet zone of ten
    "! modules on each side, so the total width is ( modules + 20 ) * iv_module
    "! @parameter iv_module | Width of the narrowest bar in points
    "! @raising zcx_open_abap_pdf | Text cannot be encoded
    METHODS barcode_128
      IMPORTING iv_x          TYPE f
                iv_y          TYPE f
                iv_text       TYPE string
                iv_height     TYPE f DEFAULT 30
                iv_module     TYPE f DEFAULT '0.8'
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf
      RAISING   zcx_open_abap_pdf.

    "! Draw a QR code, error correction level M, including the quiet zone of four
    "! modules, which the standard requires
    "! @parameter iv_size | Width and height including the quiet zone, in points
    "! @raising zcx_open_abap_pdf | Text does not fit
    METHODS qrcode
      IMPORTING iv_x          TYPE f
                iv_y          TYPE f
                iv_text       TYPE string
                iv_size       TYPE f DEFAULT 80
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf
      RAISING   zcx_open_abap_pdf.

    "! Place a base64 encoded JPEG or PNG image
    METHODS image_base64
      IMPORTING iv_base64     TYPE string
                iv_x          TYPE f
                iv_y          TYPE f
                iv_width      TYPE f DEFAULT 0
                iv_height     TYPE f DEFAULT 0
                iv_dpi        TYPE f DEFAULT 72
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf
      RAISING   zcx_open_abap_pdf.

    "! Convert millimeters to points
    CLASS-METHODS mm_to_pt
      IMPORTING iv_mm        TYPE f
      RETURNING VALUE(rv_pt) TYPE f.

    "! Convert inches to points
    CLASS-METHODS inch_to_pt
      IMPORTING iv_inch      TYPE f
      RETURNING VALUE(rv_pt) TYPE f.

  PRIVATE SECTION.
    DATA mt_pages TYPE ty_pages.
    DATA mt_fonts TYPE ty_fonts.
    DATA mt_images TYPE ty_images.
    DATA mt_objects TYPE ty_objects.
    DATA mv_current_page TYPE i.
    DATA mv_current_font TYPE string.
    DATA mv_current_font_size TYPE f.
    DATA mv_current_font_id TYPE i.
    DATA mv_next_obj_id TYPE i.
    DATA mv_text_color TYPE string.
    DATA mv_draw_color TYPE string.
    DATA mv_fill_color TYPE string.
    DATA mv_line_width TYPE f.
    DATA mv_margin_left TYPE f.
    DATA mv_margin_top TYPE f.
    DATA mv_margin_right TYPE f.
    DATA mv_margin_bottom TYPE f.
    DATA mv_x TYPE f.
    DATA mv_y TYPE f.
    DATA mv_line_height TYPE f.
    DATA mv_auto_break TYPE abap_bool.
    DATA mv_break_margin TYPE f.
    DATA mv_nb_alias TYPE string.
    DATA mo_layout TYPE REF TO zif_open_abap_pdf_layout.
    DATA mv_in_layout TYPE abap_bool.
    DATA mv_hex_images TYPE abap_bool.
    DATA mv_compress TYPE abap_bool.
    DATA mv_subset TYPE abap_bool.
    DATA mv_pdfa TYPE abap_bool.
    DATA mv_icc TYPE xstring.
    DATA mv_title TYPE string.
    DATA mv_author TYPE string.
    DATA mv_info_id TYPE i.
    DATA mv_pdfa_part TYPE i.

    TYPES:
      BEGIN OF ty_attachment,
        name     TYPE string,
        mime     TYPE string,
        relation TYPE string,
        text     TYPE string,
        data     TYPE xstring,
        spec_id  TYPE i,
      END OF ty_attachment,
      ty_attachments TYPE STANDARD TABLE OF ty_attachment WITH DEFAULT KEY.

    DATA mt_attachments TYPE ty_attachments.
    DATA mv_flatten TYPE abap_bool.
    DATA mt_fields TYPE ty_fields.

    METHODS add_object
      IMPORTING iv_content   TYPE string
                iv_id        TYPE i DEFAULT 0
      RETURNING VALUE(rv_id) TYPE i.

    METHODS add_stream_object
      IMPORTING iv_dict      TYPE string DEFAULT '<<'
                iv_data      TYPE xstring
      RETURNING VALUE(rv_id) TYPE i.

    METHODS add_flate_object
      IMPORTING iv_dict      TYPE string DEFAULT '<<'
                iv_data      TYPE xstring
      RETURNING VALUE(rv_id) TYPE i.

    "! Stream of binary data, as ASCII hex, compressed or raw, depending on the settings
    METHODS add_binary_object
      IMPORTING iv_dict      TYPE string DEFAULT '<<'
                iv_data      TYPE xstring
      RETURNING VALUE(rv_id) TYPE i.

    METHODS show_operand
      IMPORTING iv_text           TYPE string
      RETURNING VALUE(rv_operand) TYPE string.

    METHODS resolve_page_count.

    METHODS build_pdfa_objects
      RETURNING VALUE(rv_intent_id) TYPE i.

    METHODS build_metadata
      RETURNING VALUE(rv_meta_id) TYPE i.

    METHODS build_attachments
      RETURNING VALUE(rv_names_id) TYPE i.

    METHODS attachment_extension
      RETURNING VALUE(rv_xmp) TYPE string.

    METHODS timestamp
      EXPORTING ev_pdf_date TYPE string
                ev_xmp_date TYPE string.

    METHODS document_id
      RETURNING VALUE(rv_id) TYPE string.

    METHODS escape_string
      IMPORTING iv_text           TYPE string
      RETURNING VALUE(rv_escaped) TYPE string.

    METHODS get_font_id
      IMPORTING iv_name      TYPE string
      RETURNING VALUE(rv_id) TYPE i.

    METHODS ensure_font
      IMPORTING iv_name TYPE string.

    METHODS transform_y
      IMPORTING iv_y        TYPE f
      RETURNING VALUE(rv_y) TYPE f.

    METHODS format_number
      IMPORTING iv_number        TYPE f
      RETURNING VALUE(rv_string) TYPE string.

    METHODS append_to_page
      IMPORTING iv_content TYPE string.

    METHODS build_objects
      RETURNING VALUE(rv_catalog_id) TYPE i.

    METHODS build_images
      RETURNING VALUE(rv_xobjects) TYPE string.

    METHODS add_truetype_font
      IMPORTING iv_name      TYPE string
      RETURNING VALUE(rv_id) TYPE i.

    METHODS build_widths
      IMPORTING it_glyphs        TYPE zcl_open_abap_pdf_font=>ty_glyphs
      RETURNING VALUE(rv_widths) TYPE string.

    METHODS build_to_unicode
      IMPORTING it_glyphs      TYPE zcl_open_abap_pdf_font=>ty_glyphs
      RETURNING VALUE(rv_cmap) TYPE string.

    METHODS build_fields
      RETURNING VALUE(rv_field_ids) TYPE string.

    METHODS add_field
      IMPORTING is_field TYPE ty_field.

    METHODS field_rect
      IMPORTING iv_x           TYPE f
                iv_y           TYPE f
                iv_width       TYPE f
                iv_height      TYPE f
      RETURNING VALUE(rv_rect) TYPE string.

    METHODS reserve_id
      RETURNING VALUE(rv_id) TYPE i.

    METHODS annots_of_page
      IMPORTING iv_page_id       TYPE i
      RETURNING VALUE(rv_annots) TYPE string.

    METHODS emit_page_state.

    METHODS run_footer.

    METHODS draw_cell_box
      IMPORTING iv_x      TYPE f
                iv_y      TYPE f
                iv_width  TYPE f
                iv_height TYPE f
                iv_border TYPE string
                iv_fill   TYPE abap_bool.
ENDCLASS.

CLASS zcl_open_abap_pdf IMPLEMENTATION.

  METHOD create.
    CREATE OBJECT ro_pdf.
    ro_pdf->mv_next_obj_id = 1.
    ro_pdf->mv_current_font = 'Helvetica'.
    ro_pdf->mv_current_font_size = 12.
    ro_pdf->mv_text_color = '0 0 0 rg'.
    ro_pdf->mv_draw_color = '0 0 0 RG'.
    ro_pdf->mv_fill_color = '1 1 1 rg'.
    ro_pdf->mv_line_width = 1.
    ro_pdf->mv_margin_left = 10 * c_pt_per_mm.
    ro_pdf->mv_margin_top = 10 * c_pt_per_mm.
    ro_pdf->mv_margin_right = 10 * c_pt_per_mm.
    ro_pdf->mv_margin_bottom = 10 * c_pt_per_mm.
    ro_pdf->mv_line_height = 14.
    ro_pdf->mv_auto_break = abap_true.
    ro_pdf->mv_break_margin = 15 * c_pt_per_mm.
    ro_pdf->mv_nb_alias = '{nb}'.
    ro_pdf->mv_subset = abap_true.
  ENDMETHOD.

  METHOD add_page.
    run_footer( ).

    mv_current_page = lines( mt_pages ) + 1.
    DATA(ls_page) = VALUE ty_page(
      id = mv_current_page
      width = iv_width
      height = iv_height
      content = '' ).
    APPEND ls_page TO mt_pages.

    mv_x = mv_margin_left.
    mv_y = mv_margin_top.

    " Every page has its own content stream, so the graphics state is restated
    emit_page_state( ).

    IF mo_layout IS BOUND AND mv_in_layout = abap_false.
      mv_in_layout = abap_true.
      mo_layout->header( me ).
      mv_in_layout = abap_false.
    ENDIF.

    ro_pdf = me.
  ENDMETHOD.

  METHOD image.
    DATA ls_image TYPE ty_image.
    DATA lv_width TYPE f.
    DATA lv_height TYPE f.

    ls_image-info = zcl_open_abap_pdf_image=>parse( iv_data ).
    ls_image-id = lines( mt_images ) + 1.
    APPEND ls_image TO mt_images.

    DATA(lv_natural_w) = ls_image-info-width * 72 / iv_dpi.
    DATA(lv_natural_h) = ls_image-info-height * 72 / iv_dpi.

    lv_width = iv_width.
    lv_height = iv_height.
    IF lv_width <= 0 AND lv_height <= 0.
      lv_width = lv_natural_w.
      lv_height = lv_natural_h.
    ELSEIF lv_width <= 0.
      lv_width = lv_height * lv_natural_w / lv_natural_h.
    ELSEIF lv_height <= 0.
      lv_height = lv_width * lv_natural_h / lv_natural_w.
    ENDIF.

    append_to_page( |q { format_number( lv_width ) } 0 0 { format_number( lv_height ) } | &&
      |{ format_number( iv_x ) } { format_number( transform_y( iv_y + lv_height ) ) } cm | &&
      |/Im{ ls_image-id } Do Q| ).

    ro_pdf = me.
  ENDMETHOD.

  METHOD barcode_128.
    DATA lv_run TYPE i.

    DATA(lv_modules) = zcl_open_abap_pdf_barcode=>code128( iv_text ).
    DATA(lv_offset) = 0.

    append_to_page( mv_text_color ).
    WHILE lv_offset < strlen( lv_modules ).
      IF lv_modules+lv_offset(1) <> '1'.
        lv_offset = lv_offset + 1.
        CONTINUE.
      ENDIF.

      " Draw neighbouring dark modules as one rectangle
      lv_run = 0.
      WHILE lv_offset + lv_run < strlen( lv_modules ).
        DATA(lv_next) = lv_offset + lv_run.
        IF lv_modules+lv_next(1) <> '1'.
          EXIT.
        ENDIF.
        lv_run = lv_run + 1.
      ENDWHILE.

      rect(
        iv_x      = iv_x + ( lv_offset + 10 ) * iv_module
        iv_y      = iv_y
        iv_width  = lv_run * iv_module
        iv_height = iv_height
        iv_style  = 'F' ).

      lv_offset = lv_offset + lv_run.
    ENDWHILE.

    ro_pdf = me.
  ENDMETHOD.

  METHOD qrcode.
    DATA lv_row TYPE string.

    DATA(lt_rows) = zcl_open_abap_pdf_qr=>encode( iv_text ).
    DATA(lv_modules) = lines( lt_rows ).
    IF lv_modules = 0.
      ro_pdf = me.
      RETURN.
    ENDIF.

    " Four light modules on every side belong to the symbol
    DATA(lv_step) = iv_size / ( lv_modules + 8 ).
    DATA(lv_origin_x) = iv_x + 4 * lv_step.
    DATA(lv_origin_y) = iv_y + 4 * lv_step.

    append_to_page( mv_text_color ).
    LOOP AT lt_rows INTO lv_row.
      DATA(lv_y) = lv_origin_y + ( sy-tabix - 1 ) * lv_step.
      DATA(lv_offset) = 0.

      WHILE lv_offset < strlen( lv_row ).
        IF lv_row+lv_offset(1) = '1'.
          DATA(lv_run) = 0.
          WHILE lv_offset + lv_run < strlen( lv_row ).
            DATA(lv_next) = lv_offset + lv_run.
            IF lv_row+lv_next(1) <> '1'.
              EXIT.
            ENDIF.
            lv_run = lv_run + 1.
          ENDWHILE.

          rect(
            iv_x      = lv_origin_x + lv_offset * lv_step
            iv_y      = lv_y
            iv_width  = lv_run * lv_step
            iv_height = lv_step
            iv_style  = 'F' ).

          lv_offset = lv_offset + lv_run.
          CONTINUE.
        ENDIF.
        lv_offset = lv_offset + 1.
      ENDWHILE.
    ENDLOOP.

    ro_pdf = me.
  ENDMETHOD.

  METHOD image_base64.
    ro_pdf = image(
      iv_data   = cl_http_utility=>decode_x_base64( iv_base64 )
      iv_x      = iv_x
      iv_y      = iv_y
      iv_width  = iv_width
      iv_height = iv_height
      iv_dpi    = iv_dpi ).
  ENDMETHOD.

  METHOD emit_page_state.
    ensure_font( mv_current_font ).
    append_to_page( |/F{ get_font_id( mv_current_font ) } { format_number( mv_current_font_size ) } Tf| ).
    append_to_page( mv_text_color ).
    append_to_page( mv_draw_color ).
    append_to_page( |{ format_number( mv_line_width ) } w| ).
  ENDMETHOD.

  METHOD run_footer.
    IF mo_layout IS NOT BOUND OR mt_pages IS INITIAL OR mv_in_layout = abap_true.
      RETURN.
    ENDIF.

    mv_in_layout = abap_true.
    mo_layout->footer( me ).
    mv_in_layout = abap_false.
  ENDMETHOD.

  METHOD set_margins.
    mv_margin_left = iv_left.
    mv_margin_top = iv_top.
    mv_margin_right = iv_right.
    mv_margin_bottom = iv_bottom.
    ro_pdf = me.
  ENDMETHOD.

  METHOD set_auto_page_break.
    mv_auto_break = iv_active.
    mv_break_margin = iv_margin.
    ro_pdf = me.
  ENDMETHOD.

  METHOD set_layout.
    mo_layout = io_layout.
    ro_pdf = me.
  ENDMETHOD.

  METHOD set_hex_streams.
    mv_hex_images = iv_active.
    ro_pdf = me.
  ENDMETHOD.

  METHOD set_hex_images.
    ro_pdf = set_hex_streams( iv_active ).
  ENDMETHOD.

  METHOD set_compression.
    mv_compress = iv_active.
    ro_pdf = me.
  ENDMETHOD.

  METHOD set_subset_fonts.
    mv_subset = iv_active.
    ro_pdf = me.
  ENDMETHOD.

  METHOD attach_file.
    " A PDF name cannot contain a slash, so text/xml is written as text#2Fxml
    DATA(lv_mime) = iv_mime.
    REPLACE ALL OCCURRENCES OF '/' IN lv_mime WITH '#2F'.

    APPEND VALUE ty_attachment(
      name     = iv_name
      mime     = lv_mime
      relation = iv_relation
      text     = iv_text
      data     = iv_data ) TO mt_attachments.
    ro_pdf = me.
  ENDMETHOD.

  METHOD set_pdfa.
    mv_pdfa = abap_true.
    mv_pdfa_part = iv_part.
    mv_icc = iv_icc.
    mv_title = iv_title.
    mv_author = iv_author.

    " Widgets without appearance streams are not allowed, so draw the values instead
    mv_flatten = abap_true.

    ro_pdf = me.
  ENDMETHOD.

  METHOD check_pdfa.
    DATA ls_font TYPE ty_font.

    IF mv_icc IS INITIAL.
      rv_problem = 'PDF/A needs an ICC profile for the output intent'.
      RETURN.
    ENDIF.

    LOOP AT mt_fonts INTO ls_font WHERE is_ttf = abap_false.
      rv_problem = |PDF/A needs embedded fonts, { ls_font-name } is not embedded. | &&
                   |Use register_font( ) and select the font with set_font( ) before add_page( ), | &&
                   |because a new page states the current font|.
      RETURN.
    ENDLOOP.

    IF mt_fields IS NOT INITIAL.
      rv_problem = 'PDF/A does not allow interactive form fields without appearance streams'.
      RETURN.
    ENDIF.

    IF mt_attachments IS NOT INITIAL AND mv_pdfa_part <> 3.
      rv_problem = 'attachments need PDF/A-3, call set_pdfa with iv_part = 3'.
    ENDIF.
  ENDMETHOD.

  METHOD render_pdfa.
    IF mv_pdfa = abap_false.
      zcx_open_abap_pdf=>raise( 'call set_pdfa( ) before render_pdfa( )' ).
    ENDIF.

    " The fonts are only known once the content has been written
    DATA(lv_problem) = check_pdfa( ).
    IF lv_problem IS NOT INITIAL.
      zcx_open_abap_pdf=>raise( lv_problem ).
    ENDIF.

    rv_pdf = render_binary( ).
  ENDMETHOD.

  METHOD attachment_extension.
    " A hybrid invoice has to describe its XML in the metadata as well
    READ TABLE mt_attachments INTO DATA(ls_attachment) INDEX 1.
    IF sy-subrc <> 0 OR mv_pdfa_part <> 3.
      RETURN.
    ENDIF.

    rv_xmp =
      |  <rdf:Description rdf:about="" xmlns:fx="urn:factur-x:pdfa:CrossIndustryDocument:invoice:1p0#">\n| &&
      |   <fx:DocumentType>INVOICE</fx:DocumentType>\n| &&
      |   <fx:DocumentFileName>{ ls_attachment-name }</fx:DocumentFileName>\n| &&
      |   <fx:Version>1.0</fx:Version>\n| &&
      |   <fx:ConformanceLevel>BASIC</fx:ConformanceLevel>\n| &&
      |  </rdf:Description>\n|.
  ENDMETHOD.

  METHOD build_attachments.
    DATA ls_attachment TYPE ty_attachment.
    DATA lv_names TYPE string.

    LOOP AT mt_attachments INTO ls_attachment.
      DATA(lv_tabix) = sy-tabix.

      DATA(lv_file_id) = add_binary_object(
        iv_dict = |<< /Type /EmbeddedFile /Subtype /{ ls_attachment-mime } | &&
                  |/Params << /Size { xstrlen( ls_attachment-data ) } >>|
        iv_data = ls_attachment-data ).

      ls_attachment-spec_id = add_object(
        |<< /Type /Filespec /F ({ zcl_open_abap_pdf_font=>escape( ls_attachment-name ) }) | &&
        |/UF ({ zcl_open_abap_pdf_font=>escape( ls_attachment-name ) }) | &&
        |/Desc ({ zcl_open_abap_pdf_font=>escape( ls_attachment-text ) }) | &&
        |/AFRelationship /{ ls_attachment-relation } | &&
        |/EF << /F { lv_file_id } 0 R /UF { lv_file_id } 0 R >> >>| ).
      MODIFY mt_attachments FROM ls_attachment INDEX lv_tabix.

      lv_names = |{ lv_names }({ zcl_open_abap_pdf_font=>escape( ls_attachment-name ) }) | &&
                 |{ ls_attachment-spec_id } 0 R |.
    ENDLOOP.

    IF lv_names IS INITIAL.
      RETURN.
    ENDIF.

    rv_names_id = add_object( |<< /Names [{ lv_names }] >>| ).
  ENDMETHOD.

  METHOD build_pdfa_objects.
    DATA lv_icc_dict TYPE string.

    lv_icc_dict = |<< /N 3 /Alternate /DeviceRGB|.
    DATA(lv_icc_id) = add_binary_object( iv_dict = lv_icc_dict iv_data = mv_icc ).

    rv_intent_id = add_object(
      |<< /Type /OutputIntent /S /GTS_PDFA1 | &&
      |/OutputConditionIdentifier (sRGB IEC61966-2.1) /Info (sRGB IEC61966-2.1) | &&
      |/DestOutputProfile { lv_icc_id } 0 R >>| ).
  ENDMETHOD.

  METHOD timestamp.
    " PDF wants D:YYYYMMDDHHMMSS, XMP wants YYYY-MM-DDTHH:MM:SS
    DATA(lv_date) = |{ sy-datum }|.
    DATA(lv_time) = |{ sy-uzeit }|.

    ev_pdf_date = |D:{ lv_date }{ lv_time }Z|.
    ev_xmp_date = |{ lv_date(4) }-{ lv_date+4(2) }-{ lv_date+6(2) }T| &&
                  |{ lv_time(2) }:{ lv_time+2(2) }:{ lv_time+4(2) }Z|.
  ENDMETHOD.

  METHOD build_metadata.
    timestamp(
      IMPORTING ev_pdf_date = DATA(lv_pdf_date)
                ev_xmp_date = DATA(lv_xmp_date) ).

    DATA(lv_title) = mv_title.
    IF lv_title IS INITIAL.
      lv_title = 'Document'.
    ENDIF.

    " Info dictionary and XMP have to say the same thing
    mv_info_id = add_object(
      |<< /Title ({ zcl_open_abap_pdf_font=>escape( lv_title ) }) | &&
      |/Author ({ zcl_open_abap_pdf_font=>escape( mv_author ) }) | &&
      |/Producer (open-abap-pdf) /Creator (open-abap-pdf) | &&
      |/CreationDate ({ lv_pdf_date }) /ModDate ({ lv_pdf_date }) >>| ).

    DATA(lv_xmp) =
      |<?xpacket begin="" id="W5M0MpCehiHzreSzNTczkc9d"?>\n| &&
      |<x:xmpmeta xmlns:x="adobe:ns:meta/">\n| &&
      | <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">\n| &&
      |  <rdf:Description rdf:about="" xmlns:dc="http://purl.org/dc/elements/1.1/">\n| &&
      |   <dc:title><rdf:Alt><rdf:li xml:lang="x-default">{ lv_title }</rdf:li></rdf:Alt></dc:title>\n| &&
      |   <dc:creator><rdf:Seq><rdf:li>{ mv_author }</rdf:li></rdf:Seq></dc:creator>\n| &&
      |  </rdf:Description>\n| &&
      |  <rdf:Description rdf:about="" xmlns:xmp="http://ns.adobe.com/xap/1.0/">\n| &&
      |   <xmp:CreatorTool>open-abap-pdf</xmp:CreatorTool>\n| &&
      |   <xmp:CreateDate>{ lv_xmp_date }</xmp:CreateDate>\n| &&
      |   <xmp:ModifyDate>{ lv_xmp_date }</xmp:ModifyDate>\n| &&
      |  </rdf:Description>\n| &&
      |  <rdf:Description rdf:about="" xmlns:pdf="http://ns.adobe.com/pdf/1.3/">\n| &&
      |   <pdf:Producer>open-abap-pdf</pdf:Producer>\n| &&
      |  </rdf:Description>\n| &&
      |  <rdf:Description rdf:about="" xmlns:pdfaid="http://www.aiim.org/pdfa/ns/id/">\n| &&
      |   <pdfaid:part>{ mv_pdfa_part }</pdfaid:part>\n| &&
      |   <pdfaid:conformance>B</pdfaid:conformance>\n| &&
      |  </rdf:Description>\n| &&
      attachment_extension( ) &&
      | </rdf:RDF>\n</x:xmpmeta>\n<?xpacket end="w"?>|.

    " The metadata stream stays uncompressed so that a validator can read it directly
    rv_meta_id = add_stream_object(
      iv_dict = '<< /Type /Metadata /Subtype /XML'
      iv_data = cl_abap_codepage=>convert_to( lv_xmp ) ).
  ENDMETHOD.

  METHOD add_binary_object.
    IF mv_hex_images = abap_true.
      rv_id = add_stream_object(
        iv_dict = |{ iv_dict } /Filter /ASCIIHexDecode|
        iv_data = cl_abap_codepage=>convert_to( |{ iv_data }>| ) ).
      RETURN.
    ENDIF.

    rv_id = add_flate_object( iv_dict = iv_dict iv_data = iv_data ).
  ENDMETHOD.

  METHOD add_flate_object.
    IF mv_compress = abap_false.
      rv_id = add_stream_object( iv_dict = iv_dict iv_data = iv_data ).
      RETURN.
    ENDIF.

    rv_id = add_stream_object(
      iv_dict = |{ iv_dict } /Filter /FlateDecode|
      iv_data = zcl_open_abap_pdf_writer=>zlib_compress( iv_data ) ).
  ENDMETHOD.

  METHOD set_alias_nb_pages.
    mv_nb_alias = iv_alias.
    ro_pdf = me.
  ENDMETHOD.

  METHOD set_line_height.
    mv_line_height = iv_height.
    ro_pdf = me.
  ENDMETHOD.

  METHOD set_xy.
    mv_x = iv_x.
    mv_y = iv_y.
    ro_pdf = me.
  ENDMETHOD.

  METHOD set_x.
    mv_x = iv_x.
    ro_pdf = me.
  ENDMETHOD.

  METHOD set_y.
    mv_y = iv_y.
    ro_pdf = me.
  ENDMETHOD.

  METHOD get_x.
    rv_x = mv_x.
  ENDMETHOD.

  METHOD get_y.
    rv_y = mv_y.
  ENDMETHOD.

  METHOD ln.
    IF iv_height > 0.
      mv_y = mv_y + iv_height.
    ELSE.
      mv_y = mv_y + mv_line_height.
    ENDIF.
    mv_x = mv_margin_left.
    ro_pdf = me.
  ENDMETHOD.

  METHOD get_content_width.
    rv_width = get_page_width( ) - mv_margin_left - mv_margin_right.
  ENDMETHOD.

  METHOD get_page_number.
    rv_number = mv_current_page.
  ENDMETHOD.

  METHOD check_page_break.
    IF mv_auto_break = abap_false OR mv_in_layout = abap_true OR mt_pages IS INITIAL.
      RETURN.
    ENDIF.

    IF mv_y + iv_height <= get_page_height( ) - mv_break_margin.
      RETURN.
    ENDIF.

    add_page( iv_width = get_page_width( ) iv_height = get_page_height( ) ).
    rv_broken = abap_true.
  ENDMETHOD.

  METHOD draw_cell_box.
    IF iv_fill = abap_true.
      append_to_page( mv_fill_color ).
      rect( iv_x = iv_x iv_y = iv_y iv_width = iv_width iv_height = iv_height iv_style = 'F' ).
      append_to_page( mv_text_color ).
    ENDIF.

    IF iv_border IS INITIAL.
      RETURN.
    ENDIF.

    IF iv_border = '1' OR iv_border = 'LTRB'.
      rect( iv_x = iv_x iv_y = iv_y iv_width = iv_width iv_height = iv_height ).
      RETURN.
    ENDIF.

    IF iv_border CS 'L'.
      line( iv_x1 = iv_x iv_y1 = iv_y iv_x2 = iv_x iv_y2 = iv_y + iv_height ).
    ENDIF.
    IF iv_border CS 'T'.
      line( iv_x1 = iv_x iv_y1 = iv_y iv_x2 = iv_x + iv_width iv_y2 = iv_y ).
    ENDIF.
    IF iv_border CS 'R'.
      line( iv_x1 = iv_x + iv_width iv_y1 = iv_y iv_x2 = iv_x + iv_width iv_y2 = iv_y + iv_height ).
    ENDIF.
    IF iv_border CS 'B'.
      line( iv_x1 = iv_x iv_y1 = iv_y + iv_height iv_x2 = iv_x + iv_width iv_y2 = iv_y + iv_height ).
    ENDIF.
  ENDMETHOD.

  METHOD cell.
    DATA lv_width TYPE f.
    DATA lv_height TYPE f.
    DATA lv_text_x TYPE f.

    lv_width = iv_width.
    IF lv_width <= 0.
      lv_width = get_page_width( ) - mv_margin_right - mv_x.
    ENDIF.

    lv_height = iv_height.
    IF lv_height <= 0.
      lv_height = mv_line_height.
    ENDIF.

    draw_cell_box(
      iv_x      = mv_x
      iv_y      = mv_y
      iv_width  = lv_width
      iv_height = lv_height
      iv_border = iv_border
      iv_fill   = iv_fill ).

    DATA(lv_text) = iv_text.
    IF iv_truncate = abap_true AND lv_text IS NOT INITIAL.
      lv_text = zcl_open_abap_pdf_font=>truncate(
        iv_font  = mv_current_font
        iv_size  = mv_current_font_size
        iv_text  = lv_text
        iv_width = lv_width - 2 * iv_padding ).
    ENDIF.

    IF lv_text IS NOT INITIAL.
      DATA(lv_text_width) = get_text_width( lv_text ).
      CASE iv_align.
        WHEN c_align_center.
          lv_text_x = mv_x + ( lv_width - lv_text_width ) / 2.
        WHEN c_align_right.
          lv_text_x = mv_x + lv_width - lv_text_width - iv_padding.
        WHEN OTHERS.
          lv_text_x = mv_x + iv_padding.
      ENDCASE.

      " Baseline, roughly vertically centered in the box
      text(
        iv_x    = lv_text_x
        iv_y    = mv_y + ( lv_height + mv_current_font_size * '0.7' ) / 2
        iv_text = lv_text ).
    ENDIF.

    IF iv_ln = abap_true.
      mv_y = mv_y + lv_height.
      mv_x = mv_margin_left.
    ELSE.
      mv_x = mv_x + lv_width.
    ENDIF.

    ro_pdf = me.
  ENDMETHOD.

  METHOD multi_cell.
    DATA lv_line TYPE string.
    DATA lv_width TYPE f.
    DATA lv_height TYPE f.
    DATA lv_border TYPE string.

    lv_width = iv_width.
    IF lv_width <= 0.
      lv_width = get_page_width( ) - mv_margin_right - mv_x.
    ENDIF.

    lv_height = iv_height.
    IF lv_height <= 0.
      lv_height = mv_line_height.
    ENDIF.

    DATA(lv_x) = mv_x.
    DATA(lt_lines) = zcl_open_abap_pdf_font=>wrap(
      iv_font  = mv_current_font
      iv_size  = mv_current_font_size
      iv_text  = iv_text
      iv_width = lv_width - 2 * iv_padding ).

    LOOP AT lt_lines INTO lv_line.
      IF check_page_break( lv_height ) = abap_true.
        lv_x = mv_margin_left.
      ENDIF.
      mv_x = lv_x.

      lv_border = iv_border.
      IF iv_border = '1' OR iv_border = 'LTRB'.
        " Keep the block outline continuous instead of boxing every line
        lv_border = 'LR'.
        IF sy-tabix = 1.
          lv_border = 'LRT'.
        ENDIF.
        IF sy-tabix = lines( lt_lines ).
          lv_border = |{ lv_border }B|.
        ENDIF.
      ENDIF.

      DATA(lv_align) = iv_align.
      IF iv_align = c_align_justify.
        " The last line of a block keeps its natural word gaps
        lv_align = c_align_left.
        IF sy-tabix < lines( lt_lines ).
          DATA(lv_text_x) = mv_x + iv_padding.
          DATA(lv_text_y) = mv_y + ( lv_height + mv_current_font_size * '0.7' ) / 2.

          cell(
            iv_text    = ''
            iv_width   = lv_width
            iv_height  = lv_height
            iv_border  = lv_border
            iv_fill    = iv_fill
            iv_ln      = abap_false ).
          text_justified(
            iv_x     = lv_text_x
            iv_y     = lv_text_y
            iv_text  = lv_line
            iv_width = lv_width - 2 * iv_padding ).
          mv_y = mv_y + lv_height.
          mv_x = mv_margin_left.
          CONTINUE.
        ENDIF.
      ENDIF.

      cell(
        iv_text    = lv_line
        iv_width   = lv_width
        iv_height  = lv_height
        iv_align   = lv_align
        iv_border  = lv_border
        iv_fill    = iv_fill
        iv_padding = iv_padding ).
    ENDLOOP.

    mv_x = lv_x.
    ro_pdf = me.
  ENDMETHOD.

  METHOD register_font.
    zcl_open_abap_pdf_font=>register_truetype( iv_name = iv_name iv_data = iv_data ).
    ensure_font( iv_name ).
    ro_pdf = me.
  ENDMETHOD.

  METHOD set_font.
    ensure_font( iv_name ).
    mv_current_font = iv_name.
    mv_current_font_size = iv_size.
    mv_current_font_id = get_font_id( iv_name ).

    DATA(lv_content) = |/F{ mv_current_font_id } { format_number( iv_size ) } Tf|.
    append_to_page( lv_content ).

    ro_pdf = me.
  ENDMETHOD.

  METHOD set_text_color.
    DATA(lv_r) = CONV f( iv_r / 255 ).
    DATA(lv_g) = CONV f( iv_g / 255 ).
    DATA(lv_b) = CONV f( iv_b / 255 ).

    mv_text_color = |{ format_number( lv_r ) } { format_number( lv_g ) } { format_number( lv_b ) } rg|.
    append_to_page( mv_text_color ).

    ro_pdf = me.
  ENDMETHOD.

  METHOD set_draw_color.
    DATA(lv_r) = CONV f( iv_r / 255 ).
    DATA(lv_g) = CONV f( iv_g / 255 ).
    DATA(lv_b) = CONV f( iv_b / 255 ).

    mv_draw_color = |{ format_number( lv_r ) } { format_number( lv_g ) } { format_number( lv_b ) } RG|.
    append_to_page( mv_draw_color ).

    ro_pdf = me.
  ENDMETHOD.

  METHOD set_fill_color.
    DATA(lv_r) = CONV f( iv_r / 255 ).
    DATA(lv_g) = CONV f( iv_g / 255 ).
    DATA(lv_b) = CONV f( iv_b / 255 ).

    mv_fill_color = |{ format_number( lv_r ) } { format_number( lv_g ) } { format_number( lv_b ) } rg|.

    ro_pdf = me.
  ENDMETHOD.

  METHOD set_line_width.
    mv_line_width = iv_width.
    append_to_page( |{ format_number( iv_width ) } w| ).
    ro_pdf = me.
  ENDMETHOD.

  METHOD show_operand.
    IF zcl_open_abap_pdf_font=>is_truetype( mv_current_font ) = abap_true.
      " Identity-H shows glyph indices, given as a hex string
      rv_operand = |<{ zcl_open_abap_pdf_font=>glyph_hex(
        iv_name = mv_current_font iv_text = iv_text ) }>|.
    ELSE.
      rv_operand = |({ escape_string( iv_text ) })|.
    ENDIF.
  ENDMETHOD.

  METHOD text.
    DATA(lv_y) = transform_y( iv_y ).
    DATA(lv_content) = |BT { format_number( iv_x ) } { format_number( lv_y ) } Td | &&
                       |{ show_operand( iv_text ) } Tj ET|.
    append_to_page( lv_content ).

    ro_pdf = me.
  ENDMETHOD.

  METHOD text_justified.
    DATA lv_word TYPE string.
    DATA lv_words_width TYPE f.
    DATA lv_array TYPE string.

    ro_pdf = me.

    SPLIT iv_text AT ` ` INTO TABLE DATA(lt_words).
    DELETE lt_words WHERE table_line IS INITIAL.

    IF lines( lt_words ) < 2.
      text( iv_x = iv_x iv_y = iv_y iv_text = iv_text ).
      RETURN.
    ENDIF.

    LOOP AT lt_words INTO lv_word.
      lv_words_width = lv_words_width + get_text_width( lv_word ).
    ENDLOOP.

    " The gap replaces the blank completely, so it is distributed over the gaps only
    DATA(lv_gap) = ( iv_width - lv_words_width ) / ( lines( lt_words ) - 1 ).
    IF lv_gap < 0.
      text( iv_x = iv_x iv_y = iv_y iv_text = iv_text ).
      RETURN.
    ENDIF.

    " In a TJ array a negative number moves the next glyph to the right
    DATA(lv_adjust) = format_number( lv_gap * -1000 / mv_current_font_size ).

    LOOP AT lt_words INTO lv_word.
      IF sy-tabix > 1.
        lv_array = |{ lv_array } { lv_adjust } |.
      ENDIF.
      lv_array = |{ lv_array }{ show_operand( lv_word ) }|.
    ENDLOOP.

    DATA(lv_content) = |BT { format_number( iv_x ) } { format_number( transform_y( iv_y ) ) } Td | &&
                       |[{ lv_array }] TJ ET|.
    append_to_page( lv_content ).
  ENDMETHOD.

  METHOD text_rotated.
    DATA lv_rad TYPE f.
    DATA lv_sin TYPE f.
    DATA lv_cos TYPE f.

    lv_rad = iv_angle * c_pi / 180.
    lv_sin = sin( lv_rad ).
    lv_cos = cos( lv_rad ).

    DATA(lv_y) = transform_y( iv_y ).
    append_to_page( |q { format_number( lv_cos ) } { format_number( lv_sin ) } | &&
      |{ format_number( lv_sin * -1 ) } { format_number( lv_cos ) } | &&
      |{ format_number( iv_x ) } { format_number( lv_y ) } cm | &&
      |BT 0 0 Td { COND string(
        WHEN zcl_open_abap_pdf_font=>is_truetype( mv_current_font ) = abap_true
        THEN |<{ zcl_open_abap_pdf_font=>glyph_hex( iv_name = mv_current_font iv_text = iv_text ) }>|
        ELSE |({ escape_string( iv_text ) })| ) } Tj ET Q| ).

    ro_pdf = me.
  ENDMETHOD.

  METHOD line.
    DATA(lv_y1) = transform_y( iv_y1 ).
    DATA(lv_y2) = transform_y( iv_y2 ).
    DATA(lv_content) = |{ format_number( iv_x1 ) } { format_number( lv_y1 ) } m { format_number( iv_x2 ) } { format_number( lv_y2 ) } l S|.
    append_to_page( lv_content ).

    ro_pdf = me.
  ENDMETHOD.

  METHOD rect.
    DATA(lv_y) = transform_y( iv_y + iv_height ).
    DATA lv_op TYPE string.
    DATA lv_content TYPE string.

    CASE iv_style.
      WHEN 'F'.
        lv_op = 'f'.
      WHEN 'DF' OR 'FD'.
        lv_op = 'B'.
      WHEN OTHERS.
        lv_op = 'S'.
    ENDCASE.

    lv_content = |{ format_number( iv_x ) } { format_number( lv_y ) } { format_number( iv_width ) } { format_number( iv_height ) } re { lv_op }|.
    append_to_page( lv_content ).

    ro_pdf = me.
  ENDMETHOD.

  METHOD circle.
    DATA(lv_y) = transform_y( iv_y ).
    DATA(lv_k) = iv_radius * '0.5523'.  " Bezier curve approximation
    DATA lv_op TYPE string.
    DATA lv_content TYPE string.

    CASE iv_style.
      WHEN 'F'.
        lv_op = 'f'.
      WHEN 'DF' OR 'FD'.
        lv_op = 'B'.
      WHEN OTHERS.
        lv_op = 'S'.
    ENDCASE.

    " Draw circle using 4 Bezier curves
    lv_content = |{ format_number( iv_x + iv_radius ) } { format_number( lv_y ) } m |.
    lv_content = lv_content && |{ format_number( iv_x + iv_radius ) } { format_number( lv_y + lv_k ) } { format_number( iv_x + lv_k ) } { format_number( lv_y + iv_radius ) } { format_number( iv_x ) } { format_number( lv_y + iv_radius ) } c |.
    lv_content = lv_content && |{ format_number( iv_x - lv_k ) } { format_number( lv_y + iv_radius ) } { format_number( iv_x - iv_radius ) } { format_number( lv_y + lv_k ) } { format_number( iv_x - iv_radius ) } { format_number( lv_y ) } c |.
    lv_content = lv_content && |{ format_number( iv_x - iv_radius ) } { format_number( lv_y - lv_k ) } { format_number( iv_x - lv_k ) } { format_number( lv_y - iv_radius ) } { format_number( iv_x ) } { format_number( lv_y - iv_radius ) } c |.
    lv_content = lv_content && |{ format_number( iv_x + lv_k ) } { format_number( lv_y - iv_radius ) } { format_number( iv_x + iv_radius ) } { format_number( lv_y - lv_k ) } { format_number( iv_x + iv_radius ) } { format_number( lv_y ) } c |.
    lv_content = lv_content && lv_op.

    append_to_page( lv_content ).

    ro_pdf = me.
  ENDMETHOD.

  METHOD build_objects.
    DATA lv_pages_id TYPE i.
    DATA lv_saved_page TYPE i.
    DATA lv_page_ids TYPE string.
    DATA lv_font_resources TYPE string.
    DATA lv_xobjects TYPE string.
    DATA lv_resources TYPE string.
    DATA ls_page TYPE ty_page.
    DATA ls_font TYPE ty_font.
    DATA lv_stream TYPE string.
    DATA lv_page_tabix TYPE i.
    DATA lv_encoding TYPE string.
    DATA ls_attachment TYPE ty_attachment.
    DATA lv_af TYPE string.
    DATA lv_field_ids TYPE string.
    DATA lv_annots TYPE string.
    DATA lv_catalog TYPE string.

    " The footer of the last page is only known once rendering starts
    lv_saved_page = mv_current_page.
    run_footer( ).
    mv_current_page = lv_saved_page.

    " Reset objects for fresh render
    CLEAR mt_objects.
    mv_next_obj_id = 1.

    " Has to run before the fonts are written, because the page number may add glyphs
    resolve_page_count( ).

    " Interactive fields need Helvetica for the text and ZapfDingbats for the check marks
    IF mt_fields IS NOT INITIAL.
      ensure_font( 'Helvetica' ).
      ensure_font( 'ZapfDingbats' ).
    ENDIF.

    " Add fonts first
    LOOP AT mt_fonts INTO ls_font.
      DATA(lv_font_tabix) = sy-tabix.

      IF ls_font-is_ttf = abap_true.
        ls_font-obj_id = add_truetype_font( ls_font-name ).
        MODIFY mt_fonts FROM ls_font INDEX lv_font_tabix.
        CONTINUE.
      ENDIF.

      lv_encoding = ' /Encoding /WinAnsiEncoding'.
      IF ls_font-name = 'ZapfDingbats' OR ls_font-name = 'Symbol'.
        CLEAR lv_encoding.
      ENDIF.
      ls_font-obj_id = add_object(
        |<< /Type /Font /Subtype /Type1 /BaseFont /{ ls_font-name }{ lv_encoding } >>| ).
      MODIFY mt_fonts FROM ls_font INDEX lv_font_tabix.
    ENDLOOP.

    " Add page content streams and page objects
    LOOP AT mt_pages INTO ls_page.
      lv_page_tabix = sy-tabix.
      lv_stream = ls_page-content.

      ls_page-content_id = add_flate_object( iv_data = cl_abap_codepage=>convert_to( lv_stream ) ).
      MODIFY mt_pages FROM ls_page INDEX lv_page_tabix.
    ENDLOOP.

    " Build font resources string
    LOOP AT mt_fonts INTO ls_font.
      IF lv_font_resources IS NOT INITIAL.
        lv_font_resources = lv_font_resources && | |.
      ENDIF.
      lv_font_resources = lv_font_resources && |/F{ ls_font-id } { ls_font-obj_id } 0 R|.
    ENDLOOP.

    lv_xobjects = build_images( ).

    " Add page objects
    lv_resources = |/Font << { lv_font_resources } >>|.
    IF lv_xobjects IS NOT INITIAL.
      lv_resources = |{ lv_resources } /XObject << { lv_xobjects } >>|.
    ENDIF.

    " Page objects are referenced by the field annotations, so reserve their ids first
    LOOP AT mt_pages ASSIGNING FIELD-SYMBOL(<ls_page>).
      <ls_page>-obj_id = reserve_id( ).
      IF lv_page_ids IS NOT INITIAL.
        lv_page_ids = lv_page_ids && | |.
      ENDIF.
      lv_page_ids = lv_page_ids && |{ <ls_page>-obj_id } 0 R|.
    ENDLOOP.

    lv_field_ids = build_fields( ).
    lv_pages_id = reserve_id( ).

    LOOP AT mt_pages INTO ls_page.
      lv_annots = annots_of_page( ls_page-id ).
      IF lv_annots IS NOT INITIAL.
        lv_annots = | /Annots [{ lv_annots }]|.
      ENDIF.

      add_object(
        iv_id      = ls_page-obj_id
        iv_content = |<< /Type /Page /Parent { lv_pages_id } 0 R /MediaBox [0 0 { format_number( ls_page-width ) } { format_number( ls_page-height ) }] /Contents { ls_page-content_id } 0 R /Resources << { lv_resources } >>{ lv_annots } >>| ).
    ENDLOOP.

    " Add pages object
    add_object(
      iv_id      = lv_pages_id
      iv_content = |<< /Type /Pages /Kids [{ lv_page_ids }] /Count { lines( mt_pages ) } >>| ).

    " PDF/A additions: output intent with the ICC profile and the XMP metadata
    IF mv_pdfa = abap_true.
      DATA(lv_intent_id) = build_pdfa_objects( ).
      DATA(lv_meta_id) = build_metadata( ).
    ENDIF.
    DATA(lv_names_id) = build_attachments( ).

    " Add catalog, with the interactive form when there are fields
    lv_catalog = |<< /Type /Catalog /Pages { lv_pages_id } 0 R|.
    IF mv_pdfa = abap_true.
      lv_catalog = |{ lv_catalog } /OutputIntents [{ lv_intent_id } 0 R] | &&
                   |/Metadata { lv_meta_id } 0 R|.
    ENDIF.

    IF lv_names_id > 0.
      LOOP AT mt_attachments INTO ls_attachment.
        lv_af = |{ lv_af }{ ls_attachment-spec_id } 0 R |.
      ENDLOOP.

      lv_catalog = |{ lv_catalog } /AF [{ lv_af }] | &&
                   |/Names << /EmbeddedFiles { lv_names_id } 0 R >>|.
    ENDIF.
    IF lv_field_ids IS NOT INITIAL.
      READ TABLE mt_fonts INTO ls_font WITH KEY name = 'Helvetica'.
      DATA(lv_helv_id) = ls_font-obj_id.
      READ TABLE mt_fonts INTO ls_font WITH KEY name = 'ZapfDingbats'.
      lv_catalog = |{ lv_catalog } /AcroForm << /Fields [{ lv_field_ids }] | &&
                   |/NeedAppearances true /DA (/Helv 0 Tf 0 g) | &&
                   |/DR << /Font << /Helv { lv_helv_id } 0 R /ZaDb { ls_font-obj_id } 0 R >> >> >>|.
    ENDIF.

    rv_catalog_id = add_object( |{ lv_catalog } >>| ).
  ENDMETHOD.

  METHOD build_fields.
    TYPES:
      BEGIN OF ty_group,
        name      TYPE string,
        parent_id TYPE i,
        value     TYPE string,
        kids      TYPE string,
      END OF ty_group.
    DATA lt_groups TYPE STANDARD TABLE OF ty_group WITH DEFAULT KEY.
    DATA ls_field TYPE ty_field.
    DATA ls_page TYPE ty_page.
    DATA lv_dict TYPE string.
    DATA lv_as TYPE string.

    LOOP AT mt_fields INTO ls_field.
      DATA(lv_index) = sy-tabix.
      READ TABLE mt_pages INTO ls_page WITH KEY id = ls_field-page_id.
      DATA(lv_common) = |/Type /Annot /Subtype /Widget /Rect { ls_field-rect } | &&
                        |/F 4 /P { ls_page-obj_id } 0 R|.
      DATA(lv_name) = zcl_open_abap_pdf_font=>escape( ls_field-name ).

      CASE ls_field-kind.
        WHEN 'TX'.
          lv_dict = |<< { lv_common } /FT /Tx /T ({ lv_name }) | &&
                    |/V ({ zcl_open_abap_pdf_font=>escape( ls_field-value ) }) | &&
                    |/DA (/Helv { format_number( ls_field-size ) } Tf 0 g) | &&
                    |/MK << /BC [0 0 0] /BG [1 1 1] >>|.
          IF ls_field-flags > 0.
            lv_dict = |{ lv_dict } /Ff { ls_field-flags }|.
          ENDIF.
          IF ls_field-max_len > 0.
            lv_dict = |{ lv_dict } /MaxLen { ls_field-max_len }|.
          ENDIF.
          IF ls_field-quadding > 0.
            lv_dict = |{ lv_dict } /Q { ls_field-quadding }|.
          ENDIF.
        WHEN 'BTN'.
          lv_as = 'Off'.
          IF ls_field-checked = abap_true.
            lv_as = 'Yes'.
          ENDIF.
          lv_dict = |<< { lv_common } /FT /Btn /T ({ lv_name }) /V /{ lv_as } /AS /{ lv_as } | &&
                    |/DA (/ZaDb { format_number( ls_field-size * '0.8' ) } Tf 0 g) | &&
                    |/MK << /BC [0 0 0] /BG [1 1 1] /CA (4) >>|.
          IF ls_field-flags > 0.
            lv_dict = |{ lv_dict } /Ff { ls_field-flags }|.
          ENDIF.
        WHEN 'CH'.
          lv_dict = |<< { lv_common } /FT /Ch /T ({ lv_name }) | &&
                    |/V ({ zcl_open_abap_pdf_font=>escape( ls_field-value ) }) | &&
                    |/Opt [{ ls_field-options }] /Ff { ls_field-flags } | &&
                    |/DA (/Helv { format_number( ls_field-size ) } Tf 0 g) | &&
                    |/MK << /BC [0 0 0] /BG [1 1 1] >>|.
        WHEN OTHERS.
          READ TABLE lt_groups ASSIGNING FIELD-SYMBOL(<ls_group>) WITH KEY name = ls_field-name.
          IF sy-subrc <> 0.
            APPEND VALUE ty_group(
              name      = ls_field-name
              parent_id = reserve_id( ) ) TO lt_groups.
            READ TABLE lt_groups ASSIGNING <ls_group> INDEX lines( lt_groups ).
          ENDIF.

          lv_as = 'Off'.
          IF ls_field-checked = abap_true.
            lv_as = ls_field-value.
            <ls_group>-value = ls_field-value.
          ENDIF.

          lv_dict = |<< { lv_common } /Parent { <ls_group>-parent_id } 0 R | &&
                    |/AS /{ lv_as } /DA (/ZaDb 0 Tf 0 g) | &&
                    |/MK << /BC [0 0 0] /BG [1 1 1] /CA (l) >>|.
      ENDCASE.

      ls_field-obj_id = add_object( |{ lv_dict } >>| ).
      MODIFY mt_fields FROM ls_field INDEX lv_index.

      IF ls_field-kind = 'RADIO'.
        READ TABLE lt_groups ASSIGNING <ls_group> WITH KEY name = ls_field-name.
        IF <ls_group>-kids IS NOT INITIAL.
          <ls_group>-kids = <ls_group>-kids && | |.
        ENDIF.
        <ls_group>-kids = <ls_group>-kids && |{ ls_field-obj_id } 0 R|.
        CONTINUE.
      ENDIF.

      IF rv_field_ids IS NOT INITIAL.
        rv_field_ids = rv_field_ids && | |.
      ENDIF.
      rv_field_ids = rv_field_ids && |{ ls_field-obj_id } 0 R|.
    ENDLOOP.

    LOOP AT lt_groups ASSIGNING <ls_group>.
      lv_as = <ls_group>-value.
      IF lv_as IS INITIAL.
        lv_as = 'Off'.
      ENDIF.

      add_object(
        iv_id      = <ls_group>-parent_id
        iv_content = |<< /FT /Btn /Ff 32768 | &&
                     |/T ({ zcl_open_abap_pdf_font=>escape( <ls_group>-name ) }) | &&
                     |/V /{ lv_as } /Kids [{ <ls_group>-kids }] >>| ).

      IF rv_field_ids IS NOT INITIAL.
        rv_field_ids = rv_field_ids && | |.
      ENDIF.
      rv_field_ids = rv_field_ids && |{ <ls_group>-parent_id } 0 R|.
    ENDLOOP.
  ENDMETHOD.

  METHOD field_rect.
    DATA(lv_top) = transform_y( iv_y ).
    rv_rect = |[{ format_number( iv_x ) } { format_number( lv_top - iv_height ) } | &&
              |{ format_number( iv_x + iv_width ) } { format_number( lv_top ) }]|.
  ENDMETHOD.

  METHOD add_field.
    DATA ls_field TYPE ty_field.

    ls_field = is_field.
    ls_field-page_id = mv_current_page.
    APPEND ls_field TO mt_fields.
  ENDMETHOD.

  METHOD get_field_count.
    rv_count = lines( mt_fields ).
  ENDMETHOD.

  METHOD set_flatten_form.
    mv_flatten = iv_active.
    ro_pdf = me.
  ENDMETHOD.

  METHOD text_field.
    DATA lv_flags TYPE i.

    ro_pdf = me.

    IF mv_flatten = abap_true.
      DATA(lv_saved_x) = mv_x.
      DATA(lv_saved_y) = mv_y.
      set_xy( iv_x = iv_x iv_y = iv_y ).
      cell(
        iv_text   = iv_value
        iv_width  = iv_width
        iv_height = iv_height
        iv_border = '1'
        iv_align  = COND string( WHEN iv_align = 1 THEN c_align_center
                                 WHEN iv_align = 2 THEN c_align_right
                                 ELSE c_align_left ) ).
      set_xy( iv_x = lv_saved_x iv_y = lv_saved_y ).
      RETURN.
    ENDIF.

    IF iv_readonly = abap_true.
      lv_flags = lv_flags + 1.
    ENDIF.
    IF iv_required = abap_true.
      lv_flags = lv_flags + 2.
    ENDIF.
    IF iv_password = abap_true.
      lv_flags = lv_flags + 8192.
    ENDIF.
    IF iv_multiline = abap_true.
      lv_flags = lv_flags + 4096.
    ENDIF.

    add_field( VALUE ty_field(
      kind     = 'TX'
      name     = iv_name
      value    = iv_value
      rect     = field_rect( iv_x = iv_x iv_y = iv_y iv_width = iv_width iv_height = iv_height )
      flags    = lv_flags
      max_len  = iv_max_len
      quadding = iv_align
      size     = iv_size ) ).
  ENDMETHOD.

  METHOD checkbox.
    ro_pdf = me.

    IF mv_flatten = abap_true.
      rect( iv_x = iv_x iv_y = iv_y iv_width = iv_size iv_height = iv_size ).
      IF iv_checked = abap_true.
        line( iv_x1 = iv_x + 2 iv_y1 = iv_y + 2
              iv_x2 = iv_x + iv_size - 2 iv_y2 = iv_y + iv_size - 2 ).
        line( iv_x1 = iv_x + iv_size - 2 iv_y1 = iv_y + 2
              iv_x2 = iv_x + 2 iv_y2 = iv_y + iv_size - 2 ).
      ENDIF.
      RETURN.
    ENDIF.

    add_field( VALUE ty_field(
      kind    = 'BTN'
      name    = iv_name
      value   = 'Yes'
      rect    = field_rect( iv_x = iv_x iv_y = iv_y iv_width = iv_size iv_height = iv_size )
      flags   = COND i( WHEN iv_readonly = abap_true THEN 1 ELSE 0 )
      size    = iv_size
      checked = iv_checked ) ).
  ENDMETHOD.

  METHOD radio_button.
    ro_pdf = me.

    IF mv_flatten = abap_true.
      circle( iv_x = iv_x + iv_size / 2 iv_y = iv_y + iv_size / 2 iv_radius = iv_size / 2 ).
      IF iv_selected = abap_true.
        append_to_page( mv_text_color ).
        circle(
          iv_x      = iv_x + iv_size / 2
          iv_y      = iv_y + iv_size / 2
          iv_radius = iv_size / 4
          iv_style  = 'F' ).
      ENDIF.
      RETURN.
    ENDIF.

    add_field( VALUE ty_field(
      kind    = 'RADIO'
      name    = iv_name
      value   = iv_value
      rect    = field_rect( iv_x = iv_x iv_y = iv_y iv_width = iv_size iv_height = iv_size )
      size    = iv_size
      checked = iv_selected ) ).
  ENDMETHOD.

  METHOD dropdown.
    DATA lv_option TYPE string.
    DATA lv_options TYPE string.

    ro_pdf = me.

    LOOP AT it_options INTO lv_option.
      lv_options = |{ lv_options }({ zcl_open_abap_pdf_font=>escape( lv_option ) }) |.
    ENDLOOP.

    IF mv_flatten = abap_true.
      DATA(lv_saved_x) = mv_x.
      DATA(lv_saved_y) = mv_y.
      set_xy( iv_x = iv_x iv_y = iv_y ).
      cell(
        iv_text   = iv_value
        iv_width  = iv_width
        iv_height = iv_height
        iv_border = '1' ).
      set_xy( iv_x = lv_saved_x iv_y = lv_saved_y ).
      RETURN.
    ENDIF.

    add_field( VALUE ty_field(
      kind     = 'CH'
      name     = iv_name
      value    = iv_value
      options  = lv_options
      rect     = field_rect( iv_x = iv_x iv_y = iv_y iv_width = iv_width iv_height = iv_height )
      flags    = COND i( WHEN iv_editable = abap_true THEN 393216 ELSE 131072 )
      size     = iv_size ) ).
  ENDMETHOD.

  METHOD annots_of_page.
    DATA ls_field TYPE ty_field.

    LOOP AT mt_fields INTO ls_field WHERE page_id = iv_page_id.
      IF rv_annots IS NOT INITIAL.
        rv_annots = rv_annots && | |.
      ENDIF.
      rv_annots = rv_annots && |{ ls_field-obj_id } 0 R|.
    ENDLOOP.
  ENDMETHOD.

  METHOD build_widths.
    DATA ls_glyph TYPE zcl_open_abap_pdf_font=>ty_glyph.

    " One entry per glyph, [ gid [ width ] ], which is compact enough for documents
    LOOP AT it_glyphs INTO ls_glyph.
      IF ls_glyph-gid = 0.
        CONTINUE.
      ENDIF.
      rv_widths = |{ rv_widths }{ ls_glyph-gid } [{ ls_glyph-width }] |.
    ENDLOOP.
  ENDMETHOD.

  METHOD build_to_unicode.
    DATA ls_glyph TYPE zcl_open_abap_pdf_font=>ty_glyph.
    DATA lv_gid TYPE x LENGTH 2.
    DATA lv_cp TYPE x LENGTH 2.
    DATA lv_entries TYPE string.
    DATA lv_count TYPE i.

    LOOP AT it_glyphs INTO ls_glyph.
      IF ls_glyph-gid = 0 OR ls_glyph-cp > 65535.
        CONTINUE.
      ENDIF.
      lv_gid = ls_glyph-gid.
      lv_cp = ls_glyph-cp.
      lv_entries = |{ lv_entries }<{ lv_gid }> <{ lv_cp }>\n|.
      lv_count = lv_count + 1.
    ENDLOOP.

    " Without this map a reader cannot copy or search the text
    rv_cmap = |/CIDInit /ProcSet findresource begin\n12 dict begin\nbegincmap\n| &&
              |/CIDSystemInfo << /Registry (Adobe) /Ordering (UCS) /Supplement 0 >> def\n| &&
              |/CMapName /Adobe-Identity-UCS def\n/CMapType 2 def\n| &&
              |1 begincodespacerange\n<0000> <FFFF>\nendcodespacerange\n| &&
              |{ lv_count } beginbfchar\n{ lv_entries }endbfchar\n| &&
              |endcmap\nCMapName currentdict /CMap defineresource pop\nend\nend|.
  ENDMETHOD.

  METHOD add_truetype_font.
    DATA lt_gids TYPE zcl_open_abap_pdf_ttf=>ty_gids.
    DATA ls_glyph TYPE zcl_open_abap_pdf_font=>ty_glyph.
    DATA lv_file_id TYPE i.
    DATA lv_prefix TYPE string.

    DATA(ls_info) = zcl_open_abap_pdf_font=>ttf_info( iv_name ).
    DATA(lt_glyphs) = zcl_open_abap_pdf_font=>used_glyphs( iv_name ).

    DATA(lv_scale) = CONV f( 1000 ) / ls_info-units.
    DATA(lv_font_data) = ls_info-data.

    IF mv_subset = abap_true.
      LOOP AT lt_glyphs INTO ls_glyph.
        INSERT ls_glyph-gid INTO TABLE lt_gids.
      ENDLOOP.

      TRY.
          lv_font_data = zcl_open_abap_pdf_ttf=>subset( is_info = ls_info it_gids = lt_gids ).
          lv_prefix = 'SUBSET+'.
        CATCH zcx_open_abap_pdf.
          " Fall back to the complete font file rather than losing the document
          lv_font_data = ls_info-data.
      ENDTRY.
    ENDIF.

    DATA(lv_font_dict) = |<< /Length1 { xstrlen( lv_font_data ) }|.

    lv_file_id = add_binary_object( iv_dict = lv_font_dict iv_data = lv_font_data ).

    DATA(lv_descriptor_id) = add_object(
      |<< /Type /FontDescriptor /FontName /{ lv_prefix }{ ls_info-name } /Flags 32 | &&
      |/FontBBox [{ format_number( ls_info-x_min * lv_scale ) } | &&
      |{ format_number( ls_info-y_min * lv_scale ) } | &&
      |{ format_number( ls_info-x_max * lv_scale ) } | &&
      |{ format_number( ls_info-y_max * lv_scale ) }] | &&
      |/ItalicAngle { ls_info-italic_angle } | &&
      |/Ascent { format_number( ls_info-ascent * lv_scale ) } | &&
      |/Descent { format_number( ls_info-descent * lv_scale ) } | &&
      |/CapHeight { format_number( ls_info-cap_height * lv_scale ) } | &&
      |/StemV 80 /FontFile2 { lv_file_id } 0 R >>| ).

    DATA(lv_cid_id) = add_object(
      |<< /Type /Font /Subtype /CIDFontType2 /BaseFont /{ lv_prefix }{ ls_info-name } | &&
      |/CIDSystemInfo << /Registry (Adobe) /Ordering (Identity) /Supplement 0 >> | &&
      |/FontDescriptor { lv_descriptor_id } 0 R /DW 1000 | &&
      |/W [{ build_widths( lt_glyphs ) }] /CIDToGIDMap /Identity >>| ).

    DATA(lv_cmap_id) = add_flate_object(
      iv_data = cl_abap_codepage=>convert_to( build_to_unicode( lt_glyphs ) ) ).

    rv_id = add_object(
      |<< /Type /Font /Subtype /Type0 /BaseFont /{ lv_prefix }{ ls_info-name } | &&
      |/Encoding /Identity-H /DescendantFonts [{ lv_cid_id } 0 R] | &&
      |/ToUnicode { lv_cmap_id } 0 R >>| ).
  ENDMETHOD.

  METHOD resolve_page_count.
    DATA ls_font TYPE ty_font.
    FIELD-SYMBOLS <ls_page> TYPE ty_page.

    IF mv_nb_alias IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lv_count) = |{ lines( mt_pages ) }|.

    LOOP AT mt_pages ASSIGNING <ls_page>.
      REPLACE ALL OCCURRENCES OF mv_nb_alias IN <ls_page>-content WITH lv_count.

      " An embedded font writes glyph indices, so the encoded alias is replaced as well
      LOOP AT mt_fonts INTO ls_font WHERE is_ttf = abap_true.
        REPLACE ALL OCCURRENCES OF
          zcl_open_abap_pdf_font=>glyph_hex( iv_name = ls_font-name iv_text = mv_nb_alias )
          IN <ls_page>-content
          WITH zcl_open_abap_pdf_font=>glyph_hex( iv_name = ls_font-name iv_text = lv_count ).
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD document_id.
    " Deterministic, derived from the content size and the creation time
    DATA(lv_seed) = |{ sy-datum }{ sy-uzeit }{ lines( mt_pages ) }{ lines( mt_objects ) }|.

    rv_id = ''.
    WHILE strlen( rv_id ) < 32.
      rv_id = |{ rv_id }{ lv_seed }|.
    ENDWHILE.
    rv_id = rv_id(32).
    TRANSLATE rv_id USING 'ABCDEFGHIJ0123456789'.
  ENDMETHOD.

  METHOD build_images.
    DATA ls_image TYPE ty_image.
    DATA lv_colorspace TYPE string.
    DATA lv_dict TYPE string.
    DATA lv_filter TYPE string.
    DATA lv_data TYPE xstring.

    LOOP AT mt_images INTO ls_image.
      lv_colorspace = ls_image-info-colorspace.
      lv_filter = ls_image-info-filter.
      lv_data = ls_image-info-data.
      DATA(lv_palette) = ls_image-info-palette.

      IF mv_hex_images = abap_true.
        lv_filter = |[/ASCIIHexDecode { ls_image-info-filter }]|.
        lv_data = cl_abap_codepage=>convert_to( |{ lv_data }>| ).
        IF lv_palette IS NOT INITIAL.
          lv_palette = cl_abap_codepage=>convert_to( |{ lv_palette }>| ).
        ENDIF.
      ENDIF.

      IF lv_colorspace = '/Indexed'.
        IF mv_hex_images = abap_true.
          ls_image-pal_id = add_stream_object(
            iv_dict = '<< /Filter /ASCIIHexDecode'
            iv_data = lv_palette ).
        ELSE.
          ls_image-pal_id = add_stream_object( iv_data = lv_palette ).
        ENDIF.
        lv_colorspace = |[/Indexed /DeviceRGB { xstrlen( ls_image-info-palette ) / 3 - 1 } | &&
                        |{ ls_image-pal_id } 0 R]|.
      ENDIF.

      lv_dict = |<< /Type /XObject /Subtype /Image /Width { ls_image-info-width } | &&
                |/Height { ls_image-info-height } /ColorSpace { lv_colorspace } | &&
                |/BitsPerComponent { ls_image-info-bpc } /Filter { lv_filter }|.
      IF ls_image-info-decode_parms IS NOT INITIAL.
        IF mv_hex_images = abap_true.
          lv_dict = |{ lv_dict } /DecodeParms [null { ls_image-info-decode_parms }]|.
        ELSE.
          lv_dict = |{ lv_dict } /DecodeParms { ls_image-info-decode_parms }|.
        ENDIF.
      ENDIF.

      ls_image-obj_id = add_stream_object( iv_dict = lv_dict iv_data = lv_data ).
      MODIFY mt_images FROM ls_image INDEX sy-tabix.

      IF rv_xobjects IS NOT INITIAL.
        rv_xobjects = rv_xobjects && | |.
      ENDIF.
      rv_xobjects = rv_xobjects && |/Im{ ls_image-id } { ls_image-obj_id } 0 R|.
    ENDLOOP.
  ENDMETHOD.

  METHOD render.
    rv_pdf = cl_abap_codepage=>convert_from( render_binary( ) ).
  ENDMETHOD.

  METHOD render_binary.
    DATA lo_writer TYPE REF TO zcl_open_abap_pdf_writer.
    DATA ls_object TYPE ty_object.
    DATA lt_offsets TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
    DATA lv_offset_val TYPE i.
    DATA lv_offset_str TYPE string.
    DATA lv_obj_count TYPE i.
    DATA lv_startxref TYPE i.

    DATA(lv_catalog_id) = build_objects( ).

    " The xref table lists the objects in ascending object number
    SORT mt_objects BY id.

    CREATE OBJECT lo_writer.

    " Header, with binary marker so readers treat the file as binary
    " PDF/A-3 builds on PDF 1.7, everything else here stays within 1.4
    DATA(lv_version) = COND string( WHEN mv_pdfa_part = 3 THEN '1.7' ELSE '1.4' ).
    lo_writer->add_string( |%PDF-{ lv_version }\n%| ).
    lo_writer->add_xstring( CONV xstring( 'C2B5C2B6' ) ).
    lo_writer->add_string( |\n| ).

    " Objects, tracking byte offsets for the xref table
    LOOP AT mt_objects INTO ls_object.
      APPEND lo_writer->length( ) TO lt_offsets.
      lo_writer->add_string( |{ ls_object-id } 0 obj\n{ ls_object-content }\n| ).
      IF ls_object-is_stream = abap_true.
        lo_writer->add_string( |stream\n| ).
        lo_writer->add_xstring( ls_object-stream ).
        lo_writer->add_string( |\nendstream\n| ).
      ENDIF.
      lo_writer->add_string( |endobj\n| ).
    ENDLOOP.

    " Cross-reference table
    lv_startxref = lo_writer->length( ).
    lv_obj_count = lines( mt_objects ) + 1.
    lo_writer->add_string( |xref\n0 { lv_obj_count }\n0000000000 65535 f \n| ).

    LOOP AT lt_offsets INTO lv_offset_val.
      lv_offset_str = |{ lv_offset_val }|.
      WHILE strlen( lv_offset_str ) < 10.
        lv_offset_str = '0' && lv_offset_str.
      ENDWHILE.
      lo_writer->add_string( |{ lv_offset_str } 00000 n \n| ).
    ENDLOOP.

    DATA(lv_trailer) = |<< /Size { lv_obj_count } /Root { lv_catalog_id } 0 R|.
    IF mv_info_id > 0.
      lv_trailer = |{ lv_trailer } /Info { mv_info_id } 0 R|.
    ENDIF.
    IF mv_pdfa = abap_true.
      DATA(lv_doc_id) = document_id( ).
      lv_trailer = |{ lv_trailer } /ID [<{ lv_doc_id }> <{ lv_doc_id }>]|.
    ENDIF.

    lo_writer->add_string( |trailer\n{ lv_trailer } >>\nstartxref\n{ lv_startxref }\n%%EOF| ).

    rv_pdf = lo_writer->get( ).
  ENDMETHOD.

  METHOD get_page_count.
    rv_count = lines( mt_pages ).
  ENDMETHOD.

  METHOD get_page_width.
    DATA ls_page TYPE ty_page.
    READ TABLE mt_pages INTO ls_page INDEX mv_current_page.
    IF sy-subrc = 0.
      rv_width = ls_page-width.
    ENDIF.
  ENDMETHOD.

  METHOD get_page_height.
    DATA ls_page TYPE ty_page.
    READ TABLE mt_pages INTO ls_page INDEX mv_current_page.
    IF sy-subrc = 0.
      rv_height = ls_page-height.
    ENDIF.
  ENDMETHOD.

  METHOD get_text_width.
    DATA(lv_font) = mv_current_font.
    DATA(lv_size) = mv_current_font_size.

    IF iv_font IS SUPPLIED AND iv_font IS NOT INITIAL.
      lv_font = iv_font.
    ENDIF.
    IF iv_size > 0.
      lv_size = iv_size.
    ENDIF.

    rv_width = zcl_open_abap_pdf_font=>text_width(
      iv_font = lv_font
      iv_size = lv_size
      iv_text = iv_text ).
  ENDMETHOD.

  METHOD mm_to_pt.
    rv_pt = iv_mm * c_pt_per_mm.
  ENDMETHOD.

  METHOD inch_to_pt.
    rv_pt = iv_inch * 72.
  ENDMETHOD.

  METHOD add_object.
    DATA(lv_id) = iv_id.
    IF lv_id = 0.
      lv_id = reserve_id( ).
    ENDIF.

    DATA(ls_object) = VALUE ty_object(
        id = lv_id
        content = iv_content ).
    APPEND ls_object TO mt_objects.
    rv_id = lv_id.
  ENDMETHOD.

  METHOD reserve_id.
    rv_id = mv_next_obj_id.
    mv_next_obj_id = mv_next_obj_id + 1.
  ENDMETHOD.

  METHOD add_stream_object.
    DATA(ls_object) = VALUE ty_object(
        id = reserve_id( )
        content = |{ iv_dict } /Length { xstrlen( iv_data ) } >>|
        stream = iv_data
        is_stream = abap_true ).
    APPEND ls_object TO mt_objects.
    rv_id = ls_object-id.
  ENDMETHOD.

  METHOD escape_string.
    rv_escaped = zcl_open_abap_pdf_font=>escape( iv_text ).
  ENDMETHOD.

  METHOD get_font_id.
    DATA ls_font TYPE ty_font.
    LOOP AT mt_fonts INTO ls_font WHERE name = iv_name.
      rv_id = ls_font-id.
      RETURN.
    ENDLOOP.
    rv_id = 0.
  ENDMETHOD.

  METHOD ensure_font.
    DATA ls_font TYPE ty_font.
    READ TABLE mt_fonts WITH KEY name = iv_name TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
      ls_font-name = iv_name.
      ls_font-id = lines( mt_fonts ) + 1.
      ls_font-is_ttf = zcl_open_abap_pdf_font=>is_truetype( iv_name ).
      APPEND ls_font TO mt_fonts.
    ENDIF.
  ENDMETHOD.

  METHOD transform_y.
    DATA ls_page TYPE ty_page.
    READ TABLE mt_pages INTO ls_page INDEX mv_current_page.
    IF sy-subrc = 0.
      rv_y = ls_page-height - iv_y.
    ELSE.
      rv_y = iv_y.
    ENDIF.
  ENDMETHOD.

  METHOD format_number.
    DATA lv_int TYPE i.
    DATA lv_dec TYPE i.
    DATA lv_abs TYPE f.
    DATA lv_str TYPE string.
    DATA lv_dec_str TYPE string.
    DATA lv_neg TYPE abap_bool.
    DATA lv_fraction TYPE f.
    DATA lv_temp TYPE f.

    " Handle negative numbers
    IF iv_number < 0.
      lv_neg = abap_true.
      lv_abs = iv_number * -1.
    ELSE.
      lv_neg = abap_false.
      lv_abs = iv_number.
    ENDIF.

    " Get integer part
    lv_int = floor( lv_abs ).

    " Get decimal part (2 decimal places is enough for PDF)
    lv_fraction = lv_abs - lv_int.
    lv_temp = lv_fraction * 100.
    lv_dec = round( val = lv_temp dec = 0 ).

    " Handle rounding up to next integer
    IF lv_dec >= 100.
      lv_int = lv_int + 1.
      lv_dec = 0.
    ENDIF.

    " Build result
    IF lv_neg = abap_true.
      lv_str = |-{ lv_int }|.
    ELSE.
      lv_str = |{ lv_int }|.
    ENDIF.

    " Add decimals if non-zero
    IF lv_dec > 0.
      IF lv_dec < 10.
        lv_dec_str = |0{ lv_dec }|.
      ELSE.
        lv_dec_str = |{ lv_dec }|.
      ENDIF.
      " Remove trailing zero
      IF strlen( lv_dec_str ) = 2.
        IF lv_dec_str+1(1) = '0'.
          lv_dec_str = lv_dec_str(1).
        ENDIF.
      ENDIF.
      lv_str = lv_str && '.' && lv_dec_str.
    ENDIF.

    rv_string = lv_str.
  ENDMETHOD.

  METHOD append_to_page.
    FIELD-SYMBOLS <ls_page> TYPE ty_page.

    READ TABLE mt_pages ASSIGNING <ls_page> INDEX mv_current_page.
    IF sy-subrc = 0.
      IF <ls_page>-content IS NOT INITIAL.
        <ls_page>-content = <ls_page>-content && ` `.
      ENDIF.
      <ls_page>-content = <ls_page>-content && iv_content.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
