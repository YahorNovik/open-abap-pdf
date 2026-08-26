CLASS zcl_pdf_demo_layout DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_open_abap_pdf_layout.

    CLASS-METHODS run_base64
      RETURNING VALUE(rv_base64) TYPE string.

  PRIVATE SECTION.
    CLASS-METHODS lorem
      RETURNING VALUE(rv_text) TYPE string.
ENDCLASS.

CLASS zcl_pdf_demo_layout IMPLEMENTATION.

  METHOD lorem.
    " Backtick literals keep the trailing blanks
    rv_text = `Auto page break, wrapped text and repeated headers make it possible to render ` &&
              `documents of unknown length, for example a delivery note with an open number of ` &&
              `items, without any manual y coordinate arithmetic in the calling program. `.
  ENDMETHOD.

  METHOD zif_open_abap_pdf_layout~header.
    io_pdf->set_fill_color( iv_r = 0 iv_g = 51 iv_b = 102 ).
    io_pdf->set_text_color( iv_r = 255 iv_g = 255 iv_b = 255 ).
    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 14 ).
    io_pdf->cell(
      iv_text   = 'open-abap-pdf'
      iv_height = 26
      iv_fill   = abap_true ).

    io_pdf->set_text_color( iv_r = 0 iv_g = 0 iv_b = 0 ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 11 ).
    io_pdf->ln( 10 ).
  ENDMETHOD.

  METHOD zif_open_abap_pdf_layout~footer.
    DATA(lv_y) = io_pdf->get_y( ).

    io_pdf->set_y( io_pdf->get_page_height( ) - 40 ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 9 ).
    io_pdf->set_text_color( iv_r = 120 iv_g = 120 iv_b = 120 ).
    io_pdf->cell(
      iv_text  = |Page { io_pdf->get_page_number( ) } of \{nb\}|
      iv_align = zcl_open_abap_pdf=>c_align_center
      iv_border = 'T' ).

    io_pdf->set_text_color( iv_r = 0 iv_g = 0 iv_b = 0 ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 11 ).
    io_pdf->set_y( lv_y ).
  ENDMETHOD.

  METHOD run_base64.
    DATA lv_i TYPE i.

    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->set_layout( NEW zcl_pdf_demo_layout( ) ).
    lo_pdf->set_margins( iv_left = 40 iv_top = 40 iv_right = 40 iv_bottom = 40 ).
    lo_pdf->add_page( ).

    lo_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 16 ).
    lo_pdf->cell( iv_text = 'Layout and pagination' iv_height = 24 ).
    lo_pdf->set_font( iv_name = 'Helvetica' iv_size = 11 ).
    lo_pdf->ln( 6 ).

    DO 14 TIMES.
      lv_i = sy-index.
      lo_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 11 ).
      lo_pdf->multi_cell( iv_text = |Section { lv_i }| ).
      lo_pdf->set_font( iv_name = 'Helvetica' iv_size = 11 ).
      lo_pdf->multi_cell(
        iv_text   = lorem( ) && lorem( )
        iv_height = 13 ).
      lo_pdf->ln( 8 ).
    ENDDO.

    lo_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 11 ).
    lo_pdf->cell(
      iv_text   = 'Right aligned, boxed and filled'
      iv_width  = lo_pdf->get_content_width( )
      iv_height = 20
      iv_align  = zcl_open_abap_pdf=>c_align_right
      iv_border = '1'
      iv_fill   = abap_false ).

    rv_base64 = cl_http_utility=>encode_x_base64( lo_pdf->render_binary( ) ).
  ENDMETHOD.

ENDCLASS.
