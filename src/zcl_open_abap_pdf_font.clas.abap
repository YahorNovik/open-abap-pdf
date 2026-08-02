CLASS zcl_open_abap_pdf_font DEFINITION PUBLIC FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    TYPES ty_lines TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    TYPES ty_codes TYPE STANDARD TABLE OF i WITH DEFAULT KEY.

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

    CLASS-DATA gt_cache TYPE ty_caches.

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

  METHOD text_width.
    DATA lv_code TYPE i.
    DATA lv_offset TYPE i.
    DATA lv_sum TYPE i.

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

      APPEND unicode_to_winansi( lv_cp ) TO rt_codes.
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
