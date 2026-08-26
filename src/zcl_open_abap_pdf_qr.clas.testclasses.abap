CLASS ltcl_codes DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    METHODS code128_structure FOR TESTING RAISING cx_static_check.
    METHODS code128_checksum FOR TESTING RAISING cx_static_check.
    METHODS code128_rejects_non_ascii FOR TESTING RAISING cx_static_check.
    METHODS qr_size_and_patterns FOR TESTING RAISING cx_static_check.
    METHODS qr_version_grows FOR TESTING RAISING cx_static_check.
    METHODS qr_format_information FOR TESTING RAISING cx_static_check.
    METHODS qr_codewords FOR TESTING RAISING cx_static_check.
    METHODS qr_too_long FOR TESTING RAISING cx_static_check.
    METHODS draw_in_document FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_codes IMPLEMENTATION.

  METHOD code128_structure.
    DATA(lv_modules) = zcl_open_abap_pdf_barcode=>code128( 'A' ).

    " start B, one character, check digit, stop: 3 * 11 + 13 modules
    cl_abap_unit_assert=>assert_equals(
      act = strlen( lv_modules )
      exp = 46 ).

    " the start pattern of code set B is 211214
    cl_abap_unit_assert=>assert_equals(
      act = lv_modules(11)
      exp = '11010010000' ).

    " every Code 128 symbol ends with the stop pattern 2331112
    cl_abap_unit_assert=>assert_char_cp(
      act = lv_modules
      exp = '*1100011101011' ).
  ENDMETHOD.

  METHOD code128_checksum.
    " 'A' has value 33, so the check digit is ( 104 + 33 * 1 ) mod 103 = 34,
    " whose element widths are 131123, that is bar 1, space 3, bar 1, space 1, bar 2, space 3
    DATA(lv_modules) = zcl_open_abap_pdf_barcode=>code128( 'A' ).
    DATA(lv_offset) = 22.

    cl_abap_unit_assert=>assert_equals(
      act = lv_modules+lv_offset(11)
      exp = '10001011000' ).
  ENDMETHOD.

  METHOD code128_rejects_non_ascii.
    TRY.
        zcl_open_abap_pdf_barcode=>code128( |A{ cl_abap_conv_in_ce=>uccp( '00E4' ) }B| ).
        cl_abap_unit_assert=>fail( 'a umlaut cannot be encoded in code set B' ).
      CATCH zcx_open_abap_pdf INTO DATA(lx_error).
        cl_abap_unit_assert=>assert_char_cp( act = lx_error->mv_text exp = '*Code 128*' ).
    ENDTRY.
  ENDMETHOD.

  METHOD qr_size_and_patterns.
    DATA(lt_rows) = zcl_open_abap_pdf_qr=>encode( 'Hello' ).

    " a version 1 symbol has 21 by 21 modules
    cl_abap_unit_assert=>assert_equals( act = lines( lt_rows ) exp = 21 ).

    READ TABLE lt_rows INTO DATA(lv_first) INDEX 1.
    cl_abap_unit_assert=>assert_equals( act = strlen( lv_first ) exp = 21 ).

    " finder pattern in the top left corner and the separator next to it
    cl_abap_unit_assert=>assert_equals( act = lv_first(8) exp = '11111110' ).

    READ TABLE lt_rows INTO DATA(lv_second) INDEX 2.
    cl_abap_unit_assert=>assert_equals( act = lv_second(8) exp = '10000010' ).

    " timing pattern in row seven
    READ TABLE lt_rows INTO DATA(lv_timing) INDEX 7.
    cl_abap_unit_assert=>assert_equals( act = lv_timing exp = '111111101010101111111' ).
  ENDMETHOD.

  METHOD qr_version_grows.
    " version 1 holds 16 data codewords, version 2 holds 28, version 3 holds 44,
    " and two of them are used by the mode indicator and the length
    cl_abap_unit_assert=>assert_equals(
      act = lines( zcl_open_abap_pdf_qr=>encode( repeat( val = 'ab' occ = 7 ) ) )
      exp = 21
      msg = '14 bytes fit into version 1' ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( zcl_open_abap_pdf_qr=>encode( repeat( val = 'ab' occ = 10 ) ) )
      exp = 25
      msg = '20 bytes need version 2' ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( zcl_open_abap_pdf_qr=>encode( repeat( val = 'ab' occ = 15 ) ) )
      exp = 29
      msg = '30 bytes need version 3' ).

    cl_abap_unit_assert=>assert_true( xsdbool(
      lines( zcl_open_abap_pdf_qr=>encode( repeat( val = 'ab' occ = 100 ) ) ) > 45 ) ).
  ENDMETHOD.

  METHOD qr_format_information.
    " Level M with mask 2 has the format bit string 101111001111100, written
    " least significant bit first, so column 8 of the first six rows reads 0011111
    DATA(lt_rows) = zcl_open_abap_pdf_qr=>encode( 'M-100123|batch-4711' ).
    DATA lv_column TYPE string.

    LOOP AT lt_rows INTO DATA(lv_row) TO 6.
      DATA(lv_offset) = 8.
      lv_column = |{ lv_column }{ lv_row+lv_offset(1) }|.
    ENDLOOP.

    cl_abap_unit_assert=>assert_equals(
      act = lv_column
      exp = '001111'
      msg = 'format information of level M and mask 2, least significant bit first' ).
  ENDMETHOD.

  METHOD qr_codewords.
    " Byte mode is 0100, then the length in eight bits, then the data, so 'A' gives
    " 0100 00000001 01000001 0000, that is the codewords 64, 20, 16
    DATA(lt_codewords) = zcl_open_abap_pdf_qr=>codewords( 'A' ).

    READ TABLE lt_codewords INTO DATA(lv_first) INDEX 1.
    READ TABLE lt_codewords INTO DATA(lv_second) INDEX 2.
    READ TABLE lt_codewords INTO DATA(lv_third) INDEX 3.

    cl_abap_unit_assert=>assert_equals( act = lv_first exp = 64 ).
    cl_abap_unit_assert=>assert_equals( act = lv_second exp = 20 ).
    cl_abap_unit_assert=>assert_equals( act = lv_third exp = 16 ).

    " the first pad codeword after the data is 236
    READ TABLE lt_codewords INTO DATA(lv_fourth) INDEX 4.
    cl_abap_unit_assert=>assert_equals( act = lv_fourth exp = 236 ).

    " version 1 level M has 16 data and 10 error correction codewords
    cl_abap_unit_assert=>assert_equals( act = lines( lt_codewords ) exp = 26 ).
  ENDMETHOD.

  METHOD qr_too_long.
    TRY.
        zcl_open_abap_pdf_qr=>encode( repeat( val = 'x' occ = 400 ) ).
        cl_abap_unit_assert=>fail( 'more than version 10 is not supported' ).
      CATCH zcx_open_abap_pdf INTO DATA(lx_error).
        cl_abap_unit_assert=>assert_char_cp( act = lx_error->mv_text exp = '*version 10*' ).
    ENDTRY.
  ENDMETHOD.

  METHOD draw_in_document.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->add_page( ).
    lo_pdf->barcode_128( iv_x = 40 iv_y = 40 iv_text = 'ABC123' ).
    lo_pdf->qrcode( iv_x = 40 iv_y = 100 iv_text = 'https://example.com' iv_size = 80 ).

    DATA(lv_pdf) = lo_pdf->render( ).

    " both are drawn as filled rectangles
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*re f*' ).

    " the quiet zone shifts the first bar of the barcode by ten modules
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*48 * re f*' ).
  ENDMETHOD.

ENDCLASS.
