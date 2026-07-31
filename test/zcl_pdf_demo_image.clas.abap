CLASS zcl_pdf_demo_image DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    CLASS-METHODS run_base64
      RETURNING VALUE(rv_base64) TYPE string
      RAISING   zcx_open_abap_pdf.

    CLASS-METHODS run_hex_base64
      RETURNING VALUE(rv_base64) TYPE string
      RAISING   zcx_open_abap_pdf.

  PRIVATE SECTION.
    CLASS-METHODS build
      IMPORTING iv_hex        TYPE abap_bool
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf
      RAISING   zcx_open_abap_pdf.
ENDCLASS.

CLASS zcl_pdf_demo_image IMPLEMENTATION.

  METHOD run_base64.
    rv_base64 = cl_http_utility=>encode_x_base64( build( abap_false )->render_binary( ) ).
  ENDMETHOD.

  METHOD run_hex_base64.
    rv_base64 = cl_http_utility=>encode_x_base64( build( abap_true )->render_binary( ) ).
  ENDMETHOD.

  METHOD build.
    ro_pdf = zcl_open_abap_pdf=>create( ).
    ro_pdf->set_hex_images( iv_hex ).
    ro_pdf->set_margins( iv_left = 40 iv_top = 40 iv_right = 40 iv_bottom = 40 ).
    ro_pdf->add_page( ).

    ro_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 16 ).
    ro_pdf->cell( iv_text = 'Images' iv_height = 24 ).
    ro_pdf->set_font( iv_name = 'Helvetica' iv_size = 10 ).
    ro_pdf->multi_cell(
      iv_text = `PNG is embedded as FlateDecode with a PNG predictor, JPEG as DCTDecode. ` &&
                'Sizes are given in points, a missing dimension keeps the aspect ratio.' ).
    ro_pdf->ln( 10 ).

    DATA(lv_y) = ro_pdf->get_y( ).

    ro_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 10 ).
    ro_pdf->set_xy( iv_x = 40 iv_y = lv_y ).
    ro_pdf->cell( iv_text = 'PNG 48x32 px, 144 pt wide' iv_width = 200 iv_ln = abap_false ).
    ro_pdf->cell( iv_text = 'JPEG 64x48 px, 90 pt high' iv_width = 200 ).

    ro_pdf->image_base64(
      iv_base64 = zcl_pdf_test_images=>png( )
      iv_x      = 40
      iv_y      = lv_y + 18
      iv_width  = 144 ).

    ro_pdf->image_base64(
      iv_base64 = zcl_pdf_test_images=>jpeg( )
      iv_x      = 240
      iv_y      = lv_y + 18
      iv_height = 90 ).

    ro_pdf->set_xy( iv_x = 40 iv_y = lv_y + 130 ).
    ro_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 10 ).
    ro_pdf->cell( iv_text = 'Same PNG at 300 dpi, natural size' ).
    ro_pdf->image_base64(
      iv_base64 = zcl_pdf_test_images=>png( )
      iv_x      = 40
      iv_y      = ro_pdf->get_y( )
      iv_dpi    = 300 ).

    ro_pdf->set_xy( iv_x = 240 iv_y = lv_y + 148 ).
    ro_pdf->set_font( iv_name = 'Helvetica' iv_size = 9 ).
    ro_pdf->multi_cell(
      iv_text  = `A logo in a table cell or in a page header works the same way, ` &&
                 'the image is placed with absolute coordinates while the cursor stays where it was.'
      iv_width = 250 ).

    ro_pdf->set_xy( iv_x = 40 iv_y = lv_y + 220 ).
    ro_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 11 ).
    ro_pdf->cell( iv_text = |Image stream encoding: { COND string(
      WHEN iv_hex = abap_true THEN 'ASCII hex' ELSE 'raw bytes' ) }| ).
  ENDMETHOD.

ENDCLASS.
