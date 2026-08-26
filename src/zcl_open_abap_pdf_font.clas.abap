CLASS zcl_open_abap_pdf_font DEFINITION PUBLIC FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    TYPES ty_lines TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    TYPES ty_codes TYPE STANDARD TABLE OF i WITH DEFAULT KEY.

    TYPES:
      BEGIN OF ty_glyph,
        cp    TYPE i,
        gid   TYPE i,
        width TYPE i,
      END OF ty_glyph,
      ty_glyphs TYPE SORTED TABLE OF ty_glyph WITH UNIQUE KEY cp.

    "! Width of a text in points for the given Base-14 font and size
    CLASS-METHODS text_width
      IMPORTING iv_font         TYPE string
                iv_size         TYPE f
                iv_text         TYPE string
      RETURNING VALUE(rv_width) TYPE f.

    "! Break a text into lines that fit into iv_width points.
    "! Existing line breaks in iv_text are kept, long words are split.
    CLASS-METHODS wrap
      IMPORTING iv_font         TYPE string
                iv_size         TYPE f
                iv_text         TYPE string
                iv_width        TYPE f
      RETURNING VALUE(rt_lines) TYPE ty_lines.

    "! Characters of iv_text that cannot be encoded and would be printed as a question mark.
    "! Use it to detect silent data loss before shipping a document, for example customer
    "! names with Polish, Turkish or Cyrillic letters.
    CLASS-METHODS unsupported
      IMPORTING iv_text        TYPE string
      RETURNING VALUE(rv_char) TYPE string.

    "! Shorten a text so that it fits into iv_width, adding an ellipsis
    CLASS-METHODS truncate
      IMPORTING iv_font        TYPE string
                iv_size        TYPE f
                iv_text        TYPE string
                iv_width       TYPE f
                iv_ellipsis    TYPE string DEFAULT '...'
      RETURNING VALUE(rv_text) TYPE string.

    "! Escape a text for a PDF literal string, non-ASCII as WinAnsi octal
    CLASS-METHODS escape
      IMPORTING iv_text           TYPE string
      RETURNING VALUE(rv_escaped) TYPE string.

    "! WinAnsi code points of a text, unsupported characters become '?'
    CLASS-METHODS to_codes
      IMPORTING iv_text         TYPE string
      RETURNING VALUE(rt_codes) TYPE ty_codes.

    "! Unicode code points of a text
    CLASS-METHODS to_unicode
      IMPORTING iv_text         TYPE string
      RETURNING VALUE(rt_codes) TYPE ty_codes.

    "! Make a TrueType font available under iv_name for set_font and text_width
    "! @raising zcx_open_abap_pdf | Unsupported font file
    CLASS-METHODS register_truetype
      IMPORTING iv_name TYPE string
                iv_data TYPE xstring
      RAISING   zcx_open_abap_pdf.

    CLASS-METHODS is_truetype
      IMPORTING iv_name       TYPE string
      RETURNING VALUE(rv_yes) TYPE abap_bool.

    CLASS-METHODS ttf_info
      IMPORTING iv_name        TYPE string
      RETURNING VALUE(rs_info) TYPE zcl_open_abap_pdf_ttf=>ty_info.

    "! Glyph indices of a text as hex string, for use with the Identity-H encoding.
    "! The glyphs are remembered so that only used glyphs are described in the PDF.
    CLASS-METHODS glyph_hex
      IMPORTING iv_name       TYPE string
                iv_text       TYPE string
      RETURNING VALUE(rv_hex) TYPE string.

    "! Glyphs of a font that were used so far
    CLASS-METHODS used_glyphs
      IMPORTING iv_name          TYPE string
      RETURNING VALUE(rt_glyphs) TYPE ty_glyphs.

    "! True if the font name is one of the Base-14 fonts with known metrics
    CLASS-METHODS is_supported
      IMPORTING iv_font       TYPE string
      RETURNING VALUE(rv_yes) TYPE abap_bool.

  PRIVATE SECTION.
    CONSTANTS c_ascii TYPE string
      VALUE ' !"#$%&''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~'.

    TYPES:
      BEGIN OF ty_cache,
        font   TYPE string,
        widths TYPE string,
      END OF ty_cache,
      ty_caches TYPE STANDARD TABLE OF ty_cache WITH DEFAULT KEY.

    TYPES:
      BEGIN OF ty_ttf,
        name   TYPE string,
        info   TYPE zcl_open_abap_pdf_ttf=>ty_info,
        glyphs TYPE ty_glyphs,
      END OF ty_ttf,
      ty_ttfs TYPE STANDARD TABLE OF ty_ttf WITH DEFAULT KEY.

    CLASS-DATA gt_cache TYPE ty_caches.
    CLASS-DATA gt_ttf TYPE ty_ttfs.

    CLASS-METHODS glyph_of
      IMPORTING iv_name         TYPE string
                iv_cp           TYPE i
      RETURNING VALUE(rs_glyph) TYPE ty_glyph.

    " WinAnsi specials outside Latin-1, packed as 4 digit code point + 3 digit WinAnsi code
    CONSTANTS c_specials TYPE string
      VALUE '8364128821813004021318222132823013382241348225135071013682401370352138824913903381400381142'.
    CONSTANTS c_specials2 TYPE string
      VALUE '82161458217146822014782211488226149821115082121510732152848215303531548250155033915603821580376159'.

    CLASS-METHODS get_widths
      IMPORTING iv_font          TYPE string
      RETURNING VALUE(rv_widths) TYPE string.

    CLASS-METHODS unicode_to_winansi
      IMPORTING iv_cp          TYPE i
      RETURNING VALUE(rv_code) TYPE i.

    CLASS-METHODS to_octal
      IMPORTING iv_code         TYPE i
      RETURNING VALUE(rv_octal) TYPE string.
ENDCLASS.

CLASS zcl_open_abap_pdf_font IMPLEMENTATION.

  METHOD is_supported.
    rv_yes = zcl_open_abap_pdf_metrics=>is_supported( iv_font ).
  ENDMETHOD.

  METHOD get_widths.
    DATA ls_cache TYPE ty_cache.

    READ TABLE gt_cache INTO ls_cache WITH KEY font = iv_font.
    IF sy-subrc = 0.
      rv_widths = ls_cache-widths.
      RETURN.
    ENDIF.

    ls_cache-font = iv_font.
    ls_cache-widths = zcl_open_abap_pdf_metrics=>widths( iv_font ).
    APPEND ls_cache TO gt_cache.
    rv_widths = ls_cache-widths.
  ENDMETHOD.

  METHOD register_truetype.
    DATA ls_ttf TYPE ty_ttf.

    DELETE gt_ttf WHERE name = iv_name.

    ls_ttf-name = iv_name.
    ls_ttf-info = zcl_open_abap_pdf_ttf=>parse( iv_data = iv_data iv_name = iv_name ).
    APPEND ls_ttf TO gt_ttf.
  ENDMETHOD.

  METHOD is_truetype.
    READ TABLE gt_ttf TRANSPORTING NO FIELDS WITH KEY name = iv_name.
    rv_yes = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD ttf_info.
    READ TABLE gt_ttf INTO DATA(ls_ttf) WITH KEY name = iv_name.
    IF sy-subrc = 0.
      rs_info = ls_ttf-info.
    ENDIF.
  ENDMETHOD.

  METHOD used_glyphs.
    READ TABLE gt_ttf INTO DATA(ls_ttf) WITH KEY name = iv_name.
    IF sy-subrc = 0.
      rt_glyphs = ls_ttf-glyphs.
    ENDIF.
  ENDMETHOD.

  METHOD glyph_of.
    FIELD-SYMBOLS <ls_ttf> TYPE ty_ttf.

    READ TABLE gt_ttf ASSIGNING <ls_ttf> WITH KEY name = iv_name.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    READ TABLE <ls_ttf>-glyphs INTO rs_glyph WITH KEY cp = iv_cp.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.

    rs_glyph-cp = iv_cp.
    rs_glyph-gid = zcl_open_abap_pdf_ttf=>glyph_id( is_info = <ls_ttf>-info iv_cp = iv_cp ).
    rs_glyph-width = zcl_open_abap_pdf_ttf=>advance(
      is_info = <ls_ttf>-info
      iv_gid  = rs_glyph-gid ) * 1000 / <ls_ttf>-info-units.

    INSERT rs_glyph INTO TABLE <ls_ttf>-glyphs.
  ENDMETHOD.

  METHOD glyph_hex.
    DATA lv_cp TYPE i.
    DATA lv_gid TYPE i.
    DATA lv_hex TYPE x LENGTH 2.

    LOOP AT to_unicode( iv_text ) INTO lv_cp.
      lv_gid = glyph_of( iv_name = iv_name iv_cp = lv_cp )-gid.
      lv_hex = lv_gid.
      rv_hex = rv_hex && |{ lv_hex }|.
    ENDLOOP.
  ENDMETHOD.

  METHOD text_width.
    DATA lv_code TYPE i.
    DATA lv_offset TYPE i.
    DATA lv_sum TYPE i.

    IF is_truetype( iv_font ) = abap_true.
      LOOP AT to_unicode( iv_text ) INTO lv_code.
        lv_sum = lv_sum + glyph_of( iv_name = iv_font iv_cp = lv_code )-width.
      ENDLOOP.
      rv_width = lv_sum * iv_size / 1000.
      RETURN.
    ENDIF.

    DATA(lv_widths) = get_widths( iv_font ).

    LOOP AT to_codes( iv_text ) INTO lv_code.
      IF lv_code < zcl_open_abap_pdf_metrics=>c_first_code
          OR lv_code > zcl_open_abap_pdf_metrics=>c_last_code.
        lv_code = 63.
      ENDIF.
      lv_offset = ( lv_code - zcl_open_abap_pdf_metrics=>c_first_code ) * 3.
      lv_sum = lv_sum + CONV i( lv_widths+lv_offset(3) ).
    ENDLOOP.

    rv_width = lv_sum * iv_size / 1000.
  ENDMETHOD.

  METHOD wrap.
    DATA lt_paragraphs TYPE ty_lines.
    DATA lv_paragraph TYPE string.
    DATA lv_word TYPE string.
    DATA lv_line TYPE string.
    DATA lv_candidate TYPE string.
    DATA lv_char TYPE string.
    DATA lv_i TYPE i.

    SPLIT iv_text AT |\n| INTO TABLE lt_paragraphs.

    LOOP AT lt_paragraphs INTO lv_paragraph.
      CLEAR lv_line.

      SPLIT lv_paragraph AT ` ` INTO TABLE DATA(lt_words).
      LOOP AT lt_words INTO lv_word.
        IF lv_line IS INITIAL.
          lv_candidate = lv_word.
        ELSE.
          lv_candidate = |{ lv_line } { lv_word }|.
        ENDIF.

        IF text_width( iv_font = iv_font iv_size = iv_size iv_text = lv_candidate ) <= iv_width.
          lv_line = lv_candidate.
          CONTINUE.
        ENDIF.

        IF lv_line IS NOT INITIAL.
          APPEND lv_line TO rt_lines.
          CLEAR lv_line.
        ENDIF.

        " Word alone is too wide, split it character by character
        IF text_width( iv_font = iv_font iv_size = iv_size iv_text = lv_word ) <= iv_width.
          lv_line = lv_word.
          CONTINUE.
        ENDIF.

        lv_i = 0.
        WHILE lv_i < strlen( lv_word ).
          lv_char = lv_word+lv_i(1).
          lv_candidate = lv_line && lv_char.
          IF lv_line IS NOT INITIAL
              AND text_width( iv_font = iv_font iv_size = iv_size iv_text = lv_candidate ) > iv_width.
            APPEND lv_line TO rt_lines.
            lv_line = lv_char.
          ELSE.
            lv_line = lv_candidate.
          ENDIF.
          lv_i = lv_i + 1.
        ENDWHILE.
      ENDLOOP.

      APPEND lv_line TO rt_lines.
    ENDLOOP.
  ENDMETHOD.

  METHOD unsupported.
    DATA lv_char TYPE string.
    DATA lv_offset TYPE i.
    DATA lt_codes TYPE ty_codes.

    WHILE lv_offset < strlen( iv_text ).
      lv_char = iv_text+lv_offset(1).
      lv_offset = lv_offset + 1.

      IF lv_char = '?'.
        CONTINUE.
      ENDIF.

      lt_codes = to_codes( lv_char ).
      READ TABLE lt_codes INTO DATA(lv_code) INDEX 1.
      IF sy-subrc = 0 AND lv_code = 63 AND rv_char NS lv_char.
        rv_char = rv_char && lv_char.
      ENDIF.
    ENDWHILE.
  ENDMETHOD.

  METHOD truncate.
    DATA lv_length TYPE i.

    rv_text = iv_text.
    IF text_width( iv_font = iv_font iv_size = iv_size iv_text = rv_text ) <= iv_width.
      RETURN.
    ENDIF.

    lv_length = strlen( iv_text ).
    WHILE lv_length > 0.
      lv_length = lv_length - 1.
      rv_text = |{ iv_text(lv_length) }{ iv_ellipsis }|.
      IF text_width( iv_font = iv_font iv_size = iv_size iv_text = rv_text ) <= iv_width.
        RETURN.
      ENDIF.
    ENDWHILE.

    rv_text = ''.
  ENDMETHOD.

  METHOD escape.
    DATA lv_code TYPE i.
    DATA lv_offset TYPE i.

    LOOP AT to_codes( iv_text ) INTO lv_code.
      IF lv_code < 32 OR lv_code > 126.
        rv_escaped = rv_escaped && |\\{ to_octal( lv_code ) }|.
        CONTINUE.
      ENDIF.

      lv_offset = lv_code - 32.
      IF lv_code = 40 OR lv_code = 41 OR lv_code = 92.
        rv_escaped = rv_escaped && |\\| && c_ascii+lv_offset(1).
      ELSE.
        rv_escaped = rv_escaped && c_ascii+lv_offset(1).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD to_octal.
    DATA lv_rest TYPE i.

    lv_rest = iv_code.
    DO 3 TIMES.
      rv_octal = |{ lv_rest MOD 8 }{ rv_octal }|.
      lv_rest = lv_rest DIV 8.
    ENDDO.
  ENDMETHOD.

  METHOD to_codes.
    DATA lv_cp TYPE i.

    LOOP AT to_unicode( iv_text ) INTO lv_cp.
      APPEND unicode_to_winansi( lv_cp ) TO rt_codes.
    ENDLOOP.
  ENDMETHOD.

  METHOD to_unicode.
    DATA lv_bytes TYPE xstring.
    DATA lv_byte TYPE x LENGTH 1.
    DATA lv_b1 TYPE i.
    DATA lv_b2 TYPE i.
    DATA lv_b3 TYPE i.
    DATA lv_cp TYPE i.
    DATA lv_i TYPE i.

    lv_bytes = cl_abap_codepage=>convert_to( iv_text ).

    WHILE lv_i < xstrlen( lv_bytes ).
      lv_byte = lv_bytes+lv_i(1).
      lv_b1 = lv_byte.

      lv_i = lv_i + 1.

      IF lv_b1 < 128.
        lv_cp = lv_b1.
      ELSEIF lv_b1 >= 192 AND lv_b1 < 224 AND lv_i < xstrlen( lv_bytes ).
        lv_byte = lv_bytes+lv_i(1).
        lv_b2 = lv_byte.
        lv_i = lv_i + 1.
        lv_cp = ( lv_b1 - 192 ) * 64 + lv_b2 - 128.
      ELSEIF lv_b1 >= 224 AND lv_b1 < 240 AND lv_i + 1 < xstrlen( lv_bytes ).
        lv_byte = lv_bytes+lv_i(1).
        lv_b2 = lv_byte.
        lv_i = lv_i + 1.
        lv_byte = lv_bytes+lv_i(1).
        lv_b3 = lv_byte.
        lv_i = lv_i + 1.
        lv_cp = ( lv_b1 - 224 ) * 4096 + ( lv_b2 - 128 ) * 64 + lv_b3 - 128.
      ELSE.
        lv_cp = 63.
      ENDIF.

      APPEND lv_cp TO rt_codes.
    ENDWHILE.
  ENDMETHOD.

  METHOD unicode_to_winansi.
    DATA lv_offset TYPE i.
    DATA lv_table TYPE string.

    IF iv_cp <= 255.
      rv_code = iv_cp.
      RETURN.
    ENDIF.

    lv_table = c_specials && c_specials2.
    WHILE lv_offset + 7 <= strlen( lv_table ).
      IF CONV i( lv_table+lv_offset(4) ) = iv_cp.
        lv_offset = lv_offset + 4.
        rv_code = lv_table+lv_offset(3).
        RETURN.
      ENDIF.
      lv_offset = lv_offset + 7.
    ENDWHILE.

    rv_code = 63.
  ENDMETHOD.

ENDCLASS.
