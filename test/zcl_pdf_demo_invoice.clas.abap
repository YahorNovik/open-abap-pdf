CLASS zcl_pdf_demo_invoice DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_open_abap_pdf_layout.

    TYPES:
      BEGIN OF ty_item,
        posnr TYPE i,
        text  TYPE string,
        unit  TYPE string,
        qty   TYPE i,
        net   TYPE p LENGTH 9 DECIMALS 2,
        rate  TYPE i,
      END OF ty_item,
      ty_items TYPE STANDARD TABLE OF ty_item WITH DEFAULT KEY.

    CLASS-METHODS run_base64
      RETURNING VALUE(rv_base64) TYPE string
      RAISING   zcx_open_abap_pdf.

  PRIVATE SECTION.
    CONSTANTS c_left TYPE f VALUE 40.

    CLASS-METHODS items
      RETURNING VALUE(rt_items) TYPE ty_items.

    CLASS-METHODS amount
      IMPORTING iv_value       TYPE p
      RETURNING VALUE(rv_text) TYPE string.

    CLASS-METHODS block
      IMPORTING io_pdf   TYPE REF TO zcl_open_abap_pdf
                iv_x     TYPE f
                iv_y     TYPE f
                iv_title TYPE string
                it_lines TYPE zcl_open_abap_pdf_font=>ty_lines.

    CLASS-METHODS label_value
      IMPORTING io_pdf  TYPE REF TO zcl_open_abap_pdf
                iv_x    TYPE f
                iv_y    TYPE f
                iv_text TYPE string
                iv_bold TYPE abap_bool DEFAULT abap_false.
ENDCLASS.

CLASS zcl_pdf_demo_invoice IMPLEMENTATION.

  METHOD zif_open_abap_pdf_layout~header.
    RETURN.
  ENDMETHOD.

  METHOD zif_open_abap_pdf_layout~footer.
    DATA(lv_y) = io_pdf->get_y( ).

    io_pdf->set_y( io_pdf->get_page_height( ) - 90 ).
    io_pdf->set_draw_color( iv_r = 90 iv_g = 90 iv_b = 90 ).
    io_pdf->line(
      iv_x1 = c_left + 20
      iv_y1 = io_pdf->get_y( )
      iv_x2 = c_left + 170
      iv_y2 = io_pdf->get_y( ) ).
    io_pdf->line(
      iv_x1 = io_pdf->get_page_width( ) - 190
      iv_y1 = io_pdf->get_y( )
      iv_x2 = io_pdf->get_page_width( ) - 40
      iv_y2 = io_pdf->get_y( ) ).

    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 9 ).
    io_pdf->set_xy( iv_x = c_left + 20 iv_y = io_pdf->get_page_height( ) - 118 ).
    io_pdf->cell( iv_text = 'Janusz Nowak' iv_width = 150 iv_align = zcl_open_abap_pdf=>c_align_center ).

    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 7 ).
    io_pdf->set_xy( iv_x = c_left + 20 iv_y = io_pdf->get_page_height( ) - 86 ).
    io_pdf->multi_cell(
      iv_text   = |Imie i nazwisko osoby uprawnionej\ndo wystawienia faktury|
      iv_width  = 150
      iv_height = 10
      iv_align  = zcl_open_abap_pdf=>c_align_center ).

    io_pdf->set_xy( iv_x = io_pdf->get_page_width( ) - 190 iv_y = io_pdf->get_page_height( ) - 86 ).
    io_pdf->multi_cell(
      iv_text   = |Imie i nazwisko osoby uprawnionej\ndo odbioru faktury|
      iv_width  = 150
      iv_height = 10
      iv_align  = zcl_open_abap_pdf=>c_align_center ).

    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 9 ).
    io_pdf->set_y( lv_y ).
  ENDMETHOD.

  METHOD items.
    rt_items = VALUE ty_items(
      ( posnr = 1 text = 'Procesor MD1' unit = 'szt.' qty = 15 net = '200.00' rate = 23 )
      ( posnr = 2 text = 'Procesor MD2' unit = 'szt.' qty = 10 net = '250.00' rate = 23 )
      ( posnr = 3 text = 'Procesor MD3' unit = 'szt.' qty = 5 net = '350.00' rate = 23 )
      ( posnr = 4 text = 'Procesor IL2' unit = 'szt.' qty = 10 net = '300.00' rate = 23 )
      ( posnr = 5 text = 'Plyta glowna C34' unit = 'szt.' qty = 5 net = '150.00' rate = 23 )
      ( posnr = 6 text = 'Plyta glowna B45' unit = 'szt.' qty = 5 net = '200.00' rate = 23 )
      ( posnr = 7 text = 'Plyta glowna A65' unit = 'szt.' qty = 2 net = '300.00' rate = 23 ) ).
  ENDMETHOD.

  METHOD amount.
    DATA lv_int TYPE string.
    DATA lv_dec TYPE string.
    DATA lv_group TYPE string.
    DATA lv_offset TYPE i.

    " 1234.5 becomes 1 234,50, the Polish notation of the original invoice
    SPLIT |{ iv_value DECIMALS = 2 }| AT '.' INTO lv_int lv_dec.

    WHILE strlen( lv_int ) > 3.
      lv_offset = strlen( lv_int ) - 3.
      lv_group = |{ lv_int+lv_offset(3) } { lv_group }|.
      lv_int = lv_int(lv_offset).
    ENDWHILE.

    rv_text = condense( |{ lv_int } { lv_group }| ) && |,{ lv_dec }|.
  ENDMETHOD.

  METHOD block.
    DATA lv_line TYPE string.

    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 9 ).
    io_pdf->set_xy( iv_x = iv_x iv_y = iv_y ).
    io_pdf->cell( iv_text = iv_title iv_width = 240 iv_height = 14 ).

    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 9 ).
    LOOP AT it_lines INTO lv_line.
      io_pdf->set_x( iv_x ).
      io_pdf->cell( iv_text = lv_line iv_width = 240 iv_height = 13 ).
    ENDLOOP.
  ENDMETHOD.

  METHOD label_value.
    io_pdf->set_font(
      iv_name = COND string( WHEN iv_bold = abap_true THEN 'Helvetica-Bold' ELSE 'Helvetica' )
      iv_size = 9 ).
    io_pdf->set_xy( iv_x = iv_x iv_y = iv_y ).
    io_pdf->cell( iv_text = iv_text iv_width = 150 iv_height = 14 iv_ln = abap_false ).
  ENDMETHOD.

  METHOD run_base64.
    DATA ls_item TYPE ty_item.
    DATA lv_net TYPE p LENGTH 11 DECIMALS 2.
    DATA lv_gross TYPE p LENGTH 11 DECIMALS 2.
    DATA lv_total_net TYPE p LENGTH 11 DECIMALS 2.
    DATA lv_total_vat TYPE p LENGTH 11 DECIMALS 2.
    DATA lv_total_gross TYPE p LENGTH 11 DECIMALS 2.

    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->set_layout( NEW zcl_pdf_demo_invoice( ) ).
    lo_pdf->set_margins( iv_left = c_left iv_top = 40 iv_right = 40 iv_bottom = 40 ).
    lo_pdf->set_auto_page_break( iv_active = abap_true iv_margin = 130 ).
    lo_pdf->add_page( ).

    " Logo and company name
    lo_pdf->image_base64(
      iv_base64 = zcl_pdf_test_images=>logo( )
      iv_x      = c_left + 8
      iv_y      = 42
      iv_width  = 34 ).
    lo_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 26 ).
    lo_pdf->set_xy( iv_x = c_left + 50 iv_y = 44 ).
    lo_pdf->cell( iv_text = 'Twoje logo' iv_width = 200 iv_height = 32 ).

    " Document head on the right
    DATA(lv_right) = 300.
    lo_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 10 ).
    lo_pdf->set_xy( iv_x = lv_right iv_y = 44 ).
    lo_pdf->cell(
      iv_text  = 'Faktura nr FV 1/2015'
      iv_width = 215
      iv_align = zcl_open_abap_pdf=>c_align_center ).

    label_value( io_pdf = lo_pdf iv_x = lv_right iv_y = 70 iv_text = 'Data wystawienia:  2015-01-01' ).
    label_value( io_pdf = lo_pdf iv_x = lv_right + 130 iv_y = 70 iv_text = 'Data sprzedazy:  2015-01-01' ).
    label_value( io_pdf = lo_pdf iv_x = lv_right iv_y = 92 iv_text = 'Termin platnosci:  2015-01-14' ).
    label_value( io_pdf = lo_pdf iv_x = lv_right + 130 iv_y = 92 iv_text = 'Metoda platnosci:  przelew' ).

    " Seller and buyer
    block(
      io_pdf   = lo_pdf
      iv_x     = c_left
      iv_y     = 150
      iv_title = 'Sprzedawca'
      it_lines = VALUE #(
        ( 'Hurtownia Elektroniki Sp. z o.o.' )
        ( 'Boleslawa Chrobrego 10' )
        ( '50-254 Wroclaw' )
        ( 'NIP: 8982167294' )
        ( 'numer konta' )
        ( '59 1111 2222 3333 4444 5555 6666' ) ) ).

    block(
      io_pdf   = lo_pdf
      iv_x     = 300
      iv_y     = 150
      iv_title = 'Nabywca'
      it_lines = VALUE #(
        ( 'Sklep Komputerowy Sebastian Kowalski' )
        ( 'Legnicka 256' )
        ( '54-206 Wroclaw' )
        ( 'NIP: 9151677484' ) ) ).

    " Item table
    lo_pdf->set_xy( iv_x = c_left iv_y = 290 ).
    DATA(lo_table) = zcl_open_abap_pdf_table=>create( lo_pdf ).
    lo_table->set_line_height( 12 ).
    lo_table->set_padding( 2 ).
    lo_table->set_header_style( iv_font = 'Helvetica' iv_size = 8 iv_r = 255 iv_g = 255 iv_b = 255 ).
    lo_table->set_body_style( iv_font = 'Helvetica' iv_size = 8 ).
    lo_table->add_column( iv_header = 'Lp' iv_width = 18 iv_align = zcl_open_abap_pdf=>c_align_right ).
    lo_table->add_column( iv_header = 'Nazwa' iv_header_align = zcl_open_abap_pdf=>c_align_center ).
    lo_table->add_column( iv_header = 'Jedn' iv_width = 32 iv_align = zcl_open_abap_pdf=>c_align_center ).
    lo_table->add_column( iv_header = 'Ilosc' iv_width = 34 iv_align = zcl_open_abap_pdf=>c_align_right ).
    lo_table->add_column( iv_header = 'Cena netto' iv_width = 62 iv_align = zcl_open_abap_pdf=>c_align_right ).
    lo_table->add_column( iv_header = 'Stawka' iv_width = 40 iv_align = zcl_open_abap_pdf=>c_align_right ).
    lo_table->add_column( iv_header = 'Wartosc netto' iv_width = 70 iv_align = zcl_open_abap_pdf=>c_align_right ).
    lo_table->add_column( iv_header = 'Wartosc brutto' iv_width = 72 iv_align = zcl_open_abap_pdf=>c_align_right ).

    LOOP AT items( ) INTO ls_item.
      lv_net = ls_item-qty * ls_item-net.
      lv_gross = lv_net * ( 100 + ls_item-rate ) / 100.
      lv_total_net = lv_total_net + lv_net.
      lv_total_gross = lv_total_gross + lv_gross.

      lo_table->add_row( VALUE #(
        ( |{ ls_item-posnr }| )
        ( ls_item-text )
        ( ls_item-unit )
        ( |{ ls_item-qty }| )
        ( amount( ls_item-net ) )
        ( |{ ls_item-rate }%| )
        ( amount( lv_net ) )
        ( amount( lv_gross ) ) ) ).
    ENDLOOP.
    lo_table->render( ).

    lv_total_vat = lv_total_gross - lv_total_net.

    " VAT summary on the left
    DATA(lv_summary_y) = lo_pdf->get_y( ) + 16.
    lo_pdf->set_xy( iv_x = c_left iv_y = lv_summary_y ).
    DATA(lo_vat) = zcl_open_abap_pdf_table=>create( lo_pdf ).
    lo_vat->set_line_height( 12 ).
    lo_vat->set_header_style( iv_font = 'Helvetica' iv_size = 8 iv_r = 255 iv_g = 255 iv_b = 255 ).
    lo_vat->set_body_style( iv_font = 'Helvetica' iv_size = 8 ).
    lo_vat->add_column( iv_header = 'Stawka VAT' iv_width = 60 iv_align = zcl_open_abap_pdf=>c_align_center ).
    lo_vat->add_column( iv_header = 'Wartosc netto' iv_width = 70 iv_align = zcl_open_abap_pdf=>c_align_right ).
    lo_vat->add_column( iv_header = 'Kwota VAT' iv_width = 62 iv_align = zcl_open_abap_pdf=>c_align_right ).
    lo_vat->add_column( iv_header = 'Wartosc brutto' iv_width = 70 iv_align = zcl_open_abap_pdf=>c_align_right ).
    lo_vat->add_row( VALUE #(
      ( '23%' )
      ( amount( lv_total_net ) )
      ( amount( lv_total_vat ) )
      ( amount( lv_total_gross ) ) ) ).
    lo_vat->add_row(
      it_cells = VALUE #(
        ( 'Razem' )
        ( amount( lv_total_net ) )
        ( amount( lv_total_vat ) )
        ( amount( lv_total_gross ) ) )
      iv_bold  = abap_true ).
    lo_vat->render( ).

    " Payment summary on the right
    label_value( io_pdf = lo_pdf iv_x = 330 iv_y = lv_summary_y + 14 iv_text = 'Zaplacono' ).
    label_value(
      io_pdf  = lo_pdf
      iv_x    = 430
      iv_y    = lv_summary_y + 14
      iv_text = '0,00 PLN' ).
    label_value(
      io_pdf  = lo_pdf
      iv_x    = 330
      iv_y    = lv_summary_y + 30
      iv_text = 'Do zaplaty'
      iv_bold = abap_true ).
    label_value(
      io_pdf  = lo_pdf
      iv_x    = 430
      iv_y    = lv_summary_y + 30
      iv_text = |{ amount( lv_total_gross ) } PLN|
      iv_bold = abap_true ).
    label_value( io_pdf = lo_pdf iv_x = 330 iv_y = lv_summary_y + 46 iv_text = 'Razem' ).
    label_value(
      io_pdf  = lo_pdf
      iv_x    = 430
      iv_y    = lv_summary_y + 46
      iv_text = |{ amount( lv_total_gross ) } PLN| ).

    lo_pdf->set_font( iv_name = 'Helvetica' iv_size = 8 ).
    lo_pdf->set_xy( iv_x = 330 iv_y = lv_summary_y + 62 ).
    lo_pdf->multi_cell(
      iv_text   = |Slownie\npietnascie tysiecy czterysta dziewiecdziesiat osiem zlotych 0/100|
      iv_width  = 225
      iv_height = 11
      iv_align  = zcl_open_abap_pdf=>c_align_right ).

    " Remarks
    lo_pdf->set_xy( iv_x = c_left iv_y = lv_summary_y + 46 ).
    lo_pdf->set_font( iv_name = 'Helvetica' iv_size = 8 ).
    lo_pdf->multi_cell(
      iv_text   = |Uwagi:\nW tytule przelewu prosimy podac numer zamowienia 345425.|
      iv_width  = 280
      iv_height = 12 ).

    rv_base64 = cl_http_utility=>encode_x_base64( lo_pdf->render_binary( ) ).
  ENDMETHOD.

ENDCLASS.
