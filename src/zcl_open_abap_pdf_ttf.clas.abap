CLASS zcl_open_abap_pdf_ttf DEFINITION PUBLIC FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_segment,
        start_code   TYPE i,
        end_code     TYPE i,
        delta        TYPE i,
        range_offset TYPE i,
        range_addr   TYPE i,
      END OF ty_segment,
      ty_segments TYPE STANDARD TABLE OF ty_segment WITH DEFAULT KEY,

      BEGIN OF ty_info,
        name          TYPE string,
        units         TYPE i,
        ascent        TYPE i,
        descent       TYPE i,
        cap_height    TYPE i,
        x_min         TYPE i,
        y_min         TYPE i,
        x_max         TYPE i,
        y_max         TYPE i,
        italic_angle  TYPE i,
        num_glyphs    TYPE i,
        num_h_metrics TYPE i,
        hmtx_offset   TYPE i,
        segments      TYPE ty_segments,
        data          TYPE xstring,
      END OF ty_info.

    "! Read the tables of a TrueType font that are needed to embed it in a PDF.
    "! The character map is kept as segments and resolved on demand, so registering
    "! a large font stays cheap.
    "! @parameter iv_name | Name used for /BaseFont, derived from the file if empty
    "! @raising zcx_open_abap_pdf | Not a TrueType font or a required table is missing
    CLASS-METHODS parse
      IMPORTING iv_data        TYPE xstring
                iv_name        TYPE string DEFAULT ''
      RETURNING VALUE(rs_info) TYPE ty_info
      RAISING   zcx_open_abap_pdf.

    "! Glyph index of a unicode code point, 0 when the font has no such glyph
    CLASS-METHODS glyph_id
      IMPORTING is_info       TYPE ty_info
                iv_cp         TYPE i
      RETURNING VALUE(rv_gid) TYPE i.

    "! Advance width of a glyph in font units
    CLASS-METHODS advance
      IMPORTING is_info           TYPE ty_info
                iv_gid            TYPE i
      RETURNING VALUE(rv_advance) TYPE i.

    "! Unsigned big endian integer of iv_length bytes
    CLASS-METHODS uint
      IMPORTING iv_data         TYPE xstring
                iv_offset       TYPE i
                iv_length       TYPE i
      RETURNING VALUE(rv_value) TYPE i.

    "! Signed big endian 16 bit integer
    CLASS-METHODS int16
      IMPORTING iv_data         TYPE xstring
                iv_offset       TYPE i
      RETURNING VALUE(rv_value) TYPE i.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_table,
        tag    TYPE string,
        offset TYPE i,
        length TYPE i,
      END OF ty_table,
      ty_tables TYPE STANDARD TABLE OF ty_table WITH DEFAULT KEY.

    CLASS-METHODS read_tables
      IMPORTING iv_data          TYPE xstring
      RETURNING VALUE(rt_tables) TYPE ty_tables
      RAISING   zcx_open_abap_pdf.

    CLASS-METHODS table_offset
      IMPORTING it_tables        TYPE ty_tables
                iv_tag           TYPE string
      RETURNING VALUE(rv_offset) TYPE i
      RAISING   zcx_open_abap_pdf.

    CLASS-METHODS read_cmap
      IMPORTING iv_data            TYPE xstring
                iv_offset          TYPE i
      RETURNING VALUE(rt_segments) TYPE ty_segments
      RAISING   zcx_open_abap_pdf.
ENDCLASS.

CLASS zcl_open_abap_pdf_ttf IMPLEMENTATION.

  METHOD uint.
    DATA lv_byte TYPE x LENGTH 1.
    DATA lv_i TYPE i.

    DATA(lv_offset) = iv_offset.
    DO iv_length TIMES.
      lv_byte = iv_data+lv_offset(1).
      lv_i = lv_byte.
      rv_value = rv_value * 256 + lv_i.
      lv_offset = lv_offset + 1.
    ENDDO.
  ENDMETHOD.

  METHOD int16.
    rv_value = uint( iv_data = iv_data iv_offset = iv_offset iv_length = 2 ).
    IF rv_value > 32767.
      rv_value = rv_value - 65536.
    ENDIF.
  ENDMETHOD.

  METHOD read_tables.
    DATA ls_table TYPE ty_table.
    DATA lv_offset TYPE i.

    IF xstrlen( iv_data ) < 12.
      zcx_open_abap_pdf=>raise( 'font file is too short' ).
    ENDIF.

    DATA(lv_version) = uint( iv_data = iv_data iv_offset = 0 iv_length = 4 ).
    IF lv_version <> 65536 AND iv_data(4) <> '74727565'.
      zcx_open_abap_pdf=>raise( 'only TrueType outlines are supported, not CFF or WOFF' ).
    ENDIF.

    DATA(lv_count) = uint( iv_data = iv_data iv_offset = 4 iv_length = 2 ).
    lv_offset = 12.
    DO lv_count TIMES.
      CLEAR ls_table.
      ls_table-tag = cl_abap_codepage=>convert_from( iv_data+lv_offset(4) ).
      ls_table-offset = uint( iv_data = iv_data iv_offset = lv_offset + 8 iv_length = 4 ).
      ls_table-length = uint( iv_data = iv_data iv_offset = lv_offset + 12 iv_length = 4 ).
      APPEND ls_table TO rt_tables.
      lv_offset = lv_offset + 16.
    ENDDO.
  ENDMETHOD.

  METHOD table_offset.
    DATA ls_table TYPE ty_table.

    READ TABLE it_tables INTO ls_table WITH KEY tag = iv_tag.
    IF sy-subrc <> 0.
      zcx_open_abap_pdf=>raise( |font has no { iv_tag } table| ).
    ENDIF.
    rv_offset = ls_table-offset.
  ENDMETHOD.

  METHOD read_cmap.
    DATA ls_segment TYPE ty_segment.
    DATA lv_sub TYPE i.
    DATA lv_best TYPE i.
    DATA lv_platform TYPE i.
    DATA lv_encoding TYPE i.
    DATA lv_score TYPE i.
    DATA lv_best_score TYPE i.

    DATA(lv_count) = uint( iv_data = iv_data iv_offset = iv_offset + 2 iv_length = 2 ).
    DATA(lv_record) = iv_offset + 4.

    DO lv_count TIMES.
      lv_platform = uint( iv_data = iv_data iv_offset = lv_record iv_length = 2 ).
      lv_encoding = uint( iv_data = iv_data iv_offset = lv_record + 2 iv_length = 2 ).
      lv_sub = iv_offset + uint( iv_data = iv_data iv_offset = lv_record + 4 iv_length = 4 ).

      " Windows unicode BMP is the preferred table, then any unicode table
      lv_score = 0.
      IF lv_platform = 3 AND lv_encoding = 1.
        lv_score = 3.
      ELSEIF lv_platform = 0.
        lv_score = 2.
      ELSEIF lv_platform = 3 AND lv_encoding = 0.
        lv_score = 1.
      ENDIF.

      IF lv_score > lv_best_score
          AND uint( iv_data = iv_data iv_offset = lv_sub iv_length = 2 ) = 4.
        lv_best_score = lv_score.
        lv_best = lv_sub.
      ENDIF.

      lv_record = lv_record + 8.
    ENDDO.

    IF lv_best = 0.
      zcx_open_abap_pdf=>raise( 'font has no unicode cmap subtable in format 4' ).
    ENDIF.

    DATA(lv_seg_count) = uint( iv_data = iv_data iv_offset = lv_best + 6 iv_length = 2 ) / 2.
    DATA(lv_ends) = lv_best + 14.
    DATA(lv_starts) = lv_ends + lv_seg_count * 2 + 2.
    DATA(lv_deltas) = lv_starts + lv_seg_count * 2.
    DATA(lv_ranges) = lv_deltas + lv_seg_count * 2.

    DO lv_seg_count TIMES.
      DATA(lv_i) = sy-index - 1.
      CLEAR ls_segment.
      ls_segment-end_code = uint( iv_data = iv_data iv_offset = lv_ends + lv_i * 2 iv_length = 2 ).
      ls_segment-start_code = uint( iv_data = iv_data iv_offset = lv_starts + lv_i * 2 iv_length = 2 ).
      ls_segment-delta = int16( iv_data = iv_data iv_offset = lv_deltas + lv_i * 2 ).
      ls_segment-range_addr = lv_ranges + lv_i * 2.
      ls_segment-range_offset = uint( iv_data = iv_data iv_offset = ls_segment-range_addr iv_length = 2 ).
      APPEND ls_segment TO rt_segments.
    ENDDO.
  ENDMETHOD.

  METHOD parse.
    DATA(lt_tables) = read_tables( iv_data ).

    DATA(lv_head) = table_offset( it_tables = lt_tables iv_tag = 'head' ).
    DATA(lv_hhea) = table_offset( it_tables = lt_tables iv_tag = 'hhea' ).
    DATA(lv_maxp) = table_offset( it_tables = lt_tables iv_tag = 'maxp' ).

    rs_info-data = iv_data.
    rs_info-name = iv_name.
    IF rs_info-name IS INITIAL.
      rs_info-name = 'EmbeddedFont'.
    ENDIF.

    rs_info-units = uint( iv_data = iv_data iv_offset = lv_head + 18 iv_length = 2 ).
    IF rs_info-units = 0.
      rs_info-units = 1000.
    ENDIF.

    rs_info-x_min = int16( iv_data = iv_data iv_offset = lv_head + 36 ).
    rs_info-y_min = int16( iv_data = iv_data iv_offset = lv_head + 38 ).
    rs_info-x_max = int16( iv_data = iv_data iv_offset = lv_head + 40 ).
    rs_info-y_max = int16( iv_data = iv_data iv_offset = lv_head + 42 ).

    rs_info-ascent = int16( iv_data = iv_data iv_offset = lv_hhea + 4 ).
    rs_info-descent = int16( iv_data = iv_data iv_offset = lv_hhea + 6 ).
    rs_info-num_h_metrics = uint( iv_data = iv_data iv_offset = lv_hhea + 34 iv_length = 2 ).
    rs_info-num_glyphs = uint( iv_data = iv_data iv_offset = lv_maxp + 4 iv_length = 2 ).
    rs_info-hmtx_offset = table_offset( it_tables = lt_tables iv_tag = 'hmtx' ).

    " Cap height is only in OS/2 version 2 and later, fall back to the ascent
    READ TABLE lt_tables INTO DATA(ls_os2) WITH KEY tag = 'OS/2'.
    IF sy-subrc = 0 AND ls_os2-length >= 90.
      rs_info-cap_height = int16( iv_data = iv_data iv_offset = ls_os2-offset + 88 ).
    ENDIF.
    IF rs_info-cap_height <= 0.
      rs_info-cap_height = rs_info-ascent.
    ENDIF.

    READ TABLE lt_tables INTO DATA(ls_post) WITH KEY tag = 'post'.
    IF sy-subrc = 0.
      rs_info-italic_angle = int16( iv_data = iv_data iv_offset = ls_post-offset + 4 ).
    ENDIF.

    rs_info-segments = read_cmap(
      iv_data   = iv_data
      iv_offset = table_offset( it_tables = lt_tables iv_tag = 'cmap' ) ).
  ENDMETHOD.

  METHOD glyph_id.
    DATA ls_segment TYPE ty_segment.
    DATA lv_address TYPE i.

    LOOP AT is_info-segments INTO ls_segment.
      IF iv_cp < ls_segment-start_code OR iv_cp > ls_segment-end_code.
        CONTINUE.
      ENDIF.

      IF ls_segment-range_offset = 0.
        rv_gid = ( iv_cp + ls_segment-delta ) MOD 65536.
        RETURN.
      ENDIF.

      lv_address = ls_segment-range_addr + ls_segment-range_offset
                 + 2 * ( iv_cp - ls_segment-start_code ).
      IF lv_address + 2 > xstrlen( is_info-data ).
        RETURN.
      ENDIF.

      rv_gid = uint( iv_data = is_info-data iv_offset = lv_address iv_length = 2 ).
      IF rv_gid <> 0.
        rv_gid = ( rv_gid + ls_segment-delta ) MOD 65536.
      ENDIF.
      RETURN.
    ENDLOOP.
  ENDMETHOD.

  METHOD advance.
    DATA(lv_index) = iv_gid.

    IF lv_index >= is_info-num_h_metrics.
      lv_index = is_info-num_h_metrics - 1.
    ENDIF.
    IF lv_index < 0.
      RETURN.
    ENDIF.

    rv_advance = uint(
      iv_data   = is_info-data
      iv_offset = is_info-hmtx_offset + lv_index * 4
      iv_length = 2 ).
  ENDMETHOD.

ENDCLASS.
