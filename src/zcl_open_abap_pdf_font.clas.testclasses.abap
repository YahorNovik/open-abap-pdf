CLASS ltcl_font DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    METHODS afm_widths FOR TESTING RAISING cx_static_check.
    METHODS text_width FOR TESTING RAISING cx_static_check.
    METHODS courier_is_fixed FOR TESTING RAISING cx_static_check.
    METHODS unknown_font_falls_back FOR TESTING RAISING cx_static_check.
    METHODS escape_specials FOR TESTING RAISING cx_static_check.
    METHODS escape_umlaut FOR TESTING RAISING cx_static_check.
    METHODS escape_euro FOR TESTING RAISING cx_static_check.
    METHODS wrap_words FOR TESTING RAISING cx_static_check.
    METHODS wrap_keeps_newlines FOR TESTING RAISING cx_static_check.
    METHODS wrap_long_word FOR TESTING RAISING cx_static_check.
    METHODS supported FOR TESTING RAISING cx_static_check.
    METHODS truncate FOR TESTING RAISING cx_static_check.
    METHODS unsupported_chars FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_font IMPLEMENTATION.

  METHOD afm_widths.
    " Adobe AFM reference values for Helvetica
    DATA(lv_widths) = zcl_open_abap_pdf_metrics=>widths( 'Helvetica' ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_widths(3)
      exp = '278'
      msg = 'space in Helvetica is 278/1000' ).

    " 'W' is code 87, offset ( 87 - 32 ) * 3
    cl_abap_unit_assert=>assert_equals(
      act = lv_widths+165(3)
      exp = '944'
      msg = 'W in Helvetica is 944/1000' ).
  ENDMETHOD.

  METHOD text_width.
    " Hello = 722 + 556 + 222 + 222 + 556 = 2278/1000 em, at 12pt = 27.336
    DATA(lv_width) = zcl_open_abap_pdf_font=>text_width(
      iv_font = 'Helvetica'
      iv_size = 12
      iv_text = 'Hello' ).

    cl_abap_unit_assert=>assert_equals(
      act = round( val = lv_width * 1000 dec = 0 )
      exp = 27336 ).
  ENDMETHOD.

  METHOD courier_is_fixed.
    DATA(lv_width) = zcl_open_abap_pdf_font=>text_width(
      iv_font = 'Courier'
      iv_size = 10
      iv_text = 'iiiii' ).

    cl_abap_unit_assert=>assert_equals(
      act = round( val = lv_width * 100 dec = 0 )
      exp = 3000
      msg = 'Courier is 600/1000 em per glyph' ).
  ENDMETHOD.

  METHOD unknown_font_falls_back.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_open_abap_pdf_metrics=>widths( 'No-Such-Font' )
      exp = zcl_open_abap_pdf_metrics=>widths( 'Helvetica' ) ).
  ENDMETHOD.

  METHOD escape_specials.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_open_abap_pdf_font=>escape( 'a(b)c\d' )
      exp = 'a\(b\)c\\d' ).
  ENDMETHOD.

  METHOD escape_umlaut.
    " a-umlaut is WinAnsi 228 = octal 344
    cl_abap_unit_assert=>assert_equals(
      act = zcl_open_abap_pdf_font=>escape( |M{ cl_abap_conv_in_ce=>uccp( '00E4' ) }ller| )
      exp = 'M\344ller' ).
  ENDMETHOD.

  METHOD escape_euro.
    " Euro sign is WinAnsi 128 = octal 200
    cl_abap_unit_assert=>assert_equals(
      act = zcl_open_abap_pdf_font=>escape( |{ cl_abap_conv_in_ce=>uccp( '20AC' ) }10| )
      exp = '\20010' ).
  ENDMETHOD.

  METHOD wrap_words.
    DATA(lt_lines) = zcl_open_abap_pdf_font=>wrap(
      iv_font  = 'Helvetica'
      iv_size  = 12
      iv_text  = 'The quick brown fox jumps over the lazy dog'
      iv_width = 100 ).

    cl_abap_unit_assert=>assert_true( xsdbool( lines( lt_lines ) > 1 ) ).

    LOOP AT lt_lines INTO DATA(lv_line).
      cl_abap_unit_assert=>assert_true(
        act = xsdbool( zcl_open_abap_pdf_font=>text_width(
                iv_font = 'Helvetica' iv_size = 12 iv_text = lv_line ) <= 100 )
        msg = |line does not fit: { lv_line }| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD wrap_keeps_newlines.
    DATA(lt_lines) = zcl_open_abap_pdf_font=>wrap(
      iv_font  = 'Helvetica'
      iv_size  = 12
      iv_text  = |one\ntwo\nthree|
      iv_width = 500 ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_lines ) exp = 3 ).
  ENDMETHOD.

  METHOD wrap_long_word.
    DATA(lt_lines) = zcl_open_abap_pdf_font=>wrap(
      iv_font  = 'Helvetica'
      iv_size  = 12
      iv_text  = 'Donaudampfschifffahrtsgesellschaftskapitaen'
      iv_width = 60 ).

    cl_abap_unit_assert=>assert_true( xsdbool( lines( lt_lines ) > 1 ) ).
  ENDMETHOD.

  METHOD truncate.
    DATA(lv_text) = zcl_open_abap_pdf_font=>truncate(
      iv_font  = 'Helvetica'
      iv_size  = 10
      iv_text  = 'A very long material description that does not fit'
      iv_width = 60 ).

    cl_abap_unit_assert=>assert_char_cp( act = lv_text exp = 'A very*...' ).
    cl_abap_unit_assert=>assert_true( xsdbool(
      zcl_open_abap_pdf_font=>text_width(
        iv_font = 'Helvetica' iv_size = 10 iv_text = lv_text ) <= 60 ) ).

    " Short enough texts are returned unchanged
    cl_abap_unit_assert=>assert_equals(
      act = zcl_open_abap_pdf_font=>truncate(
              iv_font = 'Helvetica' iv_size = 10 iv_text = 'ok' iv_width = 60 )
      exp = 'ok' ).
  ENDMETHOD.

  METHOD unsupported_chars.
    " Latin-1 and the WinAnsi specials are fine
    cl_abap_unit_assert=>assert_initial(
      zcl_open_abap_pdf_font=>unsupported(
        |Gr{ cl_abap_conv_in_ce=>uccp( '00FC' ) }{ cl_abap_conv_in_ce=>uccp( '00DF' ) }e | &&
        |{ cl_abap_conv_in_ce=>uccp( '20AC' ) } 10| ) ).

    " Polish l with stroke and s with acute cannot be encoded
    DATA(lv_bad) = zcl_open_abap_pdf_font=>unsupported(
      |Do zap{ cl_abap_conv_in_ce=>uccp( '0142' ) }aty Ilo{ cl_abap_conv_in_ce=>uccp( '015B' ) }| ).

    cl_abap_unit_assert=>assert_equals(
      act = strlen( lv_bad )
      exp = 2
      msg = 'two distinct characters cannot be encoded' ).

    " A real question mark is not reported
    cl_abap_unit_assert=>assert_initial( zcl_open_abap_pdf_font=>unsupported( 'why?' ) ).
  ENDMETHOD.

  METHOD supported.
    cl_abap_unit_assert=>assert_true( zcl_open_abap_pdf_font=>is_supported( 'Times-Bold' ) ).
    cl_abap_unit_assert=>assert_false( zcl_open_abap_pdf_font=>is_supported( 'Arial' ) ).
  ENDMETHOD.

ENDCLASS.
