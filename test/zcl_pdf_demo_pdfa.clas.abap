CLASS zcl_pdf_demo_pdfa DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_open_abap_pdf_layout.

    "! Archive copy of an invoice as PDF/A-1b
    "! @parameter iv_ttf | Font file, PDF/A requires every font to be embedded
    CLASS-METHODS run_base64
      IMPORTING iv_ttf           TYPE xstring
      RETURNING VALUE(rv_base64) TYPE string
      RAISING   zcx_open_abap_pdf.

    "! Same document, but with a Base-14 font, which PDF/A does not allow
    CLASS-METHODS run_violation
      IMPORTING iv_ttf            TYPE xstring
      RETURNING VALUE(rv_problem) TYPE string.

  PRIVATE SECTION.
    CONSTANTS c_font TYPE string VALUE 'ArchiveSans'.
    CONSTANTS c_left TYPE f VALUE 45.

    CLASS-METHODS build
      IMPORTING iv_ttf        TYPE xstring
                iv_break_rule TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf
      RAISING   zcx_open_abap_pdf.
ENDCLASS.

CLASS zcl_pdf_demo_pdfa IMPLEMENTATION.

  METHOD zif_open_abap_pdf_layout~header.
    RETURN.
  ENDMETHOD.

  METHOD zif_open_abap_pdf_layout~footer.
    DATA(lv_y) = io_pdf->get_y( ).

    io_pdf->set_y( io_pdf->get_page_height( ) - 50 ).
    io_pdf->set_font( iv_name = c_font iv_size = 8 ).
    io_pdf->set_text_color( iv_r = 120 iv_g = 120 iv_b = 120 ).
    io_pdf->cell(
      iv_text   = |Archive copy, PDF/A-1b   -   page { io_pdf->get_page_number( ) } of \{nb\}|
      iv_align  = zcl_open_abap_pdf=>c_align_center
      iv_border = 'T' ).
    io_pdf->set_text_color( iv_r = 0 iv_g = 0 iv_b = 0 ).
    io_pdf->set_y( lv_y ).
  ENDMETHOD.

  METHOD build.
    DATA lv_i TYPE i.
    DATA lv_value TYPE p LENGTH 11 DECIMALS 2.
    DATA lv_total TYPE p LENGTH 13 DECIMALS 2.

    ro_pdf = zcl_open_abap_pdf=>create( ).
    ro_pdf->register_font( iv_name = c_font iv_data = iv_ttf ).
    ro_pdf->set_pdfa(
      iv_icc    = zcl_pdf_test_icc=>srgb( )
      iv_title  = 'Invoice 90001234'
      iv_author = 'Elektronik Grosshandel GmbH' ).
    ro_pdf->set_compression( ).
    ro_pdf->set_layout( NEW zcl_pdf_demo_pdfa( ) ).
    ro_pdf->set_margins( iv_left = c_left iv_top = 45 iv_right = c_left iv_bottom = 45 ).

    " The first page states the current font, so it has to be the embedded one
    ro_pdf->set_font( iv_name = c_font iv_size = 9 ).
    ro_pdf->add_page( ).

    ro_pdf->set_font( iv_name = c_font iv_size = 15 ).
    ro_pdf->cell( iv_text = 'Invoice 90001234' iv_height = 24 ).

    ro_pdf->set_font( iv_name = c_font iv_size = 9 ).
    ro_pdf->multi_cell(
      iv_text   = `This document is meant for long term archiving. Every font is embedded, ` &&
                  `the colours refer to an sRGB output intent, and the metadata declares the ` &&
                  `conformance level, so the file can still be reproduced in ten years.`
      iv_height = 12 ).
    ro_pdf->ln( 10 ).

    DATA(lo_table) = zcl_open_abap_pdf_table=>create( ro_pdf ).
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
    lo_table->add_column( iv_header = 'Material' iv_width = 70 ).
    lo_table->add_column( iv_header = 'Description' ).
    lo_table->add_column( iv_header = 'Value' iv_width = 80 iv_align = zcl_open_abap_pdf=>c_align_right ).

    DO 6 TIMES.
      lv_i = sy-index.
      lv_value = lv_i * '148.75'.
      lv_total = lv_total + lv_value.
      lo_table->add_row( VALUE #(
        ( |{ lv_i * 10 }| )
        ( |M-{ 100000 + lv_i }| )
        ( |Position { lv_i } with an umlaut in Gr{ cl_abap_conv_in_ce=>uccp( '00F6' ) }{ cl_abap_conv_in_ce=>uccp( '00DF' ) }e| )
        ( |{ lv_value } EUR| ) ) ).
    ENDDO.

    lo_table->add_row(
      it_cells = VALUE #( ( '' ) ( '' ) ( 'Total net' ) ( |{ lv_total } EUR| ) )
      iv_bold  = abap_true ).
    lo_table->render( ).

    IF iv_break_rule = abap_true.
      " A Base-14 font is not embedded, so this must be reported
      ro_pdf->set_font( iv_name = 'Helvetica' iv_size = 9 ).
      ro_pdf->ln( 16 ).
      ro_pdf->cell( iv_text = 'This line uses a font that is not embedded' ).
    ENDIF.
  ENDMETHOD.

  METHOD run_base64.
    rv_base64 = cl_http_utility=>encode_x_base64( build( iv_ttf )->render_pdfa( ) ).
  ENDMETHOD.

  METHOD run_violation.
    TRY.
        build( iv_ttf = iv_ttf iv_break_rule = abap_true )->render_pdfa( ).
        rv_problem = 'no problem reported'.
      CATCH zcx_open_abap_pdf INTO DATA(lx_error).
        rv_problem = lx_error->mv_text.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
