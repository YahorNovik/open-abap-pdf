CLASS zcl_pdf_demo_complex DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_open_abap_pdf_layout.

    TYPES:
      BEGIN OF ty_item,
        group TYPE string,
        posnr TYPE i,
        matnr TYPE string,
        text  TYPE string,
        note  TYPE string,
        unit  TYPE string,
        qty   TYPE i,
        price TYPE p LENGTH 9 DECIMALS 2,
      END OF ty_item,
      ty_items TYPE STANDARD TABLE OF ty_item WITH DEFAULT KEY,

      BEGIN OF ty_group_total,
        group TYPE string,
        value TYPE p LENGTH 13 DECIMALS 2,
      END OF ty_group_total,
      ty_group_totals TYPE STANDARD TABLE OF ty_group_total WITH DEFAULT KEY.

    CLASS-METHODS run_base64
      RETURNING VALUE(rv_base64) TYPE string
      RAISING   zcx_open_abap_pdf.

  PRIVATE SECTION.
    CONSTANTS c_doc TYPE string VALUE 'Order confirmation 0080004711'.
    CONSTANTS c_left TYPE f VALUE 45.

    CLASS-DATA gv_watermark TYPE abap_bool.

    CLASS-METHODS items
      RETURNING VALUE(rt_items) TYPE ty_items.

    CLASS-METHODS amount
      IMPORTING iv_value       TYPE p
      RETURNING VALUE(rv_text) TYPE string.

    CLASS-METHODS letterhead
      IMPORTING io_pdf TYPE REF TO zcl_open_abap_pdf
      RAISING   zcx_open_abap_pdf.

    CLASS-METHODS info_grid
      IMPORTING io_pdf TYPE REF TO zcl_open_abap_pdf.

    CLASS-METHODS item_table
      IMPORTING io_pdf           TYPE REF TO zcl_open_abap_pdf
      RETURNING VALUE(rt_totals) TYPE ty_group_totals.

    CLASS-METHODS totals
      IMPORTING io_pdf    TYPE REF TO zcl_open_abap_pdf
                it_totals TYPE ty_group_totals.

    CLASS-METHODS chart
      IMPORTING io_pdf    TYPE REF TO zcl_open_abap_pdf
                it_totals TYPE ty_group_totals.

    CLASS-METHODS terms
      IMPORTING io_pdf TYPE REF TO zcl_open_abap_pdf.

    CLASS-METHODS signatures
      IMPORTING io_pdf TYPE REF TO zcl_open_abap_pdf.
ENDCLASS.

CLASS zcl_pdf_demo_complex IMPLEMENTATION.

  METHOD zif_open_abap_pdf_layout~header.
    " Page one carries the full letterhead, the following pages a compact repeat
    IF io_pdf->get_page_number( ) > 1.
      io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 10 ).
      io_pdf->set_text_color( iv_r = 0 iv_g = 51 iv_b = 102 ).
      io_pdf->cell( iv_text = |{ c_doc } - continued| iv_height = 16 iv_ln = abap_false ).
      io_pdf->set_font( iv_name = 'Helvetica' iv_size = 8 ).
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
      io_pdf->set_line_width( '0.4' ).
      io_pdf->set_draw_color( iv_r = 150 iv_g = 150 iv_b = 150 ).
      io_pdf->set_text_color( iv_r = 0 iv_g = 0 iv_b = 0 ).
      io_pdf->set_font( iv_name = 'Helvetica' iv_size = 9 ).
      io_pdf->ln( 12 ).
    ENDIF.

    IF gv_watermark = abap_true.
      io_pdf->set_text_color( iv_r = 232 iv_g = 232 iv_b = 232 ).
      io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 62 ).
      io_pdf->text_rotated(
        iv_x     = 80
        iv_y     = 700
        iv_text  = 'DUPLICATE'
        iv_angle = 45 ).
      io_pdf->set_text_color( iv_r = 0 iv_g = 0 iv_b = 0 ).
      io_pdf->set_font( iv_name = 'Helvetica' iv_size = 9 ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_open_abap_pdf_layout~footer.
    DATA(lv_y) = io_pdf->get_y( ).

    io_pdf->set_y( io_pdf->get_page_height( ) - 56 ).
    io_pdf->set_draw_color( iv_r = 150 iv_g = 150 iv_b = 150 ).
    io_pdf->line(
      iv_x1 = c_left
      iv_y1 = io_pdf->get_y( )
      iv_x2 = io_pdf->get_page_width( ) - c_left
      iv_y2 = io_pdf->get_y( ) ).

    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 7 ).
    io_pdf->set_text_color( iv_r = 120 iv_g = 120 iv_b = 120 ).
    io_pdf->set_y( io_pdf->get_page_height( ) - 52 ).
    io_pdf->cell(
      iv_text   = `Elektronik Grosshandel GmbH   Hauptstrasse 1   40213 Duesseldorf   ` &&
                  `HRB 12345   VAT DE123456789`
      iv_height = 11
      iv_align  = zcl_open_abap_pdf=>c_align_center ).
    io_pdf->cell(
      iv_text   = |{ c_doc }   -   page { io_pdf->get_page_number( ) } of \{nb\}|
      iv_height = 11
      iv_align  = zcl_open_abap_pdf=>c_align_center ).

    io_pdf->set_text_color( iv_r = 0 iv_g = 0 iv_b = 0 ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 9 ).
    io_pdf->set_y( lv_y ).
  ENDMETHOD.

  METHOD amount.
    DATA lv_int TYPE string.
    DATA lv_dec TYPE string.
    DATA lv_group TYPE string.
    DATA lv_offset TYPE i.

    SPLIT |{ iv_value DECIMALS = 2 }| AT '.' INTO lv_int lv_dec.

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
    rv_text = |{ rv_text },{ lv_dec }|.
  ENDMETHOD.

  METHOD items.
    DATA lv_i TYPE i.
    DATA ls_item TYPE ty_item.
    DATA lt_groups TYPE zcl_open_abap_pdf_font=>ty_lines.
    DATA lv_group TYPE string.

    lt_groups = VALUE #(
      ( 'Processors and mainboards' )
      ( 'Storage' )
      ( 'Power supplies and cooling' )
      ( 'Cables and small parts' ) ).

    LOOP AT lt_groups INTO lv_group.
      DATA(lv_group_index) = sy-tabix.
      DO 9 TIMES.
        lv_i = lv_i + 1.
        CLEAR ls_item.
        ls_item-group = lv_group.
        ls_item-posnr = lv_i * 10.
        ls_item-matnr = |M-{ 100000 + lv_group_index * 1000 + sy-index }|.
        ls_item-unit = 'PC'.
        ls_item-qty = 3 + sy-index * 2.
        ls_item-price = sy-index * '17.35' + lv_group_index * '9.90' + '12.50'.

        CASE lv_group_index.
          WHEN 1.
            ls_item-text = |Processor unit type MD{ sy-index }, 8 cores, 3.4 GHz, socket AM5|.
            ls_item-note = 'Delivery in original packaging, ESD protected'.
          WHEN 2.
            ls_item-text = |Solid state disk { sy-index * 512 } GB, NVMe, PCIe 4.0, 3D TLC|.
          WHEN 3.
            ls_item-text = |Power supply { 400 + sy-index * 50 } W, 80 PLUS gold, modular cabling|.
            ls_item-note = `Includes mounting kit and four SATA power cables, ` &&
                           `cable length 750 mm, tested according to internal standard QS-114`.
          WHEN OTHERS.
            ls_item-text = |Cable set { sy-index }, shielded, 1.5 m|.
        ENDCASE.

        APPEND ls_item TO rt_items.
      ENDDO.
    ENDLOOP.
  ENDMETHOD.

  METHOD letterhead.
    io_pdf->image_base64(
      iv_base64 = zcl_pdf_test_images=>logo( )
      iv_x      = c_left
      iv_y      = 40
      iv_width  = 42 ).

    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 17 ).
    io_pdf->set_text_color( iv_r = 0 iv_g = 51 iv_b = 102 ).
    io_pdf->set_xy( iv_x = c_left + 52 iv_y = 42 ).
    io_pdf->cell( iv_text = 'Elektronik Grosshandel GmbH' iv_width = 300 iv_height = 22 ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 8 ).
    io_pdf->set_text_color( iv_r = 110 iv_g = 110 iv_b = 110 ).
    io_pdf->set_x( c_left + 52 ).
    io_pdf->cell( iv_text = 'Hauptstrasse 1   40213 Duesseldorf   Germany' iv_width = 300 iv_height = 12 ).

    " Address window
    io_pdf->set_text_color( iv_r = 0 iv_g = 0 iv_b = 0 ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 7 ).
    io_pdf->set_xy( iv_x = c_left iv_y = 108 ).
    io_pdf->cell(
      iv_text   = 'Elektronik Grosshandel GmbH, Hauptstrasse 1, 40213 Duesseldorf'
      iv_width  = 240
      iv_height = 10 ).
    io_pdf->line(
      iv_x1 = c_left
      iv_y1 = 118
      iv_x2 = c_left + 240
      iv_y2 = 118 ).

    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 10 ).
    io_pdf->set_xy( iv_x = c_left iv_y = 126 ).
    io_pdf->multi_cell(
      iv_text   = |Sebastian Kowalski Computer GmbH\nEinkauf, Herr M. Berger\n| &&
                  |Legnicka 256\n54-206 Wroclaw\nPoland|
      iv_width  = 240
      iv_height = 13 ).

    " Subject and intro
    io_pdf->set_xy( iv_x = c_left iv_y = 232 ).
    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 13 ).
    io_pdf->cell( iv_text = c_doc iv_height = 20 ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 9 ).
    io_pdf->multi_cell(
      iv_text   = `Thank you for your order. We confirm the positions below with the agreed ` &&
                  `prices and delivery dates. Partial deliveries are possible, the confirmed ` &&
                  `quantities are binding for six weeks.`
      iv_width  = 340
      iv_height = 12 ).
  ENDMETHOD.

  METHOD info_grid.
    DATA lt_labels TYPE zcl_open_abap_pdf_font=>ty_lines.
    DATA lt_values TYPE zcl_open_abap_pdf_font=>ty_lines.
    DATA lv_label TYPE string.
    DATA lv_value TYPE string.

    lt_labels = VALUE #(
      ( 'Customer number' ) ( 'Your order' ) ( 'Order date' ) ( 'Contact' )
      ( 'Phone' ) ( 'Incoterms' ) ( 'Payment terms' ) ( 'Currency' ) ).
    lt_values = VALUE #(
      ( '0000104711' ) ( 'PO-2026-000842' ) ( '28.07.2026' ) ( 'Anna Weber' )
      ( '+49 211 555 0142' ) ( 'DAP Wroclaw' ) ( '14 days 2%, 30 days net' ) ( 'EUR' ) ).

    DATA(lv_x) = 390.
    DATA(lv_y) = CONV f( 232 ).

    io_pdf->set_fill_color( iv_r = 243 iv_g = 246 iv_b = 250 ).
    io_pdf->set_xy( iv_x = lv_x iv_y = lv_y ).
    io_pdf->cell(
      iv_text   = ''
      iv_width  = 160
      iv_height = 8 + 8 * 14
      iv_border = '1'
      iv_fill   = abap_true
      iv_ln     = abap_false ).

    lv_y = lv_y + 4.
    LOOP AT lt_labels INTO lv_label.
      READ TABLE lt_values INTO lv_value INDEX sy-tabix.

      io_pdf->set_font( iv_name = 'Helvetica' iv_size = 8 ).
      io_pdf->set_text_color( iv_r = 110 iv_g = 110 iv_b = 110 ).
      io_pdf->set_xy( iv_x = lv_x + 6 iv_y = lv_y ).
      io_pdf->cell( iv_text = lv_label iv_width = 72 iv_height = 14 iv_ln = abap_false ).

      io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 8 ).
      io_pdf->set_text_color( iv_r = 0 iv_g = 0 iv_b = 0 ).
      io_pdf->cell(
        iv_text     = lv_value
        iv_width    = 76
        iv_height   = 14
        iv_align    = zcl_open_abap_pdf=>c_align_right
        iv_truncate = abap_true ).

      lv_y = lv_y + 14.
    ENDLOOP.

    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 9 ).
  ENDMETHOD.

  METHOD item_table.
    DATA ls_item TYPE ty_item.
    DATA lv_group TYPE string.
    DATA lv_line TYPE p LENGTH 13 DECIMALS 2.
    DATA lv_group_sum TYPE p LENGTH 13 DECIMALS 2.
    DATA ls_total TYPE ty_group_total.

    io_pdf->set_xy( iv_x = c_left iv_y = 360 ).

    DATA(lo_table) = zcl_open_abap_pdf_table=>create( io_pdf ).
    lo_table->set_line_height( 11 ).
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
    lo_table->set_border( 'LRB' ).
    lo_table->add_column( iv_header = 'Pos' iv_width = 30 iv_align = zcl_open_abap_pdf=>c_align_right ).
    lo_table->add_column( iv_header = 'Material' iv_width = 62 ).
    lo_table->add_column(
      iv_header       = 'Description'
      iv_header_align = zcl_open_abap_pdf=>c_align_center ).
    lo_table->add_column( iv_header = 'Qty' iv_width = 38 iv_align = zcl_open_abap_pdf=>c_align_right ).
    lo_table->add_column( iv_header = 'Un' iv_width = 24 iv_align = zcl_open_abap_pdf=>c_align_center ).
    lo_table->add_column( iv_header = 'Unit price' iv_width = 58 iv_align = zcl_open_abap_pdf=>c_align_right ).
    lo_table->add_column( iv_header = 'Net value' iv_width = 64 iv_align = zcl_open_abap_pdf=>c_align_right ).

    LOOP AT items( ) INTO ls_item.
      IF ls_item-group <> lv_group.
        IF lv_group IS NOT INITIAL.
          lo_table->add_span_row(
            iv_text  = |Subtotal { lv_group }   { amount( lv_group_sum ) } EUR|
            iv_align = zcl_open_abap_pdf=>c_align_right
            iv_r     = 240
            iv_g     = 240
            iv_b     = 240
            iv_keep_with_next = abap_false ).
          ls_total-group = lv_group.
          ls_total-value = lv_group_sum.
          APPEND ls_total TO rt_totals.
        ENDIF.

        lv_group = ls_item-group.
        CLEAR lv_group_sum.
        lo_table->add_span_row( iv_text = ls_item-group ).
      ENDIF.

      lv_line = ls_item-qty * ls_item-price.
      lv_group_sum = lv_group_sum + lv_line.

      DATA(lv_text) = ls_item-text.
      IF ls_item-note IS NOT INITIAL.
        lv_text = |{ lv_text }\n{ ls_item-note }|.
      ENDIF.

      lo_table->add_row( VALUE #(
        ( |{ ls_item-posnr }| )
        ( ls_item-matnr )
        ( lv_text )
        ( |{ ls_item-qty }| )
        ( ls_item-unit )
        ( amount( ls_item-price ) )
        ( amount( lv_line ) ) ) ).
    ENDLOOP.

    lo_table->add_span_row(
      iv_text  = |Subtotal { lv_group }   { amount( lv_group_sum ) } EUR|
      iv_align = zcl_open_abap_pdf=>c_align_right
      iv_r     = 240
      iv_g     = 240
      iv_b     = 240
      iv_keep_with_next = abap_false ).
    ls_total-group = lv_group.
    ls_total-value = lv_group_sum.
    APPEND ls_total TO rt_totals.

    lo_table->render( ).
  ENDMETHOD.

  METHOD totals.
    DATA ls_total TYPE ty_group_total.
    DATA lv_net TYPE p LENGTH 13 DECIMALS 2.
    DATA lv_vat TYPE p LENGTH 13 DECIMALS 2.

    LOOP AT it_totals INTO ls_total.
      lv_net = lv_net + ls_total-value.
    ENDLOOP.
    lv_vat = lv_net * 19 / 100.

    io_pdf->check_page_break( 70 ).

    DATA(lv_x) = io_pdf->get_page_width( ) - c_left - 240.
    io_pdf->set_xy( iv_x = lv_x iv_y = io_pdf->get_y( ) + 8 ).

    DATA(lo_sum) = zcl_open_abap_pdf_table=>create( io_pdf ).
    lo_sum->set_line_height( 13 ).
    lo_sum->set_border( 'LRB' ).
    lo_sum->set_body_style( iv_font = 'Helvetica' iv_size = 9 ).
    lo_sum->set_header_style(
      iv_font   = 'Helvetica-Bold'
      iv_size   = 9
      iv_r      = 0
      iv_g      = 51
      iv_b      = 102
      iv_text_r = 255
      iv_text_g = 255
      iv_text_b = 255 ).
    lo_sum->add_column( iv_header = 'Summary' iv_width = 150 ).
    lo_sum->add_column( iv_header = 'EUR' iv_width = 90 iv_align = zcl_open_abap_pdf=>c_align_right ).
    lo_sum->add_row( VALUE #( ( 'Net value' ) ( amount( lv_net ) ) ) ).
    lo_sum->add_row( VALUE #( ( 'Value added tax 19 %' ) ( amount( lv_vat ) ) ) ).
    lo_sum->add_row(
      it_cells = VALUE #( ( 'Total gross' ) ( amount( lv_net + lv_vat ) ) )
      iv_bold  = abap_true ).
    lo_sum->render( ).

    io_pdf->set_x( c_left ).
  ENDMETHOD.

  METHOD chart.
    DATA ls_total TYPE ty_group_total.
    DATA lv_max TYPE p LENGTH 13 DECIMALS 2.
    DATA lv_width TYPE f.

    LOOP AT it_totals INTO ls_total.
      IF ls_total-value > lv_max.
        lv_max = ls_total-value.
      ENDIF.
    ENDLOOP.

    io_pdf->check_page_break( 110 ).
    io_pdf->set_x( c_left ).
    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 10 ).
    io_pdf->cell( iv_text = 'Net value per product group' iv_height = 18 ).

    DATA(lv_y) = io_pdf->get_y( ) + 4.
    LOOP AT it_totals INTO ls_total.
      io_pdf->set_font( iv_name = 'Helvetica' iv_size = 8 ).
      io_pdf->set_xy( iv_x = c_left iv_y = lv_y ).
      io_pdf->cell( iv_text = ls_total-group iv_width = 150 iv_height = 14 iv_ln = abap_false ).

      lv_width = 220 * ls_total-value / lv_max.
      io_pdf->set_fill_color( iv_r = 0 iv_g = 92 iv_b = 158 ).
      io_pdf->rect(
        iv_x      = c_left + 155
        iv_y      = lv_y + 3
        iv_width  = lv_width
        iv_height = 8
        iv_style  = 'F' ).

      io_pdf->set_xy( iv_x = c_left + 155 + lv_width + 6 iv_y = lv_y ).
      io_pdf->cell(
        iv_text   = |{ amount( ls_total-value ) } EUR|
        iv_width  = 90
        iv_height = 14 ).

      lv_y = lv_y + 15.
    ENDLOOP.

    io_pdf->set_xy( iv_x = c_left iv_y = lv_y + 6 ).
  ENDMETHOD.

  METHOD terms.
    DATA(lv_y) = io_pdf->get_y( ).

    io_pdf->check_page_break( 130 ).
    lv_y = io_pdf->get_y( ).

    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 10 ).
    io_pdf->set_x( c_left ).
    io_pdf->cell( iv_text = 'Terms and conditions' iv_height = 18 ).
    lv_y = io_pdf->get_y( ).

    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 7 ).
    io_pdf->set_xy( iv_x = c_left iv_y = lv_y ).
    io_pdf->multi_cell(
      iv_text   = `Prices are net, excluding value added tax. Delivery takes place from our ` &&
                  `warehouse in Duesseldorf. Retention of title applies until full payment ` &&
                  `has been received. Complaints about visible defects have to be reported ` &&
                  `within eight working days after receipt of the goods.`
      iv_width  = 245
      iv_height = 10 ).

    io_pdf->set_xy( iv_x = c_left + 260 iv_y = lv_y ).
    io_pdf->multi_cell(
      iv_text   = `The place of jurisdiction is Duesseldorf. German law applies. Packaging ` &&
                  `is taken back according to the packaging act. Our general terms of sale ` &&
                  `in the version of January 2026 are part of this confirmation and are ` &&
                  `available on request.`
      iv_width  = 245
      iv_height = 10 ).
  ENDMETHOD.

  METHOD signatures.
    io_pdf->check_page_break( 46 ).

    DATA(lv_y) = io_pdf->get_y( ) + 26.
    io_pdf->set_draw_color( iv_r = 90 iv_g = 90 iv_b = 90 ).
    io_pdf->line( iv_x1 = c_left iv_y1 = lv_y iv_x2 = c_left + 160 iv_y2 = lv_y ).
    io_pdf->line(
      iv_x1 = io_pdf->get_page_width( ) - c_left - 160
      iv_y1 = lv_y
      iv_x2 = io_pdf->get_page_width( ) - c_left
      iv_y2 = lv_y ).

    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 7 ).
    io_pdf->set_xy( iv_x = c_left iv_y = lv_y + 2 ).
    io_pdf->cell( iv_text = 'Elektronik Grosshandel GmbH' iv_width = 160 iv_height = 11 ).
    io_pdf->set_xy( iv_x = io_pdf->get_page_width( ) - c_left - 160 iv_y = lv_y + 2 ).
    io_pdf->cell( iv_text = 'Confirmed by the customer' iv_width = 160 iv_height = 11 ).
  ENDMETHOD.

  METHOD run_base64.
    gv_watermark = abap_true.

    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->set_layout( NEW zcl_pdf_demo_complex( ) ).
    lo_pdf->set_margins( iv_left = c_left iv_top = 45 iv_right = c_left iv_bottom = 45 ).
    lo_pdf->set_auto_page_break( iv_active = abap_true iv_margin = 62 ).
    lo_pdf->set_line_height( 12 ).
    lo_pdf->add_page( ).

    letterhead( lo_pdf ).
    info_grid( lo_pdf ).
    DATA(lt_totals) = item_table( lo_pdf ).

    totals( io_pdf = lo_pdf it_totals = lt_totals ).
    lo_pdf->ln( 18 ).
    chart( io_pdf = lo_pdf it_totals = lt_totals ).
    terms( lo_pdf ).
    signatures( lo_pdf ).

    rv_base64 = cl_http_utility=>encode_x_base64( lo_pdf->render_binary( ) ).
  ENDMETHOD.

ENDCLASS.
