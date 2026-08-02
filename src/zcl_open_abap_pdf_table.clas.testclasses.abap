CLASS ltcl_table DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    METHODS columns_share_width FOR TESTING RAISING cx_static_check.
    METHODS header_and_rows FOR TESTING RAISING cx_static_check.
    METHODS header_repeats_on_break FOR TESTING RAISING cx_static_check.
    METHODS row_grows_with_wrapped_text FOR TESTING RAISING cx_static_check.
    METHODS cursor_returns_to_left FOR TESTING RAISING cx_static_check.
    METHODS span_row FOR TESTING RAISING cx_static_check.
    METHODS keep_with_next FOR TESTING RAISING cx_static_check.
    METHODS header_text_color FOR TESTING RAISING cx_static_check.

    METHODS given_pdf
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.
ENDCLASS.

CLASS ltcl_table IMPLEMENTATION.

  METHOD span_row.
    DATA(lo_pdf) = given_pdf( ).

    zcl_open_abap_pdf_table=>create( lo_pdf
      )->add_column( iv_header = 'A' iv_width = 100
      )->add_column( iv_header = 'B' iv_width = 100
      )->add_span_row( iv_text = 'Group one'
      )->add_row( VALUE #( ( '1' ) ( '2' ) )
      )->render( ).

    " One box over both columns, so 200 points wide
    cl_abap_unit_assert=>assert_char_cp(
      act = lo_pdf->render( )
      exp = '*40 * 200 *re*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lo_pdf->render( ) exp = '*(Group one)*' ).
  ENDMETHOD.

  METHOD keep_with_next.
    DATA(lo_pdf) = given_pdf( ).
    DATA(lo_table) = zcl_open_abap_pdf_table=>create( lo_pdf ).
    lo_table->set_line_height( 14 ).
    lo_table->add_column( iv_header = 'Text' ).

    " Fill the page so that the group header would land at the very bottom
    DO 50 TIMES.
      lo_table->add_row( VALUE #( ( |row { sy-index }| ) ) ).
    ENDDO.
    lo_table->add_span_row( iv_text = 'Group at the page end' ).
    lo_table->add_row( VALUE #( ( 'first row of the group' ) ) ).
    lo_table->render( ).

    DATA(lv_pdf) = lo_pdf->render( ).
    DATA(lv_header_page) = 0.
    DATA(lv_row_page) = 0.

    SPLIT lv_pdf AT 'stream' INTO TABLE DATA(lt_streams).
    LOOP AT lt_streams INTO DATA(lv_stream).
      IF lv_stream CS '(Group at the page end)'.
        lv_header_page = sy-tabix.
      ENDIF.
      IF lv_stream CS '(first row of the group)'.
        lv_row_page = sy-tabix.
      ENDIF.
    ENDLOOP.

    cl_abap_unit_assert=>assert_equals(
      act = lv_row_page
      exp = lv_header_page
      msg = 'a group header must stay on the page of its first row' ).
  ENDMETHOD.

  METHOD header_text_color.
    DATA(lo_pdf) = given_pdf( ).

    zcl_open_abap_pdf_table=>create( lo_pdf
      )->set_header_style( iv_r = 0 iv_g = 51 iv_b = 102
                           iv_text_r = 255 iv_text_g = 255 iv_text_b = 255
      )->add_column( iv_header = 'Material'
      )->add_row( VALUE #( ( 'M-1' ) )
      )->render( ).

    DATA(lv_pdf) = lo_pdf->render( ).

    " White header text, black body text again afterwards
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*1 1 1 rg*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*0 0.2 0.4 rg*' ).
  ENDMETHOD.

  METHOD given_pdf.
    ro_pdf = zcl_open_abap_pdf=>create( ).
    ro_pdf->set_margins( iv_left = 40 iv_top = 40 iv_right = 40 iv_bottom = 40 ).
    ro_pdf->add_page( ).
  ENDMETHOD.

  METHOD columns_share_width.
    DATA(lo_pdf) = given_pdf( ).
    DATA(lv_before) = lo_pdf->get_y( ).

    zcl_open_abap_pdf_table=>create( lo_pdf
      )->add_column( iv_header = 'A' iv_width = 100
      )->add_column( iv_header = 'B'
      )->add_column( iv_header = 'C'
      )->add_row( VALUE #( ( '1' ) ( '2' ) ( '3' ) )
      )->render( ).

    cl_abap_unit_assert=>assert_equals(
      act = lo_pdf->get_x( )
      exp = 40
      msg = 'cursor is back at the left margin' ).
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( lo_pdf->get_y( ) > lv_before )
      msg = 'table advances the cursor' ).
  ENDMETHOD.

  METHOD header_and_rows.
    DATA(lo_pdf) = given_pdf( ).

    zcl_open_abap_pdf_table=>create( lo_pdf
      )->add_column( iv_header = 'Material'
      )->add_column( iv_header = 'Quantity'
      )->add_row( VALUE #( ( 'M-1' ) ( '5 PC' ) )
      )->add_row( VALUE #( ( 'M-2' ) ( '7 PC' ) )
      )->render( ).

    DATA(lv_pdf) = lo_pdf->render( ).

    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*(Material)*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*(M-1)*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*(7 PC)*' ).
  ENDMETHOD.

  METHOD header_repeats_on_break.
    DATA lv_offset TYPE i.
    DATA lv_count TYPE i.

    DATA(lo_pdf) = given_pdf( ).
    DATA(lo_table) = zcl_open_abap_pdf_table=>create( lo_pdf ).
    lo_table->add_column( iv_header = 'ItemHeader' ).

    DO 80 TIMES.
      lo_table->add_row( VALUE #( ( |row { sy-index }| ) ) ).
    ENDDO.
    lo_table->render( ).

    cl_abap_unit_assert=>assert_true(
      act = xsdbool( lo_pdf->get_page_count( ) > 1 )
      msg = '80 rows must not fit on a single page' ).

    DATA(lv_pdf) = lo_pdf->render( ).
    WHILE lv_offset < strlen( lv_pdf ).
      FIND FIRST OCCURRENCE OF '(ItemHeader)' IN SECTION OFFSET lv_offset OF lv_pdf
        MATCH OFFSET DATA(lv_found).
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.
      lv_count = lv_count + 1.
      lv_offset = lv_found + 1.
    ENDWHILE.

    cl_abap_unit_assert=>assert_equals(
      act = lv_count
      exp = lo_pdf->get_page_count( )
      msg = 'the header row repeats on every page' ).
  ENDMETHOD.

  METHOD row_grows_with_wrapped_text.
    DATA(lo_pdf) = given_pdf( ).
    DATA(lv_before) = lo_pdf->get_y( ).

    zcl_open_abap_pdf_table=>create( lo_pdf
      )->set_line_height( 12
      )->add_column( iv_header = 'Text' iv_width = 80
      )->add_row( VALUE #( ( 'a very long cell text that needs at least three lines in eighty points' ) )
      )->render( ).

    " header line plus at least three wrapped lines
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( lo_pdf->get_y( ) - lv_before >= 4 * 12 )
      msg = 'row height follows the number of wrapped lines' ).
  ENDMETHOD.

  METHOD cursor_returns_to_left.
    DATA(lo_pdf) = given_pdf( ).
    lo_pdf->set_x( 60 ).

    zcl_open_abap_pdf_table=>create( lo_pdf
      )->add_column( iv_header = 'A' iv_width = 50
      )->add_column( iv_header = 'B' iv_width = 50
      )->add_row( VALUE #( ( '1' ) ( '2' ) )
      )->render( ).

    cl_abap_unit_assert=>assert_equals(
      act = lo_pdf->get_x( )
      exp = 60
      msg = 'the table keeps the x it started from' ).
  ENDMETHOD.

ENDCLASS.
