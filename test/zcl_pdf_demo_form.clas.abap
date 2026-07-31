CLASS zcl_pdf_demo_form DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    CLASS-METHODS run_base64
      RETURNING VALUE(rv_base64) TYPE string.

    CLASS-METHODS run_flat_base64
      RETURNING VALUE(rv_base64) TYPE string.

  PRIVATE SECTION.
    CLASS-METHODS build
      IMPORTING iv_flatten    TYPE abap_bool
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

    CLASS-METHODS label
      IMPORTING io_pdf  TYPE REF TO zcl_open_abap_pdf
                iv_text TYPE string
                iv_y    TYPE f.
ENDCLASS.

CLASS zcl_pdf_demo_form IMPLEMENTATION.

  METHOD run_base64.
    rv_base64 = cl_http_utility=>encode_x_base64( build( abap_false )->render_binary( ) ).
  ENDMETHOD.

  METHOD run_flat_base64.
    rv_base64 = cl_http_utility=>encode_x_base64( build( abap_true )->render_binary( ) ).
  ENDMETHOD.

  METHOD label.
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 10 ).
    io_pdf->set_xy( iv_x = 40 iv_y = iv_y ).
    io_pdf->cell( iv_text = iv_text iv_width = 150 iv_height = 18 iv_ln = abap_false ).
  ENDMETHOD.

  METHOD build.
    DATA lv_y TYPE f.

    ro_pdf = zcl_open_abap_pdf=>create( ).
    ro_pdf->set_flatten_form( iv_flatten ).
    ro_pdf->set_margins( iv_left = 40 iv_top = 40 iv_right = 40 iv_bottom = 40 ).
    ro_pdf->add_page( ).

    ro_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 16 ).
    ro_pdf->cell( iv_text = 'Travel expense request' iv_height = 26 ).
    ro_pdf->set_font( iv_name = 'Helvetica' iv_size = 10 ).
    ro_pdf->multi_cell(
      iv_text = COND string(
        WHEN iv_flatten = abap_true
        THEN `Flattened copy, the values are drawn as static text.`
        ELSE `Fillable AcroForm, open in a PDF reader and type into the fields.` ) ).
    ro_pdf->ln( 12 ).

    lv_y = ro_pdf->get_y( ).

    label( io_pdf = ro_pdf iv_text = 'Employee' iv_y = lv_y ).
    ro_pdf->text_field(
      iv_name  = 'EMPLOYEE'
      iv_x     = 190
      iv_y     = lv_y
      iv_width = 250
      iv_value = 'Lars Hvam' ).

    lv_y = lv_y + 26.
    label( io_pdf = ro_pdf iv_text = 'Cost center' iv_y = lv_y ).
    ro_pdf->text_field(
      iv_name    = 'COST_CENTER'
      iv_x       = 190
      iv_y       = lv_y
      iv_width   = 120
      iv_value   = '1000-4711'
      iv_max_len = 10 ).

    lv_y = lv_y + 26.
    label( io_pdf = ro_pdf iv_text = 'Amount' iv_y = lv_y ).
    ro_pdf->text_field(
      iv_name  = 'AMOUNT'
      iv_x     = 190
      iv_y     = lv_y
      iv_width = 120
      iv_value = '1.250,00 EUR'
      iv_align = 2 ).

    lv_y = lv_y + 26.
    label( io_pdf = ro_pdf iv_text = 'Trip type' iv_y = lv_y ).
    ro_pdf->dropdown(
      iv_name    = 'TRIP_TYPE'
      it_options = VALUE #( ( 'Domestic' ) ( 'International' ) ( 'Training' ) )
      iv_x       = 190
      iv_y       = lv_y
      iv_width   = 160
      iv_value   = 'International' ).

    lv_y = lv_y + 26.
    label( io_pdf = ro_pdf iv_text = 'Advance payment' iv_y = lv_y ).
    ro_pdf->checkbox(
      iv_name    = 'ADVANCE'
      iv_x       = 192
      iv_y       = lv_y + 3
      iv_checked = abap_true ).

    lv_y = lv_y + 26.
    label( io_pdf = ro_pdf iv_text = 'Approval level' iv_y = lv_y ).
    ro_pdf->radio_button(
      iv_name     = 'LEVEL'
      iv_value    = 'Manager'
      iv_x        = 192
      iv_y        = lv_y + 3
      iv_selected = abap_true ).
    ro_pdf->set_xy( iv_x = 210 iv_y = lv_y ).
    ro_pdf->cell( iv_text = 'Manager' iv_width = 80 iv_height = 18 iv_ln = abap_false ).
    ro_pdf->radio_button(
      iv_name  = 'LEVEL'
      iv_value = 'Director'
      iv_x     = 300
      iv_y     = lv_y + 3 ).
    ro_pdf->set_xy( iv_x = 318 iv_y = lv_y ).
    ro_pdf->cell( iv_text = 'Director' iv_width = 80 iv_height = 18 iv_ln = abap_false ).

    lv_y = lv_y + 34.
    label( io_pdf = ro_pdf iv_text = 'Reason' iv_y = lv_y ).
    ro_pdf->text_field(
      iv_name      = 'REASON'
      iv_x         = 190
      iv_y         = lv_y
      iv_width     = 320
      iv_height    = 70
      iv_value     = 'Customer workshop'
      iv_multiline = abap_true ).

    lv_y = lv_y + 90.
    ro_pdf->set_xy( iv_x = 40 iv_y = lv_y ).
    ro_pdf->set_font( iv_name = 'Helvetica' iv_size = 9 ).
    ro_pdf->cell(
      iv_text   = |Interactive fields in this document: { ro_pdf->get_field_count( ) }|
      iv_border = 'T' ).
  ENDMETHOD.

ENDCLASS.
