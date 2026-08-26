CLASS zcl_pdf_demo_dummy_inv DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    "! A dummy invoice with hard coded data, so the whole document is one ABAP
    "! class with no database and no selection. Render it outside SAP with
    "!   node test/render.mjs ZCL_PDF_DEMO_DUMMY_INV run_base64 invoice.pdf
    "! or call run_binary( ) from a report and hand the xstring to a channel.
    CLASS-METHODS run_base64
      RETURNING VALUE(rv_base64) TYPE string
      RAISING   zcx_open_abap_pdf.

    CLASS-METHODS run_binary
      RETURNING VALUE(rv_pdf) TYPE xstring
      RAISING   zcx_open_abap_pdf.

  PRIVATE SECTION.
    TYPES ty_amount TYPE p LENGTH 13 DECIMALS 2.
    TYPES:
      BEGIN OF ty_item,
        pos   TYPE string,
        matnr TYPE string,
        text  TYPE string,
        qty   TYPE i,
        price TYPE p LENGTH 9 DECIMALS 2,
      END OF ty_item,
      ty_items TYPE STANDARD TABLE OF ty_item WITH DEFAULT KEY.

    CONSTANTS c_left TYPE f VALUE 45.
    CONSTANTS c_number TYPE string VALUE 'INV-2026-00471'.
    CONSTANTS c_iban TYPE string VALUE 'DE89370400440532013000'.

    CLASS-METHODS items
      RETURNING VALUE(rt_items) TYPE ty_items.

    CLASS-METHODS header
      IMPORTING io_pdf TYPE REF TO zcl_open_abap_pdf.

    CLASS-METHODS info_and_partner
      IMPORTING io_pdf TYPE REF TO zcl_open_abap_pdf.

    CLASS-METHODS item_table
      IMPORTING io_pdf        TYPE REF TO zcl_open_abap_pdf
      RETURNING VALUE(rv_net) TYPE ty_amount.

    CLASS-METHODS totals
      IMPORTING io_pdf TYPE REF TO zcl_open_abap_pdf
                iv_net TYPE ty_amount.

    CLASS-METHODS codes
      IMPORTING io_pdf   TYPE REF TO zcl_open_abap_pdf
                iv_gross TYPE ty_amount
      RAISING   zcx_open_abap_pdf.

    "! Group the integer part in thousands and use a comma as the decimal mark
    CLASS-METHODS amount
      IMPORTING iv_value       TYPE ty_amount
      RETURNING VALUE(rv_text) TYPE string.

    "! The amount the way a SEPA QR wants it, a dot and no grouping
    CLASS-METHODS plain
      IMPORTING iv_value       TYPE ty_amount
      RETURNING VALUE(rv_text) TYPE string.

    CLASS-METHODS pair
      IMPORTING io_pdf   TYPE REF TO zcl_open_abap_pdf
                iv_key   TYPE string
                iv_value TYPE string.
ENDCLASS.


CLASS zcl_pdf_demo_dummy_inv IMPLEMENTATION.

  METHOD run_base64.
    rv_base64 = cl_http_utility=>encode_x_base64( run_binary( ) ).
  ENDMETHOD.


  METHOD run_binary.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->set_compression( ).
    lo_pdf->set_margins( iv_left = c_left iv_top = 40 iv_right = c_left iv_bottom = 40 ).
    lo_pdf->add_page( ).

    header( lo_pdf ).
    info_and_partner( lo_pdf ).
    DATA(lv_net) = item_table( lo_pdf ).
    totals( io_pdf = lo_pdf iv_net = lv_net ).

    " Nineteen percent value added tax. The rounding has to match the totals
    " block, otherwise the amount in the payment QR differs from the printed one
    DATA(lv_vat) = CONV ty_amount( lv_net * 19 / 100 ).
    DATA(lv_gross) = CONV ty_amount( lv_net + lv_vat ).
    codes( io_pdf = lo_pdf iv_gross = lv_gross ).

    lo_pdf->set_font( iv_name = 'Helvetica' iv_size = 8 ).
    lo_pdf->set_xy( iv_x = c_left iv_y = 690 ).
    lo_pdf->cell(
      iv_text   = 'Please transfer the total amount by the due date quoting the invoice number. Thank you for your business.'
      iv_height = 11
      iv_padding = 0 ).

    rv_pdf = lo_pdf->render_binary( ).
  ENDMETHOD.


  METHOD header.
    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 22 ).
    io_pdf->set_text_color( iv_r = 0 iv_g = 51 iv_b = 102 ).
    io_pdf->cell( iv_text = 'INVOICE' iv_height = 28 ).
    io_pdf->set_text_color( iv_r = 0 iv_g = 0 iv_b = 0 ).

    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 10 ).
    io_pdf->cell( iv_text = 'Elektronik Grosshandel GmbH' iv_height = 14 ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 9 ).
    io_pdf->cell( iv_text = 'Hauptstrasse 1' iv_height = 12 ).
    io_pdf->cell( iv_text = '40213 Duesseldorf' iv_height = 12 ).
    io_pdf->cell( iv_text = 'VAT DE123456789' iv_height = 12 ).
    io_pdf->cell( iv_text = |IBAN { c_iban }| iv_height = 12 ).
    io_pdf->ln( 6 ).
  ENDMETHOD.


  METHOD pair.
    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 9 ).
    io_pdf->cell( iv_text = iv_key iv_width = 90 iv_height = 12 iv_ln = abap_false iv_padding = 0 ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 9 ).
    io_pdf->cell( iv_text = iv_value iv_height = 12 iv_padding = 0 ).
  ENDMETHOD.


  METHOD info_and_partner.
    pair( io_pdf = io_pdf iv_key = 'Invoice no' iv_value = c_number ).
    pair( io_pdf = io_pdf iv_key = 'Date' iv_value = '05.08.2026' ).
    pair( io_pdf = io_pdf iv_key = 'Due date' iv_value = '04.09.2026' ).
    pair( io_pdf = io_pdf iv_key = 'Customer' iv_value = '47110' ).
    pair( io_pdf = io_pdf iv_key = 'Currency' iv_value = 'EUR' ).
    pair( io_pdf = io_pdf iv_key = 'Payment terms' iv_value = '30 days net' ).
    pair( io_pdf = io_pdf iv_key = 'Your PO' iv_value = '4500017832' ).
    io_pdf->ln( 6 ).

    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 9 ).
    io_pdf->cell( iv_text = 'Bill to' iv_height = 12 ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 9 ).
    io_pdf->cell( iv_text = 'Zuern Praezisionstechnik GmbH' iv_height = 11 ).
    io_pdf->cell( iv_text = 'Industriering 8' iv_height = 11 ).
    io_pdf->cell( iv_text = '70565 Stuttgart' iv_height = 11 ).
    io_pdf->cell( iv_text = 'Germany' iv_height = 11 ).
    io_pdf->ln( 10 ).
  ENDMETHOD.


  METHOD item_table.
    DATA(lo_table) = zcl_open_abap_pdf_table=>create( io_pdf ).
    lo_table->set_line_height( 12 ).
    lo_table->set_padding( 3 ).
    lo_table->set_header_style(
      iv_font   = 'Helvetica-Bold'
      iv_size   = 8
      iv_r      = 0
      iv_g      = 51
      iv_b      = 102
      iv_text_r = 255
      iv_text_g = 255
      iv_text_b = 255 ).
    lo_table->set_body_style( iv_font = 'Helvetica' iv_size = 8 ).
    lo_table->set_zebra( ).
    lo_table->set_border( 'LRB' ).
    lo_table->add_column( iv_header = 'Pos' iv_width = 30 iv_align = zcl_open_abap_pdf=>c_align_right ).
    lo_table->add_column( iv_header = 'Material' iv_width = 70 ).
    lo_table->add_column( iv_header = 'Description' ).
    lo_table->add_column( iv_header = 'Qty' iv_width = 35 iv_align = zcl_open_abap_pdf=>c_align_right ).
    lo_table->add_column( iv_header = 'Unit price' iv_width = 60 iv_align = zcl_open_abap_pdf=>c_align_right ).
    lo_table->add_column( iv_header = 'Net value' iv_width = 65 iv_align = zcl_open_abap_pdf=>c_align_right ).

    LOOP AT items( ) INTO DATA(ls_item).
      DATA(lv_line) = CONV ty_amount( ls_item-qty * ls_item-price ).
      rv_net = rv_net + lv_line.

      lo_table->add_row( it_cells = VALUE #(
        ( ls_item-pos )
        ( ls_item-matnr )
        ( ls_item-text )
        ( |{ ls_item-qty }| )
        ( amount( ls_item-price ) )
        ( amount( lv_line ) ) ) ).
    ENDLOOP.

    lo_table->render( ).
  ENDMETHOD.


  METHOD totals.
    DATA(lv_vat) = CONV ty_amount( iv_net * 19 / 100 ).
    DATA(lv_gross) = iv_net + lv_vat.
    DATA(lv_r) = zcl_open_abap_pdf=>c_align_right.

    io_pdf->ln( 8 ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 9 ).
    io_pdf->cell( iv_text = 'Subtotal' iv_width = 380 iv_height = 14 iv_align = lv_r iv_ln = abap_false iv_padding = 0 ).
    io_pdf->cell( iv_text = |{ amount( iv_net ) } EUR| iv_width = 125 iv_height = 14 iv_align = lv_r iv_padding = 0 ).

    io_pdf->cell( iv_text = 'VAT 19%' iv_width = 380 iv_height = 14 iv_align = lv_r iv_ln = abap_false iv_padding = 0 ).
    io_pdf->cell( iv_text = |{ amount( lv_vat ) } EUR| iv_width = 125 iv_height = 14 iv_align = lv_r iv_padding = 0 ).

    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 10 ).
    io_pdf->cell( iv_text = 'Total' iv_width = 380 iv_height = 14 iv_align = lv_r iv_ln = abap_false iv_padding = 0 ).
    io_pdf->cell( iv_text = |{ amount( lv_gross ) } EUR| iv_width = 125 iv_height = 14 iv_align = lv_r iv_padding = 0 ).
  ENDMETHOD.


  METHOD codes.
    DATA(lv_y) = CONV f( 560 ).

    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 8 ).
    io_pdf->set_xy( iv_x = c_left iv_y = lv_y - 14 ).
    io_pdf->cell( iv_text = 'Scan to pay' iv_height = 11 iv_padding = 0 ).

    " A SEPA payment QR that banking apps read, only a text with line breaks
    DATA(lv_payload) = |BCD\n002\n1\nSCT\nCOBADEFFXXX\nElektronik Grosshandel GmbH\n| &&
                       |{ c_iban }\nEUR{ plain( iv_gross ) }\n\n\n{ c_number }|.
    io_pdf->qrcode( iv_x = c_left iv_y = lv_y iv_text = lv_payload iv_size = 72 ).

    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 8 ).
    io_pdf->set_xy( iv_x = 150 iv_y = lv_y - 14 ).
    io_pdf->cell( iv_text = 'Reference' iv_height = 11 iv_padding = 0 ).
    io_pdf->barcode_128( iv_x = 150 iv_y = lv_y + 4 iv_text = c_number iv_height = 28 iv_module = '0.9' ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 7 ).
    io_pdf->set_xy( iv_x = 150 iv_y = lv_y + 44 ).
    io_pdf->cell( iv_text = c_number iv_height = 10 iv_padding = 0 ).
  ENDMETHOD.


  METHOD items.
    rt_items = VALUE #(
      ( pos = '10' matnr = 'PROC-MD1'   text = 'Processor unit MD1'        qty = 40  price = '150.00' )
      ( pos = '20' matnr = 'CBL-SH120'  text = 'Cable set, shielded'       qty = 120 price = '28.50' )
      ( pos = '30' matnr = 'PSU-24V25'  text = 'Power supply 24V, 25W'     qty = 25  price = '75.00' )
      ( pos = '40' matnr = 'SENS-S7'    text = 'Sensor module S7'          qty = 60  price = '90.00' )
      ( pos = '50' matnr = 'HSG-ALU200' text = 'Housing aluminium'         qty = 200 price = '13.00' )
      ( pos = '60' matnr = 'SRV-ASM30'  text = 'Assembly service, 30h'     qty = 1   price = '2250.00' )
      ( pos = '70' matnr = 'DSP-7IN'    text = 'Display unit 7 inch'       qty = 15  price = '199.00' )
      ( pos = '80' matnr = 'EXT-WARR'   text = 'Extended warranty, annual' qty = 1   price = '990.00' ) ).
  ENDMETHOD.


  METHOD amount.
    DATA lv_int TYPE string.
    DATA lv_dec TYPE string.
    DATA lv_group TYPE string.
    DATA lv_offset TYPE i.

    SPLIT |{ iv_value DECIMALS = 2 }| AT '.' INTO lv_int lv_dec.

    WHILE strlen( lv_int ) > 3.
      lv_offset = strlen( lv_int ) - 3.
      lv_group = |,{ lv_int+lv_offset(3) }{ lv_group }|.
      lv_int = lv_int(lv_offset).
    ENDWHILE.

    rv_text = |{ lv_int }{ lv_group }.{ lv_dec }|.
  ENDMETHOD.


  METHOD plain.
    rv_text = |{ iv_value DECIMALS = 2 }|.
    CONDENSE rv_text NO-GAPS.
  ENDMETHOD.

ENDCLASS.
