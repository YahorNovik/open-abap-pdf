CLASS zcl_pdf_demo_table DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_open_abap_pdf_layout.

    CLASS-METHODS run_base64
      RETURNING VALUE(rv_base64) TYPE string.

  PRIVATE SECTION.
    CLASS-METHODS material
      IMPORTING iv_index       TYPE i
      RETURNING VALUE(rv_text) TYPE string.
ENDCLASS.

CLASS zcl_pdf_demo_table IMPLEMENTATION.

  METHOD zif_open_abap_pdf_layout~header.
    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 15 ).
    io_pdf->set_text_color( iv_r = 0 iv_g = 51 iv_b = 102 ).
    io_pdf->cell( iv_text = 'Delivery note 80001234' iv_height = 22 iv_ln = abap_false ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 9 ).
    io_pdf->set_text_color( iv_r = 90 iv_g = 90 iv_b = 90 ).
    io_pdf->cell(
      iv_text   = |Plant 1000 / created 31.07.2026|
      iv_height = 22
      iv_align  = zcl_open_abap_pdf=>c_align_right ).

    io_pdf->set_draw_color( iv_r = 0 iv_g = 51 iv_b = 102 ).
    io_pdf->set_line_width( '1.5' ).
    io_pdf->line(
      iv_x1 = io_pdf->get_x( )
      iv_y1 = io_pdf->get_y( )
      iv_x2 = io_pdf->get_x( ) + io_pdf->get_content_width( )
      iv_y2 = io_pdf->get_y( ) ).
    io_pdf->set_line_width( '0.4' ).
    io_pdf->set_draw_color( iv_r = 160 iv_g = 160 iv_b = 160 ).
    io_pdf->set_text_color( iv_r = 0 iv_g = 0 iv_b = 0 ).
    io_pdf->ln( 14 ).
  ENDMETHOD.

  METHOD zif_open_abap_pdf_layout~footer.
    DATA(lv_y) = io_pdf->get_y( ).

    io_pdf->set_y( io_pdf->get_page_height( ) - 38 ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 8 ).
    io_pdf->set_text_color( iv_r = 130 iv_g = 130 iv_b = 130 ).
    io_pdf->cell(
      iv_text   = |open-abap-pdf   -   page { io_pdf->get_page_number( ) } of \{nb\}|
      iv_align  = zcl_open_abap_pdf=>c_align_center
      iv_border = 'T' ).
    io_pdf->set_text_color( iv_r = 0 iv_g = 0 iv_b = 0 ).
    io_pdf->set_y( lv_y ).
  ENDMETHOD.

  METHOD material.
    CASE iv_index MOD 4.
      WHEN 0.
        rv_text = 'Hexagon screw M8x40, stainless steel A2, DIN 933, packed in units of 100'.
      WHEN 1.
        rv_text = 'Ball bearing 6204-2RS'.
      WHEN 2.
        rv_text = 'Hydraulic hose DN12, 2SN, 1.8 m, with pressed fittings on both ends'.
      WHEN OTHERS.
        rv_text = 'Sealing ring 40x52x7'.
    ENDCASE.
  ENDMETHOD.

  METHOD run_base64.
    DATA lv_i TYPE i.
    DATA lv_qty TYPE i.
    DATA lv_price TYPE p LENGTH 8 DECIMALS 2.
    DATA lv_value TYPE p LENGTH 10 DECIMALS 2.
    DATA lv_total TYPE p LENGTH 10 DECIMALS 2.

    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->set_layout( NEW zcl_pdf_demo_table( ) ).
    lo_pdf->set_margins( iv_left = 40 iv_top = 40 iv_right = 40 iv_bottom = 40 ).
    lo_pdf->add_page( ).

    DATA(lo_table) = zcl_open_abap_pdf_table=>create( lo_pdf ).
    lo_table->add_column( iv_header = 'Item' iv_width = 40 iv_align = zcl_open_abap_pdf=>c_align_right ).
    lo_table->add_column( iv_header = 'Material' iv_width = 70 ).
    lo_table->add_column( iv_header = 'Description' ).
    lo_table->add_column( iv_header = 'Qty' iv_width = 45 iv_align = zcl_open_abap_pdf=>c_align_right ).
    lo_table->add_column( iv_header = 'Price' iv_width = 70 iv_align = zcl_open_abap_pdf=>c_align_right ).
    lo_table->add_column( iv_header = 'Value' iv_width = 85 iv_align = zcl_open_abap_pdf=>c_align_right ).
    lo_table->set_line_height( 13 ).
    lo_table->set_zebra( ).

    DO 34 TIMES.
      lv_i = sy-index.
      lv_qty = lv_i * 3.
      lv_price = lv_i * '1.75' + '4.20'.
      lv_value = lv_qty * lv_price.
      lv_total = lv_total + lv_value.

      lo_table->add_row( VALUE #(
        ( |{ lv_i * 10 }| )
        ( |M-{ 1000 + lv_i }| )
        ( material( lv_i ) )
        ( |{ lv_qty } PC| )
        ( |{ lv_price } EUR| )
        ( |{ lv_value } EUR| ) ) ).
    ENDDO.

    lo_table->add_row(
      it_cells = VALUE #( ( '' ) ( '' ) ( 'Total' ) ( '' ) ( '' ) ( |{ lv_total } EUR| ) )
      iv_bold  = abap_true ).

    lo_table->render( ).

    lo_pdf->ln( 20 ).
    lo_pdf->set_font( iv_name = 'Helvetica-Oblique' iv_size = 9 ).
    lo_pdf->multi_cell(
      iv_text = 'Long descriptions wrap inside the cell, the row grows, and the header row ' &&
                'is repeated automatically on every new page.' ).

    rv_base64 = cl_http_utility=>encode_x_base64( lo_pdf->render_binary( ) ).
  ENDMETHOD.

ENDCLASS.
