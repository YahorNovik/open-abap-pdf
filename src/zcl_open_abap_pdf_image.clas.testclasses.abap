CLASS ltcl_image DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    METHODS parse_png FOR TESTING RAISING cx_static_check.
    METHODS parse_jpeg FOR TESTING RAISING cx_static_check.
    METHODS reject_garbage FOR TESTING RAISING cx_static_check.
    METHODS place_in_document FOR TESTING RAISING cx_static_check.
    METHODS keep_aspect_ratio FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_image IMPLEMENTATION.

  METHOD parse_png.
    DATA(ls_info) = zcl_open_abap_pdf_image=>parse(
      cl_http_utility=>decode_x_base64( zcl_pdf_test_images=>png( ) ) ).

    cl_abap_unit_assert=>assert_equals( act = ls_info-format exp = 'PNG' ).
    cl_abap_unit_assert=>assert_equals( act = ls_info-width exp = 48 ).
    cl_abap_unit_assert=>assert_equals( act = ls_info-height exp = 32 ).
    cl_abap_unit_assert=>assert_equals( act = ls_info-bpc exp = 8 ).
    cl_abap_unit_assert=>assert_equals( act = ls_info-colorspace exp = '/DeviceRGB' ).
    cl_abap_unit_assert=>assert_equals( act = ls_info-filter exp = '/FlateDecode' ).
    cl_abap_unit_assert=>assert_char_cp( act = ls_info-decode_parms exp = '*/Predictor 15*' ).
    cl_abap_unit_assert=>assert_char_cp( act = ls_info-decode_parms exp = '*/Columns 48*' ).
    cl_abap_unit_assert=>assert_not_initial( ls_info-data ).
  ENDMETHOD.

  METHOD parse_jpeg.
    DATA(ls_info) = zcl_open_abap_pdf_image=>parse(
      cl_http_utility=>decode_x_base64( zcl_pdf_test_images=>jpeg( ) ) ).

    cl_abap_unit_assert=>assert_equals( act = ls_info-format exp = 'JPEG' ).
    cl_abap_unit_assert=>assert_equals( act = ls_info-width exp = 64 ).
    cl_abap_unit_assert=>assert_equals( act = ls_info-height exp = 48 ).
    cl_abap_unit_assert=>assert_equals( act = ls_info-colorspace exp = '/DeviceRGB' ).
    cl_abap_unit_assert=>assert_equals( act = ls_info-filter exp = '/DCTDecode' ).
    cl_abap_unit_assert=>assert_initial( ls_info-decode_parms ).
  ENDMETHOD.

  METHOD reject_garbage.
    TRY.
        zcl_open_abap_pdf_image=>parse( CONV xstring( '00112233445566778899AABB' ) ).
        cl_abap_unit_assert=>fail( 'unsupported format must raise' ).
      CATCH zcx_open_abap_pdf INTO DATA(lx_error).
        cl_abap_unit_assert=>assert_char_cp(
          act = lx_error->mv_text
          exp = '*JPEG and PNG*' ).
    ENDTRY.
  ENDMETHOD.

  METHOD place_in_document.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->set_hex_streams( ).
    lo_pdf->add_page( ).
    lo_pdf->image_base64(
      iv_base64 = zcl_pdf_test_images=>png( )
      iv_x      = 50
      iv_y      = 50
      iv_width  = 96 ).

    DATA(lv_pdf) = lo_pdf->render( ).

    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/XObject << /Im1*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/Subtype /Image*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/Im1 Do Q*' ).
  ENDMETHOD.

  METHOD keep_aspect_ratio.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->add_page( ).

    " 48 x 32 pixels scaled to 96 points wide must be 64 points high
    lo_pdf->image_base64(
      iv_base64 = zcl_pdf_test_images=>png( )
      iv_x      = 10
      iv_y      = 10
      iv_width  = 96 ).

    " Raw bytes, so the document is searched in byte mode
    DATA(lv_bytes) = lo_pdf->render_binary( ).
    FIND FIRST OCCURRENCE OF cl_abap_codepage=>convert_to( 'q 96 0 0 64 10' )
      IN lv_bytes IN BYTE MODE.

    cl_abap_unit_assert=>assert_subrc( exp = 0 ).
  ENDMETHOD.

ENDCLASS.
