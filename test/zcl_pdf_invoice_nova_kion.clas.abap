CLASS zcl_pdf_invoice_nova_kion DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    "! A service invoice from Nova to KION, all data hard coded, so the whole
    "! document is one self contained ABAP class. Render it outside SAP with
    "!   node test/render.mjs ZCL_PDF_INVOICE_NOVA_KION run_base64 invoice.pdf
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
        code  TYPE string,
        text  TYPE string,
        qty   TYPE p LENGTH 5 DECIMALS 2,
        unit  TYPE string,
        price TYPE ty_amount,
      END OF ty_item,
      ty_items TYPE STANDARD TABLE OF ty_item WITH DEFAULT KEY.

    CONSTANTS c_left TYPE f VALUE 45.
    CONSTANTS c_number TYPE string VALUE 'NOVA-2026-0087'.
    CONSTANTS c_iban TYPE string VALUE 'DE21100110012620773955'.
    CONSTANTS c_bic TYPE string VALUE 'NTSBDEB1XXX'.
    CONSTANTS c_vat_rate TYPE i VALUE 19.

    CLASS-METHODS items
      RETURNING VALUE(rt_items) TYPE ty_items.

    CLASS-METHODS masthead
      IMPORTING io_pdf TYPE REF TO zcl_open_abap_pdf.

    CLASS-METHODS parties
      IMPORTING io_pdf TYPE REF TO zcl_open_abap_pdf.

    CLASS-METHODS meta
      IMPORTING io_pdf TYPE REF TO zcl_open_abap_pdf.

    CLASS-METHODS item_table
      IMPORTING io_pdf        TYPE REF TO zcl_open_abap_pdf
      RETURNING VALUE(rv_net) TYPE ty_amount.

    CLASS-METHODS totals
      IMPORTING io_pdf          TYPE REF TO zcl_open_abap_pdf
                iv_net          TYPE ty_amount
      RETURNING VALUE(rv_gross) TYPE ty_amount.

    CLASS-METHODS payment_block
      IMPORTING io_pdf   TYPE REF TO zcl_open_abap_pdf
                iv_gross TYPE ty_amount
      RAISING   zcx_open_abap_pdf.

    CLASS-METHODS footer
      IMPORTING io_pdf TYPE REF TO zcl_open_abap_pdf.

    "! Thousands grouped with a dot, a comma as the decimal mark, German style
    CLASS-METHODS amount
      IMPORTING iv_value       TYPE ty_amount
      RETURNING VALUE(rv_text) TYPE string.

    "! Quantity without trailing decimals when it is a whole number
    CLASS-METHODS quantity
      IMPORTING iv_value       TYPE p
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


CLASS zcl_pdf_invoice_nova_kion IMPLEMENTATION.

  METHOD run_base64.
    rv_base64 = cl_http_utility=>encode_x_base64( run_binary( ) ).
  ENDMETHOD.


  METHOD run_binary.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->set_compression( ).
    lo_pdf->set_margins( iv_left = c_left iv_top = 42 iv_right = c_left iv_bottom = 42 ).
    lo_pdf->add_page( ).

    masthead( lo_pdf ).
    parties( lo_pdf ).
    meta( lo_pdf ).
    DATA(lv_net) = item_table( lo_pdf ).
    DATA(lv_gross) = totals( io_pdf = lo_pdf iv_net = lv_net ).
    payment_block( io_pdf = lo_pdf iv_gross = lv_gross ).
    footer( lo_pdf ).

    rv_pdf = lo_pdf->render_binary( ).
  ENDMETHOD.


  METHOD masthead.
    " Wordmark drawn as text, and a rule in the corporate colour underneath
    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 24 ).
    io_pdf->set_text_color( iv_r = 20 iv_g = 110 iv_b = 200 ).
    io_pdf->cell( iv_text = 'NOVA' iv_width = 120 iv_height = 26 iv_ln = abap_false iv_padding = 0 ).

    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 20 ).
    io_pdf->set_text_color( iv_r = 60 iv_g = 60 iv_b = 60 ).
    io_pdf->cell(
      iv_text   = 'Invoice'
      iv_height = 26
      iv_align  = zcl_open_abap_pdf=>c_align_right
      iv_padding = 0 ).

    io_pdf->set_draw_color( iv_r = 20 iv_g = 110 iv_b = 200 ).
    io_pdf->set_line_width( 2 ).
    io_pdf->line(
      iv_x1 = c_left
      iv_y1 = 74
      iv_x2 = io_pdf->get_page_width( ) - c_left
      iv_y2 = 74 ).
    io_pdf->set_text_color( iv_r = 0 iv_g = 0 iv_b = 0 ).
    io_pdf->set_xy( iv_x = c_left iv_y = 84 ).
  ENDMETHOD.


  METHOD parties.
    " Seller on the left, buyer on the right, both in an address block
    DATA(lv_top) = CONV f( 90 ).

    io_pdf->set_xy( iv_x = c_left iv_y = lv_top ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 7 ).
    io_pdf->set_text_color( iv_r = 130 iv_g = 130 iv_b = 130 ).
    io_pdf->cell( iv_text = 'From' iv_height = 10 iv_padding = 0 ).
    io_pdf->set_text_color( iv_r = 0 iv_g = 0 iv_b = 0 ).

    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 10 ).
    io_pdf->set_x( c_left ).
    io_pdf->cell( iv_text = 'Nova Software GmbH' iv_height = 13 iv_padding = 0 ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 9 ).
    io_pdf->set_x( c_left ).
    io_pdf->cell( iv_text = 'Rosenheimer Strasse 143' iv_height = 12 iv_padding = 0 ).
    io_pdf->set_x( c_left ).
    io_pdf->cell( iv_text = '81671 Munich, Germany' iv_height = 12 iv_padding = 0 ).
    io_pdf->set_x( c_left ).
    io_pdf->cell( iv_text = 'VAT DE311882048' iv_height = 12 iv_padding = 0 ).
    io_pdf->set_x( c_left ).
    io_pdf->cell( iv_text = 'billing@novasoftware.example' iv_height = 12 iv_padding = 0 ).

    DATA(lv_x) = CONV f( 320 ).
    io_pdf->set_xy( iv_x = lv_x iv_y = lv_top ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 7 ).
    io_pdf->set_text_color( iv_r = 130 iv_g = 130 iv_b = 130 ).
    io_pdf->cell( iv_text = 'Bill to' iv_height = 10 iv_padding = 0 ).
    io_pdf->set_text_color( iv_r = 0 iv_g = 0 iv_b = 0 ).

    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 10 ).
    io_pdf->set_x( lv_x ).
    io_pdf->cell( iv_text = 'KION Group AG' iv_height = 13 iv_padding = 0 ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 9 ).
    io_pdf->set_x( lv_x ).
    io_pdf->cell( iv_text = 'Thea-Rasche-Strasse 8' iv_height = 12 iv_padding = 0 ).
    io_pdf->set_x( lv_x ).
    io_pdf->cell( iv_text = '60549 Frankfurt am Main, Germany' iv_height = 12 iv_padding = 0 ).
    io_pdf->set_x( lv_x ).
    io_pdf->cell( iv_text = 'VAT DE264265444' iv_height = 12 iv_padding = 0 ).
    io_pdf->set_x( lv_x ).
    io_pdf->cell( iv_text = 'Accounts payable' iv_height = 12 iv_padding = 0 ).
  ENDMETHOD.


  METHOD pair.
    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 9 ).
    io_pdf->cell( iv_text = iv_key iv_width = 110 iv_height = 13 iv_ln = abap_false iv_padding = 0 ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 9 ).
    io_pdf->cell( iv_text = iv_value iv_height = 13 iv_padding = 0 ).
  ENDMETHOD.


  METHOD meta.
    io_pdf->set_xy( iv_x = c_left iv_y = 176 ).
    pair( io_pdf = io_pdf iv_key = 'Invoice number' iv_value = c_number ).
    pair( io_pdf = io_pdf iv_key = 'Invoice date' iv_value = '05 August 2026' ).
    pair( io_pdf = io_pdf iv_key = 'Service period' iv_value = 'July 2026' ).
    pair( io_pdf = io_pdf iv_key = 'Customer number' iv_value = 'KION-10030' ).
    pair( io_pdf = io_pdf iv_key = 'Your PO' iv_value = '4500098213' ).
    pair( io_pdf = io_pdf iv_key = 'Payment terms' iv_value = '30 days net' ).
    pair( io_pdf = io_pdf iv_key = 'Due date' iv_value = '04 September 2026' ).
    io_pdf->ln( 12 ).
  ENDMETHOD.


  METHOD item_table.
    DATA(lo_table) = zcl_open_abap_pdf_table=>create( io_pdf ).
    lo_table->set_line_height( 12 ).
    lo_table->set_padding( 3 ).
    lo_table->set_header_style(
      iv_font   = 'Helvetica-Bold'
      iv_size   = 8
      iv_r      = 20
      iv_g      = 110
      iv_b      = 200
      iv_text_r = 255
      iv_text_g = 255
      iv_text_b = 255 ).
    lo_table->set_body_style( iv_font = 'Helvetica' iv_size = 8 ).
    lo_table->set_zebra( iv_r = 238 iv_g = 244 iv_b = 251 ).
    lo_table->set_border( 'LRB' ).
    lo_table->add_column( iv_header = 'Pos' iv_width = 28 iv_align = zcl_open_abap_pdf=>c_align_right ).
    lo_table->add_column( iv_header = 'Code' iv_width = 66 ).
    lo_table->add_column( iv_header = 'Service' ).
    lo_table->add_column( iv_header = 'Qty' iv_width = 42 iv_align = zcl_open_abap_pdf=>c_align_right ).
    lo_table->add_column( iv_header = 'Unit' iv_width = 34 iv_align = zcl_open_abap_pdf=>c_align_center ).
    lo_table->add_column( iv_header = 'Rate' iv_width = 60 iv_align = zcl_open_abap_pdf=>c_align_right ).
    lo_table->add_column( iv_header = 'Amount' iv_width = 66 iv_align = zcl_open_abap_pdf=>c_align_right ).

    LOOP AT items( ) INTO DATA(ls_item).
      DATA(lv_line) = CONV ty_amount( ls_item-qty * ls_item-price ).
      rv_net = rv_net + lv_line.

      lo_table->add_row( it_cells = VALUE #(
        ( ls_item-pos )
        ( ls_item-code )
        ( ls_item-text )
        ( quantity( ls_item-qty ) )
        ( ls_item-unit )
        ( amount( ls_item-price ) )
        ( amount( lv_line ) ) ) ).
    ENDLOOP.

    lo_table->render( ).
  ENDMETHOD.


  METHOD totals.
    DATA(lv_vat) = CONV ty_amount( iv_net * c_vat_rate / 100 ).
    rv_gross = iv_net + lv_vat.
    DATA(lv_r) = zcl_open_abap_pdf=>c_align_right.

    io_pdf->ln( 8 ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 9 ).
    io_pdf->cell( iv_text = 'Net amount' iv_width = 384 iv_height = 14 iv_align = lv_r iv_ln = abap_false iv_padding = 0 ).
    io_pdf->cell( iv_text = |{ amount( iv_net ) } EUR| iv_width = 122 iv_height = 14 iv_align = lv_r iv_padding = 0 ).

    io_pdf->cell( iv_text = |VAT { c_vat_rate }%| iv_width = 384 iv_height = 14 iv_align = lv_r iv_ln = abap_false iv_padding = 0 ).
    io_pdf->cell( iv_text = |{ amount( lv_vat ) } EUR| iv_width = 122 iv_height = 14 iv_align = lv_r iv_padding = 0 ).

    " A filled bar behind the grand total
    DATA(lv_y) = io_pdf->get_y( ).
    io_pdf->set_fill_color( iv_r = 20 iv_g = 110 iv_b = 200 ).
    io_pdf->rect( iv_x = 320 iv_y = lv_y iv_width = 230 iv_height = 18 iv_style = 'F' ).
    io_pdf->set_text_color( iv_r = 255 iv_g = 255 iv_b = 255 ).
    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 11 ).
    io_pdf->set_xy( iv_x = 326 iv_y = lv_y + 3 ).
    io_pdf->cell( iv_text = 'Total due' iv_width = 120 iv_height = 13 iv_ln = abap_false iv_padding = 0 ).
    io_pdf->cell( iv_text = |{ amount( rv_gross ) } EUR| iv_width = 98 iv_height = 13 iv_align = lv_r iv_padding = 0 ).
    io_pdf->set_text_color( iv_r = 0 iv_g = 0 iv_b = 0 ).
    io_pdf->set_xy( iv_x = c_left iv_y = lv_y + 30 ).
  ENDMETHOD.


  METHOD payment_block.
    DATA(lv_y) = CONV f( 566 ).

    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 9 ).
    io_pdf->set_xy( iv_x = c_left iv_y = lv_y - 16 ).
    io_pdf->cell( iv_text = 'Payment' iv_height = 12 iv_padding = 0 ).

    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 9 ).
    io_pdf->set_xy( iv_x = c_left iv_y = lv_y ).
    io_pdf->cell( iv_text = |IBAN   { c_iban }| iv_height = 13 iv_padding = 0 ).
    io_pdf->set_x( c_left ).
    io_pdf->cell( iv_text = |BIC    { c_bic }| iv_height = 13 iv_padding = 0 ).
    io_pdf->set_x( c_left ).
    io_pdf->cell( iv_text = |Ref    { c_number }| iv_height = 13 iv_padding = 0 ).

    " A SEPA payment QR that banking apps read, only a text with line breaks
    DATA(lv_payload) = |BCD\n002\n1\nSCT\n{ c_bic }\nNova Software GmbH\n| &&
                       |{ c_iban }\nEUR{ plain( iv_gross ) }\n\n\n{ c_number }|.
    io_pdf->qrcode( iv_x = 320 iv_y = lv_y - 16 iv_text = lv_payload iv_size = 84 ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 7 ).
    io_pdf->set_xy( iv_x = 320 iv_y = lv_y + 70 ).
    io_pdf->cell( iv_text = 'Scan to pay' iv_height = 10 iv_padding = 0 ).
  ENDMETHOD.


  METHOD footer.
    io_pdf->set_draw_color( iv_r = 200 iv_g = 200 iv_b = 200 ).
    io_pdf->set_line_width( '0.5' ).
    io_pdf->line( iv_x1 = c_left iv_y1 = 760 iv_x2 = io_pdf->get_page_width( ) - c_left iv_y2 = 760 ).

    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 8 ).
    io_pdf->set_text_color( iv_r = 110 iv_g = 110 iv_b = 110 ).
    io_pdf->set_xy( iv_x = c_left iv_y = 766 ).
    io_pdf->cell(
      iv_text   = 'Please pay the total due by the due date quoting the invoice reference. Thank you for working with Nova.'
      iv_height = 11
      iv_padding = 0 ).
    io_pdf->set_x( c_left ).
    io_pdf->cell(
      iv_text   = 'Nova Software GmbH   Amtsgericht Muenchen HRB 245011   Managing Director: A. Novak   VAT DE311882048'
      iv_height = 11
      iv_padding = 0 ).
    io_pdf->set_text_color( iv_r = 0 iv_g = 0 iv_b = 0 ).
  ENDMETHOD.


  METHOD items.
    rt_items = VALUE #(
      ( pos = '10' code = 'PDF-LIB-ENT'  text = 'open-abap-pdf enterprise licence, annual'
        qty = 1 unit = 'EA' price = '18000.00' )
      ( pos = '20' code = 'IMPL-PO'      text = 'Purchase order output, ADS replacement, fixed price'
        qty = 1 unit = 'EA' price = '24500.00' )
      ( pos = '30' code = 'CONS-SR'      text = 'Senior consulting, layout and integration'
        qty = 12 unit = 'DAY' price = '1250.00' )
      ( pos = '40' code = 'CONS-DEV'     text = 'Development, forms and unit tests'
        qty = 18 unit = 'DAY' price = '980.00' )
      ( pos = '50' code = 'TRAIN-ABAP'   text = 'Workshop, generating PDF in ABAP, on site'
        qty = 3 unit = 'DAY' price = '1450.00' )
      ( pos = '60' code = 'SUP-GOLD'     text = 'Gold support, 12 months'
        qty = 1 unit = 'EA' price = '9600.00' ) ).
  ENDMETHOD.


  METHOD amount.
    DATA lv_int TYPE string.
    DATA lv_dec TYPE string.
    DATA lv_group TYPE string.
    DATA lv_offset TYPE i.

    SPLIT |{ iv_value DECIMALS = 2 }| AT '.' INTO lv_int lv_dec.

    WHILE strlen( lv_int ) > 3.
      lv_offset = strlen( lv_int ) - 3.
      lv_group = |.{ lv_int+lv_offset(3) }{ lv_group }|.
      lv_int = lv_int(lv_offset).
    ENDWHILE.

    rv_text = |{ lv_int }{ lv_group },{ lv_dec }|.
  ENDMETHOD.


  METHOD quantity.
    rv_text = |{ iv_value DECIMALS = 2 }|.
    CONDENSE rv_text NO-GAPS.
    " Drop the two decimals when the quantity is whole
    IF rv_text CP '*.00'.
      rv_text = substring( val = rv_text len = strlen( rv_text ) - 3 ).
    ENDIF.
  ENDMETHOD.


  METHOD plain.
    rv_text = |{ iv_value DECIMALS = 2 }|.
    CONDENSE rv_text NO-GAPS.
  ENDMETHOD.

ENDCLASS.
