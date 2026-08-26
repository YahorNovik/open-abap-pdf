CLASS zcl_open_abap_pdf_table DEFINITION PUBLIC FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    TYPES ty_cells TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    TYPES ty_widths TYPE STANDARD TABLE OF f WITH DEFAULT KEY.

    TYPES:
      BEGIN OF ty_column,
        header       TYPE string,
        width        TYPE f,
        align        TYPE string,
        header_align TYPE string,
      END OF ty_column,
      ty_columns TYPE STANDARD TABLE OF ty_column WITH DEFAULT KEY,

      BEGIN OF ty_row,
        cells TYPE ty_cells,
        bold  TYPE abap_bool,
        span  TYPE abap_bool,
        align TYPE string,
        fill  TYPE abap_bool,
        r     TYPE i,
        g     TYPE i,
        b     TYPE i,
        keep  TYPE abap_bool,
      END OF ty_row,
      ty_rows TYPE STANDARD TABLE OF ty_row WITH DEFAULT KEY.

    "! Build a table that is drawn into the given document
    CLASS-METHODS create
      IMPORTING io_pdf          TYPE REF TO zcl_open_abap_pdf
      RETURNING VALUE(ro_table) TYPE REF TO zcl_open_abap_pdf_table.

    "! Add a column
    "! @parameter iv_width | Column width in points, 0 shares out the remaining width
    "! @parameter iv_align | L, C or R
    "! @parameter iv_header_align | Alignment of the header cell, defaults to iv_align
    METHODS add_column
      IMPORTING iv_header       TYPE string DEFAULT ''
                iv_width        TYPE f DEFAULT 0
                iv_align        TYPE string DEFAULT 'L'
                iv_header_align TYPE string DEFAULT ''
      RETURNING VALUE(ro_table) TYPE REF TO zcl_open_abap_pdf_table.

    "! Add a data row, cells are matched to the columns by position
    "! @parameter iv_keep_with_next | Keep this row and the next one on the same page
    METHODS add_row
      IMPORTING it_cells          TYPE ty_cells
                iv_bold           TYPE abap_bool DEFAULT abap_false
                iv_keep_with_next TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(ro_table)   TYPE REF TO zcl_open_abap_pdf_table.

    "! Add a row that spans all columns, for group headers and subtotals
    METHODS add_span_row
      IMPORTING iv_text           TYPE string
                iv_align          TYPE string DEFAULT 'L'
                iv_bold           TYPE abap_bool DEFAULT abap_true
                iv_fill           TYPE abap_bool DEFAULT abap_true
                iv_r              TYPE i DEFAULT 225
                iv_g              TYPE i DEFAULT 232
                iv_b              TYPE i DEFAULT 240
                iv_keep_with_next TYPE abap_bool DEFAULT abap_true
      RETURNING VALUE(ro_table)   TYPE REF TO zcl_open_abap_pdf_table.

    "! Font, background and text color of the header row, which repeats after a page break
    "! @parameter iv_r | Background red, use a light background for dark text
    "! @parameter iv_text_r | Text red, set 255 255 255 for a dark background
    METHODS set_header_style
      IMPORTING iv_font         TYPE string DEFAULT 'Helvetica-Bold'
                iv_size         TYPE f DEFAULT 0
                iv_r            TYPE i DEFAULT 230
                iv_g            TYPE i DEFAULT 235
                iv_b            TYPE i DEFAULT 240
                iv_text_r       TYPE i DEFAULT 0
                iv_text_g       TYPE i DEFAULT 0
                iv_text_b       TYPE i DEFAULT 0
      RETURNING VALUE(ro_table) TYPE REF TO zcl_open_abap_pdf_table.

    METHODS set_body_style
      IMPORTING iv_font         TYPE string DEFAULT 'Helvetica'
                iv_size         TYPE f DEFAULT 0
                iv_text_r       TYPE i DEFAULT 0
                iv_text_g       TYPE i DEFAULT 0
                iv_text_b       TYPE i DEFAULT 0
      RETURNING VALUE(ro_table) TYPE REF TO zcl_open_abap_pdf_table.

    "! Shade every second data row
    METHODS set_zebra
      IMPORTING iv_active       TYPE abap_bool DEFAULT abap_true
                iv_r            TYPE i DEFAULT 245
                iv_g            TYPE i DEFAULT 245
                iv_b            TYPE i DEFAULT 245
      RETURNING VALUE(ro_table) TYPE REF TO zcl_open_abap_pdf_table.

    "! Cell borders, any combination of L, T, R, B or 1 for all sides
    METHODS set_border
      IMPORTING iv_border       TYPE string DEFAULT '1'
      RETURNING VALUE(ro_table) TYPE REF TO zcl_open_abap_pdf_table.

    METHODS set_line_height
      IMPORTING iv_height       TYPE f DEFAULT 14
      RETURNING VALUE(ro_table) TYPE REF TO zcl_open_abap_pdf_table.

    METHODS set_padding
      IMPORTING iv_padding      TYPE f DEFAULT 3
      RETURNING VALUE(ro_table) TYPE REF TO zcl_open_abap_pdf_table.

    "! Draw the table at the current cursor position
    METHODS render
      RETURNING VALUE(ro_pdf) TYPE REF TO zcl_open_abap_pdf.

  PRIVATE SECTION.
    DATA mo_pdf TYPE REF TO zcl_open_abap_pdf.
    DATA mt_columns TYPE ty_columns.
    DATA mt_rows TYPE ty_rows.
    DATA mv_header_font TYPE string.
    DATA mv_header_size TYPE f.
    DATA mv_header_r TYPE i.
    DATA mv_header_g TYPE i.
    DATA mv_header_b TYPE i.
    DATA mv_header_text_r TYPE i.
    DATA mv_header_text_g TYPE i.
    DATA mv_header_text_b TYPE i.
    DATA mv_body_font TYPE string.
    DATA mv_body_size TYPE f.
    DATA mv_body_text_r TYPE i.
    DATA mv_body_text_g TYPE i.
    DATA mv_body_text_b TYPE i.
    DATA mv_zebra TYPE abap_bool.
    DATA mv_zebra_r TYPE i.
    DATA mv_zebra_g TYPE i.
    DATA mv_zebra_b TYPE i.
    DATA mv_border TYPE string.
    DATA mv_line_height TYPE f.
    DATA mv_padding TYPE f.

    METHODS resolved_widths
      RETURNING VALUE(rt_widths) TYPE ty_widths.

    METHODS draw_row
      IMPORTING it_cells  TYPE ty_cells
                it_widths TYPE ty_widths
                iv_font   TYPE string
                iv_size   TYPE f
                iv_fill   TYPE abap_bool
                iv_header TYPE abap_bool DEFAULT abap_false
                iv_align  TYPE string DEFAULT ''
                iv_r      TYPE i DEFAULT 255
                iv_g      TYPE i DEFAULT 255
                iv_b      TYPE i DEFAULT 255
                iv_text_r TYPE i DEFAULT 0
                iv_text_g TYPE i DEFAULT 0
                iv_text_b TYPE i DEFAULT 0.

    METHODS row_height
      IMPORTING it_cells         TYPE ty_cells
                it_widths        TYPE ty_widths
                iv_font          TYPE string
                iv_size          TYPE f
      RETURNING VALUE(rv_height) TYPE f.

    METHODS draw_header
      IMPORTING it_widths TYPE ty_widths.
ENDCLASS.

CLASS zcl_open_abap_pdf_table IMPLEMENTATION.

  METHOD create.
    CREATE OBJECT ro_table.
    ro_table->mo_pdf = io_pdf.
    ro_table->mv_header_font = 'Helvetica-Bold'.
    ro_table->mv_body_font = 'Helvetica'.
    ro_table->mv_header_r = 230.
    ro_table->mv_header_g = 235.
    ro_table->mv_header_b = 240.
    ro_table->mv_zebra_r = 245.
    ro_table->mv_zebra_g = 245.
    ro_table->mv_zebra_b = 245.
    ro_table->mv_border = '1'.
    ro_table->mv_line_height = 14.
    ro_table->mv_padding = 3.
  ENDMETHOD.

  METHOD add_column.
    DATA(lv_header_align) = iv_header_align.
    IF lv_header_align IS INITIAL.
      lv_header_align = iv_align.
    ENDIF.

    APPEND VALUE ty_column(
      header       = iv_header
      width        = iv_width
      align        = iv_align
      header_align = lv_header_align ) TO mt_columns.
    ro_table = me.
  ENDMETHOD.

  METHOD add_row.
    APPEND VALUE ty_row(
      cells = it_cells
      bold  = iv_bold
      keep  = iv_keep_with_next ) TO mt_rows.
    ro_table = me.
  ENDMETHOD.

  METHOD add_span_row.
    APPEND VALUE ty_row(
      cells = VALUE ty_cells( ( iv_text ) )
      bold  = iv_bold
      span  = abap_true
      align = iv_align
      fill  = iv_fill
      r     = iv_r
      g     = iv_g
      b     = iv_b
      keep  = iv_keep_with_next ) TO mt_rows.
    ro_table = me.
  ENDMETHOD.

  METHOD set_header_style.
    mv_header_font = iv_font.
    mv_header_size = iv_size.
    mv_header_r = iv_r.
    mv_header_g = iv_g.
    mv_header_b = iv_b.
    mv_header_text_r = iv_text_r.
    mv_header_text_g = iv_text_g.
    mv_header_text_b = iv_text_b.
    ro_table = me.
  ENDMETHOD.

  METHOD set_body_style.
    mv_body_font = iv_font.
    mv_body_size = iv_size.
    mv_body_text_r = iv_text_r.
    mv_body_text_g = iv_text_g.
    mv_body_text_b = iv_text_b.
    ro_table = me.
  ENDMETHOD.

  METHOD set_zebra.
    mv_zebra = iv_active.
    mv_zebra_r = iv_r.
    mv_zebra_g = iv_g.
    mv_zebra_b = iv_b.
    ro_table = me.
  ENDMETHOD.

  METHOD set_border.
    mv_border = iv_border.
    ro_table = me.
  ENDMETHOD.

  METHOD set_line_height.
    mv_line_height = iv_height.
    ro_table = me.
  ENDMETHOD.

  METHOD set_padding.
    mv_padding = iv_padding.
    ro_table = me.
  ENDMETHOD.

  METHOD resolved_widths.
    DATA ls_column TYPE ty_column.
    DATA lv_fixed TYPE f.
    DATA lv_open TYPE i.
    DATA lv_share TYPE f.

    LOOP AT mt_columns INTO ls_column.
      IF ls_column-width > 0.
        lv_fixed = lv_fixed + ls_column-width.
      ELSE.
        lv_open = lv_open + 1.
      ENDIF.
    ENDLOOP.

    IF lv_open > 0.
      lv_share = ( mo_pdf->get_content_width( ) - lv_fixed ) / lv_open.
    ENDIF.

    LOOP AT mt_columns INTO ls_column.
      IF ls_column-width > 0.
        APPEND ls_column-width TO rt_widths.
      ELSE.
        APPEND lv_share TO rt_widths.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD row_height.
    DATA lv_cell TYPE string.
    DATA lv_width TYPE f.
    DATA lv_lines TYPE i.
    DATA lv_max TYPE i.

    lv_max = 1.
    LOOP AT it_cells INTO lv_cell.
      READ TABLE it_widths INTO lv_width INDEX sy-tabix.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      lv_lines = lines( zcl_open_abap_pdf_font=>wrap(
        iv_font  = iv_font
        iv_size  = iv_size
        iv_text  = lv_cell
        iv_width = lv_width - 2 * mv_padding ) ).
      IF lv_lines > lv_max.
        lv_max = lv_lines.
      ENDIF.
    ENDLOOP.

    rv_height = lv_max * mv_line_height.
  ENDMETHOD.

  METHOD draw_row.
    DATA lv_cell TYPE string.
    DATA lv_width TYPE f.
    DATA lv_line TYPE string.
    DATA ls_column TYPE ty_column.
    DATA lv_index TYPE i.

    DATA(lv_height) = row_height(
      it_cells  = it_cells
      it_widths = it_widths
      iv_font   = iv_font
      iv_size   = iv_size ).

    DATA(lv_start_x) = mo_pdf->get_x( ).
    DATA(lv_x) = lv_start_x.
    DATA(lv_y) = mo_pdf->get_y( ).

    mo_pdf->set_font( iv_name = iv_font iv_size = iv_size ).
    IF iv_fill = abap_true.
      mo_pdf->set_fill_color( iv_r = iv_r iv_g = iv_g iv_b = iv_b ).
    ENDIF.
    mo_pdf->set_text_color( iv_r = iv_text_r iv_g = iv_text_g iv_b = iv_text_b ).

    LOOP AT it_widths INTO lv_width.
      lv_index = sy-tabix.
      CLEAR lv_cell.
      READ TABLE it_cells INTO lv_cell INDEX lv_index.
      READ TABLE mt_columns INTO ls_column INDEX lv_index.

      " Background and border first, then the wrapped lines on top
      mo_pdf->set_xy( iv_x = lv_x iv_y = lv_y ).
      mo_pdf->cell(
        iv_text   = ''
        iv_width  = lv_width
        iv_height = lv_height
        iv_border = mv_border
        iv_fill   = iv_fill
        iv_ln     = abap_false ).

      DATA(lv_align) = ls_column-align.
      IF iv_header = abap_true.
        lv_align = ls_column-header_align.
      ENDIF.
      IF iv_align IS NOT INITIAL.
        lv_align = iv_align.
      ENDIF.

      LOOP AT zcl_open_abap_pdf_font=>wrap(
                iv_font  = iv_font
                iv_size  = iv_size
                iv_text  = lv_cell
                iv_width = lv_width - 2 * mv_padding ) INTO lv_line.
        mo_pdf->set_xy(
          iv_x = lv_x
          iv_y = lv_y + ( sy-tabix - 1 ) * mv_line_height ).
        mo_pdf->cell(
          iv_text    = lv_line
          iv_width   = lv_width
          iv_height  = mv_line_height
          iv_align   = lv_align
          iv_padding = mv_padding
          iv_ln      = abap_false ).
      ENDLOOP.

      lv_x = lv_x + lv_width.
    ENDLOOP.

    mo_pdf->set_xy( iv_x = lv_start_x iv_y = lv_y + lv_height ).
    mo_pdf->set_text_color(
      iv_r = mv_body_text_r
      iv_g = mv_body_text_g
      iv_b = mv_body_text_b ).
  ENDMETHOD.

  METHOD draw_header.
    DATA lt_cells TYPE ty_cells.
    DATA ls_column TYPE ty_column.

    LOOP AT mt_columns INTO ls_column.
      APPEND ls_column-header TO lt_cells.
    ENDLOOP.

    IF lt_cells IS INITIAL.
      RETURN.
    ENDIF.

    draw_row(
      it_cells  = lt_cells
      it_widths = it_widths
      iv_font   = mv_header_font
      iv_size   = mv_header_size
      iv_fill   = abap_true
      iv_header = abap_true
      iv_r      = mv_header_r
      iv_g      = mv_header_g
      iv_b      = mv_header_b
      iv_text_r = mv_header_text_r
      iv_text_g = mv_header_text_g
      iv_text_b = mv_header_text_b ).
  ENDMETHOD.

  METHOD render.
    DATA ls_row TYPE ty_row.
    DATA ls_next TYPE ty_row.
    DATA lv_font TYPE string.
    DATA lv_fill TYPE abap_bool.
    DATA lv_row_no TYPE i.
    DATA lv_needed TYPE f.
    DATA lv_width TYPE f.
    DATA lv_total TYPE f.
    DATA lt_span TYPE ty_widths.
    DATA lt_row_widths TYPE ty_widths.
    DATA lv_r TYPE i.
    DATA lv_g TYPE i.
    DATA lv_b TYPE i.

    DATA(lt_widths) = resolved_widths( ).
    DATA(lv_left) = mo_pdf->get_x( ).

    IF mv_header_size <= 0.
      mv_header_size = 11.
    ENDIF.
    IF mv_body_size <= 0.
      mv_body_size = 11.
    ENDIF.

    LOOP AT lt_widths INTO lv_width.
      lv_total = lv_total + lv_width.
    ENDLOOP.
    APPEND lv_total TO lt_span.

    draw_header( lt_widths ).

    LOOP AT mt_rows INTO ls_row.
      lv_row_no = sy-tabix.

      lv_font = mv_body_font.
      IF ls_row-bold = abap_true.
        lv_font = mv_header_font.
      ENDIF.

      lt_row_widths = lt_widths.
      IF ls_row-span = abap_true.
        lt_row_widths = lt_span.
      ENDIF.

      lv_needed = row_height(
        it_cells  = ls_row-cells
        it_widths = lt_row_widths
        iv_font   = lv_font
        iv_size   = mv_body_size ).

      " A group header must not be the last row on a page
      IF ls_row-keep = abap_true.
        READ TABLE mt_rows INTO ls_next INDEX lv_row_no + 1.
        IF sy-subrc = 0.
          lv_needed = lv_needed + row_height(
            it_cells  = ls_next-cells
            it_widths = COND #( WHEN ls_next-span = abap_true THEN lt_span ELSE lt_widths )
            iv_font   = mv_body_font
            iv_size   = mv_body_size ).
        ENDIF.
      ENDIF.

      IF mo_pdf->check_page_break( lv_needed ) = abap_true.
        mo_pdf->set_x( lv_left ).
        draw_header( lt_widths ).
      ENDIF.

      lv_fill = abap_false.
      lv_r = mv_zebra_r.
      lv_g = mv_zebra_g.
      lv_b = mv_zebra_b.
      IF mv_zebra = abap_true AND lv_row_no MOD 2 = 0.
        lv_fill = abap_true.
      ENDIF.
      IF ls_row-span = abap_true.
        lv_fill = ls_row-fill.
        lv_r = ls_row-r.
        lv_g = ls_row-g.
        lv_b = ls_row-b.
      ENDIF.

      mo_pdf->set_x( lv_left ).
      draw_row(
        it_cells  = ls_row-cells
        it_widths = lt_row_widths
        iv_font   = lv_font
        iv_size   = mv_body_size
        iv_fill   = lv_fill
        iv_align  = ls_row-align
        iv_r      = lv_r
        iv_g      = lv_g
        iv_b      = lv_b
        iv_text_r = mv_body_text_r
        iv_text_g = mv_body_text_g
        iv_text_b = mv_body_text_b ).
    ENDLOOP.

    mo_pdf->set_x( lv_left ).
    ro_pdf = mo_pdf.
  ENDMETHOD.

ENDCLASS.
