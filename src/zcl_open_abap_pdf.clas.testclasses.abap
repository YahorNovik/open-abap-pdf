CLASS ltcl_form DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    METHODS text_field FOR TESTING RAISING cx_static_check.
    METHODS text_field_flags FOR TESTING RAISING cx_static_check.
    METHODS checkbox FOR TESTING RAISING cx_static_check.
    METHODS dropdown FOR TESTING RAISING cx_static_check.
    METHODS radio_group FOR TESTING RAISING cx_static_check.
    METHODS flatten FOR TESTING RAISING cx_static_check.
    METHODS no_acroform_without_fields FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_form IMPLEMENTATION.

  METHOD text_field.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->add_page( ).
    lo_pdf->text_field(
      iv_name  = 'EMPLOYEE'
      iv_x     = 100
      iv_y     = 200
      iv_width = 150
      iv_value = 'Lars Hvam' ).

    DATA(lv_pdf) = lo_pdf->render( ).

    cl_abap_unit_assert=>assert_equals( act = lo_pdf->get_field_count( ) exp = 1 ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/AcroForm*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/NeedAppearances true*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/FT /Tx /T (EMPLOYEE)*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/V (Lars Hvam)*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/Annots [*' ).

    " Rect is measured from the bottom of the page
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/Rect [100 623.89 250 641.89]*' ).
  ENDMETHOD.

  METHOD text_field_flags.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->add_page( ).
    lo_pdf->text_field(
      iv_name      = 'NOTE'
      iv_x         = 10
      iv_y         = 10
      iv_width     = 100
      iv_multiline = abap_true
      iv_required  = abap_true
      iv_max_len   = 40
      iv_align     = 2 ).

    DATA(lv_pdf) = lo_pdf->render( ).

    " multiline 4096 plus required 2
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/Ff 4098*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/MaxLen 40*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/Q 2*' ).
  ENDMETHOD.

  METHOD checkbox.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->add_page( ).
    lo_pdf->checkbox( iv_name = 'ADVANCE' iv_x = 10 iv_y = 10 iv_checked = abap_true ).
    lo_pdf->checkbox( iv_name = 'URGENT' iv_x = 40 iv_y = 10 ).

    DATA(lv_pdf) = lo_pdf->render( ).

    cl_abap_unit_assert=>assert_equals( act = lo_pdf->get_field_count( ) exp = 2 ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/T (ADVANCE) /V /Yes /AS /Yes*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/T (URGENT) /V /Off /AS /Off*' ).
  ENDMETHOD.

  METHOD dropdown.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->add_page( ).
    lo_pdf->dropdown(
      iv_name    = 'PLANT'
      it_options = VALUE #( ( '1000' ) ( '2000' ) )
      iv_x       = 10
      iv_y       = 10
      iv_width   = 100
      iv_value   = '2000' ).

    DATA(lv_pdf) = lo_pdf->render( ).

    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/FT /Ch /T (PLANT)*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/Opt [(1000) (2000) ]*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/Ff 131072*' ).
  ENDMETHOD.

  METHOD radio_group.
    DATA lv_offset TYPE i.
    DATA lv_kids TYPE i.

    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->add_page( ).
    lo_pdf->radio_button(
      iv_name     = 'LEVEL'
      iv_value    = 'Manager'
      iv_x        = 10
      iv_y        = 10
      iv_selected = abap_true ).
    lo_pdf->radio_button( iv_name = 'LEVEL' iv_value = 'Director' iv_x = 60 iv_y = 10 ).

    DATA(lv_pdf) = lo_pdf->render( ).

    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/Ff 32768 /T (LEVEL) /V /Manager /Kids [*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/AS /Manager*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/AS /Off*' ).

    WHILE lv_offset < strlen( lv_pdf ).
      FIND FIRST OCCURRENCE OF '/Parent' IN SECTION OFFSET lv_offset OF lv_pdf
        MATCH OFFSET DATA(lv_found).
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.
      lv_kids = lv_kids + 1.
      lv_offset = lv_found + 1.
    ENDWHILE.

    cl_abap_unit_assert=>assert_equals(
      act = lv_kids
      exp = 3
      msg = 'two radio kids plus the parent reference of the page tree' ).
  ENDMETHOD.

  METHOD flatten.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->set_flatten_form( ).
    lo_pdf->add_page( ).
    lo_pdf->text_field(
      iv_name  = 'EMPLOYEE'
      iv_x     = 10
      iv_y     = 10
      iv_width = 100
      iv_value = 'Lars Hvam' ).
    lo_pdf->checkbox( iv_name = 'ADVANCE' iv_x = 10 iv_y = 40 iv_checked = abap_true ).

    DATA(lv_pdf) = lo_pdf->render( ).

    cl_abap_unit_assert=>assert_equals( act = lo_pdf->get_field_count( ) exp = 0 ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*(Lars Hvam)*' ).

    FIND FIRST OCCURRENCE OF '/AcroForm' IN lv_pdf.
    cl_abap_unit_assert=>assert_subrc(
      exp = 4
      msg = 'a flattened document has no interactive form' ).
  ENDMETHOD.

  METHOD no_acroform_without_fields.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->add_page( ).
    lo_pdf->cell( iv_text = 'plain' ).

    FIND FIRST OCCURRENCE OF '/Annots' IN lo_pdf->render( ).
    cl_abap_unit_assert=>assert_subrc( exp = 4 ).
  ENDMETHOD.

ENDCLASS.

CLASS ltcl_paint DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    METHODS filled_shape_states_its_colour FOR TESTING RAISING cx_static_check.
    METHODS text_colour_after_a_fill FOR TESTING RAISING cx_static_check.
    METHODS circle_is_round FOR TESTING RAISING cx_static_check.
    METHODS justify_leaves_the_last_line FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_paint IMPLEMENTATION.

  METHOD filled_shape_states_its_colour.
    " A filled rectangle used to inherit whatever colour was painted last
    DATA(lv_pdf) = zcl_open_abap_pdf=>create(
      )->add_page(
      )->set_fill_color( iv_r = 0 iv_g = 128 iv_b = 255
      )->rect( iv_x = 10 iv_y = 10 iv_width = 50 iv_height = 20 iv_style = 'F'
      )->render( ).

    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*0 0.5 1 rg 10 *re f*' ).
  ENDMETHOD.

  METHOD text_colour_after_a_fill.
    " and the text after it has to go back to the text colour
    DATA(lv_pdf) = zcl_open_abap_pdf=>create(
      )->add_page(
      )->set_font( iv_name = 'Helvetica' iv_size = 10
      )->set_text_color( iv_r = 0 iv_g = 0 iv_b = 0
      )->set_fill_color( iv_r = 255 iv_g = 0 iv_b = 0
      )->rect( iv_x = 10 iv_y = 10 iv_width = 50 iv_height = 20 iv_style = 'F'
      )->text( iv_x = 10 iv_y = 50 iv_text = 'after'
      )->render( ).

    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*0 0 0 rg BT 10 * (after) Tj ET*' ).
  ENDMETHOD.

  METHOD circle_is_round.
    " The Bezier handles have to keep their decimals, otherwise the four curves
    " degenerate into the straight edges of a diamond
    DATA(lv_pdf) = zcl_open_abap_pdf=>create(
      )->add_page(
      )->circle( iv_x = 100 iv_y = 100 iv_radius = 30
      )->render( ).

    " 30 * 0.55228 = 16.57, so the first handle sits at 100 + 16.57 from the centre
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*116.57*' ).
    cl_abap_unit_assert=>assert_false(
      act = xsdbool( lv_pdf CP '*130 742.89 m 130 743.89*' )
      msg = 'the handle must not collapse to one point' ).
  ENDMETHOD.

  METHOD justify_leaves_the_last_line.
    " The closing line of a justified block keeps its natural word gaps, which
    " means it is drawn with Tj and not as a TJ array
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->add_page( ).
    lo_pdf->set_font( iv_name = 'Helvetica' iv_size = 10 ).
    lo_pdf->multi_cell(
      iv_width = 200
      iv_align = zcl_open_abap_pdf=>c_align_justify
      iv_text  = `Amounts shown as debit increase the balance you owe and amounts shown ` &&
                 `as credit reduce it, so the last line here ends early.` ).

    DATA(lv_pdf) = lo_pdf->render( ).

    cl_abap_unit_assert=>assert_char_cp(
      act = lv_pdf
      exp = '*] TJ ET*'
      msg = 'the full lines are stretched' ).
    cl_abap_unit_assert=>assert_char_cp(
      act = lv_pdf
      exp = '*(early.) Tj ET*'
      msg = 'the last line is not stretched' ).
  ENDMETHOD.

ENDCLASS.

CLASS ltcl_pdf_test DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    METHODS test_create FOR TESTING RAISING cx_static_check.
    METHODS test_add_page FOR TESTING RAISING cx_static_check.
    METHODS test_render_empty FOR TESTING RAISING cx_static_check.
    METHODS test_text FOR TESTING RAISING cx_static_check.
    METHODS test_multiple_pages FOR TESTING RAISING cx_static_check.
    METHODS test_shapes FOR TESTING RAISING cx_static_check.
    METHODS test_mm_to_pt FOR TESTING RAISING cx_static_check.
    METHODS test_inch_to_pt FOR TESTING RAISING cx_static_check.
    METHODS test_fluent_api FOR TESTING RAISING cx_static_check.
    METHODS test_letter_size FOR TESTING RAISING cx_static_check.
    METHODS test_cursor_and_cell FOR TESTING RAISING cx_static_check.
    METHODS test_auto_page_break FOR TESTING RAISING cx_static_check.
    METHODS test_alias_nb_pages FOR TESTING RAISING cx_static_check.
    METHODS test_multi_cell_wraps FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_pdf_test IMPLEMENTATION.

  METHOD test_create.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    cl_abap_unit_assert=>assert_not_initial( lo_pdf ).
  ENDMETHOD.

  METHOD test_add_page.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->add_page( ).

    cl_abap_unit_assert=>assert_equals(
      act = lo_pdf->get_page_count( )
      exp = 1 ).

    cl_abap_unit_assert=>assert_equals(
      act = lo_pdf->get_page_width( )
      exp = zcl_open_abap_pdf=>c_a4_width ).

    cl_abap_unit_assert=>assert_equals(
      act = lo_pdf->get_page_height( )
      exp = zcl_open_abap_pdf=>c_a4_height ).
  ENDMETHOD.

  METHOD test_render_empty.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->add_page( ).
    DATA(lv_result) = lo_pdf->render( ).

    cl_abap_unit_assert=>assert_char_cp(
      act = lv_result
      exp = '*%PDF-1.4*' ).

    cl_abap_unit_assert=>assert_char_cp(
      act = lv_result
      exp = '*%%EOF*' ).
  ENDMETHOD.

  METHOD test_text.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->add_page( ).
    lo_pdf->set_font( iv_name = 'Helvetica' iv_size = 16 ).
    lo_pdf->text( iv_x = 50 iv_y = 50 iv_text = 'Hello World' ).

    DATA(lv_result) = lo_pdf->render( ).

    cl_abap_unit_assert=>assert_char_cp(
      act = lv_result
      exp = '*(Hello World)*' ).
  ENDMETHOD.

  METHOD test_multiple_pages.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->add_page( ).
    lo_pdf->add_page( ).
    lo_pdf->add_page( ).

    cl_abap_unit_assert=>assert_equals(
      act = lo_pdf->get_page_count( )
      exp = 3 ).

    DATA(lv_result) = lo_pdf->render( ).

    cl_abap_unit_assert=>assert_char_cp(
      act = lv_result
      exp = '*/Count 3*' ).
  ENDMETHOD.

  METHOD test_shapes.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->add_page( ).
    lo_pdf->line( iv_x1 = 10 iv_y1 = 10 iv_x2 = 100 iv_y2 = 100 ).
    lo_pdf->rect( iv_x = 50 iv_y = 50 iv_width = 100 iv_height = 50 ).

    DATA(lv_result) = lo_pdf->render( ).

    " Just verify it renders without error
    cl_abap_unit_assert=>assert_char_cp(
      act = lv_result
      exp = '*%PDF-1.4*' ).
  ENDMETHOD.

  METHOD test_mm_to_pt.
    DATA(lv_pt) = zcl_open_abap_pdf=>mm_to_pt( 10 ).
    DATA(lv_pt_int) = CONV i( lv_pt ).
    " 10mm should be approximately 28.35 points
    cl_abap_unit_assert=>assert_number_between(
      lower = 28
      upper = 29
      number = lv_pt_int ).
  ENDMETHOD.

  METHOD test_inch_to_pt.
    DATA(lv_pt) = zcl_open_abap_pdf=>inch_to_pt( 1 ).
    " 1 inch = 72 points
    cl_abap_unit_assert=>assert_equals(
      act = lv_pt
      exp = 72 ).
  ENDMETHOD.

  METHOD test_letter_size.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->add_page(
      iv_width  = zcl_open_abap_pdf=>c_letter_width
      iv_height = zcl_open_abap_pdf=>c_letter_height ).

    cl_abap_unit_assert=>assert_equals(
      act = lo_pdf->get_page_width( )
      exp = 612 ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_pdf->get_page_height( )
      exp = 792 ).
  ENDMETHOD.

  METHOD test_cursor_and_cell.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->set_margins( iv_left = 40 iv_top = 50 iv_right = 40 iv_bottom = 40 ).
    lo_pdf->add_page( ).

    cl_abap_unit_assert=>assert_equals(
      act = lo_pdf->get_y( )
      exp = 50
      msg = 'cursor starts at the top margin' ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_pdf->get_x( )
      exp = 40 ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_pdf->get_content_width( )
      exp = zcl_open_abap_pdf=>c_a4_width - 80 ).

    lo_pdf->set_line_height( 20 ).
    lo_pdf->cell( iv_text = 'first' iv_align = zcl_open_abap_pdf=>c_align_left ).

    cl_abap_unit_assert=>assert_equals(
      act = lo_pdf->get_y( )
      exp = 70
      msg = 'cell with ln advances one line' ).
  ENDMETHOD.

  METHOD test_auto_page_break.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->add_page( ).
    lo_pdf->set_line_height( 20 ).

    DO 60 TIMES.
      lo_pdf->multi_cell( iv_text = |line { sy-index }| ).
    ENDDO.

    cl_abap_unit_assert=>assert_true(
      act = xsdbool( lo_pdf->get_page_count( ) > 1 )
      msg = 'content longer than one page must break' ).
  ENDMETHOD.

  METHOD test_alias_nb_pages.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->add_page( ).
    lo_pdf->add_page( ).
    lo_pdf->cell( iv_text = 'of {nb} pages' ).

    DATA(lv_result) = lo_pdf->render( ).

    cl_abap_unit_assert=>assert_char_cp(
      act = lv_result
      exp = '*(of 2 pages)*' ).
  ENDMETHOD.

  METHOD test_multi_cell_wraps.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->add_page( ).
    lo_pdf->set_font( iv_name = 'Helvetica' iv_size = 12 ).
    DATA(lv_y_before) = lo_pdf->get_y( ).

    lo_pdf->multi_cell(
      iv_text  = 'The quick brown fox jumps over the lazy dog and keeps on running for a while'
      iv_width = 120 ).

    cl_abap_unit_assert=>assert_true(
      act = xsdbool( lo_pdf->get_y( ) > lv_y_before + 2 * 14 )
      msg = 'wrapped text must occupy more than two lines' ).
  ENDMETHOD.

  METHOD test_fluent_api.
    " Test that fluent API works
    DATA(lv_result) = zcl_open_abap_pdf=>create(
      )->add_page(
      )->set_font( iv_name = 'Courier' iv_size = 12
      )->set_text_color( iv_r = 255 iv_g = 0 iv_b = 0
      )->text( iv_x = 100 iv_y = 100 iv_text = 'Red Text'
      )->render( ).

    cl_abap_unit_assert=>assert_char_cp(
      act = lv_result
      exp = '*(Red Text)*' ).
  ENDMETHOD.

ENDCLASS.
