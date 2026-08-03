*&---------------------------------------------------------------------*
*& Report ZSTPO_PDF_PREVIEW_DEMO
*&---------------------------------------------------------------------*
*& Proves in a real system that the library renders and that the preview
*& handover works, without touching output determination or a print program.
*&
*& Run it, and the PDF opens in the viewer of the workstation. Nothing is
*& printed, no spool request is created, no output type is involved.
*&---------------------------------------------------------------------*
REPORT zstpo_pdf_preview_demo.

PARAMETERS p_ebeln TYPE ekko-ebeln OBLIGATORY DEFAULT '4500000001'.
PARAMETERS p_read  TYPE abap_bool AS CHECKBOX DEFAULT abap_true.
PARAMETERS p_show  RADIOBUTTON GROUP out DEFAULT 'X'.
PARAMETERS p_save  RADIOBUTTON GROUP out.
PARAMETERS p_file  TYPE string LOWER CASE DEFAULT 'C:\temp\po.pdf'.

CLASS lcl_demo DEFINITION FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    CLASS-METHODS run RAISING zcx_open_abap_pdf.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_item,
        ebelp TYPE ekpo-ebelp,
        matnr TYPE ekpo-matnr,
        txz01 TYPE ekpo-txz01,
        menge TYPE ekpo-menge,
        meins TYPE ekpo-meins,
        netpr TYPE ekpo-netpr,
        netwr TYPE ekpo-netwr,
        eindt TYPE eket-eindt,
      END OF ty_item,
      ty_items TYPE STANDARD TABLE OF ty_item WITH DEFAULT KEY.

    CLASS-DATA gs_head TYPE ekko.
    CLASS-DATA gt_items TYPE ty_items.

    CLASS-METHODS read_document.
    CLASS-METHODS sample_document.
    CLASS-METHODS build
      RETURNING VALUE(rv_pdf) TYPE xstring
      RAISING   zcx_open_abap_pdf.
    CLASS-METHODS amount
      IMPORTING iv_value       TYPE p
      RETURNING VALUE(rv_text) TYPE string.
    CLASS-METHODS date
      IMPORTING iv_date        TYPE d
      RETURNING VALUE(rv_text) TYPE string.
ENDCLASS.

CLASS lcl_demo IMPLEMENTATION.

  METHOD run.
    IF p_read = abap_true.
      read_document( ).
    ENDIF.
    IF gs_head-ebeln IS INITIAL.
      " Nothing found, or the checkbox is off, so the layout is shown with
      " sample values. The point of the report is the rendering and the preview.
      sample_document( ).
    ENDIF.

    DATA(lv_pdf) = build( ).
    DATA(lv_size) = xstrlen( lv_pdf ).

    WRITE: / 'Document', gs_head-ebeln,
           / 'Size    ', lv_size, 'bytes'.

    IF p_save = abap_true.
      zcl_stpo_pdf_view=>download( iv_pdf = lv_pdf iv_path = p_file ).
      WRITE: / 'Saved to', p_file.
    ELSE.
      zcl_stpo_pdf_view=>display( iv_pdf = lv_pdf iv_name = |PO_{ gs_head-ebeln }| ).
    ENDIF.
  ENDMETHOD.


  METHOD read_document.
    SELECT SINGLE * FROM ekko INTO gs_head WHERE ebeln = p_ebeln.
    IF sy-subrc <> 0.
      CLEAR gs_head.
      RETURN.
    ENDIF.

    SELECT ebelp matnr txz01 menge meins netpr netwr
      FROM ekpo
      INTO CORRESPONDING FIELDS OF TABLE gt_items
      WHERE ebeln = p_ebeln
        AND loekz = space
      ORDER BY ebelp.

    LOOP AT gt_items ASSIGNING FIELD-SYMBOL(<ls_item>).
      SELECT SINGLE eindt FROM eket INTO <ls_item>-eindt
        WHERE ebeln = p_ebeln AND ebelp = <ls_item>-ebelp.
    ENDLOOP.
  ENDMETHOD.


  METHOD sample_document.
    gs_head-ebeln = p_ebeln.
    gs_head-bedat = sy-datum.
    gs_head-lifnr = '0000000193'.
    gs_head-waers = 'EUR'.
    gs_head-inco1 = 'FCA'.
    gs_head-inco2 = 'LAINATE'.

    gt_items = VALUE ty_items(
      ( ebelp = '00010' matnr = 'SP_457730' txz01 = 'pallet stacker EXV 10-12'
        menge = 1 meins = 'PCE' netpr = '7562.70' netwr = '7562.70' eindt = sy-datum )
      ( ebelp = '00020' matnr = 'SP_457731' txz01 = 'battery 24V / 375Ah'
        menge = 2 meins = 'PCE' netpr = '1240.00' netwr = '2480.00' eindt = sy-datum )
      ( ebelp = '00030' matnr = 'SRV_00012' txz01 = 'commissioning on site'
        menge = 4 meins = 'H' netpr = '95.00' netwr = '380.00' eindt = sy-datum ) ).
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


  METHOD date.
    IF iv_date IS INITIAL.
      RETURN.
    ENDIF.
    rv_text = |{ iv_date+6(2) }.{ iv_date+4(2) }.{ iv_date(4) }|.
  ENDMETHOD.


  METHOD build.
    DATA ls_item TYPE ty_item.
    DATA lv_total TYPE p LENGTH 13 DECIMALS 2.

    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->set_compression( ).
    lo_pdf->set_margins( iv_left = 44 iv_top = 30 iv_right = 37 iv_bottom = 40 ).
    lo_pdf->add_page( ).

    lo_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 15 ).
    lo_pdf->cell( iv_text = 'Purchase Order' iv_height = 22 iv_padding = 0 ).

    lo_pdf->set_font( iv_name = 'Helvetica' iv_size = 9 ).
    lo_pdf->cell( iv_text = |Document { gs_head-ebeln }| iv_height = 13 iv_padding = 0 ).
    lo_pdf->cell( iv_text = |Date { date( gs_head-bedat ) }| iv_height = 13 iv_padding = 0 ).
    lo_pdf->cell( iv_text = |Vendor { gs_head-lifnr }| iv_height = 13 iv_padding = 0 ).
    lo_pdf->cell(
      iv_text   = |Incoterms { gs_head-inco1 } { gs_head-inco2 }   Currency { gs_head-waers }|
      iv_height = 13
      iv_padding = 0 ).
    lo_pdf->ln( 10 ).

    DATA(lo_table) = zcl_open_abap_pdf_table=>create( lo_pdf ).
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
    lo_table->set_zebra( ).
    lo_table->set_border( 'LRB' ).
    lo_table->add_column( iv_header = 'Item' iv_width = 36 iv_align = zcl_open_abap_pdf=>c_align_right ).
    lo_table->add_column( iv_header = 'Material' iv_width = 74 ).
    lo_table->add_column( iv_header = 'Description' ).
    lo_table->add_column( iv_header = 'Qty' iv_width = 44 iv_align = zcl_open_abap_pdf=>c_align_right ).
    lo_table->add_column( iv_header = 'UoM' iv_width = 30 iv_align = zcl_open_abap_pdf=>c_align_center ).
    lo_table->add_column( iv_header = 'Delivery' iv_width = 54 iv_align = zcl_open_abap_pdf=>c_align_center ).
    lo_table->add_column( iv_header = 'Net value' iv_width = 66 iv_align = zcl_open_abap_pdf=>c_align_right ).

    LOOP AT gt_items INTO ls_item.
      lv_total = lv_total + ls_item-netwr.
      lo_table->add_row( it_cells = VALUE zcl_open_abap_pdf_table=>ty_cells(
        ( |{ ls_item-ebelp ALPHA = OUT }| )
        ( |{ ls_item-matnr }| )
        ( |{ ls_item-txz01 }| )
        ( amount( ls_item-menge ) )
        ( |{ ls_item-meins }| )
        ( date( ls_item-eindt ) )
        ( amount( ls_item-netwr ) ) ) ).
    ENDLOOP.

    lo_table->render( ).

    lo_pdf->ln( 8 ).
    lo_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 9 ).
    lo_pdf->cell(
      iv_text   = |Total net value   { amount( lv_total ) } { gs_head-waers }|
      iv_align  = zcl_open_abap_pdf=>c_align_right
      iv_height = 14
      iv_padding = 0 ).

    lo_pdf->set_font( iv_name = 'Helvetica' iv_size = 8 ).
    lo_pdf->ln( 14 ).
    lo_pdf->cell(
      iv_text   = |Rendered in ABAP by open-abap-pdf, { date( sy-datum ) }, no Adobe Document Services|
      iv_height = 12
      iv_padding = 0 ).

    rv_pdf = lo_pdf->render_binary( ).
  ENDMETHOD.

ENDCLASS.


START-OF-SELECTION.
  TRY.
      lcl_demo=>run( ).
    CATCH zcx_open_abap_pdf INTO DATA(lx_error).
      MESSAGE lx_error->mv_text TYPE 'I' DISPLAY LIKE 'E'.
  ENDTRY.
