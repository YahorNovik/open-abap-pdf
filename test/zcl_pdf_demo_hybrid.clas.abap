CLASS zcl_pdf_demo_hybrid DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    "! Hybrid electronic invoice: a readable PDF/A-3 with the invoice XML attached,
    "! which is how ZUGFeRD and Factur-X work, plus the round trip of a filled form.
    CLASS-METHODS run_base64
      IMPORTING iv_ttf           TYPE xstring
      RETURNING VALUE(rv_base64) TYPE string
      RAISING   zcx_open_abap_pdf.

    "! Fill a form, render it, read the values back out of the bytes
    CLASS-METHODS round_trip
      RETURNING VALUE(rv_report) TYPE string
      RAISING   zcx_open_abap_pdf.

  PRIVATE SECTION.
    CONSTANTS c_font TYPE string VALUE 'InvoiceSans'.

    CLASS-METHODS invoice_xml
      RETURNING VALUE(rv_xml) TYPE string.
ENDCLASS.

CLASS zcl_pdf_demo_hybrid IMPLEMENTATION.

  METHOD invoice_xml.
    " Shortened Cross Industry Invoice, enough to show the mechanism
    rv_xml =
      |<?xml version="1.0" encoding="UTF-8"?>\n| &&
      |<rsm:CrossIndustryInvoice xmlns:rsm="urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100">\n| &&
      |  <rsm:ExchangedDocument>\n| &&
      |    <ram:ID>90001234</ram:ID>\n| &&
      |    <ram:IssueDateTime>20260802</ram:IssueDateTime>\n| &&
      |  </rsm:ExchangedDocument>\n| &&
      |  <rsm:SupplyChainTradeTransaction>\n| &&
      |    <ram:ApplicableHeaderTradeSettlement>\n| &&
      |      <ram:InvoiceCurrencyCode>EUR</ram:InvoiceCurrencyCode>\n| &&
      |      <ram:GrandTotalAmount>1785.00</ram:GrandTotalAmount>\n| &&
      |    </ram:ApplicableHeaderTradeSettlement>\n| &&
      |  </rsm:SupplyChainTradeTransaction>\n| &&
      |</rsm:CrossIndustryInvoice>|.
  ENDMETHOD.

  METHOD run_base64.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->register_font( iv_name = c_font iv_data = iv_ttf ).
    lo_pdf->set_pdfa(
      iv_icc    = zcl_pdf_test_icc=>srgb( )
      iv_title  = 'Invoice 90001234'
      iv_author = 'Elektronik Grosshandel GmbH'
      iv_part   = 3 ).
    lo_pdf->attach_file(
      iv_name     = 'factur-x.xml'
      iv_data     = cl_abap_codepage=>convert_to( invoice_xml( ) )
      iv_mime     = 'text/xml'
      iv_relation = 'Alternative'
      iv_text     = 'Invoice data in Factur-X format' ).
    lo_pdf->set_compression( ).
    lo_pdf->set_margins( iv_left = 45 iv_top = 45 iv_right = 45 iv_bottom = 45 ).
    lo_pdf->set_font( iv_name = c_font iv_size = 10 ).
    lo_pdf->add_page( ).

    lo_pdf->set_font( iv_name = c_font iv_size = 15 ).
    lo_pdf->cell( iv_text = 'Invoice 90001234' iv_height = 24 ).

    lo_pdf->set_font( iv_name = c_font iv_size = 9 ).
    lo_pdf->multi_cell(
      iv_text   = `This is a hybrid invoice. The page is what a person reads, the attached ` &&
                  `factur-x.xml carries the same data for the accounting system, and the ` &&
                  `metadata states both the PDF/A-3 conformance and the invoice profile.`
      iv_align  = zcl_open_abap_pdf=>c_align_justify
      iv_height = 12 ).
    lo_pdf->ln( 12 ).

    DATA(lo_table) = zcl_open_abap_pdf_table=>create( lo_pdf ).
    lo_table->set_line_height( 13 ).
    lo_table->set_body_style( iv_font = c_font iv_size = 9 ).
    lo_table->set_header_style(
      iv_font   = c_font
      iv_size   = 9
      iv_r      = 0
      iv_g      = 51
      iv_b      = 102
      iv_text_r = 255
      iv_text_g = 255
      iv_text_b = 255 ).
    lo_table->add_column( iv_header = 'Pos' iv_width = 34 iv_align = zcl_open_abap_pdf=>c_align_right ).
    lo_table->add_column( iv_header = 'Description' ).
    lo_table->add_column( iv_header = 'Value' iv_width = 90 iv_align = zcl_open_abap_pdf=>c_align_right ).
    lo_table->add_row( VALUE #( ( '10' ) ( 'Processor unit MD1, 10 pieces' ) ( '1.500,00 EUR' ) ) ).
    lo_table->add_row( VALUE #( ( '20' ) ( 'Cable set, shielded, 5 pieces' ) ( '285,00 EUR' ) ) ).
    lo_table->add_row(
      it_cells = VALUE #( ( '' ) ( 'Grand total' ) ( '1.785,00 EUR' ) )
      iv_bold  = abap_true ).
    lo_table->render( ).

    lo_pdf->ln( 16 ).
    lo_pdf->set_font( iv_name = c_font iv_size = 9 ).
    lo_pdf->cell( iv_text = 'Scan to pay' iv_height = 14 ).
    lo_pdf->qrcode(
      iv_x    = 45
      iv_y    = lo_pdf->get_y( )
      iv_text = |BCD\n002\n1\nSCT\nCOBADEFFXXX\nElektronik Grosshandel GmbH\n| &&
                |DE89370400440532013000\nEUR1785.00\n\n\nInvoice 90001234|
      iv_size = 90 ).

    rv_base64 = cl_http_utility=>encode_x_base64( lo_pdf->render_pdfa( ) ).
  ENDMETHOD.

  METHOD round_trip.
    DATA ls_field TYPE zcl_open_abap_pdf_reader=>ty_field.

    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->add_page( ).
    lo_pdf->set_font( iv_name = 'Helvetica' iv_size = 10 ).
    lo_pdf->text_field(
      iv_name  = 'EMPLOYEE'
      iv_x     = 150
      iv_y     = 60
      iv_width = 200
      iv_value = 'Anna Weber' ).
    lo_pdf->text_field(
      iv_name  = 'COST_CENTER'
      iv_x     = 150
      iv_y     = 90
      iv_width = 120
      iv_value = '1000-4711' ).
    lo_pdf->dropdown(
      iv_name    = 'TRIP_TYPE'
      it_options = VALUE #( ( 'Domestic' ) ( 'International' ) )
      iv_x       = 150
      iv_y       = 120
      iv_width   = 160
      iv_value   = 'International' ).
    lo_pdf->checkbox( iv_name = 'ADVANCE' iv_x = 150 iv_y = 150 iv_checked = abap_true ).
    lo_pdf->radio_button(
      iv_name     = 'LEVEL'
      iv_value    = 'Manager'
      iv_x        = 150
      iv_y        = 180
      iv_selected = abap_true ).

    DATA(lv_bytes) = lo_pdf->render_binary( ).

    rv_report = |pages { zcl_open_abap_pdf_reader=>page_count( lv_bytes ) }|.
    LOOP AT zcl_open_abap_pdf_reader=>read_fields( lv_bytes ) INTO ls_field.
      rv_report = |{ rv_report }; { ls_field-name }={ ls_field-value }|.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
