CLASS zcl_pdf_demo_ttf DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    "! @parameter iv_ttf | Content of a ttf file, in a real system read from SMW0 or a table
    CLASS-METHODS run_base64
      IMPORTING iv_ttf           TYPE xstring
                iv_ttf_bold      TYPE xstring OPTIONAL
      RETURNING VALUE(rv_base64) TYPE string
      RAISING   zcx_open_abap_pdf.

  PRIVATE SECTION.
    CONSTANTS c_font TYPE string VALUE 'CompanySans'.
    CONSTANTS c_font_bold TYPE string VALUE 'CompanySans-Bold'.

    CLASS-METHODS row
      IMPORTING io_pdf   TYPE REF TO zcl_open_abap_pdf
                iv_label TYPE string
                iv_text  TYPE string.
ENDCLASS.

CLASS zcl_pdf_demo_ttf IMPLEMENTATION.

  METHOD row.
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = 8 ).
    io_pdf->set_text_color( iv_r = 120 iv_g = 120 iv_b = 120 ).
    io_pdf->cell( iv_text = iv_label iv_width = 110 iv_height = 20 iv_ln = abap_false ).

    io_pdf->set_text_color( iv_r = 0 iv_g = 0 iv_b = 0 ).
    io_pdf->set_font( iv_name = c_font iv_size = 12 ).
    io_pdf->cell( iv_text = iv_text iv_height = 20 ).
  ENDMETHOD.

  METHOD run_base64.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->set_compression( ).
    lo_pdf->set_margins( iv_left = 45 iv_top = 45 iv_right = 45 iv_bottom = 45 ).
    lo_pdf->register_font( iv_name = c_font iv_data = iv_ttf ).
    IF iv_ttf_bold IS NOT INITIAL.
      lo_pdf->register_font( iv_name = c_font_bold iv_data = iv_ttf_bold ).
    ENDIF.
    lo_pdf->add_page( ).

    lo_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = 16 ).
    lo_pdf->cell( iv_text = 'Embedded TrueType font' iv_height = 24 ).
    lo_pdf->set_font( iv_name = 'Helvetica' iv_size = 9 ).
    lo_pdf->multi_cell(
      iv_text   = 'The lines below are written with an embedded font using the Identity-H ' &&
                  'encoding, so they are not limited to the WinAnsi character set. The grey ' &&
                  'labels are Helvetica for comparison.'
      iv_height = 12 ).
    lo_pdf->ln( 10 ).

    row( io_pdf = lo_pdf
         iv_label = 'Polish'
         iv_text = |Ilo{ cl_abap_conv_in_ce=>uccp( '015B' ) }{ cl_abap_conv_in_ce=>uccp( '0107' ) }, | &&
                   |Do zap{ cl_abap_conv_in_ce=>uccp( '0142' ) }aty, | &&
                   |Warto{ cl_abap_conv_in_ce=>uccp( '015B' ) }{ cl_abap_conv_in_ce=>uccp( '0107' ) } netto, | &&
                   |P{ cl_abap_conv_in_ce=>uccp( '0142' ) }yta g{ cl_abap_conv_in_ce=>uccp( '0142' ) }{ cl_abap_conv_in_ce=>uccp( '00F3' ) }wna| ).

    row( io_pdf = lo_pdf
         iv_label = 'Czech and Hungarian'
         iv_text = |P{ cl_abap_conv_in_ce=>uccp( '0159' ) }{ cl_abap_conv_in_ce=>uccp( '00ED' ) }jem, | &&
                   |dod{ cl_abap_conv_in_ce=>uccp( '00E1' ) }vka, | &&
                   |{ cl_abap_conv_in_ce=>uccp( '00C1' ) }rusz{ cl_abap_conv_in_ce=>uccp( '00E1' ) }m{ cl_abap_conv_in_ce=>uccp( '00ED' ) }t{ cl_abap_conv_in_ce=>uccp( '00E1' ) }s| ).

    row( io_pdf = lo_pdf
         iv_label = 'Turkish'
         iv_text = |Te{ cl_abap_conv_in_ce=>uccp( '015F' ) }ekk{ cl_abap_conv_in_ce=>uccp( '00FC' ) }rler, | &&
                   |{ cl_abap_conv_in_ce=>uccp( '0130' ) }stanbul, | &&
                   |{ cl_abap_conv_in_ce=>uccp( '015E' ) }irket| ).

    row( io_pdf = lo_pdf
         iv_label = 'Cyrillic'
         iv_text = |{ cl_abap_conv_in_ce=>uccp( '0421' ) }{ cl_abap_conv_in_ce=>uccp( '0447' ) }{ cl_abap_conv_in_ce=>uccp( '0451' ) }{ cl_abap_conv_in_ce=>uccp( '0442' ) } | &&
                   |{ cl_abap_conv_in_ce=>uccp( '043D' ) }{ cl_abap_conv_in_ce=>uccp( '0430' ) } | &&
                   |{ cl_abap_conv_in_ce=>uccp( '043E' ) }{ cl_abap_conv_in_ce=>uccp( '043F' ) }{ cl_abap_conv_in_ce=>uccp( '043B' ) }{ cl_abap_conv_in_ce=>uccp( '0430' ) }{ cl_abap_conv_in_ce=>uccp( '0442' ) }{ cl_abap_conv_in_ce=>uccp( '0443' ) }| ).

    row( io_pdf = lo_pdf
         iv_label = 'Greek'
         iv_text = |{ cl_abap_conv_in_ce=>uccp( '03A4' ) }{ cl_abap_conv_in_ce=>uccp( '03B9' ) }{ cl_abap_conv_in_ce=>uccp( '03BC' ) }{ cl_abap_conv_in_ce=>uccp( '03BF' ) }{ cl_abap_conv_in_ce=>uccp( '03BB' ) }{ cl_abap_conv_in_ce=>uccp( '03CC' ) }{ cl_abap_conv_in_ce=>uccp( '03B3' ) }{ cl_abap_conv_in_ce=>uccp( '03B9' ) }{ cl_abap_conv_in_ce=>uccp( '03BF' ) }| ).

    row( io_pdf = lo_pdf
         iv_label = 'German and French'
         iv_text = |Gr{ cl_abap_conv_in_ce=>uccp( '00FC' ) }{ cl_abap_conv_in_ce=>uccp( '00DF' ) }e, | &&
                   |{ cl_abap_conv_in_ce=>uccp( '00C4' ) }nderung, facture d{ cl_abap_conv_in_ce=>uccp( '2019' ) }achat| ).

    row( io_pdf = lo_pdf
         iv_label = 'Currency and symbols'
         iv_text = |{ cl_abap_conv_in_ce=>uccp( '20AC' ) } 1.250,00   | &&
                   |{ cl_abap_conv_in_ce=>uccp( '00A3' ) } 980   | &&
                   |{ cl_abap_conv_in_ce=>uccp( '20BD' ) } 75.000   | &&
                   |{ cl_abap_conv_in_ce=>uccp( '2122' ) } { cl_abap_conv_in_ce=>uccp( '00AE' ) } { cl_abap_conv_in_ce=>uccp( '2264' ) }| ).

    lo_pdf->ln( 14 ).

    " Text measuring works for the embedded font, so tables still line up
    DATA(lo_table) = zcl_open_abap_pdf_table=>create( lo_pdf ).
    lo_table->set_line_height( 14 ).
    lo_table->set_body_style( iv_font = c_font iv_size = 10 ).
    lo_table->set_header_style(
      iv_font   = COND string( WHEN iv_ttf_bold IS NOT INITIAL THEN c_font_bold ELSE c_font )
      iv_size   = 10
      iv_r      = 0
      iv_g      = 51
      iv_b      = 102
      iv_text_r = 255
      iv_text_g = 255
      iv_text_b = 255 ).
    lo_table->add_column(
      iv_header = |Nazwa towaru|
      iv_header_align = zcl_open_abap_pdf=>c_align_center ).
    lo_table->add_column(
      iv_header = |Ilo{ cl_abap_conv_in_ce=>uccp( '015B' ) }{ cl_abap_conv_in_ce=>uccp( '0107' ) }|
      iv_width  = 60
      iv_align  = zcl_open_abap_pdf=>c_align_right ).
    lo_table->add_column(
      iv_header = |Warto{ cl_abap_conv_in_ce=>uccp( '015B' ) }{ cl_abap_conv_in_ce=>uccp( '0107' ) } netto|
      iv_width  = 100
      iv_align  = zcl_open_abap_pdf=>c_align_right ).

    lo_table->add_row( VALUE #(
      ( |P{ cl_abap_conv_in_ce=>uccp( '0142' ) }yta g{ cl_abap_conv_in_ce=>uccp( '0142' ) }{ cl_abap_conv_in_ce=>uccp( '00F3' ) }wna C34| )
      ( '5 szt.' )
      ( |750,00 { cl_abap_conv_in_ce=>uccp( '20AC' ) }| ) ) ).
    lo_table->add_row( VALUE #(
      ( |{ cl_abap_conv_in_ce=>uccp( '0141' ) }{ cl_abap_conv_in_ce=>uccp( '0105' ) }cznik { cl_abap_conv_in_ce=>uccp( '015B' ) }rubowy| )
      ( '120 szt.' )
      ( |1.230,00 { cl_abap_conv_in_ce=>uccp( '20AC' ) }| ) ) ).
    lo_table->render( ).

    rv_base64 = cl_http_utility=>encode_x_base64( lo_pdf->render_binary( ) ).
  ENDMETHOD.

ENDCLASS.
