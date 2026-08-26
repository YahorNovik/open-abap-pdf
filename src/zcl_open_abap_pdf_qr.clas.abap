CLASS zcl_open_abap_pdf_qr DEFINITION PUBLIC FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    TYPES ty_rows TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    TYPES ty_bytes TYPE STANDARD TABLE OF i WITH DEFAULT KEY.

    "! Encode a text as a QR code, byte mode, error correction level M,
    "! versions 1 to 10, which holds up to 271 characters.
    "! @parameter rt_rows | One string per row, 1 is a dark module
    "! @raising zcx_open_abap_pdf | Text too long or not encodable
    CLASS-METHODS encode
      IMPORTING iv_text        TYPE string
      RETURNING VALUE(rt_rows) TYPE ty_rows
      RAISING   zcx_open_abap_pdf.

    "! Final codeword sequence, data and error correction interleaved.
    "! Exposed so that the encoding can be tested without looking at the matrix.
    CLASS-METHODS codewords
      IMPORTING iv_text       TYPE string
      RETURNING VALUE(rt_out) TYPE ty_bytes
      RAISING   zcx_open_abap_pdf.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_spec,
        version TYPE i,
        total   TYPE i,
        data    TYPE i,
        ec      TYPE i,
        blocks1 TYPE i,
        data1   TYPE i,
        blocks2 TYPE i,
        data2   TYPE i,
      END OF ty_spec.

    CLASS-DATA gt_exp TYPE ty_bytes.
    CLASS-DATA gt_log TYPE ty_bytes.
    CLASS-DATA gv_size TYPE i.
    CLASS-DATA gt_module TYPE ty_bytes.
    CLASS-DATA gt_fixed TYPE ty_bytes.

    CLASS-METHODS spec_for
      IMPORTING iv_length      TYPE i
      RETURNING VALUE(rs_spec) TYPE ty_spec
      RAISING   zcx_open_abap_pdf.

    CLASS-METHODS build_bits
      IMPORTING it_data       TYPE ty_bytes
                is_spec       TYPE ty_spec
      RETURNING VALUE(rt_out) TYPE ty_bytes.

    CLASS-METHODS interleave
      IMPORTING it_data       TYPE ty_bytes
                is_spec       TYPE ty_spec
      RETURNING VALUE(rt_out) TYPE ty_bytes.

    CLASS-METHODS ec_codewords
      IMPORTING it_block      TYPE ty_bytes
                iv_count      TYPE i
      RETURNING VALUE(rt_out) TYPE ty_bytes.

    CLASS-METHODS init_tables.

    CLASS-METHODS xor
      IMPORTING iv_a            TYPE i
                iv_b            TYPE i
      RETURNING VALUE(rv_value) TYPE i.

    CLASS-METHODS gf_mul
      IMPORTING iv_a            TYPE i
                iv_b            TYPE i
      RETURNING VALUE(rv_value) TYPE i.

    CLASS-METHODS generator
      IMPORTING iv_degree      TYPE i
      RETURNING VALUE(rt_poly) TYPE ty_bytes.

    CLASS-METHODS index_of
      IMPORTING iv_x            TYPE i
                iv_y            TYPE i
      RETURNING VALUE(rv_index) TYPE i.

    CLASS-METHODS set_module
      IMPORTING iv_x     TYPE i
                iv_y     TYPE i
                iv_dark  TYPE i
                iv_fixed TYPE abap_bool DEFAULT abap_true.

    CLASS-METHODS get_module
      IMPORTING iv_x           TYPE i
                iv_y           TYPE i
      RETURNING VALUE(rv_dark) TYPE i.

    CLASS-METHODS is_fixed
      IMPORTING iv_x            TYPE i
                iv_y            TYPE i
      RETURNING VALUE(rv_fixed) TYPE abap_bool.

    CLASS-METHODS draw_patterns
      IMPORTING iv_version TYPE i.

    CLASS-METHODS draw_finder
      IMPORTING iv_x TYPE i
                iv_y TYPE i.

    CLASS-METHODS place_data
      IMPORTING it_codewords TYPE ty_bytes.

    CLASS-METHODS apply_mask
      IMPORTING iv_mask TYPE i.

    CLASS-METHODS mask_condition
      IMPORTING iv_mask        TYPE i
                iv_x           TYPE i
                iv_y           TYPE i
      RETURNING VALUE(rv_flip) TYPE abap_bool.

    CLASS-METHODS penalty
      RETURNING VALUE(rv_score) TYPE i.

    CLASS-METHODS draw_format
      IMPORTING iv_mask TYPE i.

    CLASS-METHODS draw_version
      IMPORTING iv_version TYPE i.

    CLASS-METHODS alignment_centers
      IMPORTING iv_version       TYPE i
      RETURNING VALUE(rt_values) TYPE ty_bytes.
ENDCLASS.

CLASS zcl_open_abap_pdf_qr IMPLEMENTATION.

  METHOD init_tables.
    DATA lv_value TYPE i.

    IF gt_exp IS NOT INITIAL.
      RETURN.
    ENDIF.

    CLEAR gt_log.
    DO 256 TIMES.
      APPEND 0 TO gt_log.
    ENDDO.

    lv_value = 1.
    DO 256 TIMES.
      APPEND lv_value TO gt_exp.
      IF sy-index <= 255.
        MODIFY gt_log INDEX lv_value + 1 FROM sy-index - 1.
      ENDIF.

      lv_value = lv_value * 2.
      IF lv_value >= 256.
        " x^8 + x^4 + x^3 + x^2 + 1
        lv_value = xor( iv_a = lv_value iv_b = 285 ).
      ENDIF.
    ENDDO.
  ENDMETHOD.

  METHOD xor.
    " ABAP has BIT-XOR for byte fields only, so the integers take a detour
    DATA lv_a TYPE x LENGTH 4.
    DATA lv_b TYPE x LENGTH 4.
    DATA lv_result TYPE x LENGTH 4.

    lv_a = iv_a.
    lv_b = iv_b.
    lv_result = lv_a BIT-XOR lv_b.
    rv_value = lv_result.
  ENDMETHOD.

  METHOD gf_mul.
    IF iv_a = 0 OR iv_b = 0.
      RETURN.
    ENDIF.

    init_tables( ).
    DATA(lv_ia) = iv_a + 1.
    DATA(lv_ib) = iv_b + 1.
    READ TABLE gt_log INTO DATA(lv_la) INDEX lv_ia.
    READ TABLE gt_log INTO DATA(lv_lb) INDEX lv_ib.
    READ TABLE gt_exp INTO rv_value INDEX ( lv_la + lv_lb ) MOD 255 + 1.
  ENDMETHOD.

  METHOD generator.
    DATA lt_next TYPE ty_bytes.
    DATA lv_i TYPE i.
    DATA lv_root TYPE i.

    init_tables( ).
    APPEND 1 TO rt_poly.

    DO iv_degree TIMES.
      READ TABLE gt_exp INTO lv_root INDEX sy-index.
      CLEAR lt_next.

      " multiply the polynomial by ( x - root )
      DO lines( rt_poly ) + 1 TIMES.
        lv_i = sy-index.
        DATA(lv_value) = 0.
        IF lv_i <= lines( rt_poly ).
          READ TABLE rt_poly INTO lv_value INDEX lv_i.
        ENDIF.
        IF lv_i > 1.
          READ TABLE rt_poly INTO DATA(lv_prev) INDEX lv_i - 1.
          lv_value = xor( iv_a = lv_value iv_b = gf_mul( iv_a = lv_prev iv_b = lv_root ) ).
        ENDIF.
        APPEND lv_value TO lt_next.
      ENDDO.

      rt_poly = lt_next.
    ENDDO.
  ENDMETHOD.

  METHOD ec_codewords.
    DATA lt_work TYPE ty_bytes.
    DATA lv_factor TYPE i.
    DATA lv_i TYPE i.
    DATA lv_value TYPE i.
    FIELD-SYMBOLS <lv_cell> TYPE i.

    DATA(lt_gen) = generator( iv_count ).

    lt_work = it_block.
    DO iv_count TIMES.
      APPEND 0 TO lt_work.
    ENDDO.

    DO lines( it_block ) TIMES.
      DATA(lv_pos) = sy-index.
      READ TABLE lt_work INTO lv_factor INDEX lv_pos.
      IF lv_factor = 0.
        CONTINUE.
      ENDIF.

      LOOP AT lt_gen INTO lv_value.
        lv_i = lv_pos + sy-tabix - 1.
        READ TABLE lt_work ASSIGNING <lv_cell> INDEX lv_i.
        IF sy-subrc = 0.
          <lv_cell> = xor( iv_a = <lv_cell> iv_b = gf_mul( iv_a = lv_value iv_b = lv_factor ) ).
        ENDIF.
      ENDLOOP.
    ENDDO.

    LOOP AT lt_work INTO lv_value FROM lines( it_block ) + 1.
      APPEND lv_value TO rt_out.
    ENDLOOP.
  ENDMETHOD.

  METHOD spec_for.
    DATA lt_specs TYPE STANDARD TABLE OF ty_spec WITH DEFAULT KEY.
    DATA ls_spec TYPE ty_spec.

    " version, total codewords, data codewords, ec per block, blocks and sizes, level M
    lt_specs = VALUE #(
      ( version = 1 total = 26 data = 16 ec = 10 blocks1 = 1 data1 = 16 )
      ( version = 2 total = 44 data = 28 ec = 16 blocks1 = 1 data1 = 28 )
      ( version = 3 total = 70 data = 44 ec = 26 blocks1 = 1 data1 = 44 )
      ( version = 4 total = 100 data = 64 ec = 18 blocks1 = 2 data1 = 32 )
      ( version = 5 total = 134 data = 86 ec = 24 blocks1 = 2 data1 = 43 )
      ( version = 6 total = 172 data = 108 ec = 16 blocks1 = 4 data1 = 27 )
      ( version = 7 total = 196 data = 124 ec = 18 blocks1 = 4 data1 = 31 )
      ( version = 8 total = 242 data = 154 ec = 22 blocks1 = 2 data1 = 38 blocks2 = 2 data2 = 39 )
      ( version = 9 total = 292 data = 182 ec = 22 blocks1 = 3 data1 = 36 blocks2 = 2 data2 = 37 )
      ( version = 10 total = 346 data = 216 ec = 26 blocks1 = 4 data1 = 43 blocks2 = 1 data2 = 44 ) ).

    LOOP AT lt_specs INTO ls_spec.
      " mode indicator and character count take two bytes up to version 9
      DATA(lv_header) = 2.
      IF ls_spec-version >= 10.
        lv_header = 3.
      ENDIF.

      IF iv_length + lv_header <= ls_spec-data.
        rs_spec = ls_spec.
        RETURN.
      ENDIF.
    ENDLOOP.

    DATA(lv_message) = |text of { iv_length } bytes does not fit into a QR code of version 10|.
    zcx_open_abap_pdf=>raise( lv_message ).
  ENDMETHOD.

  METHOD build_bits.
    DATA lv_bits TYPE string.
    DATA lv_byte TYPE i.
    DATA lv_pad TYPE i.

    " byte mode
    lv_bits = '0100'.

    " character count, 8 bits up to version 9, 16 bits from version 10
    DATA(lv_count_bits) = 8.
    IF is_spec-version >= 10.
      lv_count_bits = 16.
    ENDIF.

    DATA(lv_count) = lines( it_data ).
    DATA(lv_i) = lv_count_bits.
    WHILE lv_i > 0.
      lv_i = lv_i - 1.
      lv_bits = |{ lv_bits }{ lv_count DIV ipow( base = 2 exp = lv_i ) MOD 2 }|.
    ENDWHILE.

    LOOP AT it_data INTO lv_byte.
      lv_i = 8.
      WHILE lv_i > 0.
        lv_i = lv_i - 1.
        lv_bits = |{ lv_bits }{ lv_byte DIV ipow( base = 2 exp = lv_i ) MOD 2 }|.
      ENDWHILE.
    ENDLOOP.

    " terminator, then fill the last codeword
    DATA(lv_capacity) = is_spec-data * 8.
    DO 4 TIMES.
      IF strlen( lv_bits ) < lv_capacity.
        lv_bits = |{ lv_bits }0|.
      ENDIF.
    ENDDO.
    WHILE strlen( lv_bits ) MOD 8 <> 0.
      lv_bits = |{ lv_bits }0|.
    ENDWHILE.

    " codewords
    DATA(lv_offset) = 0.
    WHILE lv_offset < strlen( lv_bits ).
      lv_byte = 0.
      DO 8 TIMES.
        lv_byte = lv_byte * 2 + CONV i( lv_bits+lv_offset(1) ).
        lv_offset = lv_offset + 1.
      ENDDO.
      APPEND lv_byte TO rt_out.
    ENDWHILE.

    " pad codewords alternate between 236 and 17
    lv_pad = 0.
    WHILE lines( rt_out ) < is_spec-data.
      IF lv_pad MOD 2 = 0.
        APPEND 236 TO rt_out.
      ELSE.
        APPEND 17 TO rt_out.
      ENDIF.
      lv_pad = lv_pad + 1.
    ENDWHILE.
  ENDMETHOD.

  METHOD interleave.
    TYPES ty_blocks TYPE STANDARD TABLE OF ty_bytes WITH DEFAULT KEY.
    DATA lt_data_blocks TYPE ty_blocks.
    DATA lt_ec_blocks TYPE ty_blocks.
    DATA lt_block TYPE ty_bytes.
    DATA lv_value TYPE i.
    DATA lv_offset TYPE i.
    DATA lv_max TYPE i.

    " split the data codewords into the blocks of the version
    DO is_spec-blocks1 TIMES.
      CLEAR lt_block.
      DO is_spec-data1 TIMES.
        lv_offset = lv_offset + 1.
        READ TABLE it_data INTO lv_value INDEX lv_offset.
        APPEND lv_value TO lt_block.
      ENDDO.
      APPEND lt_block TO lt_data_blocks.
      APPEND ec_codewords( it_block = lt_block iv_count = is_spec-ec ) TO lt_ec_blocks.
    ENDDO.

    DO is_spec-blocks2 TIMES.
      CLEAR lt_block.
      DO is_spec-data2 TIMES.
        lv_offset = lv_offset + 1.
        READ TABLE it_data INTO lv_value INDEX lv_offset.
        APPEND lv_value TO lt_block.
      ENDDO.
      APPEND lt_block TO lt_data_blocks.
      APPEND ec_codewords( it_block = lt_block iv_count = is_spec-ec ) TO lt_ec_blocks.
    ENDDO.

    " data codewords column by column, then the error correction codewords
    lv_max = is_spec-data1.
    IF is_spec-data2 > lv_max.
      lv_max = is_spec-data2.
    ENDIF.

    DO lv_max TIMES.
      DATA(lv_pos) = sy-index.
      LOOP AT lt_data_blocks INTO lt_block.
        READ TABLE lt_block INTO lv_value INDEX lv_pos.
        IF sy-subrc = 0.
          APPEND lv_value TO rt_out.
        ENDIF.
      ENDLOOP.
    ENDDO.

    DO is_spec-ec TIMES.
      lv_pos = sy-index.
      LOOP AT lt_ec_blocks INTO lt_block.
        READ TABLE lt_block INTO lv_value INDEX lv_pos.
        IF sy-subrc = 0.
          APPEND lv_value TO rt_out.
        ENDIF.
      ENDLOOP.
    ENDDO.
  ENDMETHOD.

  METHOD index_of.
    rv_index = iv_y * gv_size + iv_x + 1.
  ENDMETHOD.

  METHOD set_module.
    IF iv_x < 0 OR iv_y < 0 OR iv_x >= gv_size OR iv_y >= gv_size.
      RETURN.
    ENDIF.

    DATA(lv_index) = index_of( iv_x = iv_x iv_y = iv_y ).
    MODIFY gt_module INDEX lv_index FROM iv_dark.
    IF iv_fixed = abap_true.
      MODIFY gt_fixed INDEX lv_index FROM 1.
    ENDIF.
  ENDMETHOD.

  METHOD get_module.
    IF iv_x < 0 OR iv_y < 0 OR iv_x >= gv_size OR iv_y >= gv_size.
      RETURN.
    ENDIF.
    READ TABLE gt_module INTO rv_dark INDEX index_of( iv_x = iv_x iv_y = iv_y ).
  ENDMETHOD.

  METHOD is_fixed.
    READ TABLE gt_fixed INTO DATA(lv_value) INDEX index_of( iv_x = iv_x iv_y = iv_y ).
    rv_fixed = xsdbool( lv_value = 1 ).
  ENDMETHOD.

  METHOD draw_finder.
    DATA lv_dx TYPE i.
    DATA lv_dy TYPE i.

    lv_dy = -1.
    WHILE lv_dy <= 7.
      lv_dx = -1.
      WHILE lv_dx <= 7.
        DATA(lv_dark) = 0.
        IF lv_dx >= 0 AND lv_dx <= 6 AND lv_dy >= 0 AND lv_dy <= 6
            AND ( lv_dx = 0 OR lv_dx = 6 OR lv_dy = 0 OR lv_dy = 6
                  OR ( lv_dx >= 2 AND lv_dx <= 4 AND lv_dy >= 2 AND lv_dy <= 4 ) ).
          lv_dark = 1.
        ENDIF.
        set_module( iv_x = iv_x + lv_dx iv_y = iv_y + lv_dy iv_dark = lv_dark ).
        lv_dx = lv_dx + 1.
      ENDWHILE.
      lv_dy = lv_dy + 1.
    ENDWHILE.
  ENDMETHOD.

  METHOD alignment_centers.
    CASE iv_version.
      WHEN 1.
        RETURN.
      WHEN 2.
        rt_values = VALUE #( ( 6 ) ( 18 ) ).
      WHEN 3.
        rt_values = VALUE #( ( 6 ) ( 22 ) ).
      WHEN 4.
        rt_values = VALUE #( ( 6 ) ( 26 ) ).
      WHEN 5.
        rt_values = VALUE #( ( 6 ) ( 30 ) ).
      WHEN 6.
        rt_values = VALUE #( ( 6 ) ( 34 ) ).
      WHEN 7.
        rt_values = VALUE #( ( 6 ) ( 22 ) ( 38 ) ).
      WHEN 8.
        rt_values = VALUE #( ( 6 ) ( 24 ) ( 42 ) ).
      WHEN 9.
        rt_values = VALUE #( ( 6 ) ( 26 ) ( 46 ) ).
      WHEN OTHERS.
        rt_values = VALUE #( ( 6 ) ( 28 ) ( 50 ) ).
    ENDCASE.
  ENDMETHOD.

  METHOD draw_patterns.
    DATA lv_i TYPE i.
    DATA lv_row TYPE i.
    DATA lv_col TYPE i.

    draw_finder( iv_x = 0 iv_y = 0 ).
    draw_finder( iv_x = gv_size - 7 iv_y = 0 ).
    draw_finder( iv_x = 0 iv_y = gv_size - 7 ).

    " timing patterns
    lv_i = 8.
    WHILE lv_i < gv_size - 8.
      DATA(lv_dark) = 0.
      IF lv_i MOD 2 = 0.
        lv_dark = 1.
      ENDIF.
      set_module( iv_x = lv_i iv_y = 6 iv_dark = lv_dark ).
      set_module( iv_x = 6 iv_y = lv_i iv_dark = lv_dark ).
      lv_i = lv_i + 1.
    ENDWHILE.

    " alignment patterns
    DATA(lt_centers) = alignment_centers( iv_version ).
    LOOP AT lt_centers INTO lv_row.
      LOOP AT lt_centers INTO lv_col.
        IF ( lv_row = 6 AND lv_col = 6 )
            OR ( lv_row = 6 AND lv_col = gv_size - 7 )
            OR ( lv_row = gv_size - 7 AND lv_col = 6 ).
          CONTINUE.
        ENDIF.

        DATA(lv_dy) = -2.
        WHILE lv_dy <= 2.
          DATA(lv_dx) = -2.
          WHILE lv_dx <= 2.
            lv_dark = 0.
            IF abs( lv_dx ) = 2 OR abs( lv_dy ) = 2 OR ( lv_dx = 0 AND lv_dy = 0 ).
              lv_dark = 1.
            ENDIF.
            set_module( iv_x = lv_col + lv_dx iv_y = lv_row + lv_dy iv_dark = lv_dark ).
            lv_dx = lv_dx + 1.
          ENDWHILE.
          lv_dy = lv_dy + 1.
        ENDWHILE.
      ENDLOOP.
    ENDLOOP.

    " reserve the format areas, index 6 belongs to the timing pattern
    lv_i = 0.
    WHILE lv_i <= 8.
      IF lv_i <> 6.
        set_module( iv_x = lv_i iv_y = 8 iv_dark = 0 ).
        set_module( iv_x = 8 iv_y = lv_i iv_dark = 0 ).
      ENDIF.
      lv_i = lv_i + 1.
    ENDWHILE.
    lv_i = 0.
    WHILE lv_i <= 7.
      set_module( iv_x = gv_size - 1 - lv_i iv_y = 8 iv_dark = 0 ).
      set_module( iv_x = 8 iv_y = gv_size - 1 - lv_i iv_dark = 0 ).
      lv_i = lv_i + 1.
    ENDWHILE.

    " the module above the lower left finder is always dark
    set_module( iv_x = 8 iv_y = gv_size - 8 iv_dark = 1 ).

    IF iv_version >= 7.
      lv_i = 0.
      WHILE lv_i < 6.
        DATA(lv_j) = 0.
        WHILE lv_j < 3.
          set_module( iv_x = lv_i iv_y = gv_size - 11 + lv_j iv_dark = 0 ).
          set_module( iv_x = gv_size - 11 + lv_j iv_y = lv_i iv_dark = 0 ).
          lv_j = lv_j + 1.
        ENDWHILE.
        lv_i = lv_i + 1.
      ENDWHILE.
    ENDIF.
  ENDMETHOD.

  METHOD place_data.
    DATA lv_bit TYPE i.
    DATA lv_byte TYPE i.
    DATA lv_col TYPE i.
    DATA lv_row TYPE i.
    DATA lv_upward TYPE abap_bool VALUE abap_true.

    DATA(lv_bit_index) = 0.
    DATA(lv_total_bits) = lines( it_codewords ) * 8.

    lv_col = gv_size - 1.
    WHILE lv_col > 0.
      " the vertical timing pattern is skipped
      IF lv_col = 6.
        lv_col = lv_col - 1.
      ENDIF.

      DATA(lv_step) = 0.
      WHILE lv_step < gv_size.
        IF lv_upward = abap_true.
          lv_row = gv_size - 1 - lv_step.
        ELSE.
          lv_row = lv_step.
        ENDIF.

        DATA(lv_offset) = 0.
        WHILE lv_offset <= 1.
          DATA(lv_x) = lv_col - lv_offset.
          IF is_fixed( iv_x = lv_x iv_y = lv_row ) = abap_false.
            lv_bit = 0.
            IF lv_bit_index < lv_total_bits.
              READ TABLE it_codewords INTO lv_byte INDEX lv_bit_index DIV 8 + 1.
              lv_bit = lv_byte DIV ipow( base = 2 exp = 7 - lv_bit_index MOD 8 ) MOD 2.
            ENDIF.
            set_module( iv_x = lv_x iv_y = lv_row iv_dark = lv_bit iv_fixed = abap_false ).
            lv_bit_index = lv_bit_index + 1.
          ENDIF.
          lv_offset = lv_offset + 1.
        ENDWHILE.

        lv_step = lv_step + 1.
      ENDWHILE.

      IF lv_upward = abap_true.
        lv_upward = abap_false.
      ELSE.
        lv_upward = abap_true.
      ENDIF.
      lv_col = lv_col - 2.
    ENDWHILE.
  ENDMETHOD.

  METHOD mask_condition.
    DATA lv_value TYPE i.

    CASE iv_mask.
      WHEN 0.
        lv_value = ( iv_y + iv_x ) MOD 2.
      WHEN 1.
        lv_value = iv_y MOD 2.
      WHEN 2.
        lv_value = iv_x MOD 3.
      WHEN 3.
        lv_value = ( iv_y + iv_x ) MOD 3.
      WHEN 4.
        lv_value = ( iv_y DIV 2 + iv_x DIV 3 ) MOD 2.
      WHEN 5.
        lv_value = iv_y * iv_x MOD 2 + iv_y * iv_x MOD 3.
      WHEN 6.
        lv_value = ( iv_y * iv_x MOD 2 + iv_y * iv_x MOD 3 ) MOD 2.
      WHEN OTHERS.
        lv_value = ( ( iv_y + iv_x ) MOD 2 + iv_y * iv_x MOD 3 ) MOD 2.
    ENDCASE.

    rv_flip = xsdbool( lv_value = 0 ).
  ENDMETHOD.

  METHOD apply_mask.
    DATA lv_y TYPE i.
    DATA lv_x TYPE i.

    WHILE lv_y < gv_size.
      lv_x = 0.
      WHILE lv_x < gv_size.
        IF is_fixed( iv_x = lv_x iv_y = lv_y ) = abap_false
            AND mask_condition( iv_mask = iv_mask iv_x = lv_x iv_y = lv_y ) = abap_true.
          set_module(
            iv_x     = lv_x
            iv_y     = lv_y
            iv_dark  = 1 - get_module( iv_x = lv_x iv_y = lv_y )
            iv_fixed = abap_false ).
        ENDIF.
        lv_x = lv_x + 1.
      ENDWHILE.
      lv_y = lv_y + 1.
    ENDWHILE.
  ENDMETHOD.

  METHOD penalty.
    DATA lv_x TYPE i.
    DATA lv_y TYPE i.
    DATA lv_run TYPE i.
    DATA lv_last TYPE i.
    DATA lv_dark TYPE i.
    DATA lv_total TYPE i.

    " runs of five or more in rows and columns
    DO 2 TIMES.
      DATA(lv_vertical) = xsdbool( sy-index = 2 ).
      lv_y = 0.
      WHILE lv_y < gv_size.
        lv_run = 0.
        lv_last = -1.
        lv_x = 0.
        WHILE lv_x < gv_size.
          IF lv_vertical = abap_true.
            lv_dark = get_module( iv_x = lv_y iv_y = lv_x ).
          ELSE.
            lv_dark = get_module( iv_x = lv_x iv_y = lv_y ).
          ENDIF.

          IF lv_dark = lv_last.
            lv_run = lv_run + 1.
          ELSE.
            IF lv_run >= 5.
              rv_score = rv_score + 3 + lv_run - 5.
            ENDIF.
            lv_run = 1.
            lv_last = lv_dark.
          ENDIF.
          lv_x = lv_x + 1.
        ENDWHILE.
        IF lv_run >= 5.
          rv_score = rv_score + 3 + lv_run - 5.
        ENDIF.
        lv_y = lv_y + 1.
      ENDWHILE.
    ENDDO.

    " blocks of two by two
    lv_y = 0.
    WHILE lv_y < gv_size - 1.
      lv_x = 0.
      WHILE lv_x < gv_size - 1.
        lv_dark = get_module( iv_x = lv_x iv_y = lv_y ).
        IF lv_dark = get_module( iv_x = lv_x + 1 iv_y = lv_y )
            AND lv_dark = get_module( iv_x = lv_x iv_y = lv_y + 1 )
            AND lv_dark = get_module( iv_x = lv_x + 1 iv_y = lv_y + 1 ).
          rv_score = rv_score + 3.
        ENDIF.
        lv_x = lv_x + 1.
      ENDWHILE.
      lv_y = lv_y + 1.
    ENDWHILE.

    " dark to light ratio
    lv_y = 0.
    WHILE lv_y < gv_size.
      lv_x = 0.
      WHILE lv_x < gv_size.
        lv_total = lv_total + get_module( iv_x = lv_x iv_y = lv_y ).
        lv_x = lv_x + 1.
      ENDWHILE.
      lv_y = lv_y + 1.
    ENDWHILE.

    DATA(lv_percent) = lv_total * 100 / ( gv_size * gv_size ).
    rv_score = rv_score + abs( lv_percent - 50 ) DIV 5 * 10.
  ENDMETHOD.

  METHOD draw_format.
    DATA lv_i TYPE i.

    " level M is 00, followed by the mask
    DATA(lv_data) = iv_mask.
    DATA(lv_value) = lv_data * 1024.

    lv_i = 4.
    WHILE lv_i >= 0.
      IF lv_value DIV ipow( base = 2 exp = lv_i + 10 ) MOD 2 = 1.
        lv_value = xor( iv_a = lv_value iv_b = 1335 * ipow( base = 2 exp = lv_i ) ).
      ENDIF.
      lv_i = lv_i - 1.
    ENDWHILE.

    DATA(lv_format) = xor( iv_a = lv_data * 1024 + lv_value iv_b = 21522 ).

    " The 15 bits go to their positions with the least significant bit first
    lv_i = 0.
    WHILE lv_i <= 14.
      DATA(lv_bit) = lv_format DIV ipow( base = 2 exp = lv_i ) MOD 2.

      IF lv_i <= 5.
        set_module( iv_x = 8 iv_y = lv_i iv_dark = lv_bit ).
      ELSEIF lv_i = 6.
        set_module( iv_x = 8 iv_y = 7 iv_dark = lv_bit ).
      ELSEIF lv_i = 7.
        set_module( iv_x = 8 iv_y = 8 iv_dark = lv_bit ).
      ELSEIF lv_i = 8.
        set_module( iv_x = 7 iv_y = 8 iv_dark = lv_bit ).
      ELSE.
        set_module( iv_x = 14 - lv_i iv_y = 8 iv_dark = lv_bit ).
      ENDIF.

      IF lv_i <= 7.
        set_module( iv_x = gv_size - 1 - lv_i iv_y = 8 iv_dark = lv_bit ).
      ELSE.
        set_module( iv_x = 8 iv_y = gv_size - 15 + lv_i iv_dark = lv_bit ).
      ENDIF.

      lv_i = lv_i + 1.
    ENDWHILE.
  ENDMETHOD.

  METHOD draw_version.
    DATA lv_i TYPE i.

    IF iv_version < 7.
      RETURN.
    ENDIF.

    DATA(lv_value) = iv_version * 4096.
    lv_i = 5.
    WHILE lv_i >= 0.
      IF lv_value DIV ipow( base = 2 exp = lv_i + 12 ) MOD 2 = 1.
        lv_value = xor( iv_a = lv_value iv_b = 7973 * ipow( base = 2 exp = lv_i ) ).
      ENDIF.
      lv_i = lv_i - 1.
    ENDWHILE.

    DATA(lv_info) = iv_version * 4096 + lv_value.

    lv_i = 0.
    WHILE lv_i <= 17.
      DATA(lv_bit) = lv_info DIV ipow( base = 2 exp = lv_i ) MOD 2.
      DATA(lv_row) = lv_i DIV 3.
      DATA(lv_col) = lv_i MOD 3.
      set_module( iv_x = lv_row iv_y = gv_size - 11 + lv_col iv_dark = lv_bit ).
      set_module( iv_x = gv_size - 11 + lv_col iv_y = lv_row iv_dark = lv_bit ).
      lv_i = lv_i + 1.
    ENDWHILE.
  ENDMETHOD.

  METHOD codewords.
    DATA lt_data TYPE ty_bytes.
    DATA lv_byte TYPE x LENGTH 1.
    DATA lv_offset TYPE i.

    DATA(lv_bytes) = cl_abap_codepage=>convert_to( iv_text ).
    WHILE lv_offset < xstrlen( lv_bytes ).
      lv_byte = lv_bytes+lv_offset(1).
      APPEND CONV i( lv_byte ) TO lt_data.
      lv_offset = lv_offset + 1.
    ENDWHILE.

    DATA(ls_spec) = spec_for( lines( lt_data ) ).
    rt_out = interleave(
      it_data = build_bits( it_data = lt_data is_spec = ls_spec )
      is_spec = ls_spec ).
  ENDMETHOD.

  METHOD encode.
    DATA lt_data TYPE ty_bytes.
    DATA lv_byte TYPE x LENGTH 1.
    DATA lv_offset TYPE i.
    DATA lt_best TYPE ty_bytes.
    DATA lv_best_score TYPE i.
    DATA lv_best_mask TYPE i.
    DATA lv_row TYPE string.

    DATA(lv_bytes) = cl_abap_codepage=>convert_to( iv_text ).
    WHILE lv_offset < xstrlen( lv_bytes ).
      lv_byte = lv_bytes+lv_offset(1).
      APPEND CONV i( lv_byte ) TO lt_data.
      lv_offset = lv_offset + 1.
    ENDWHILE.

    DATA(ls_spec) = spec_for( lines( lt_data ) ).
    DATA(lt_codewords) = codewords( iv_text ).

    gv_size = 17 + 4 * ls_spec-version.

    " try every mask and keep the one with the lowest penalty
    lv_best_score = -1.
    DATA(lv_mask) = 0.
    WHILE lv_mask <= 7.
      CLEAR gt_module.
      CLEAR gt_fixed.
      DO gv_size * gv_size TIMES.
        APPEND 0 TO gt_module.
        APPEND 0 TO gt_fixed.
      ENDDO.

      draw_patterns( ls_spec-version ).
      place_data( lt_codewords ).
      apply_mask( lv_mask ).
      draw_format( lv_mask ).
      draw_version( ls_spec-version ).

      DATA(lv_score) = penalty( ).
      IF lv_best_score < 0 OR lv_score < lv_best_score.
        lv_best_score = lv_score.
        lv_best_mask = lv_mask.
        lt_best = gt_module.
      ENDIF.

      lv_mask = lv_mask + 1.
    ENDWHILE.

    gt_module = lt_best.

    DATA(lv_y) = 0.
    WHILE lv_y < gv_size.
      CLEAR lv_row.
      DATA(lv_x) = 0.
      WHILE lv_x < gv_size.
        lv_row = |{ lv_row }{ get_module( iv_x = lv_x iv_y = lv_y ) }|.
        lv_x = lv_x + 1.
      ENDWHILE.
      APPEND lv_row TO rt_rows.
      lv_y = lv_y + 1.
    ENDWHILE.
  ENDMETHOD.

ENDCLASS.
