CLASS zcl_pdf_demo_showcase DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_open_abap_pdf_layout.

    TYPES:
      BEGIN OF ty_txn,
        month   TYPE string,
        date    TYPE string,
        doc     TYPE string,
        text    TYPE string,
        debit   TYPE p LENGTH 11 DECIMALS 2,
        credit  TYPE p LENGTH 11 DECIMALS 2,
        balance TYPE p LENGTH 13 DECIMALS 2,
      END OF ty_txn,
      ty_txns TYPE STANDARD TABLE OF ty_txn WITH DEFAULT KEY,

      BEGIN OF ty_month_total,
        month  TYPE string,
        debit  TYPE p LENGTH 13 DECIMALS 2,
        credit TYPE p LENGTH 13 DECIMALS 2,
      END OF ty_month_total,
      ty_month_totals TYPE STANDARD TABLE OF ty_month_total WITH DEFAULT KEY.

    "! Build the showcase document as a PDF/A-3 archive with an embedded XML statement.
    "! @parameter iv_ttf | A TrueType font, embedded because PDF/A requires it
    "! @parameter iv_ttf_bold | The bold cut of the same family
    CLASS-METHODS run_base64
      IMPORTING iv_ttf           TYPE xstring
                iv_ttf_bold      TYPE xstring OPTIONAL
      RETURNING VALUE(rv_base64) TYPE string
      RAISING   zcx_open_abap_pdf.

  PRIVATE SECTION.
    CONSTANTS c_doc TYPE string VALUE 'Statement of Account 900-2026-0042'.
    CONSTANTS c_left TYPE f VALUE 45.
    CONSTANTS c_font TYPE string VALUE 'ShowcaseSans'.
    CONSTANTS c_bold TYPE string VALUE 'ShowcaseSans-Bold'.

    CLASS-DATA gv_bold TYPE string.

    CLASS-METHODS transactions
      RETURNING VALUE(rt_txns) TYPE ty_txns.

    CLASS-METHODS cover
      IMPORTING io_pdf TYPE REF TO zcl_open_abap_pdf
      RAISING   zcx_open_abap_pdf.

    CLASS-METHODS info_grid
      IMPORTING io_pdf TYPE REF TO zcl_open_abap_pdf.

    CLASS-METHODS codes
      IMPORTING io_pdf TYPE REF TO zcl_open_abap_pdf
      RAISING   zcx_open_abap_pdf.

    CLASS-METHODS txn_table
      IMPORTING io_pdf           TYPE REF TO zcl_open_abap_pdf
      RETURNING VALUE(rt_totals) TYPE ty_month_totals.

    CLASS-METHODS summary
      IMPORTING io_pdf    TYPE REF TO zcl_open_abap_pdf
                it_totals TYPE ty_month_totals.

    CLASS-METHODS chart
      IMPORTING io_pdf    TYPE REF TO zcl_open_abap_pdf
                it_totals TYPE ty_month_totals.

    CLASS-METHODS terms
      IMPORTING io_pdf TYPE REF TO zcl_open_abap_pdf.

    CLASS-METHODS signatures
      IMPORTING io_pdf TYPE REF TO zcl_open_abap_pdf.

    CLASS-METHODS amount
      IMPORTING iv_value       TYPE p
      RETURNING VALUE(rv_text) TYPE string.

    CLASS-METHODS statement_xml
      IMPORTING it_txns       TYPE ty_txns
      RETURNING VALUE(rv_xml) TYPE string.
ENDCLASS.


CLASS zcl_pdf_demo_showcase IMPLEMENTATION.

  METHOD run_base64.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).

    " Every glyph on the page has to come from an embedded font for PDF/A, so the
    " regular and, if given, the bold cut are registered before anything is drawn
    lo_pdf->register_font( iv_name = c_font iv_data = iv_ttf ).
    gv_bold = c_font.
    IF iv_ttf_bold IS NOT INITIAL.
      lo_pdf->register_font( iv_name = c_bold iv_data = iv_ttf_bold ).
      gv_bold = c_bold.
    ENDIF.

    " PDF/A-3 is the only part that allows the embedded XML of a hybrid document
    lo_pdf->set_pdfa(
      iv_icc    = zcl_pdf_test_icc=>srgb( )
      iv_title  = c_doc
      iv_author = 'Elektronik Grosshandel GmbH'
      iv_part   = 3 ).

    DATA(lt_txns) = transactions( ).
    lo_pdf->attach_file(
      iv_name     = 'statement.xml'
      iv_data     = cl_abap_codepage=>convert_to( statement_xml( lt_txns ) )
      iv_mime     = 'text/xml'
      iv_relation = 'Data'
      iv_text     = 'Machine readable account statement' ).

    lo_pdf->set_compression( ).
    lo_pdf->set_margins( iv_left = c_left iv_top = 45 iv_right = c_left iv_bottom = 60 ).

    " Keep the content clear of the footer, which starts 52 points above the edge
    lo_pdf->set_auto_page_break( iv_margin = 68 ).
    lo_pdf->set_layout( NEW zcl_pdf_demo_showcase( ) ).

    " A new page states the current font, so select the embedded one first
    lo_pdf->set_font( iv_name = c_font iv_size = 9 ).
    lo_pdf->add_page( ).

    cover( lo_pdf ).
    DATA(lt_totals) = txn_table( lo_pdf ).
    summary( io_pdf = lo_pdf it_totals = lt_totals ).
    chart( io_pdf = lo_pdf it_totals = lt_totals ).
    terms( lo_pdf ).
    signatures( lo_pdf ).

    rv_base64 = cl_http_utility=>encode_x_base64( lo_pdf->render_pdfa( ) ).
  ENDMETHOD.


  METHOD zif_open_abap_pdf_layout~header.
    " A light diagonal watermark on every page marks the file as an archive copy
    io_pdf->set_text_color( iv_r = 242 iv_g = 244 iv_b = 248 ).
    io_pdf->set_font( iv_name = gv_bold iv_size = 46 ).
    io_pdf->text_rotated(
      iv_x     = 120
      iv_y     = 700
      iv_text  = 'ARCHIVE COPY'
      iv_angle = 32 ).
    io_pdf->set_text_color( iv_r = 0 iv_g = 0 iv_b = 0 ).
    io_pdf->set_font( iv_name = c_font iv_size = 9 ).

    " Page one carries the full cover, the following pages a compact running head
    IF io_pdf->get_page_number( ) > 1.
      io_pdf->set_font( iv_name = gv_bold iv_size = 10 ).
      io_pdf->set_text_color( iv_r = 0 iv_g = 51 iv_b = 102 ).
      io_pdf->cell( iv_text = |{ c_doc } - continued| iv_height = 16 iv_ln = abap_false ).
      io_pdf->set_font( iv_name = c_font iv_size = 8 ).
      io_pdf->set_text_color( iv_r = 110 iv_g = 110 iv_b = 110 ).
      io_pdf->cell(
        iv_text   = 'Elektronik Grosshandel GmbH'
        iv_height = 16
        iv_align  = zcl_open_abap_pdf=>c_align_right ).

      io_pdf->set_draw_color( iv_r = 0 iv_g = 51 iv_b = 102 ).
      io_pdf->set_line_width( 1 ).
      io_pdf->line(
        iv_x1 = c_left
        iv_y1 = io_pdf->get_y( )
        iv_x2 = io_pdf->get_page_width( ) - c_left
        iv_y2 = io_pdf->get_y( ) ).
      io_pdf->set_text_color( iv_r = 0 iv_g = 0 iv_b = 0 ).
      io_pdf->set_font( iv_name = c_font iv_size = 9 ).
      io_pdf->ln( 12 ).
    ENDIF.
  ENDMETHOD.


  METHOD zif_open_abap_pdf_layout~footer.
    DATA(lv_y) = io_pdf->get_y( ).

    io_pdf->set_y( io_pdf->get_page_height( ) - 52 ).
    io_pdf->set_draw_color( iv_r = 150 iv_g = 150 iv_b = 150 ).
    io_pdf->set_line_width( '0.4' ).
    io_pdf->line(
      iv_x1 = c_left
      iv_y1 = io_pdf->get_y( )
      iv_x2 = io_pdf->get_page_width( ) - c_left
      iv_y2 = io_pdf->get_y( ) ).

    io_pdf->set_font( iv_name = c_font iv_size = 7 ).
    io_pdf->set_text_color( iv_r = 120 iv_g = 120 iv_b = 120 ).
    io_pdf->set_y( io_pdf->get_page_height( ) - 48 ).
    io_pdf->cell(
      iv_text   = `Elektronik Grosshandel GmbH   Hauptstrasse 1   40213 Duesseldorf   ` &&
                  `HRB 12345   VAT DE123456789   IBAN DE89 3704 0044 0532 0130 00`
      iv_height = 11
      iv_align  = zcl_open_abap_pdf=>c_align_center ).
    io_pdf->cell(
      iv_text   = |Generated 02.08.2026 by open-abap-pdf   -   page { io_pdf->get_page_number( ) } of \{nb\}|
      iv_height = 11
      iv_align  = zcl_open_abap_pdf=>c_align_center ).

    io_pdf->set_text_color( iv_r = 0 iv_g = 0 iv_b = 0 ).
    io_pdf->set_font( iv_name = c_font iv_size = 9 ).
    io_pdf->set_y( lv_y ).
  ENDMETHOD.


  METHOD cover.
    " Logo as an embedded JPEG, which PDF/A-1 allows because it is DCTDecode and RGB
    io_pdf->image_base64(
      iv_base64 = zcl_pdf_test_images=>jpeg( )
      iv_x      = c_left
      iv_y      = 45
      iv_width  = 96 ).

    io_pdf->set_xy( iv_x = 260 iv_y = 46 ).
    io_pdf->set_font( iv_name = gv_bold iv_size = 13 ).
    io_pdf->set_text_color( iv_r = 0 iv_g = 51 iv_b = 102 ).
    io_pdf->cell(
      iv_text   = 'Elektronik Grosshandel GmbH'
      iv_height = 16
      iv_align  = zcl_open_abap_pdf=>c_align_right ).
    io_pdf->set_font( iv_name = c_font iv_size = 8 ).
    io_pdf->set_text_color( iv_r = 90 iv_g = 90 iv_b = 90 ).
    io_pdf->set_x( 260 ).
    io_pdf->cell(
      iv_text   = 'Hauptstrasse 1   40213 Duesseldorf'
      iv_height = 12
      iv_align  = zcl_open_abap_pdf=>c_align_right ).
    io_pdf->set_x( 260 ).
    io_pdf->cell(
      iv_text   = 'accounts@elektronik-grosshandel.example'
      iv_height = 12
      iv_align  = zcl_open_abap_pdf=>c_align_right ).

    " Title with an underline in the corporate colour
    io_pdf->set_xy( iv_x = c_left iv_y = 118 ).
    io_pdf->set_font( iv_name = gv_bold iv_size = 22 ).
    io_pdf->set_text_color( iv_r = 0 iv_g = 51 iv_b = 102 ).
    io_pdf->cell( iv_text = 'Statement of Account' iv_height = 28 ).
    io_pdf->set_draw_color( iv_r = 0 iv_g = 92 iv_b = 158 ).
    io_pdf->set_line_width( 2 ).
    io_pdf->line( iv_x1 = c_left iv_y1 = 150 iv_x2 = 300 iv_y2 = 150 ).
    io_pdf->set_text_color( iv_r = 0 iv_g = 0 iv_b = 0 ).

    " Customer address window on the left
    io_pdf->set_draw_color( iv_r = 190 iv_g = 190 iv_b = 190 ).
    io_pdf->set_line_width( '0.6' ).
    io_pdf->rect( iv_x = c_left iv_y = 168 iv_width = 250 iv_height = 74 ).
    io_pdf->set_font( iv_name = c_font iv_size = 7 ).
    io_pdf->set_text_color( iv_r = 130 iv_g = 130 iv_b = 130 ).
    io_pdf->set_xy( iv_x = c_left + 8 iv_y = 174 ).
    io_pdf->cell( iv_text = 'Account holder' iv_height = 10 ).
    io_pdf->set_text_color( iv_r = 0 iv_g = 0 iv_b = 0 ).
    io_pdf->set_font( iv_name = gv_bold iv_size = 10 ).
    io_pdf->set_x( c_left + 8 ).
    io_pdf->cell( iv_text = 'Zuern Praezisionstechnik GmbH' iv_height = 14 ).
    io_pdf->set_font( iv_name = c_font iv_size = 9 ).
    io_pdf->set_x( c_left + 8 ).
    io_pdf->cell( iv_text = 'z.H. Frau Kuecuek' iv_height = 12 ).
    io_pdf->set_x( c_left + 8 ).
    io_pdf->cell( iv_text = 'Industriering 8' iv_height = 12 ).
    io_pdf->set_x( c_left + 8 ).
    io_pdf->cell( iv_text = '70565 Stuttgart' iv_height = 12 ).

    info_grid( io_pdf ).

    " Justified introduction spanning the full content width
    io_pdf->set_xy( iv_x = c_left iv_y = 258 ).
    io_pdf->set_font( iv_name = c_font iv_size = 9 ).
    io_pdf->multi_cell(
      iv_text  = `This statement lists all postings on your account between April and July 2026, ` &&
                 `grouped by month with a subtotal after each group and a running balance in the ` &&
                 `last column. The same figures are attached to this file as a machine readable XML ` &&
                 `document, so your accounting system can import them without rekeying. The QR code ` &&
                 `below opens the item in the customer portal, the barcode encodes the statement number.`
      iv_align = zcl_open_abap_pdf=>c_align_justify ).

    codes( io_pdf ).

    io_pdf->set_xy( iv_x = c_left iv_y = 430 ).
  ENDMETHOD.


  METHOD info_grid.
    TYPES: BEGIN OF ty_pair,
             key   TYPE string,
             value TYPE string,
           END OF ty_pair.
    DATA lt_pairs TYPE STANDARD TABLE OF ty_pair WITH DEFAULT KEY.

    lt_pairs = VALUE #(
      ( key = 'Statement no' value = '900-2026-0042' )
      ( key = 'Period'       value = '01.04.2026 - 31.07.2026' )
      ( key = 'Account'      value = '0000047110' )
      ( key = 'Currency'     value = 'EUR' )
      ( key = 'Terms'        value = '30 days net' )
      ( key = 'Issued'       value = '02.08.2026' ) ).

    DATA(lv_x) = CONV f( 320 ).
    DATA(lv_y) = CONV f( 168 ).
    LOOP AT lt_pairs INTO DATA(ls_pair).
      io_pdf->set_xy( iv_x = lv_x iv_y = lv_y ).
      io_pdf->set_font( iv_name = c_font iv_size = 8 ).
      io_pdf->set_text_color( iv_r = 120 iv_g = 120 iv_b = 120 ).
      io_pdf->cell( iv_text = ls_pair-key iv_width = 78 iv_height = 12 iv_ln = abap_false ).
      io_pdf->set_font( iv_name = gv_bold iv_size = 8 ).
      io_pdf->set_text_color( iv_r = 0 iv_g = 0 iv_b = 0 ).
      io_pdf->cell( iv_text = ls_pair-value iv_width = 122 iv_height = 12 ).
      lv_y = lv_y + 12.
    ENDLOOP.
    io_pdf->set_text_color( iv_r = 0 iv_g = 0 iv_b = 0 ).
  ENDMETHOD.


  METHOD codes.
    io_pdf->set_font( iv_name = gv_bold iv_size = 8 ).
    io_pdf->set_xy( iv_x = c_left iv_y = 336 ).
    io_pdf->cell( iv_text = 'Open in portal' iv_height = 12 ).
    io_pdf->qrcode(
      iv_x    = c_left
      iv_y    = 350
      iv_text = 'https://portal.example/sap/statement?id=900-2026-0042'
      iv_size = 66 ).

    io_pdf->set_xy( iv_x = 150 iv_y = 336 ).
    io_pdf->cell( iv_text = 'Statement number' iv_height = 12 ).
    io_pdf->barcode_128(
      iv_x      = 150
      iv_y      = 352
      iv_text   = '900-2026-0042'
      iv_height = 34
      iv_module = '0.9' ).
    io_pdf->set_font( iv_name = c_font iv_size = 7 ).
    io_pdf->set_xy( iv_x = 150 iv_y = 388 ).
    io_pdf->cell( iv_text = '900-2026-0042' iv_height = 10 ).
  ENDMETHOD.


  METHOD txn_table.
    DATA lv_month TYPE string.
    DATA lv_deb TYPE p LENGTH 13 DECIMALS 2.
    DATA lv_cred TYPE p LENGTH 13 DECIMALS 2.
    DATA ls_total TYPE ty_month_total.

    io_pdf->set_xy( iv_x = c_left iv_y = 430 ).
    io_pdf->set_font( iv_name = gv_bold iv_size = 11 ).
    io_pdf->set_text_color( iv_r = 0 iv_g = 51 iv_b = 102 ).
    io_pdf->cell( iv_text = 'Postings' iv_height = 20 ).
    io_pdf->set_text_color( iv_r = 0 iv_g = 0 iv_b = 0 ).

    DATA(lo_table) = zcl_open_abap_pdf_table=>create( io_pdf ).
    lo_table->set_line_height( 11 ).
    lo_table->set_padding( 3 ).
    lo_table->set_header_style(
      iv_font   = gv_bold
      iv_size   = 8
      iv_r      = 0
      iv_g      = 51
      iv_b      = 102
      iv_text_r = 255
      iv_text_g = 255
      iv_text_b = 255 ).
    lo_table->set_body_style( iv_font = c_font iv_size = 8 ).
    lo_table->set_zebra( iv_r = 244 iv_g = 247 iv_b = 250 ).
    lo_table->set_border( 'LRB' ).
    lo_table->add_column( iv_header = 'Date' iv_width = 58 ).
    lo_table->add_column( iv_header = 'Document' iv_width = 66 ).
    lo_table->add_column(
      iv_header       = 'Description'
      iv_header_align = zcl_open_abap_pdf=>c_align_center ).
    lo_table->add_column( iv_header = 'Debit' iv_width = 68 iv_align = zcl_open_abap_pdf=>c_align_right ).
    lo_table->add_column( iv_header = 'Credit' iv_width = 68 iv_align = zcl_open_abap_pdf=>c_align_right ).
    lo_table->add_column( iv_header = 'Balance' iv_width = 74 iv_align = zcl_open_abap_pdf=>c_align_right ).

    LOOP AT transactions( ) INTO DATA(ls_txn).
      IF ls_txn-month <> lv_month.
        IF lv_month IS NOT INITIAL.
          lo_table->add_span_row(
            iv_text  = |Subtotal { lv_month }      debit { amount( lv_deb ) }      credit { amount( lv_cred ) }|
            iv_align = zcl_open_abap_pdf=>c_align_right
            iv_r     = 235
            iv_g     = 238
            iv_b     = 242
            iv_keep_with_next = abap_false ).
          ls_total-month  = lv_month.
          ls_total-debit  = lv_deb.
          ls_total-credit = lv_cred.
          APPEND ls_total TO rt_totals.
        ENDIF.

        lv_month = ls_txn-month.
        CLEAR: lv_deb, lv_cred.
        lo_table->add_span_row( iv_text = ls_txn-month ).
      ENDIF.

      lv_deb  = lv_deb + ls_txn-debit.
      lv_cred = lv_cred + ls_txn-credit.

      lo_table->add_row( it_cells = VALUE #(
        ( ls_txn-date )
        ( ls_txn-doc )
        ( ls_txn-text )
        ( COND string( WHEN ls_txn-debit  > 0 THEN amount( ls_txn-debit ) ELSE '' ) )
        ( COND string( WHEN ls_txn-credit > 0 THEN amount( ls_txn-credit ) ELSE '' ) )
        ( amount( ls_txn-balance ) ) ) ).
    ENDLOOP.

    lo_table->add_span_row(
      iv_text  = |Subtotal { lv_month }      debit { amount( lv_deb ) }      credit { amount( lv_cred ) }|
      iv_align = zcl_open_abap_pdf=>c_align_right
      iv_r     = 235
      iv_g     = 238
      iv_b     = 242
      iv_keep_with_next = abap_false ).
    ls_total-month  = lv_month.
    ls_total-debit  = lv_deb.
    ls_total-credit = lv_cred.
    APPEND ls_total TO rt_totals.

    lo_table->render( ).
  ENDMETHOD.


  METHOD summary.
    DATA lv_debit TYPE p LENGTH 13 DECIMALS 2.
    DATA lv_credit TYPE p LENGTH 13 DECIMALS 2.

    LOOP AT it_totals INTO DATA(ls_total).
      lv_debit  = lv_debit + ls_total-debit.
      lv_credit = lv_credit + ls_total-credit.
    ENDLOOP.
    DATA(lv_open) = CONV p( '4200.00' ).
    DATA(lv_close) = lv_open + lv_debit - lv_credit.

    io_pdf->check_page_break( 96 ).
    io_pdf->ln( 12 ).
    DATA(lv_x) = io_pdf->get_page_width( ) - c_left - 250.
    DATA(lv_y) = io_pdf->get_y( ).

    io_pdf->set_fill_color( iv_r = 244 iv_g = 247 iv_b = 250 ).
    io_pdf->set_draw_color( iv_r = 0 iv_g = 51 iv_b = 102 ).
    io_pdf->set_line_width( 1 ).
    io_pdf->rect( iv_x = lv_x iv_y = lv_y iv_width = 250 iv_height = 84 iv_style = 'DF' ).

    io_pdf->set_xy( iv_x = lv_x + 10 iv_y = lv_y + 8 ).
    io_pdf->set_font( iv_name = gv_bold iv_size = 10 ).
    io_pdf->set_text_color( iv_r = 0 iv_g = 51 iv_b = 102 ).
    io_pdf->cell( iv_text = 'Balance summary' iv_height = 16 ).
    io_pdf->set_text_color( iv_r = 0 iv_g = 0 iv_b = 0 ).
    io_pdf->set_font( iv_name = c_font iv_size = 9 ).

    DATA(lv_line) = lv_y + 28.
    DATA(lt_rows) = VALUE string_table(
      ( |Opening balance;{ amount( lv_open ) } EUR| )
      ( |Total debit;{ amount( lv_debit ) } EUR| )
      ( |Total credit;{ amount( lv_credit ) } EUR| ) ).
    LOOP AT lt_rows INTO DATA(lv_row).
      SPLIT lv_row AT ';' INTO DATA(lv_key) DATA(lv_val).
      io_pdf->set_xy( iv_x = lv_x + 10 iv_y = lv_line ).
      io_pdf->cell( iv_text = lv_key iv_width = 150 iv_height = 12 iv_ln = abap_false ).
      io_pdf->cell( iv_text = lv_val iv_width = 80 iv_height = 12 iv_align = zcl_open_abap_pdf=>c_align_right ).
      lv_line = lv_line + 12.
    ENDLOOP.

    io_pdf->set_draw_color( iv_r = 150 iv_g = 150 iv_b = 150 ).
    io_pdf->line( iv_x1 = lv_x + 10 iv_y1 = lv_line + 1 iv_x2 = lv_x + 240 iv_y2 = lv_line + 1 ).
    io_pdf->set_xy( iv_x = lv_x + 10 iv_y = lv_line + 3 ).
    io_pdf->set_font( iv_name = gv_bold iv_size = 10 ).
    io_pdf->cell( iv_text = 'Closing balance' iv_width = 150 iv_height = 14 iv_ln = abap_false ).
    io_pdf->cell(
      iv_text   = |{ amount( lv_close ) } EUR|
      iv_width  = 80
      iv_height = 14
      iv_align  = zcl_open_abap_pdf=>c_align_right ).
    io_pdf->set_font( iv_name = c_font iv_size = 9 ).
    io_pdf->set_xy( iv_x = c_left iv_y = lv_y + 96 ).
  ENDMETHOD.


  METHOD chart.
    DATA lv_max TYPE p LENGTH 13 DECIMALS 2.

    LOOP AT it_totals INTO DATA(ls_total).
      IF ls_total-debit > lv_max.
        lv_max = ls_total-debit.
      ENDIF.
      IF ls_total-credit > lv_max.
        lv_max = ls_total-credit.
      ENDIF.
    ENDLOOP.
    IF lv_max = 0.
      RETURN.
    ENDIF.

    io_pdf->check_page_break( 130 ).
    io_pdf->set_x( c_left ).
    io_pdf->set_font( iv_name = gv_bold iv_size = 11 ).
    io_pdf->set_text_color( iv_r = 0 iv_g = 51 iv_b = 102 ).
    io_pdf->cell( iv_text = 'Debit and credit per month' iv_height = 20 ).
    io_pdf->set_text_color( iv_r = 0 iv_g = 0 iv_b = 0 ).

    " A small legend
    io_pdf->set_fill_color( iv_r = 0 iv_g = 92 iv_b = 158 ).
    io_pdf->rect( iv_x = c_left iv_y = io_pdf->get_y( ) + 2 iv_width = 10 iv_height = 8 iv_style = 'F' ).
    io_pdf->set_font( iv_name = c_font iv_size = 8 ).
    io_pdf->set_xy( iv_x = c_left + 14 iv_y = io_pdf->get_y( ) ).
    io_pdf->cell( iv_text = 'Debit' iv_width = 50 iv_height = 12 iv_ln = abap_false ).
    io_pdf->set_fill_color( iv_r = 120 iv_g = 170 iv_b = 90 ).
    io_pdf->rect( iv_x = c_left + 70 iv_y = io_pdf->get_y( ) + 2 iv_width = 10 iv_height = 8 iv_style = 'F' ).
    io_pdf->set_xy( iv_x = c_left + 84 iv_y = io_pdf->get_y( ) ).
    io_pdf->cell( iv_text = 'Credit' iv_height = 12 ).

    DATA(lv_y) = io_pdf->get_y( ) + 8.
    LOOP AT it_totals INTO ls_total.
      io_pdf->set_font( iv_name = c_font iv_size = 8 ).
      io_pdf->set_xy( iv_x = c_left iv_y = lv_y ).
      io_pdf->cell( iv_text = ls_total-month iv_width = 90 iv_height = 24 iv_ln = abap_false ).

      DATA(lv_wd) = CONV f( 300 * ls_total-debit / lv_max ).
      io_pdf->set_fill_color( iv_r = 0 iv_g = 92 iv_b = 158 ).
      io_pdf->rect( iv_x = c_left + 95 iv_y = lv_y + 1 iv_width = lv_wd iv_height = 9 iv_style = 'F' ).
      io_pdf->set_xy( iv_x = c_left + 100 + lv_wd iv_y = lv_y ).
      io_pdf->cell( iv_text = |{ amount( ls_total-debit ) }| iv_height = 11 ).

      DATA(lv_wc) = CONV f( 300 * ls_total-credit / lv_max ).
      io_pdf->set_fill_color( iv_r = 120 iv_g = 170 iv_b = 90 ).
      io_pdf->rect( iv_x = c_left + 95 iv_y = lv_y + 12 iv_width = lv_wc iv_height = 9 iv_style = 'F' ).
      io_pdf->set_xy( iv_x = c_left + 100 + lv_wc iv_y = lv_y + 11 ).
      io_pdf->cell( iv_text = |{ amount( ls_total-credit ) }| iv_height = 11 ).

      lv_y = lv_y + 28.
    ENDLOOP.

    io_pdf->set_xy( iv_x = c_left iv_y = lv_y + 6 ).
  ENDMETHOD.


  METHOD terms.
    io_pdf->check_page_break( 150 ).
    io_pdf->set_x( c_left ).
    io_pdf->set_font( iv_name = gv_bold iv_size = 11 ).
    io_pdf->set_text_color( iv_r = 0 iv_g = 51 iv_b = 102 ).
    io_pdf->cell( iv_text = 'Notes' iv_height = 20 ).
    io_pdf->set_text_color( iv_r = 0 iv_g = 0 iv_b = 0 ).

    DATA(lv_top) = io_pdf->get_y( ).
    DATA(lv_col) = ( io_pdf->get_content_width( ) - 20 ) / 2.

    io_pdf->set_font( iv_name = c_font iv_size = 8 ).
    io_pdf->set_xy( iv_x = c_left iv_y = lv_top ).
    io_pdf->multi_cell(
      iv_width = lv_col
      iv_align = zcl_open_abap_pdf=>c_align_justify
      iv_text  = `Amounts shown as debit increase the balance you owe, amounts shown as credit ` &&
                 `reduce it. The running balance in the last column already includes the ` &&
                 `posting on the same line. Please settle the closing balance within the ` &&
                 `payment terms stated on the cover page, quoting the statement number so we ` &&
                 `can allocate your payment without delay.` ).

    io_pdf->set_xy( iv_x = c_left + lv_col + 20 iv_y = lv_top ).
    io_pdf->multi_cell(
      iv_width = lv_col
      iv_align = zcl_open_abap_pdf=>c_align_justify
      iv_text  = `This document is a PDF/A-3 archive, so it stays readable for the long term ` &&
                 `and carries its own fonts and colour profile. The attached statement.xml ` &&
                 `repeats every figure in a structured form for straight through processing. ` &&
                 `If the printed figures and the attachment ever disagree, the attachment is ` &&
                 `the authoritative record.` ).

    io_pdf->ln( 10 ).
  ENDMETHOD.


  METHOD signatures.
    io_pdf->check_page_break( 70 ).
    io_pdf->ln( 24 ).
    DATA(lv_y) = io_pdf->get_y( ).
    DATA(lv_w) = ( io_pdf->get_content_width( ) - 40 ) / 2.

    io_pdf->set_draw_color( iv_r = 0 iv_g = 0 iv_b = 0 ).
    io_pdf->set_line_width( '0.6' ).
    io_pdf->line( iv_x1 = c_left iv_y1 = lv_y iv_x2 = c_left + lv_w iv_y2 = lv_y ).
    io_pdf->line(
      iv_x1 = c_left + lv_w + 40
      iv_y1 = lv_y
      iv_x2 = c_left + lv_w + 40 + lv_w
      iv_y2 = lv_y ).

    io_pdf->set_font( iv_name = c_font iv_size = 8 ).
    io_pdf->set_text_color( iv_r = 90 iv_g = 90 iv_b = 90 ).
    io_pdf->set_xy( iv_x = c_left iv_y = lv_y + 3 ).
    io_pdf->cell( iv_text = 'Accounts receivable' iv_width = lv_w iv_height = 12 iv_ln = abap_false ).
    io_pdf->set_x( c_left + lv_w + 40 ).
    io_pdf->cell( iv_text = 'Head of finance' iv_width = lv_w iv_height = 12 ).
    io_pdf->set_text_color( iv_r = 0 iv_g = 0 iv_b = 0 ).
  ENDMETHOD.


  METHOD amount.
    DATA lv_int TYPE string.
    DATA lv_dec TYPE string.
    DATA lv_group TYPE string.
    DATA lv_offset TYPE i.
    DATA lv_sign TYPE string.
    DATA lv_value TYPE p LENGTH 13 DECIMALS 2.

    lv_value = iv_value.
    IF lv_value < 0.
      lv_sign = '-'.
      lv_value = lv_value * -1.
    ENDIF.

    SPLIT |{ lv_value DECIMALS = 2 }| AT '.' INTO lv_int lv_dec.

    WHILE strlen( lv_int ) > 3.
      lv_offset = strlen( lv_int ) - 3.
      lv_group = |{ lv_int+lv_offset(3) }.{ lv_group }|.
      lv_int = lv_int(lv_offset).
    ENDWHILE.

    rv_text = |{ lv_int }.{ lv_group }|.
    REPLACE ALL OCCURRENCES OF '..' IN rv_text WITH '.'.
    IF rv_text CP '*.'.
      lv_offset = strlen( rv_text ) - 1.
      rv_text = rv_text(lv_offset).
    ENDIF.
    rv_text = |{ lv_sign }{ rv_text },{ lv_dec }|.
  ENDMETHOD.


  METHOD transactions.
    TYPES: BEGIN OF ty_seed,
             month  TYPE string,
             date   TYPE string,
             doc    TYPE string,
             text   TYPE string,
             debit  TYPE p LENGTH 11 DECIMALS 2,
             credit TYPE p LENGTH 11 DECIMALS 2,
           END OF ty_seed.
    DATA lt_seed TYPE STANDARD TABLE OF ty_seed WITH DEFAULT KEY.

    lt_seed = VALUE #(
      ( month = 'April 2026' date = '03.04.2026' doc = 'INV 500128' text = 'Processor units MD1, 40 pieces' debit = '6000.00' )
      ( month = 'April 2026' date = '08.04.2026' doc = 'INV 500141' text = 'Cable sets, shielded, 120 pieces' debit = '3420.00' )
      ( month = 'April 2026' date = '12.04.2026' doc = 'PAY 900771' text = 'Incoming payment, thank you' credit = '4200.00' )
      ( month = 'April 2026' date = '15.04.2026' doc = 'INV 500152' text = 'Mounting rails DIN 35mm, 400 pieces' debit = '1240.00' )
      ( month = 'April 2026' date = '19.04.2026' doc = 'INV 500163' text = 'Power supplies 24V, 25 pieces' debit = '1875.00' )
      ( month = 'April 2026' date = '23.04.2026' doc = 'INV 500171' text = 'Freight and packaging, express delivery to Stuttgart plant 2' debit = '318.00' )
      ( month = 'April 2026' date = '27.04.2026' doc = 'CRN 700018' text = 'Credit note, returned goods' credit = '312.50' )
      ( month = 'April 2026' date = '30.04.2026' doc = 'PAY 900788' text = 'Incoming payment' credit = '3420.00' )

      ( month = 'May 2026' date = '05.05.2026' doc = 'INV 500204' text = 'Sensor modules S7, 60 pieces' debit = '5400.00' )
      ( month = 'May 2026' date = '08.05.2026' doc = 'INV 500212' text = 'Terminal blocks, assorted, 750 pieces' debit = '1425.00' )
      ( month = 'May 2026' date = '11.05.2026' doc = 'PAY 900802' text = 'Incoming payment' credit = '6000.00' )
      ( month = 'May 2026' date = '15.05.2026' doc = 'INV 500221' text = 'Housings aluminium, 200 pieces' debit = '2600.00' )
      ( month = 'May 2026' date = '19.05.2026' doc = 'INV 500229' text = 'Calibration service, on site, two technicians' debit = '1680.00' )
      ( month = 'May 2026' date = '22.05.2026' doc = 'INV 500238' text = 'Assembly service, 30 hours' debit = '2250.00' )
      ( month = 'May 2026' date = '26.05.2026' doc = 'CRN 700021' text = 'Credit note, quantity discount' credit = '540.00' )
      ( month = 'May 2026' date = '29.05.2026' doc = 'PAY 900834' text = 'Incoming payment' credit = '5400.00' )

      ( month = 'June 2026' date = '02.06.2026' doc = 'INV 500266' text = 'Processor units MD2, 30 pieces' debit = '5100.00' )
      ( month = 'June 2026' date = '05.06.2026' doc = 'PAY 900851' text = 'Incoming payment' credit = '2600.00' )
      ( month = 'June 2026' date = '09.06.2026' doc = 'INV 500279' text = 'Connector kits, 300 pieces' debit = '1740.00' )
      ( month = 'June 2026' date = '12.06.2026' doc = 'INV 500288' text = 'Firmware licence, 12 months, 30 devices' debit = '2160.00' )
      ( month = 'June 2026' date = '14.06.2026' doc = 'PAY 900867' text = 'Incoming payment' credit = '4850.00' )
      ( month = 'June 2026' date = '18.06.2026' doc = 'CRN 700025' text = 'Credit note, price adjustment' credit = '128.00' )
      ( month = 'June 2026' date = '23.06.2026' doc = 'INV 500301' text = 'Display units 7 inch, 15 pieces' debit = '2985.00' )
      ( month = 'June 2026' date = '26.06.2026' doc = 'INV 500309' text = 'Repair of returned control unit, labour and spare parts' debit = '742.00' )
      ( month = 'June 2026' date = '30.06.2026' doc = 'INV 500318' text = 'Extended warranty, annual' debit = '990.00' )

      ( month = 'July 2026' date = '02.07.2026' doc = 'PAY 900889' text = 'Incoming payment' credit = '5100.00' )
      ( month = 'July 2026' date = '06.07.2026' doc = 'INV 500334' text = 'Processor units MD2, 25 pieces' debit = '4250.00' )
      ( month = 'July 2026' date = '10.07.2026' doc = 'INV 500347' text = 'Cable sets, shielded, 90 pieces' debit = '2565.00' )
      ( month = 'July 2026' date = '14.07.2026' doc = 'PAY 900904' text = 'Incoming payment' credit = '3900.00' )
      ( month = 'July 2026' date = '17.07.2026' doc = 'INV 500355' text = 'Enclosure fans, 120 pieces' debit = '960.00' )
      ( month = 'July 2026' date = '21.07.2026' doc = 'INV 500362' text = 'Training on the new controller generation, two days, six participants' debit = '3600.00' )
      ( month = 'July 2026' date = '24.07.2026' doc = 'CRN 700031' text = 'Credit note, transport damage' credit = '415.00' )
      ( month = 'July 2026' date = '28.07.2026' doc = 'INV 500371' text = 'Spare part package, priority stock' debit = '1830.00' )
      ( month = 'July 2026' date = '31.07.2026' doc = 'PAY 900921' text = 'Incoming payment' credit = '4250.00' ) ).

    DATA(lv_balance) = CONV p( '4200.00' ).
    LOOP AT lt_seed INTO DATA(ls_seed).
      lv_balance = lv_balance + ls_seed-debit - ls_seed-credit.
      APPEND VALUE ty_txn(
        month   = ls_seed-month
        date    = ls_seed-date
        doc     = ls_seed-doc
        text    = ls_seed-text
        debit   = ls_seed-debit
        credit  = ls_seed-credit
        balance = lv_balance ) TO rt_txns.
    ENDLOOP.
  ENDMETHOD.


  METHOD statement_xml.
    DATA(lv_lines) = ``.
    LOOP AT it_txns INTO DATA(ls_txn).
      lv_lines = lv_lines &&
        |    <Posting>\n| &&
        |      <Date>{ ls_txn-date }</Date>\n| &&
        |      <Document>{ ls_txn-doc }</Document>\n| &&
        |      <Debit>{ ls_txn-debit DECIMALS = 2 }</Debit>\n| &&
        |      <Credit>{ ls_txn-credit DECIMALS = 2 }</Credit>\n| &&
        |      <Balance>{ ls_txn-balance DECIMALS = 2 }</Balance>\n| &&
        |    </Posting>\n|.
    ENDLOOP.

    rv_xml = |<?xml version="1.0" encoding="UTF-8"?>\n| &&
             |<Statement number="900-2026-0042" currency="EUR">\n| &&
             |  <Account>0000047110</Account>\n| &&
             |  <Period from="2026-04-01" to="2026-07-31"/>\n| &&
             |  <Postings>\n| &&
             lv_lines &&
             |  </Postings>\n| &&
             |</Statement>\n|.
  ENDMETHOD.

ENDCLASS.
