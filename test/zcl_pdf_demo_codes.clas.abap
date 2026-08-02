CLASS zcl_pdf_demo_codes DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    CLASS-METHODS run_base64
      RETURNING VALUE(rv_base64) TYPE string
      RAISING   zcx_open_abap_pdf.

  PRIVATE SECTION.
    CONSTANTS c_left TYPE f VALUE 45.

    CLASS-METHODS caption
      IMPORTING io_pdf  TYPE REF TO zcl_open_abap_pdf
                iv_x    TYPE f
                iv_y    TYPE f
                iv_text TYPE string.
ENDCLASS.

CLASS zcl_pdf_demo_codes IMPLEMENTATION.

  METHOD caption.
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 8 ).
    io_pdf->set_xy( iv_x = iv_x iv_y = iv_y ).
    io_pdf->cell( iv_text = iv_text iv_width = 260 iv_height = 12 ).
  ENDMETHOD.

  METHOD run_base64.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->set_margins( iv_left = c_left iv_top = 45 iv_right = c_left iv_bottom = 45 ).
    lo_pdf->add_page( ).

    lo_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 16 ).
    lo_pdf->cell( iv_text = 'Barcodes, QR codes and justified text' iv_height = 26 ).

    " Justified text
    lo_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 10 ).
    lo_pdf->cell( iv_text = 'Justified' iv_height = 16 ).
    lo_pdf->set_font( iv_name = 'Helvetica' iv_size = 9 ).
    lo_pdf->multi_cell(
      iv_text   = `Justified text distributes the remaining space of a line over the gaps ` &&
                  `between the words, which is done with a TJ array so that it also works ` &&
                  `for embedded fonts, where the word spacing operator has no effect. The ` &&
                  `last line of a block keeps its natural word gaps.`
      iv_width  = 240
      iv_height = 12
      iv_align  = zcl_open_abap_pdf=>c_align_justify
      iv_border = '1' ).

    " Code 128
    caption(
      io_pdf  = lo_pdf
      iv_x    = 310
      iv_y    = 90
      iv_text = 'Code 128 B, delivery note number' ).
    lo_pdf->barcode_128(
      iv_x      = 310
      iv_y      = 104
      iv_text   = '80001234-2026'
      iv_height = 34
      iv_module = '0.9' ).
    caption(
      io_pdf  = lo_pdf
      iv_x    = 310
      iv_y    = 140
      iv_text = '80001234-2026' ).

    caption(
      io_pdf  = lo_pdf
      iv_x    = 310
      iv_y    = 164
      iv_text = 'Code 128 B, handling unit' ).
    lo_pdf->barcode_128(
      iv_x      = 310
      iv_y      = 178
      iv_text   = 'HU/0009988776/P1'
      iv_height = 30
      iv_module = '0.75' ).

    " QR codes of different sizes and contents
    caption(
      io_pdf  = lo_pdf
      iv_x    = c_left
      iv_y    = 250
      iv_text = 'QR, material and batch' ).
    lo_pdf->qrcode(
      iv_x    = c_left
      iv_y    = 264
      iv_text = 'M-100123|BATCH-4711|PLANT-1000'
      iv_size = 90 ).

    caption(
      io_pdf  = lo_pdf
      iv_x    = 170
      iv_y    = 250
      iv_text = 'QR, EPC payment data' ).
    lo_pdf->qrcode(
      iv_x    = 170
      iv_y    = 264
      iv_text = |BCD\n002\n1\nSCT\nCOBADEFFXXX\nElektronik Grosshandel GmbH\n| &&
                |DE89370400440532013000\nEUR78968.40\n\n\nInvoice 0080004711|
      iv_size = 110 ).

    caption(
      io_pdf  = lo_pdf
      iv_x    = 320
      iv_y    = 250
      iv_text = 'QR, link to the document in the system' ).
    lo_pdf->qrcode(
      iv_x    = 320
      iv_y    = 264
      iv_text = 'https://s4.example.com/sap/bc/ui2/flp#Invoice-display?id=0080004711'
      iv_size = 110 ).

    " A larger payload, which needs a higher version
    caption(
      io_pdf  = lo_pdf
      iv_x    = c_left
      iv_y    = 400
      iv_text = 'QR, 200 characters, higher version and more alignment patterns' ).
    lo_pdf->qrcode(
      iv_x    = c_left
      iv_y    = 414
      iv_text = |Order 0080004711 confirmed on 02.08.2026 for Sklep Komputerowy, | &&
                |4 groups, 36 items, net 66360.00 EUR, gross 78968.40 EUR, | &&
                |delivery DAP Wroclaw, payment 14 days 2 percent, contact Anna Weber|
      iv_size = 130 ).

    rv_base64 = cl_http_utility=>encode_x_base64( lo_pdf->render_binary( ) ).
  ENDMETHOD.

ENDCLASS.
