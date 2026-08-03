CLASS zcl_pdf_demo_po DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    "! Replica of an intercompany purchase order, drawn with absolute coordinates
    "! the way a print form does it. Uses Base-14 fonts only, so it needs no font file.
    CLASS-METHODS run_base64
      RETURNING VALUE(rv_base64) TYPE string
      RAISING   zcx_open_abap_pdf.

  PRIVATE SECTION.
    CONSTANTS c_left TYPE f VALUE 44.
    CONSTANTS c_right_col TYPE f VALUE 345.
    CONSTANTS c_right_val TYPE f VALUE 415.
    CONSTANTS c_right TYPE f VALUE 558.
    CONSTANTS c_font TYPE string VALUE 'Helvetica'.
    CONSTANTS c_bold TYPE string VALUE 'Helvetica-Bold'.

    CLASS-METHODS logo
      IMPORTING io_pdf TYPE REF TO zcl_open_abap_pdf.

    CLASS-METHODS sender
      IMPORTING io_pdf TYPE REF TO zcl_open_abap_pdf.

    CLASS-METHODS supplier_box
      IMPORTING io_pdf TYPE REF TO zcl_open_abap_pdf.

    CLASS-METHODS ship_and_invoice
      IMPORTING io_pdf TYPE REF TO zcl_open_abap_pdf.

    CLASS-METHODS document_block
      IMPORTING io_pdf TYPE REF TO zcl_open_abap_pdf.

    CLASS-METHODS conditions
      IMPORTING io_pdf TYPE REF TO zcl_open_abap_pdf.

    CLASS-METHODS item_table
      IMPORTING io_pdf TYPE REF TO zcl_open_abap_pdf.

    CLASS-METHODS footer_block
      IMPORTING io_pdf TYPE REF TO zcl_open_abap_pdf.

    "! Grey bar with a black frame and a bold caption, as used for Supplier or Ship-To
    CLASS-METHODS caption_bar
      IMPORTING io_pdf   TYPE REF TO zcl_open_abap_pdf
                iv_y     TYPE f
                iv_text  TYPE string
                iv_width TYPE f DEFAULT 231.

    "! Bold label on the left, plain value at a fixed column
    CLASS-METHODS label_value
      IMPORTING io_pdf   TYPE REF TO zcl_open_abap_pdf
                iv_x     TYPE f
                iv_y     TYPE f
                iv_label TYPE string
                iv_value TYPE string
                iv_val_x TYPE f
                iv_bold  TYPE abap_bool DEFAULT abap_true
                iv_size  TYPE f DEFAULT 8.

    "! Text with a rule underneath, for the mandatory heading and the link
    CLASS-METHODS underlined
      IMPORTING io_pdf  TYPE REF TO zcl_open_abap_pdf
                iv_x    TYPE f
                iv_y    TYPE f
                iv_text TYPE string
                iv_font TYPE string
                iv_size TYPE f.

    "! Bold key directly followed by the value, as the bank block prints it
    CLASS-METHODS bank_line
      IMPORTING io_pdf   TYPE REF TO zcl_open_abap_pdf
                iv_y     TYPE f
                iv_label TYPE string
                iv_value TYPE string.

    CLASS-METHODS lines_at
      IMPORTING io_pdf   TYPE REF TO zcl_open_abap_pdf
                iv_x     TYPE f
                iv_y     TYPE f
                iv_step  TYPE f
                iv_size  TYPE f
                iv_font  TYPE string DEFAULT 'Helvetica'
                it_lines TYPE string_table.
ENDCLASS.


CLASS zcl_pdf_demo_po IMPLEMENTATION.

  METHOD run_base64.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->set_compression( ).
    lo_pdf->set_margins( iv_left = c_left iv_top = 30 iv_right = 37 iv_bottom = 30 ).
    lo_pdf->set_auto_page_break( iv_active = abap_false ).
    lo_pdf->add_page( ).

    lo_pdf->set_font( iv_name = c_bold iv_size = 15 ).
    lo_pdf->set_xy( iv_x = c_left iv_y = 30 ).
    lo_pdf->cell( iv_text = 'InterCompanySales PO' iv_height = 20 iv_padding = 0 ).

    logo( lo_pdf ).
    sender( lo_pdf ).
    supplier_box( lo_pdf ).
    ship_and_invoice( lo_pdf ).
    document_block( lo_pdf ).
    conditions( lo_pdf ).
    item_table( lo_pdf ).
    footer_block( lo_pdf ).

    rv_base64 = cl_http_utility=>encode_x_base64( lo_pdf->render_binary( ) ).
  ENDMETHOD.


  METHOD logo.
    " The wordmark is drawn from rectangles, the way the squared letters are built,
    " and the slanted mark above is filled with thin columns
    DATA(lv_x) = CONV f( 478 ).
    DATA(lv_y) = CONV f( 52 ).
    DATA(lv_h) = CONV f( 26 ).
    DATA(lv_w) = CONV f( 5 ).

    io_pdf->set_fill_color( iv_r = 0 iv_g = 0 iv_b = 0 ).

    " S as five bars
    io_pdf->rect( iv_x = lv_x iv_y = lv_y iv_width = 20 iv_height = lv_w iv_style = 'F' ).
    io_pdf->rect( iv_x = lv_x iv_y = lv_y iv_width = lv_w iv_height = 12 iv_style = 'F' ).
    io_pdf->rect( iv_x = lv_x iv_y = lv_y + 11 iv_width = 20 iv_height = lv_w iv_style = 'F' ).
    io_pdf->rect( iv_x = lv_x + 15 iv_y = lv_y + 11 iv_width = lv_w iv_height = 15 iv_style = 'F' ).
    io_pdf->rect( iv_x = lv_x iv_y = lv_y + 21 iv_width = 20 iv_height = lv_w iv_style = 'F' ).

    " T
    io_pdf->rect( iv_x = lv_x + 23 iv_y = lv_y iv_width = 20 iv_height = lv_w iv_style = 'F' ).
    io_pdf->rect( iv_x = lv_x + 30 iv_y = lv_y iv_width = lv_w iv_height = lv_h iv_style = 'F' ).

    " I
    io_pdf->rect( iv_x = lv_x + 46 iv_y = lv_y iv_width = lv_w iv_height = lv_h iv_style = 'F' ).

    " L L
    io_pdf->rect( iv_x = lv_x + 54 iv_y = lv_y iv_width = lv_w iv_height = lv_h iv_style = 'F' ).
    io_pdf->rect( iv_x = lv_x + 54 iv_y = lv_y + 21 iv_width = 18 iv_height = lv_w iv_style = 'F' ).
    io_pdf->rect( iv_x = lv_x + 75 iv_y = lv_y iv_width = lv_w iv_height = lv_h iv_style = 'F' ).
    io_pdf->rect( iv_x = lv_x + 75 iv_y = lv_y + 21 iv_width = 18 iv_height = lv_w iv_style = 'F' ).

    " The orange mark, a parallelogram filled column by column
    io_pdf->set_fill_color( iv_r = 232 iv_g = 119 iv_b = 34 ).
    DATA(lv_step) = CONV f( '0.4' ).
    DATA(lv_i) = 0.
    WHILE lv_i < 233.
      DATA(lv_dx) = lv_i * lv_step.
      io_pdf->rect(
        iv_x      = lv_x + 2 + lv_dx
        iv_y      = lv_y - 8 - lv_dx * '0.13'
        iv_width  = lv_step + '0.3'
        iv_height = 10
        iv_style  = 'F' ).
      lv_i = lv_i + 1.
    ENDWHILE.

    io_pdf->set_fill_color( iv_r = 255 iv_g = 255 iv_b = 255 ).
  ENDMETHOD.


  METHOD sender.
    io_pdf->set_font( iv_name = c_bold iv_size = 8 ).
    io_pdf->set_xy( iv_x = c_left iv_y = 62 ).
    io_pdf->cell( iv_text = 'STILL IT c/o Urban Logistics' iv_height = 10 iv_padding = 0 ).

    lines_at(
      io_pdf   = io_pdf
      iv_x     = c_left
      iv_y     = 71
      iv_step  = 8
      iv_size  = 8
      it_lines = VALUE #(
        ( `STILL S.p.A.` )
        ( `Viale A. de Gasperi 7` )
        ( `20045 Lainate  MI` ) ) ).
  ENDMETHOD.


  METHOD caption_bar.
    io_pdf->set_fill_color( iv_r = 217 iv_g = 217 iv_b = 217 ).
    io_pdf->set_draw_color( iv_r = 0 iv_g = 0 iv_b = 0 ).
    io_pdf->set_line_width( '0.7' ).
    io_pdf->rect( iv_x = c_left iv_y = iv_y iv_width = iv_width iv_height = 13 iv_style = 'DF' ).
    io_pdf->set_fill_color( iv_r = 255 iv_g = 255 iv_b = 255 ).

    io_pdf->set_font( iv_name = c_bold iv_size = '8.5' ).
    io_pdf->set_xy( iv_x = c_left + 4 iv_y = iv_y + 2 ).
    io_pdf->cell( iv_text = iv_text iv_height = 10 iv_padding = 0 ).
  ENDMETHOD.


  METHOD supplier_box.
    caption_bar( io_pdf = io_pdf iv_y = 114 iv_text = 'Supplier' ).

    io_pdf->set_line_width( '0.7' ).
    io_pdf->rect( iv_x = c_left iv_y = 127 iv_width = 231 iv_height = 74 ).

    lines_at(
      io_pdf   = io_pdf
      iv_x     = c_left + 4
      iv_y     = '131.5'
      iv_step  = '7.8'
      iv_size  = 8
      it_lines = VALUE #(
        ( `STILL SPA` )
        ( `VIALE DE GASPERI 7` )
        ( `FACTORY` )
        ( `20020 LAINATE  MI` ) ) ).

    " Two thin separators split the box into address, contact and account
    io_pdf->line( iv_x1 = c_left iv_y1 = 166 iv_x2 = c_left + 231 iv_y2 = 166 ).
    io_pdf->line( iv_x1 = c_left iv_y1 = 189 iv_x2 = c_left + 231 iv_y2 = 189 ).

    io_pdf->set_font( iv_name = c_font iv_size = 8 ).
    io_pdf->set_xy( iv_x = c_left + 4 iv_y = 169 ).
    io_pdf->cell( iv_text = 'Phone:' iv_width = 100 iv_height = 10 iv_padding = 0 iv_ln = abap_false ).
    io_pdf->cell( iv_text = '+39003902937651' iv_height = 10 iv_padding = 0 ).
    io_pdf->set_x( c_left + 4 ).
    io_pdf->cell( iv_text = 'Email:' iv_height = 10 iv_padding = 0 ).

    io_pdf->set_xy( iv_x = c_left + 4 iv_y = 191 ).
    io_pdf->cell( iv_text = 'Vendor Account No.' iv_width = 86 iv_height = 10 iv_padding = 0 iv_ln = abap_false ).
    io_pdf->cell( iv_text = '193' iv_height = 10 iv_padding = 0 ).
  ENDMETHOD.


  METHOD ship_and_invoice.
    caption_bar( io_pdf = io_pdf iv_y = 229 iv_text = 'Ship-To' ).
    io_pdf->rect( iv_x = c_left iv_y = 242 iv_width = 231 iv_height = 33 ).
    lines_at(
      io_pdf   = io_pdf
      iv_x     = c_left + 4
      iv_y     = 245
      iv_step  = '7.6'
      iv_size  = 8
      it_lines = VALUE #(
        ( `Company` )
        ( `Urban Logistica Srl` )
        ( `Via Martin Luther King 1 23` )
        ( `42047 ROLO  RE` ) ) ).

    caption_bar( io_pdf = io_pdf iv_y = 279 iv_text = 'Invoice-To' ).
    io_pdf->rect( iv_x = c_left iv_y = 292 iv_width = 231 iv_height = 35 ).
    lines_at(
      io_pdf   = io_pdf
      iv_x     = c_left + 4
      iv_y     = '293.5'
      iv_step  = '7.7'
      iv_size  = 8
      it_lines = VALUE #(
        ( `Italian invoice: Amministrazione@pec.still.it` )
        ( `SDI Code: N6ATSO2` )
        ( `Foreign invoice: STILL-IT-SAS@pdf.basware.com` )
        ( `Finance Contact: AP.STILL.IT.COE@kiongroup.com` ) ) ).
  ENDMETHOD.


  METHOD document_block.
    " Framed line with the document number and the page count
    io_pdf->set_line_width( '0.7' ).
    io_pdf->rect( iv_x = c_right_col - 3 iv_y = 114 iv_width = c_right - c_right_col + 3 iv_height = 15 ).
    io_pdf->line( iv_x1 = 512 iv_y1 = 114 iv_x2 = 512 iv_y2 = 129 ).
    io_pdf->set_font( iv_name = c_bold iv_size = 10 ).
    io_pdf->set_xy( iv_x = c_right_col iv_y = 117 ).
    io_pdf->cell( iv_text = 'Document No. 7400000049' iv_width = 160 iv_height = 11 iv_padding = 0 iv_ln = abap_false ).
    io_pdf->set_font( iv_name = c_font iv_size = 8 ).
    io_pdf->set_x( 516 ).
    io_pdf->cell(
      iv_text   = 'Page 1 of 1'
      iv_width  = c_right - 520
      iv_height = 11
      iv_align  = zcl_open_abap_pdf=>c_align_right
      iv_padding = 0 ).

    label_value(
      io_pdf   = io_pdf
      iv_x     = c_right_col
      iv_y     = 136
      iv_label = 'Issue Date:'
      iv_value = '09 May 2024'
      iv_val_x = c_right_val ).

    label_value( io_pdf = io_pdf iv_x = c_right_col iv_y = 219 iv_label = 'Buyer:'
                 iv_value = 'Stuart Windsor' iv_val_x = c_right_val ).
    label_value( io_pdf = io_pdf iv_x = c_right_col iv_y = 228 iv_label = 'Phone:'
                 iv_value = '+44 194 285-2122' iv_val_x = c_right_val iv_bold = abap_false ).
    label_value( io_pdf = io_pdf iv_x = c_right_col iv_y = 237 iv_label = 'Email:'
                 iv_value = 'stuart.windsor@linde-mh.co.uk' iv_val_x = c_right_val iv_bold = abap_false ).

    label_value( io_pdf = io_pdf iv_x = c_right_col iv_y = 254 iv_label = 'Payment Terms:'
                 iv_value = 'Intercompany-15th next month' iv_val_x = c_right_val ).

    label_value( io_pdf = io_pdf iv_x = c_right_col iv_y = 271 iv_label = 'Freight Terms:'
                 iv_value = 'FCA' iv_val_x = c_right_val ).
    label_value( io_pdf = io_pdf iv_x = c_right_col iv_y = 280 iv_label = 'Incoterms:'
                 iv_value = 'LAINATE' iv_val_x = c_right_val ).
    label_value( io_pdf = io_pdf iv_x = c_right_col iv_y = 289 iv_label = 'Currency:'
                 iv_value = 'EUR' iv_val_x = c_right_val ).

    label_value( io_pdf = io_pdf iv_x = c_right_col iv_y = 306 iv_label = 'Legacy ref. No.'
                 iv_value = '' iv_val_x = c_right_val ).
    label_value( io_pdf = io_pdf iv_x = c_right_col iv_y = 315 iv_label = 'VAT No.'
                 iv_value = 'IT11543160151' iv_val_x = c_right_val ).
    label_value( io_pdf = io_pdf iv_x = c_right_col iv_y = 324 iv_label = 'Customer Order:'
                 iv_value = '1600000347' iv_val_x = c_right_val ).
  ENDMETHOD.


  METHOD label_value.
    io_pdf->set_font(
      iv_name = COND string( WHEN iv_bold = abap_true THEN c_bold ELSE c_font )
      iv_size = iv_size ).
    io_pdf->set_xy( iv_x = iv_x iv_y = iv_y ).
    io_pdf->cell( iv_text = iv_label iv_width = iv_val_x - iv_x iv_height = 10 iv_padding = 0 iv_ln = abap_false ).

    io_pdf->set_font( iv_name = c_font iv_size = iv_size ).
    io_pdf->cell( iv_text = iv_value iv_height = 10 iv_padding = 0 ).
  ENDMETHOD.


  METHOD bank_line.
    io_pdf->set_font( iv_name = c_bold iv_size = '5.5' ).
    DATA(lv_width) = io_pdf->get_text_width( iv_label ) + 2.
    io_pdf->set_xy( iv_x = 415 iv_y = iv_y ).
    io_pdf->cell( iv_text = iv_label iv_width = lv_width iv_height = 7 iv_padding = 0 iv_ln = abap_false ).

    io_pdf->set_font( iv_name = c_font iv_size = '5.5' ).
    io_pdf->cell( iv_text = iv_value iv_height = 7 iv_padding = 0 ).
  ENDMETHOD.


  METHOD lines_at.
    DATA(lv_y) = iv_y.
    io_pdf->set_font( iv_name = iv_font iv_size = iv_size ).
    LOOP AT it_lines INTO DATA(lv_line).
      io_pdf->set_xy( iv_x = iv_x iv_y = lv_y ).
      io_pdf->cell( iv_text = lv_line iv_height = iv_step iv_padding = 0 ).
      lv_y = lv_y + iv_step.
    ENDLOOP.
  ENDMETHOD.


  METHOD underlined.
    io_pdf->set_font( iv_name = iv_font iv_size = iv_size ).
    io_pdf->set_xy( iv_x = iv_x iv_y = iv_y ).
    io_pdf->cell( iv_text = iv_text iv_height = 10 iv_padding = 0 ).

    DATA(lv_width) = io_pdf->get_text_width( iv_text ).
    io_pdf->set_line_width( '0.4' ).
    io_pdf->line(
      iv_x1 = iv_x
      iv_y1 = iv_y + iv_size + '1.5'
      iv_x2 = iv_x + lv_width
      iv_y2 = iv_y + iv_size + '1.5' ).
  ENDMETHOD.


  METHOD conditions.
    io_pdf->set_font( iv_name = c_bold iv_size = '8.5' ).
    io_pdf->set_xy( iv_x = c_left iv_y = 353 ).
    io_pdf->cell( iv_text = 'TERMS AND CONDITIONS' iv_height = 11 iv_padding = 0 ).

    " The paragraph is broken by hand so the line ends match the original,
    " the link carries a rule of its own
    lines_at(
      io_pdf   = io_pdf
      iv_x     = c_left
      iv_y     = 364
      iv_step  = 11
      iv_size  = '8.5'
      it_lines = VALUE #(
        ( `The General Terms and Conditions of Purchase shall be fully applicable to this Purchase Document. ` &&
          |Supplier furthermore agrees to KION{ cl_abap_conv_in_ce=>uccp( '00B4' ) }s| )
        ( `Principles of Supplier Conduct. Both documents form an integral part of this Purchase Document and ` &&
          |can be found on KION{ cl_abap_conv_in_ce=>uccp( '00B4' ) }s website| ) ) ).

    io_pdf->set_font( iv_name = c_font iv_size = '8.5' ).
    DATA(lv_x) = c_left + io_pdf->get_text_width( 'under: ' ).
    io_pdf->set_xy( iv_x = c_left iv_y = 386 ).
    io_pdf->cell(
      iv_text   = 'under: '
      iv_width  = lv_x - c_left
      iv_height = 11
      iv_padding = 0
      iv_ln     = abap_false ).
    underlined(
      io_pdf  = io_pdf
      iv_x    = lv_x
      iv_y    = 386
      iv_text = 'https://www.kiongroup.com/en/About-us/Suppliers/'
      iv_font = c_font
      iv_size = '8.5' ).
    io_pdf->set_font( iv_name = c_font iv_size = '8.5' ).
    io_pdf->set_xy(
      iv_x = lv_x + io_pdf->get_text_width( 'https://www.kiongroup.com/en/About-us/Suppliers/' )
      iv_y = 386 ).
    io_pdf->cell( iv_text = '. Upon request we will provide you a copy.' iv_height = 11 iv_padding = 0 ).

    io_pdf->set_font( iv_name = c_bold iv_size = '8.5' ).
    io_pdf->set_xy( iv_x = c_left iv_y = 402 ).
    io_pdf->cell( iv_text = 'ORDER CONFIRMATION' iv_height = 11 iv_padding = 0 ).
    lines_at(
      io_pdf   = io_pdf
      iv_x     = c_left
      iv_y     = '412.5'
      iv_step  = '10.5'
      iv_size  = '8.5'
      it_lines = VALUE #(
        ( `Please acknowledge receipt of this PO and confirm price and delivery for all PO Line Items ` &&
          `within 3 business day ARO.` )
        ( `In case of missing feedback within these 3 business days, we are entitled to consider accepted ` &&
          `& confirmed the PO (in all its parts)` ) ) ).

    io_pdf->set_font( iv_name = c_bold iv_size = '8.5' ).
    io_pdf->set_xy( iv_x = c_left iv_y = 441 ).
    io_pdf->cell( iv_text = 'BILLING SPECIFICATIONS' iv_height = 11 iv_padding = 0 ).

    underlined(
      io_pdf  = io_pdf
      iv_x    = c_left
      iv_y    = 450
      iv_text = 'Mandatory for all invoices:'
      iv_font = c_bold
      iv_size = '8.5' ).

    lines_at(
      io_pdf   = io_pdf
      iv_x     = c_left
      iv_y     = 460
      iv_step  = '10.4'
      iv_size  = '8.5'
      it_lines = VALUE #(
        ( `- Complete bank details, including IBAN number and SWIFT/BIC number` )
        ( `- VAT/TAX ID number of the Seller and the Customer` )
        ( `- Document type, currency, full description of the goods/services and payment term` )
        ( `- Purchase Order Number and item number` )
        ( `- Separate PDF document for each invoice` ) ) ).

    io_pdf->set_font( iv_name = c_bold iv_size = '8.5' ).
    io_pdf->set_xy( iv_x = c_left iv_y = 519 ).
    io_pdf->cell(
      iv_text   = 'The invoice will be returned if the instructions are not followed.'
      iv_height = 11
      iv_padding = 0 ).
  ENDMETHOD.


  METHOD item_table.
    TYPES: BEGIN OF ty_col,
             x      TYPE f,
             width  TYPE f,
             header TYPE string,
             align  TYPE string,
           END OF ty_col.
    DATA lt_cols TYPE STANDARD TABLE OF ty_col WITH DEFAULT KEY.

    lt_cols = VALUE #(
      ( x = 44  width = 33 header = 'Line'          align = 'C' )
      ( x = 77  width = 50 header = 'Material No.'  align = 'C' )
      ( x = 127 width = 171 header = 'Description'  align = 'C' )
      ( x = 298 width = 28 header = 'UoM'           align = 'C' )
      ( x = 326 width = 32 header = 'Quantity'      align = 'C' )
      ( x = 358 width = 44 header = 'Delivery Date' align = 'C' )
      ( x = 402 width = 40 header = 'Unit Price'    align = 'C' )
      ( x = 442 width = 22 header = 'Per'           align = 'C' )
      ( x = 464 width = 94 header = 'Total'         align = 'C' ) ).

    DATA(lv_top) = CONV f( 586 ).
    DATA(lv_head) = CONV f( 20 ).

    io_pdf->set_line_width( '0.5' ).
    io_pdf->set_draw_color( iv_r = 0 iv_g = 0 iv_b = 0 ).
    io_pdf->set_fill_color( iv_r = 217 iv_g = 217 iv_b = 217 ).
    io_pdf->set_font( iv_name = c_bold iv_size = '6.5' ).

    LOOP AT lt_cols INTO DATA(ls_col).
      io_pdf->rect(
        iv_x      = ls_col-x
        iv_y      = lv_top
        iv_width  = ls_col-width
        iv_height = lv_head
        iv_style  = 'DF' ).

      " The last column carries a two line caption
      IF ls_col-header = 'Total'.
        io_pdf->set_xy( iv_x = ls_col-x iv_y = lv_top + 3 ).
        io_pdf->cell(
          iv_text   = 'Total'
          iv_width  = ls_col-width
          iv_height = 8
          iv_align  = zcl_open_abap_pdf=>c_align_center
          iv_padding = 0 ).
        io_pdf->set_x( ls_col-x ).
        io_pdf->cell(
          iv_text   = 'Amount'
          iv_width  = ls_col-width
          iv_height = 8
          iv_align  = zcl_open_abap_pdf=>c_align_center
          iv_padding = 0 ).
      ELSE.
        io_pdf->set_xy( iv_x = ls_col-x iv_y = lv_top + 7 ).
        io_pdf->cell(
          iv_text   = ls_col-header
          iv_width  = ls_col-width
          iv_height = 8
          iv_align  = zcl_open_abap_pdf=>c_align_center
          iv_padding = 0 ).
      ENDIF.
    ENDLOOP.

    io_pdf->set_fill_color( iv_r = 255 iv_g = 255 iv_b = 255 ).

    " The item itself, plain text without a grid
    DATA(lv_row) = lv_top + lv_head + 5.
    io_pdf->set_font( iv_name = c_font iv_size = '7.5' ).

    io_pdf->set_xy( iv_x = 44 iv_y = lv_row ).
    io_pdf->cell( iv_text = '00010' iv_width = 33 iv_height = 10
                  iv_align = zcl_open_abap_pdf=>c_align_center iv_padding = 0 iv_ln = abap_false ).
    io_pdf->cell( iv_text = 'SP_457730' iv_width = 50 iv_height = 10
                  iv_align = zcl_open_abap_pdf=>c_align_center iv_padding = 0 iv_ln = abap_false ).
    io_pdf->set_x( 131 ).
    io_pdf->cell( iv_text = |pallet stacker 'EXV 10-12| iv_width = 167 iv_height = 10
                  iv_padding = 0 iv_ln = abap_false ).
    io_pdf->cell( iv_text = 'Piece' iv_width = 28 iv_height = 10
                  iv_align = zcl_open_abap_pdf=>c_align_center iv_padding = 0 iv_ln = abap_false ).
    io_pdf->cell( iv_text = '1' iv_width = 32 iv_height = 10
                  iv_align = zcl_open_abap_pdf=>c_align_center iv_padding = 0 iv_ln = abap_false ).
    io_pdf->cell( iv_text = '18 Jul 2024' iv_width = 44 iv_height = 10
                  iv_align = zcl_open_abap_pdf=>c_align_center iv_padding = 0 iv_ln = abap_false ).
    io_pdf->cell( iv_text = '7,562.70' iv_width = 40 iv_height = 10
                  iv_align = zcl_open_abap_pdf=>c_align_right iv_padding = 0 iv_ln = abap_false ).
    io_pdf->cell( iv_text = '1' iv_width = 22 iv_height = 10
                  iv_align = zcl_open_abap_pdf=>c_align_center iv_padding = 0 iv_ln = abap_false ).
    io_pdf->cell( iv_text = '7,562.70' iv_width = 90 iv_height = 10
                  iv_align = zcl_open_abap_pdf=>c_align_right iv_padding = 0 ).

    io_pdf->set_xy( iv_x = 131 iv_y = lv_row + 13 ).
    io_pdf->cell( iv_text = 'Supplier Material No.' iv_width = 86 iv_height = 10 iv_padding = 0 iv_ln = abap_false ).
    io_pdf->cell( iv_text = '45770000030' iv_height = 10 iv_padding = 0 ).

    io_pdf->set_line_width( '0.5' ).
    io_pdf->line( iv_x1 = 44 iv_y1 = lv_row + 28 iv_x2 = 558 iv_y2 = lv_row + 28 ).

    " Total line, right aligned against the last column
    io_pdf->set_font( iv_name = c_bold iv_size = '7.5' ).
    io_pdf->set_xy( iv_x = 318 iv_y = lv_row + 47 ).
    io_pdf->cell( iv_text = 'Total net value excl. tax:' iv_width = 175 iv_height = 10
                  iv_align = zcl_open_abap_pdf=>c_align_right iv_padding = 0 iv_ln = abap_false ).
    io_pdf->set_font( iv_name = c_font iv_size = '7.5' ).
    io_pdf->set_x( 510 ).
    io_pdf->cell( iv_text = 'EUR' iv_width = 20 iv_height = 10 iv_padding = 0 iv_ln = abap_false ).
    io_pdf->set_x( 508 ).
    io_pdf->cell( iv_text = '7,562.70' iv_width = 58 iv_height = 10
                  iv_align = zcl_open_abap_pdf=>c_align_right iv_padding = 0 ).

    io_pdf->set_font( iv_name = c_font iv_size = '8.5' ).
    io_pdf->set_xy( iv_x = c_left iv_y = lv_row + 69 ).
    io_pdf->cell(
      iv_text   = 'This Purchase Order is generated automatically and is valid without a signature.'
      iv_height = 11
      iv_padding = 0 ).
  ENDMETHOD.


  METHOD footer_block.
    io_pdf->set_line_width( '0.5' ).
    io_pdf->set_draw_color( iv_r = 0 iv_g = 0 iv_b = 0 ).
    io_pdf->line( iv_x1 = c_left iv_y1 = 738 iv_x2 = 558 iv_y2 = 738 ).

    io_pdf->set_font( iv_name = c_bold iv_size = '5.5' ).
    io_pdf->set_xy( iv_x = c_left iv_y = 748 ).
    io_pdf->cell( iv_text = 'STILL S.p.A.' iv_height = 7 iv_padding = 0 ).

    lines_at(
      io_pdf   = io_pdf
      iv_x     = c_left
      iv_y     = 755
      iv_step  = 7
      iv_size  = '5.5'
      it_lines = VALUE #(
        ( `Sede` )
        ( `Viale A. De Gasperi, 7` )
        ( `I-20045 Lainate (MI)` )
        ( `Tel.: +39 02 937651` )
        ( `Fax: +39 02 93765450` )
        ( `www.still.it` )
        ( `info@still.it` )
        ( `PEC still@pec.still.it` ) ) ).

    lines_at(
      io_pdf   = io_pdf
      iv_x     = 230
      iv_y     = 748
      iv_step  = 7
      iv_size  = '5.5'
      it_lines = VALUE #(
        ( `Cap. Soc. Euro 21.550.000` )
        ( `Registro Imprese di Milano` )
        ( `C.F. 01296940214` )
        ( `P.IVA IT11543160151` )
        ( `REA MI-1351064` ) ) ).

    lines_at(
      io_pdf   = io_pdf
      iv_x     = 230
      iv_y     = 791
      iv_step  = 7
      iv_size  = '5.5'
      it_lines = VALUE #(
        ( `Nr. Iscrizione registro nazionale dei soggetti` )
        ( `tenuti al finanziamento dei sistemi di` )
        ( `gestione dei rifiuti di pile e accumulatori` )
        ( `IT 11020P00002451` ) ) ).

    " The bank block keeps the label in bold and the value plain
    bank_line( io_pdf = io_pdf iv_y = 748 iv_label = 'Banca:' iv_value = 'UniCredit S.p.A.' ).
    bank_line( io_pdf = io_pdf iv_y = 755 iv_label = 'IBAN:' iv_value = 'IT40B0200805364000103144187' ).
    bank_line( io_pdf = io_pdf iv_y = 762 iv_label = 'SWIFT:' iv_value = 'UNCRITMMORR' ).

    lines_at(
      io_pdf   = io_pdf
      iv_x     = 415
      iv_y     = 776
      iv_step  = 7
      iv_size  = '5.5'
      it_lines = VALUE #(
        ( |Societ{ cl_abap_conv_in_ce=>uccp( '00E0' ) } soggetta a direzione e| )
        ( `coordinamento di KION Group AG` ) ) ).

    io_pdf->set_font( iv_name = c_font iv_size = '5.5' ).
    io_pdf->set_xy( iv_x = 415 iv_y = 804 ).
    io_pdf->cell( iv_text = 'Trading Partner: 1030' iv_height = 7 iv_padding = 0 ).
  ENDMETHOD.

ENDCLASS.
