CLASS ltcl_ttf DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    METHODS parse_head FOR TESTING RAISING cx_static_check.
    METHODS map_characters FOR TESTING RAISING cx_static_check.
    METHODS advance_widths FOR TESTING RAISING cx_static_check.
    METHODS reject_other_formats FOR TESTING RAISING cx_static_check.
    METHODS registry_and_width FOR TESTING RAISING cx_static_check.
    METHODS glyph_hex FOR TESTING RAISING cx_static_check.
    METHODS embed_in_document FOR TESTING RAISING cx_static_check.
    METHODS non_winansi_text FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_ttf IMPLEMENTATION.

  METHOD parse_head.
    DATA(ls_info) = zcl_open_abap_pdf_ttf=>parse(
      iv_data = zcl_pdf_test_font=>ttf( )
      iv_name = 'TestFont' ).

    cl_abap_unit_assert=>assert_equals( act = ls_info-name exp = 'TestFont' ).
    cl_abap_unit_assert=>assert_equals( act = ls_info-units exp = 1000 ).
    cl_abap_unit_assert=>assert_equals( act = ls_info-num_glyphs exp = 3 ).
    cl_abap_unit_assert=>assert_equals( act = ls_info-ascent exp = 800 ).
    cl_abap_unit_assert=>assert_equals( act = ls_info-descent exp = -200 ).
    cl_abap_unit_assert=>assert_equals( act = ls_info-y_max exp = 700 ).
    cl_abap_unit_assert=>assert_not_initial( ls_info-segments ).
  ENDMETHOD.

  METHOD map_characters.
    DATA(ls_info) = zcl_open_abap_pdf_ttf=>parse( zcl_pdf_test_font=>ttf( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = zcl_open_abap_pdf_ttf=>glyph_id( is_info = ls_info iv_cp = 65 )
      exp = 1
      msg = 'A is glyph 1' ).

    " L with stroke, a character that WinAnsi cannot encode
    cl_abap_unit_assert=>assert_equals(
      act = zcl_open_abap_pdf_ttf=>glyph_id( is_info = ls_info iv_cp = 321 )
      exp = 2 ).

    cl_abap_unit_assert=>assert_equals(
      act = zcl_open_abap_pdf_ttf=>glyph_id( is_info = ls_info iv_cp = 66 )
      exp = 0
      msg = 'characters without a glyph give zero' ).
  ENDMETHOD.

  METHOD advance_widths.
    DATA(ls_info) = zcl_open_abap_pdf_ttf=>parse( zcl_pdf_test_font=>ttf( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = zcl_open_abap_pdf_ttf=>advance( is_info = ls_info iv_gid = 1 )
      exp = 600 ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_open_abap_pdf_ttf=>advance( is_info = ls_info iv_gid = 2 )
      exp = 500 ).
  ENDMETHOD.

  METHOD reject_other_formats.
    TRY.
        zcl_open_abap_pdf_ttf=>parse( CONV xstring( '4F54544F00010000AABBCCDD' ) ).
        cl_abap_unit_assert=>fail( 'OpenType with CFF outlines must be rejected' ).
      CATCH zcx_open_abap_pdf INTO DATA(lx_error).
        cl_abap_unit_assert=>assert_char_cp( act = lx_error->mv_text exp = '*TrueType*' ).
    ENDTRY.
  ENDMETHOD.

  METHOD registry_and_width.
    zcl_open_abap_pdf_font=>register_truetype(
      iv_name = 'RegTest'
      iv_data = zcl_pdf_test_font=>ttf( ) ).

    cl_abap_unit_assert=>assert_true( zcl_open_abap_pdf_font=>is_truetype( 'RegTest' ) ).
    cl_abap_unit_assert=>assert_false( zcl_open_abap_pdf_font=>is_truetype( 'Helvetica' ) ).

    " A is 600/1000 em, so at 10pt it is 6 points wide
    cl_abap_unit_assert=>assert_equals(
      act = round( val = zcl_open_abap_pdf_font=>text_width(
                           iv_font = 'RegTest' iv_size = 10 iv_text = 'AA' ) * 100 dec = 0 )
      exp = 1200 ).
  ENDMETHOD.

  METHOD glyph_hex.
    zcl_open_abap_pdf_font=>register_truetype(
      iv_name = 'HexTest'
      iv_data = zcl_pdf_test_font=>ttf( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = zcl_open_abap_pdf_font=>glyph_hex( iv_name = 'HexTest' iv_text = 'AA' )
      exp = '00010001' ).

    cl_abap_unit_assert=>assert_equals(
      act = zcl_open_abap_pdf_font=>glyph_hex(
              iv_name = 'HexTest'
              iv_text = cl_abap_conv_in_ce=>uccp( '0141' ) )
      exp = '0002' ).
  ENDMETHOD.

  METHOD embed_in_document.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->set_hex_streams( ).
    lo_pdf->register_font( iv_name = 'DocFont' iv_data = zcl_pdf_test_font=>ttf( ) ).
    lo_pdf->add_page( ).
    lo_pdf->set_font( iv_name = 'DocFont' iv_size = 12 ).
    lo_pdf->text( iv_x = 50 iv_y = 50 iv_text = 'A' ).

    DATA(lv_pdf) = lo_pdf->render( ).

    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/Subtype /Type0*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/Encoding /Identity-H*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/Subtype /CIDFontType2*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/FontFile2*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/ToUnicode*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/CIDToGIDMap /Identity*' ).

    " Glyph indices instead of a literal string, and the width of glyph 1
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*<0001> Tj*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/W [1 [600]*' ).
  ENDMETHOD.

  METHOD non_winansi_text.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->set_hex_streams( ).
    lo_pdf->register_font( iv_name = 'PlFont' iv_data = zcl_pdf_test_font=>ttf( ) ).
    lo_pdf->add_page( ).
    lo_pdf->set_font( iv_name = 'PlFont' iv_size = 12 ).
    lo_pdf->text(
      iv_x    = 50
      iv_y    = 50
      iv_text = cl_abap_conv_in_ce=>uccp( '0141' ) ).

    DATA(lv_pdf) = lo_pdf->render( ).

    " With a Base-14 font this character would end up as a question mark
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*<0002> Tj*' ).

    " The ToUnicode map has to point glyph 2 back to U+0141 for copy and search
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*<0002> <0141>*' ).
  ENDMETHOD.

ENDCLASS.
