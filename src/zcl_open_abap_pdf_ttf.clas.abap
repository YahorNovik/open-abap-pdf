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
        head_offset   TYPE i,
        hhea_offset   TYPE i,
        maxp_offset   TYPE i,
        loca_offset   TYPE i,
        loca_format   TYPE i,
        glyf_offset   TYPE i,
        segments      TYPE ty_segments,
        data          TYPE xstring,
      END OF ty_info.

    TYPES ty_gids TYPE SORTED TABLE OF i WITH UNIQUE DEFAULT KEY.

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

    "! Build a font that contains only the given glyphs plus everything they
    "! reference. Glyph indices are kept, so the PDF side does not change.
    "! Hinting and the character map are dropped, which a PDF with Identity-H
    "! encoding and an identity CID to GID map does not need.
    "! @raising zcx_open_abap_pdf | The font cannot be subset
    CLASS-METHODS subset
      IMPORTING is_info        TYPE ty_info
                it_gids        TYPE ty_gids
      RETURNING VALUE(rv_data) TYPE xstring
      RAISING   zcx_open_abap_pdf.

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

    CLASS-METHODS glyph_offset
      IMPORTING is_info          TYPE ty_info
                iv_gid           TYPE i
      RETURNING VALUE(rv_offset) TYPE i.

    CLASS-METHODS add_components
      IMPORTING is_info TYPE ty_info
                iv_gid  TYPE i
      CHANGING  ct_gids TYPE ty_gids.

    CLASS-METHODS pad4
      IMPORTING iv_data        TYPE xstring
      RETURNING VALUE(rv_data) TYPE xstring.
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

    rs_info-head_offset = lv_head.
    rs_info-hhea_offset = lv_hhea.
    rs_info-maxp_offset = lv_maxp.
    rs_info-loca_offset = table_offset( it_tables = lt_tables iv_tag = 'loca' ).
    rs_info-glyf_offset = table_offset( it_tables = lt_tables iv_tag = 'glyf' ).
    rs_info-loca_format = int16( iv_data = iv_data iv_offset = lv_head + 50 ).

    rs_info-segments = read_cmap(
      iv_data   = iv_data
      iv_offset = table_offset( it_tables = lt_tables iv_tag = 'cmap' ) ).
  ENDMETHOD.

  METHOD glyph_offset.
    IF is_info-loca_format = 0.
      rv_offset = uint(
        iv_data   = is_info-data
        iv_offset = is_info-loca_offset + iv_gid * 2
        iv_length = 2 ) * 2.
    ELSE.
      rv_offset = uint(
        iv_data   = is_info-data
        iv_offset = is_info-loca_offset + iv_gid * 4
        iv_length = 4 ).
    ENDIF.
  ENDMETHOD.

  METHOD add_components.
    DATA lv_flags TYPE i.
    DATA lv_component TYPE i.

    DATA(lv_start) = is_info-glyf_offset + glyph_offset( is_info = is_info iv_gid = iv_gid ).
    DATA(lv_end) = is_info-glyf_offset + glyph_offset( is_info = is_info iv_gid = iv_gid + 1 ).
    IF lv_end <= lv_start.
      RETURN.
    ENDIF.

    IF int16( iv_data = is_info-data iv_offset = lv_start ) >= 0.
      " A simple glyph has no references
      RETURN.
    ENDIF.

    DATA(lv_offset) = lv_start + 10.
    DO 16 TIMES.
      IF lv_offset + 4 > lv_end.
        RETURN.
      ENDIF.

      lv_flags = uint( iv_data = is_info-data iv_offset = lv_offset iv_length = 2 ).
      lv_component = uint( iv_data = is_info-data iv_offset = lv_offset + 2 iv_length = 2 ).
      lv_offset = lv_offset + 4.

      INSERT lv_component INTO TABLE ct_gids.
      IF sy-subrc = 0.
        " newly added, so follow its own references as well
        add_components(
          EXPORTING is_info = is_info
                    iv_gid  = lv_component
          CHANGING  ct_gids = ct_gids ).
      ENDIF.

      IF lv_flags MOD 2 = 1.
        lv_offset = lv_offset + 4.
      ELSE.
        lv_offset = lv_offset + 2.
      ENDIF.

      " A scale, an x and y scale or a two by two matrix may follow
      CASE 1.
        WHEN lv_flags DIV 8 MOD 2.
          lv_offset = lv_offset + 2.
        WHEN lv_flags DIV 64 MOD 2.
          lv_offset = lv_offset + 4.
        WHEN lv_flags DIV 128 MOD 2.
          lv_offset = lv_offset + 8.
      ENDCASE.

      IF lv_flags DIV 32 MOD 2 = 0.
        RETURN.
      ENDIF.
    ENDDO.
  ENDMETHOD.

  METHOD pad4.
    DATA lv_pad TYPE xstring.

    rv_data = iv_data.
    WHILE xstrlen( rv_data ) MOD 4 <> 0.
      lv_pad = '00'.
      CONCATENATE rv_data lv_pad INTO rv_data IN BYTE MODE.
    ENDWHILE.
  ENDMETHOD.

  METHOD subset.
    DATA lt_gids TYPE ty_gids.
    DATA lv_gid TYPE i.
    DATA lv_glyf TYPE xstring.
    DATA lv_loca TYPE xstring.
    DATA lv_hmtx TYPE xstring.
    DATA lv_part TYPE xstring.
    DATA lv_offset4 TYPE x LENGTH 4.
    DATA lv_word TYPE x LENGTH 2.
    DATA lv_head TYPE xstring.
    DATA lv_hhea TYPE xstring.
    DATA lv_maxp TYPE xstring.
    DATA lv_body TYPE xstring.
    DATA lv_directory TYPE xstring.
    DATA lv_entry TYPE xstring.
    DATA lv_tag TYPE xstring.
    DATA lt_names TYPE zcl_open_abap_pdf_font=>ty_lines.
    DATA lv_max_gid TYPE i.

    IF is_info-glyf_offset = 0 OR is_info-loca_offset = 0.
      zcx_open_abap_pdf=>raise( 'font cannot be subset, no glyf or loca table' ).
    ENDIF.

    " Glyph 0 is always needed, then add the components of composite glyphs
    lt_gids = it_gids.
    INSERT 0 INTO TABLE lt_gids.
    LOOP AT it_gids INTO lv_gid.
      add_components(
        EXPORTING is_info = is_info
                  iv_gid  = lv_gid
        CHANGING  ct_gids = lt_gids ).
    ENDLOOP.

    LOOP AT lt_gids INTO lv_gid.
      IF lv_gid > lv_max_gid.
        lv_max_gid = lv_gid.
      ENDIF.
    ENDLOOP.
    DATA(lv_num_glyphs) = lv_max_gid + 1.

    " glyf keeps the used outlines, loca points unused glyphs to an empty entry
    DO lv_num_glyphs TIMES.
      lv_gid = sy-index - 1.
      lv_offset4 = xstrlen( lv_glyf ).
      CONCATENATE lv_loca lv_offset4 INTO lv_loca IN BYTE MODE.

      IF line_exists( lt_gids[ table_line = lv_gid ] ).
        DATA(lv_from) = is_info-glyf_offset + glyph_offset( is_info = is_info iv_gid = lv_gid ).
        DATA(lv_to) = is_info-glyf_offset + glyph_offset( is_info = is_info iv_gid = lv_gid + 1 ).
        IF lv_to > lv_from.
          DATA(lv_length) = lv_to - lv_from.
          lv_part = pad4( is_info-data+lv_from(lv_length) ).
          CONCATENATE lv_glyf lv_part INTO lv_glyf IN BYTE MODE.
        ENDIF.
      ENDIF.

      lv_word = advance( is_info = is_info iv_gid = lv_gid ).
      CONCATENATE lv_hmtx lv_word INTO lv_hmtx IN BYTE MODE.
      lv_word = '0000'.
      CONCATENATE lv_hmtx lv_word INTO lv_hmtx IN BYTE MODE.
    ENDDO.

    lv_offset4 = xstrlen( lv_glyf ).
    CONCATENATE lv_loca lv_offset4 INTO lv_loca IN BYTE MODE.

    " head with the long loca format and without the file checksum
    lv_head = is_info-data+is_info-head_offset(54).
    lv_word = '0001'.
    CONCATENATE lv_head(50) lv_word INTO lv_head IN BYTE MODE.
    lv_word = '0000'.
    CONCATENATE lv_head lv_word INTO lv_head IN BYTE MODE.
    lv_offset4 = 0.
    CONCATENATE lv_head(8) lv_offset4 lv_head+12 INTO lv_head IN BYTE MODE.

    " hhea with one horizontal metric per glyph
    lv_hhea = is_info-data+is_info-hhea_offset(36).
    lv_word = lv_num_glyphs.
    CONCATENATE lv_hhea(34) lv_word INTO lv_hhea IN BYTE MODE.

    lv_maxp = is_info-data+is_info-maxp_offset(32).
    lv_word = lv_num_glyphs.
    CONCATENATE lv_maxp(4) lv_word lv_maxp+6 INTO lv_maxp IN BYTE MODE.

    " The tables of the new font, in the order the directory requires
    lt_names = VALUE #( ( 'glyf' ) ( 'head' ) ( 'hhea' ) ( 'hmtx' ) ( 'loca' ) ( 'maxp' ) ).
    DATA(lv_count) = lines( lt_names ).
    DATA(lv_position) = 12 + 16 * lv_count.

    LOOP AT lt_names INTO DATA(lv_name).
      CASE lv_name.
        WHEN 'glyf'.
          lv_part = lv_glyf.
        WHEN 'head'.
          lv_part = lv_head.
        WHEN 'hhea'.
          lv_part = lv_hhea.
        WHEN 'hmtx'.
          lv_part = lv_hmtx.
        WHEN 'loca'.
          lv_part = lv_loca.
        WHEN OTHERS.
          lv_part = lv_maxp.
      ENDCASE.

      lv_tag = cl_abap_codepage=>convert_to( lv_name ).
      lv_offset4 = 0.
      CONCATENATE lv_directory lv_tag lv_offset4 INTO lv_entry IN BYTE MODE.
      lv_offset4 = lv_position.
      CONCATENATE lv_entry lv_offset4 INTO lv_entry IN BYTE MODE.
      lv_offset4 = xstrlen( lv_part ).
      CONCATENATE lv_entry lv_offset4 INTO lv_directory IN BYTE MODE.

      lv_part = pad4( lv_part ).
      CONCATENATE lv_body lv_part INTO lv_body IN BYTE MODE.
      lv_position = lv_position + xstrlen( lv_part ).
    ENDLOOP.

    lv_offset4 = 65536.
    rv_data = lv_offset4.
    lv_word = lv_count.
    CONCATENATE rv_data lv_word INTO rv_data IN BYTE MODE.
    lv_word = 64.
    CONCATENATE rv_data lv_word INTO rv_data IN BYTE MODE.
    lv_word = 2.
    CONCATENATE rv_data lv_word INTO rv_data IN BYTE MODE.
    lv_word = lv_count * 16 - 64.
    CONCATENATE rv_data lv_word INTO rv_data IN BYTE MODE.
    CONCATENATE rv_data lv_directory lv_body INTO rv_data IN BYTE MODE.
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
