CLASS zcl_open_abap_pdf_reader DEFINITION PUBLIC FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_field,
        name  TYPE string,
        value TYPE string,
      END OF ty_field,
      ty_fields TYPE STANDARD TABLE OF ty_field WITH DEFAULT KEY.

    "! Read the values of the interactive fields out of a PDF, for example a form
    "! that a customer filled in and sent back. Compressed object streams are
    "! unpacked, so documents saved by a reader are handled as well.
    "! The document is scanned as bytes, so binary streams cannot break it.
    "! @raising zcx_open_abap_pdf | Not a PDF
    CLASS-METHODS read_fields
      IMPORTING iv_pdf           TYPE xstring
      RETURNING VALUE(rt_fields) TYPE ty_fields
      RAISING   zcx_open_abap_pdf.

    "! Number of pages, counted from the page objects
    CLASS-METHODS page_count
      IMPORTING iv_pdf          TYPE xstring
      RETURNING VALUE(rv_count) TYPE i
      RAISING   zcx_open_abap_pdf.

  PRIVATE SECTION.
    CLASS-METHODS check_header
      IMPORTING iv_pdf TYPE xstring
      RAISING   zcx_open_abap_pdf.

    "! Offset of a text inside the bytes, -1 when it does not occur
    CLASS-METHODS find
      IMPORTING iv_pdf           TYPE xstring
                iv_text          TYPE string
                iv_from          TYPE i DEFAULT 0
      RETURNING VALUE(rv_offset) TYPE i.

    CLASS-METHODS text_at
      IMPORTING iv_pdf         TYPE xstring
                iv_from        TYPE i
                iv_length      TYPE i
      RETURNING VALUE(rv_text) TYPE string.

    CLASS-METHODS collect_fields
      IMPORTING iv_pdf    TYPE xstring
      CHANGING  ct_fields TYPE ty_fields.

    CLASS-METHODS inflate_streams
      IMPORTING iv_pdf         TYPE xstring
      RETURNING VALUE(rv_data) TYPE xstring.

    CLASS-METHODS count_pages
      IMPORTING iv_data         TYPE xstring
      RETURNING VALUE(rv_count) TYPE i.

    CLASS-METHODS unescape
      IMPORTING iv_text        TYPE string
      RETURNING VALUE(rv_text) TYPE string.

    "! Offset of the next byte that is not a blank or a line break
    CLASS-METHODS skip_blanks
      IMPORTING iv_pdf           TYPE xstring
                iv_from          TYPE i
      RETURNING VALUE(rv_offset) TYPE i.

    "! Read a PDF string, either ( literal ) or < hex >, at iv_from
    CLASS-METHODS parse_string
      IMPORTING iv_pdf  TYPE xstring
                iv_from TYPE i
      EXPORTING ev_text TYPE string
                ev_next TYPE i.

    "! Read a PDF name such as /Yes at iv_from
    CLASS-METHODS parse_name
      IMPORTING iv_pdf  TYPE xstring
                iv_from TYPE i
      EXPORTING ev_text TYPE string
                ev_next TYPE i.
ENDCLASS.

CLASS zcl_open_abap_pdf_reader IMPLEMENTATION.

  METHOD check_header.
    DATA(lv_magic) = CONV xstring( '25504446' ).

    IF xstrlen( iv_pdf ) < 8 OR iv_pdf(4) <> lv_magic.
      zcx_open_abap_pdf=>raise( 'not a PDF, the header is missing' ).
    ENDIF.
  ENDMETHOD.

  METHOD find.
    rv_offset = -1.

    IF iv_from >= xstrlen( iv_pdf ).
      RETURN.
    ENDIF.

    FIND FIRST OCCURRENCE OF cl_abap_codepage=>convert_to( iv_text )
      IN SECTION OFFSET iv_from OF iv_pdf IN BYTE MODE
      MATCH OFFSET DATA(lv_offset).
    IF sy-subrc = 0.
      rv_offset = lv_offset.
    ENDIF.
  ENDMETHOD.

  METHOD text_at.
    DATA(lv_length) = iv_length.
    IF iv_from + lv_length > xstrlen( iv_pdf ).
      lv_length = xstrlen( iv_pdf ) - iv_from.
    ENDIF.
    IF lv_length <= 0.
      RETURN.
    ENDIF.

    rv_text = cl_abap_codepage=>convert_from( iv_pdf+iv_from(lv_length) ).
  ENDMETHOD.

  METHOD unescape.
    rv_text = iv_text.
    REPLACE ALL OCCURRENCES OF '\(' IN rv_text WITH '('.
    REPLACE ALL OCCURRENCES OF '\)' IN rv_text WITH ')'.
    REPLACE ALL OCCURRENCES OF '\\' IN rv_text WITH '\'.
  ENDMETHOD.

  METHOD skip_blanks.
    rv_offset = iv_from.
    WHILE rv_offset < xstrlen( iv_pdf ).
      DATA(lv_char) = text_at( iv_pdf = iv_pdf iv_from = rv_offset iv_length = 1 ).
      IF lv_char <> ` ` AND lv_char <> |\n| AND lv_char <> |\r| AND lv_char <> |\t|.
        RETURN.
      ENDIF.
      rv_offset = rv_offset + 1.
    ENDWHILE.
  ENDMETHOD.

  METHOD parse_string.
    ev_next = skip_blanks( iv_pdf = iv_pdf iv_from = iv_from ).
    DATA(lv_open) = text_at( iv_pdf = iv_pdf iv_from = ev_next iv_length = 1 ).

    IF lv_open = '('.
      " A backslash escapes the next byte, and parentheses may be nested,
      " so the end cannot be found by searching for the first bracket
      DATA(lv_escape) = CONV xstring( '5C' ).
      DATA(lv_left) = CONV xstring( '28' ).
      DATA(lv_right) = CONV xstring( '29' ).

      DATA(lv_start) = ev_next + 1.
      DATA(lv_pos) = lv_start.
      DATA(lv_depth) = 1.

      WHILE lv_pos < xstrlen( iv_pdf ).
        DATA(lv_byte) = iv_pdf+lv_pos(1).

        IF lv_byte = lv_escape.
          lv_pos = lv_pos + 2.
          CONTINUE.
        ENDIF.

        " any other byte simply belongs to the value
        CASE lv_byte.
          WHEN lv_left.
            lv_depth = lv_depth + 1.
          WHEN lv_right.
            lv_depth = lv_depth - 1.
            IF lv_depth = 0.
              EXIT.
            ENDIF.
        ENDCASE.

        lv_pos = lv_pos + 1.
      ENDWHILE.

      ev_text = unescape( text_at(
        iv_pdf    = iv_pdf
        iv_from   = lv_start
        iv_length = lv_pos - lv_start ) ).
      ev_next = lv_pos + 1.
      RETURN.
    ENDIF.

    IF lv_open = '<'.
      DATA(lv_end) = find( iv_pdf = iv_pdf iv_text = '>' iv_from = ev_next + 1 ).
      IF lv_end < 0.
        RETURN.
      ENDIF.
      lv_start = ev_next + 1.
      DATA(lv_hex) = text_at(
        iv_pdf    = iv_pdf
        iv_from   = lv_start
        iv_length = lv_end - lv_start ).
      TRY.
          ev_text = cl_abap_codepage=>convert_from( CONV xstring( lv_hex ) ).
        CATCH cx_root.
          CLEAR ev_text.
      ENDTRY.
      ev_next = lv_end + 1.
    ENDIF.
  ENDMETHOD.

  METHOD parse_name.
    ev_next = skip_blanks( iv_pdf = iv_pdf iv_from = iv_from ).
    IF text_at( iv_pdf = iv_pdf iv_from = ev_next iv_length = 1 ) <> '/'.
      RETURN.
    ENDIF.

    ev_next = ev_next + 1.
    WHILE ev_next < xstrlen( iv_pdf ).
      DATA(lv_char) = text_at( iv_pdf = iv_pdf iv_from = ev_next iv_length = 1 ).
      IF lv_char CA '/[]<>() ' OR lv_char = |\n| OR lv_char = |\r|.
        RETURN.
      ENDIF.
      ev_text = |{ ev_text }{ lv_char }|.
      ev_next = ev_next + 1.
    ENDWHILE.
  ENDMETHOD.

  METHOD collect_fields.
    DATA ls_field TYPE ty_field.
    DATA lv_offset TYPE i.
    DATA lv_value TYPE string.
    DATA lv_name TYPE string.
    DATA lv_next TYPE i.

    " A field dictionary has /T with the name and /V with the value. Writers put a
    " blank between key and value or not, and the value is a string or a name,
    " for example /V (text), /V <hex> or /V /Yes for a check box.
    WHILE lv_offset >= 0.
      DATA(lv_key) = find( iv_pdf = iv_pdf iv_text = '/T' iv_from = lv_offset ).
      IF lv_key < 0.
        RETURN.
      ENDIF.
      lv_offset = lv_key + 2.

      parse_string(
        EXPORTING iv_pdf  = iv_pdf
                  iv_from = lv_offset
        IMPORTING ev_text = lv_name
                  ev_next = lv_next ).
      IF lv_name IS INITIAL.
        CONTINUE.
      ENDIF.

      " Only look inside the same dictionary
      DATA(lv_dict_end) = find( iv_pdf = iv_pdf iv_text = '>>' iv_from = lv_next ).
      IF lv_dict_end < 0.
        lv_dict_end = xstrlen( iv_pdf ).
      ENDIF.

      CLEAR lv_value.
      DATA(lv_value_key) = find( iv_pdf = iv_pdf iv_text = '/V' iv_from = lv_next ).
      IF lv_value_key >= 0 AND lv_value_key < lv_dict_end.
        parse_string(
          EXPORTING iv_pdf  = iv_pdf
                    iv_from = lv_value_key + 2
          IMPORTING ev_text = lv_value ).
        IF lv_value IS INITIAL.
          parse_name(
            EXPORTING iv_pdf  = iv_pdf
                      iv_from = lv_value_key + 2
            IMPORTING ev_text = lv_value ).
        ENDIF.
      ENDIF.

      ls_field-name = lv_name.
      ls_field-value = lv_value.

      READ TABLE ct_fields TRANSPORTING NO FIELDS WITH KEY name = ls_field-name.
      IF sy-subrc <> 0.
        APPEND ls_field TO ct_fields.
      ENDIF.

      lv_offset = lv_next.
    ENDWHILE.
  ENDMETHOD.

  METHOD inflate_streams.
    DATA lv_raw TYPE xstring.
    DATA lv_plain TYPE xstring.
    DATA lv_offset TYPE i.

    DATA(lv_zlib) = CONV xstring( '78' ).

    " A reader stores the objects of a saved form in compressed object streams
    WHILE lv_offset >= 0.
      DATA(lv_start) = find( iv_pdf = iv_pdf iv_text = 'stream' iv_from = lv_offset ).
      IF lv_start < 0.
        RETURN.
      ENDIF.

      DATA(lv_from) = lv_start + 6.
      DATA(lv_end) = find( iv_pdf = iv_pdf iv_text = 'endstream' iv_from = lv_from ).
      IF lv_end < 0.
        RETURN.
      ENDIF.

      DATA(lv_length) = lv_end - lv_from.
      IF lv_length > 4.
        lv_raw = iv_pdf+lv_from(lv_length).

        " Skip the line break after the keyword, then expect the zlib header
        DATA(lv_skip) = 0.
        WHILE lv_skip < 4 AND lv_skip < xstrlen( lv_raw ) AND lv_raw+lv_skip(1) <> lv_zlib.
          lv_skip = lv_skip + 1.
        ENDWHILE.

        IF lv_skip + 2 < xstrlen( lv_raw ) AND lv_raw+lv_skip(1) = lv_zlib.
          lv_skip = lv_skip + 2.
          TRY.
              cl_abap_gzip=>decompress_binary(
                EXPORTING gzip_in = lv_raw+lv_skip
                IMPORTING raw_out = lv_plain ).
              CONCATENATE rv_data lv_plain INTO rv_data IN BYTE MODE.
            CATCH cx_root.
              CLEAR lv_plain.
          ENDTRY.
        ENDIF.
      ENDIF.

      lv_offset = lv_end + 9.
    ENDWHILE.
  ENDMETHOD.

  METHOD read_fields.
    check_header( iv_pdf ).

    collect_fields(
      EXPORTING iv_pdf    = iv_pdf
      CHANGING  ct_fields = rt_fields ).

    IF rt_fields IS INITIAL.
      collect_fields(
        EXPORTING iv_pdf    = inflate_streams( iv_pdf )
        CHANGING  ct_fields = rt_fields ).
    ENDIF.
  ENDMETHOD.

  METHOD count_pages.
    DATA lv_offset TYPE i.

    WHILE lv_offset >= 0.
      DATA(lv_found) = find( iv_pdf = iv_data iv_text = '/Type' iv_from = lv_offset ).
      IF lv_found < 0.
        RETURN.
      ENDIF.

      DATA(lv_name) = ``.
      parse_name(
        EXPORTING iv_pdf  = iv_data
                  iv_from = lv_found + 5
        IMPORTING ev_text = lv_name ).

      " /Pages is the page tree, not a page
      IF lv_name = 'Page'.
        rv_count = rv_count + 1.
      ENDIF.

      lv_offset = lv_found + 5.
    ENDWHILE.
  ENDMETHOD.

  METHOD page_count.
    check_header( iv_pdf ).

    rv_count = count_pages( iv_pdf ).
    IF rv_count = 0.
      rv_count = count_pages( inflate_streams( iv_pdf ) ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
