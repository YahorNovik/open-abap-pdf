CLASS zcl_pdf_bench DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    CLASS-METHODS run
      IMPORTING iv_rows       TYPE i
                iv_compress   TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(rv_out) TYPE string.
ENDCLASS.

CLASS zcl_pdf_bench IMPLEMENTATION.

  METHOD run.
    DATA lv_i TYPE i.

    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->set_compression( iv_compress ).
    lo_pdf->set_margins( iv_left = 40 iv_top = 40 iv_right = 40 iv_bottom = 40 ).
    lo_pdf->add_page( ).

    DATA(lo_table) = zcl_open_abap_pdf_table=>create( lo_pdf ).
    lo_table->set_line_height( 11 ).
    lo_table->set_body_style( iv_font = 'Helvetica' iv_size = 8 ).
    lo_table->add_column( iv_header = 'Pos' iv_width = 34 iv_align = 'R' ).
    lo_table->add_column( iv_header = 'Material' iv_width = 70 ).
    lo_table->add_column( iv_header = 'Description' ).
    lo_table->add_column( iv_header = 'Qty' iv_width = 40 iv_align = 'R' ).
    lo_table->add_column( iv_header = 'Value' iv_width = 70 iv_align = 'R' ).

    DO iv_rows TIMES.
      lv_i = sy-index.
      lo_table->add_row( VALUE #(
        ( |{ lv_i * 10 }| )
        ( |M-{ 100000 + lv_i }| )
        ( |Material description of item { lv_i }, warehouse 0001, batch B{ lv_i }| )
        ( |{ lv_i MOD 97 + 1 } PC| )
        ( |{ lv_i * 17 } EUR| ) ) ).
    ENDDO.

    lo_table->render( ).

    rv_out = |{ lo_pdf->get_page_count( ) };{ xstrlen( lo_pdf->render_binary( ) ) }|.
  ENDMETHOD.

ENDCLASS.
