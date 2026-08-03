CLASS ltcl_code128 DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    CONSTANTS c_start_b TYPE string VALUE '11010010000'.
    CONSTANTS c_stop TYPE string VALUE '1100011101011'.

    METHODS one_character FOR TESTING RAISING cx_static_check.
    METHODS two_characters FOR TESTING RAISING cx_static_check.
    METHODS frame FOR TESTING RAISING cx_static_check.
    METHODS length_grows_by_eleven FOR TESTING RAISING cx_static_check.
    METHODS every_module_is_a_bit FOR TESTING RAISING cx_static_check.
    METHODS control_character FOR TESTING RAISING cx_static_check.
    METHODS above_winansi FOR TESTING RAISING cx_static_check.
    METHODS empty_text FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_code128 IMPLEMENTATION.

  METHOD one_character.
    " Start B, the character, the check digit and the stop pattern.
    " 'A' is value 33, and the check digit is ( 104 + 1 * 33 ) mod 103 = 34.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_open_abap_pdf_barcode=>code128( 'A' )
      exp = '1101001000010100011000100010110001100011101011' ).
  ENDMETHOD.

  METHOD two_characters.
    " The check digit weighs the second character twice, so it has to differ
    " from the one character case even though the prefix is the same
    cl_abap_unit_assert=>assert_equals(
      act = zcl_open_abap_pdf_barcode=>code128( 'AB' )
      exp = '110100100001010001100010001011000111101011101100011101011' ).
  ENDMETHOD.

  METHOD frame.
    DATA(lv_modules) = zcl_open_abap_pdf_barcode=>code128( '900-2026-0042' ).

    cl_abap_unit_assert=>assert_equals(
      act = substring( val = lv_modules len = 11 )
      exp = c_start_b
      msg = 'a Code 128 B symbol has to open with the start B pattern' ).

    cl_abap_unit_assert=>assert_equals(
      act = substring( val = lv_modules off = strlen( lv_modules ) - 13 )
      exp = c_stop
      msg = 'the stop pattern is thirteen modules wide, not eleven' ).
  ENDMETHOD.

  METHOD length_grows_by_eleven.
    " Every character adds one pattern of eleven modules. The frame is the start
    " pattern, the check digit and the thirteen module stop pattern.
    DATA(lv_short) = strlen( zcl_open_abap_pdf_barcode=>code128( 'X' ) ).
    DATA(lv_long) = strlen( zcl_open_abap_pdf_barcode=>code128( 'XXXXX' ) ).

    cl_abap_unit_assert=>assert_equals( act = lv_short exp = 46 ).
    cl_abap_unit_assert=>assert_equals( act = lv_long exp = 46 + 4 * 11 ).
  ENDMETHOD.

  METHOD every_module_is_a_bit.
    " The caller draws a rectangle for every run of ones, so anything other
    " than a zero or a one would silently disappear from the symbol
    DATA(lv_modules) = zcl_open_abap_pdf_barcode=>code128( 'Nova 42/7' ).

    DATA(lv_offset) = 0.
    WHILE lv_offset < strlen( lv_modules ).
      DATA(lv_char) = substring( val = lv_modules off = lv_offset len = 1 ).
      IF lv_char <> '0' AND lv_char <> '1'.
        cl_abap_unit_assert=>fail( |module { lv_offset } is { lv_char }| ).
      ENDIF.
      lv_offset = lv_offset + 1.
    ENDWHILE.
  ENDMETHOD.

  METHOD control_character.
    TRY.
        zcl_open_abap_pdf_barcode=>code128( |a{ cl_abap_char_utilities=>horizontal_tab }b| ).
        cl_abap_unit_assert=>fail( 'a tab is not in character set B' ).
      CATCH zcx_open_abap_pdf INTO DATA(lx_error).
        cl_abap_unit_assert=>assert_char_cp( act = lx_error->mv_text exp = '*cannot encode*' ).
    ENDTRY.
  ENDMETHOD.

  METHOD above_winansi.
    " Character set B covers 32 to 126, an umlaut is outside it
    TRY.
        zcl_open_abap_pdf_barcode=>code128( |Gr{ cl_abap_conv_in_ce=>uccp( '00F6' ) }sse| ).
        cl_abap_unit_assert=>fail( 'an umlaut is not in character set B' ).
      CATCH zcx_open_abap_pdf INTO DATA(lx_error).
        cl_abap_unit_assert=>assert_char_cp( act = lx_error->mv_text exp = '*cannot encode*' ).
    ENDTRY.
  ENDMETHOD.

  METHOD empty_text.
    " A symbol without content would scan as an empty string, which is worse
    " than no symbol at all, so it is refused
    TRY.
        zcl_open_abap_pdf_barcode=>code128( `` ).
        cl_abap_unit_assert=>fail( 'an empty barcode has to be refused' ).
      CATCH zcx_open_abap_pdf INTO DATA(lx_error).
        cl_abap_unit_assert=>assert_char_cp( act = lx_error->mv_text exp = '*nothing to encode*' ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
