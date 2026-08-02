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
    METHODS subset_structure FOR TESTING RAISING cx_static_check.
    METHODS subset_keeps_glyph_ids FOR TESTING RAISING cx_static_check.
    METHODS subset_switch FOR TESTING RAISING cx_static_check.
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

  METHOD subset_structure.
    DATA(ls_info) = zcl_open_abap_pdf_ttf=>parse( zcl_pdf_test_font=>ttf( ) ).

    DATA(lv_subset) = zcl_open_abap_pdf_ttf=>subset(
      is_info = ls_info
      it_gids = VALUE #( ( 1 ) ) ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_subset(4)
      exp = CONV xstring( '00010000' )
      msg = 'a TrueType font starts with version 1.0' ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_subset+4(2)
      exp = CONV xstring( '0006' )
      msg = 'glyf, head, hhea, hmtx, loca and maxp' ).

    cl_abap_unit_assert=>assert_true(
      act = xsdbool( xstrlen( lv_subset ) < xstrlen( ls_info-data ) )
      msg = 'the subset has to be smaller than the original' ).
  ENDMETHOD.

  METHOD subset_keeps_glyph_ids.
    DATA(ls_info) = zcl_open_abap_pdf_ttf=>parse( zcl_pdf_test_font=>ttf( ) ).

    " Glyph 2 alone, so the font needs two glyph slots plus the empty glyph 0
    DATA(lv_subset) = zcl_open_abap_pdf_ttf=>subset(
      is_info = ls_info
      it_gids = VALUE #( ( 2 ) ) ).

    DATA(ls_subset_info) = ls_info.
    ls_subset_info-data = lv_subset.

    " Read the directory of the new font and check the number of glyphs in maxp
    DATA(lv_tables) = zcl_open_abap_pdf_ttf=>uint( iv_data = lv_subset iv_offset = 4 iv_length = 2 ).
    DATA(lv_offset) = 12.
    DATA(lv_maxp) = 0.
    DO lv_tables TIMES.
      IF cl_abap_codepage=>convert_from( lv_subset+lv_offset(4) ) = 'maxp'.
        lv_maxp = zcl_open_abap_pdf_ttf=>uint(
          iv_data   = lv_subset
          iv_offset = lv_offset + 8
          iv_length = 4 ).
      ENDIF.
      lv_offset = lv_offset + 16.
    ENDDO.

    cl_abap_unit_assert=>assert_equals(
      act = zcl_open_abap_pdf_ttf=>uint( iv_data = lv_subset iv_offset = lv_maxp + 4 iv_length = 2 )
      exp = 3
      msg = 'glyph indices are kept, so the count reaches the highest used glyph' ).
  ENDMETHOD.

  METHOD subset_switch.
    DATA(lv_full_size) = xstrlen( zcl_pdf_test_font=>ttf( ) ).

    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->set_hex_streams( ).
    lo_pdf->set_subset_fonts( abap_false ).
    lo_pdf->register_font( iv_name = 'FullFont' iv_data = zcl_pdf_test_font=>ttf( ) ).
    lo_pdf->add_page( ).
    lo_pdf->set_font( iv_name = 'FullFont' iv_size = 12 ).
    lo_pdf->text( iv_x = 10 iv_y = 10 iv_text = 'A' ).

    cl_abap_unit_assert=>assert_char_cp(
      act = lo_pdf->render( )
      exp = |*/Length1 { lv_full_size }*|
      msg = 'without subsetting the whole font file is embedded' ).

    DATA(lo_subset) = zcl_open_abap_pdf=>create( ).
    lo_subset->set_hex_streams( ).
    lo_subset->register_font( iv_name = 'SubFont' iv_data = zcl_pdf_test_font=>ttf( ) ).
    lo_subset->add_page( ).
    lo_subset->set_font( iv_name = 'SubFont' iv_size = 12 ).
    lo_subset->text( iv_x = 10 iv_y = 10 iv_text = 'A' ).

    DATA(lv_pdf) = lo_subset->render( ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/BaseFont /SUBSET+SubFont*' ).
    cl_abap_unit_assert=>assert_false( xsdbool( lv_pdf CS |/Length1 { lv_full_size }| ) ).
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
