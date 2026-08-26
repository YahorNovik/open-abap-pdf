CLASS zcl_pdf_delnote DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    "! Redraw of a delivery note, generated from the original by
    "! tools/pdf_to_abap.py, so every coordinate is the one of the source.
    CLASS-METHODS run_base64
      RETURNING VALUE(rv_base64) TYPE string
      RAISING   zcx_open_abap_pdf.

  PRIVATE SECTION.
    CLASS-METHODS logo
      RETURNING VALUE(rv_base64) TYPE string.

    CLASS-METHODS page_1
      IMPORTING io_pdf TYPE REF TO zcl_open_abap_pdf
      RAISING   zcx_open_abap_pdf.

    CLASS-METHODS page_2
      IMPORTING io_pdf TYPE REF TO zcl_open_abap_pdf
      RAISING   zcx_open_abap_pdf.

    CLASS-METHODS page_3
      IMPORTING io_pdf TYPE REF TO zcl_open_abap_pdf
      RAISING   zcx_open_abap_pdf.

    CLASS-METHODS page_4
      IMPORTING io_pdf TYPE REF TO zcl_open_abap_pdf
      RAISING   zcx_open_abap_pdf.

ENDCLASS.


CLASS zcl_pdf_delnote IMPLEMENTATION.

  METHOD run_base64.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->set_compression( ).
    lo_pdf->set_auto_page_break( iv_active = abap_false ).
    lo_pdf->set_font( iv_name = 'Helvetica' iv_size = 9 ).

    lo_pdf->add_page( iv_width = '595.276' iv_height = '841.89' ).
    page_1( lo_pdf ).
    lo_pdf->add_page( iv_width = '595.276' iv_height = '841.89' ).
    page_2( lo_pdf ).
    lo_pdf->add_page( iv_width = '595.276' iv_height = '841.89' ).
    page_3( lo_pdf ).
    lo_pdf->add_page( iv_width = '595.276' iv_height = '841.89' ).
    page_4( lo_pdf ).

    rv_base64 = cl_http_utility=>encode_x_base64( lo_pdf->render_binary( ) ).
  ENDMETHOD.


  METHOD page_1.
    io_pdf->image_base64(
      iv_base64 = logo( )
      iv_x      = '476.504'
      iv_y      = '12.756'
      iv_width  = '93.332'
      iv_height = '28.58' ).

    io_pdf->set_draw_color( iv_r = 0 iv_g = 0 iv_b = 0 ).
    io_pdf->set_line_width( '0.5' ).
    io_pdf->rect( iv_x = '27.0' iv_y = '288.0' iv_width = '540.0' iv_height = '183.685' iv_style = 'D' ).
    io_pdf->set_fill_color( iv_r = 192 iv_g = 192 iv_b = 192 ).
    io_pdf->rect( iv_x = '27.0' iv_y = '279.0' iv_width = '198.0' iv_height = '11.339' iv_style = 'F' ).
    io_pdf->rect( iv_x = '27.0' iv_y = '279.0' iv_width = '198.0' iv_height = '11.339' iv_style = 'D' ).
    io_pdf->rect( iv_x = '27.0' iv_y = '346.677' iv_width = '198.0' iv_height = '11.339' iv_style = 'F' ).
    io_pdf->rect( iv_x = '27.0' iv_y = '346.677' iv_width = '198.0' iv_height = '11.339' iv_style = 'D' ).
    io_pdf->rect( iv_x = '27.0' iv_y = '414.709' iv_width = '198.0' iv_height = '11.339' iv_style = 'F' ).
    io_pdf->rect( iv_x = '27.0' iv_y = '414.709' iv_width = '198.0' iv_height = '11.339' iv_style = 'D' ).
    io_pdf->rect( iv_x = '225.0' iv_y = '279.0' iv_width = '342.0' iv_height = '11.339' iv_style = 'F' ).
    io_pdf->rect( iv_x = '225.0' iv_y = '279.0' iv_width = '342.0' iv_height = '11.339' iv_style = 'D' ).
    io_pdf->rect( iv_x = '225.0' iv_y = '289.984' iv_width = '198.426' iv_height = '79.373' iv_style = 'D' ).
    io_pdf->rect( iv_x = '225.0' iv_y = '289.984' iv_width = '99.213' iv_height = '11.339' iv_style = 'D' ).
    io_pdf->rect( iv_x = '225.0' iv_y = '301.323' iv_width = '99.213' iv_height = '11.339' iv_style = 'D' ).
    io_pdf->rect( iv_x = '225.0' iv_y = '312.662' iv_width = '99.213' iv_height = '11.339' iv_style = 'D' ).
    io_pdf->rect( iv_x = '225.0' iv_y = '324.001' iv_width = '99.213' iv_height = '11.339' iv_style = 'D' ).
    io_pdf->rect( iv_x = '225.0' iv_y = '335.34' iv_width = '99.213' iv_height = '11.339' iv_style = 'D' ).
    io_pdf->rect( iv_x = '225.0' iv_y = '346.679' iv_width = '99.213' iv_height = '11.339' iv_style = 'D' ).
    io_pdf->rect( iv_x = '225.0' iv_y = '358.018' iv_width = '99.213' iv_height = '11.339' iv_style = 'D' ).
    io_pdf->rect( iv_x = '225.0' iv_y = '369.085' iv_width = '198.425' iv_height = '14.112' iv_style = 'D' ).
    io_pdf->set_fill_color( iv_r = 192 iv_g = 192 iv_b = 192 ).
    io_pdf->rect( iv_x = '27.0' iv_y = '502.455' iv_width = '540.0' iv_height = '11.835' iv_style = 'F' ).
    io_pdf->rect( iv_x = '27.0' iv_y = '502.455' iv_width = '540.0' iv_height = '11.835' iv_style = 'D' ).
    io_pdf->rect( iv_x = '27.0' iv_y = '514.29' iv_width = '540.001' iv_height = '247.756' iv_style = 'D' ).

    io_pdf->set_line_width( '0.5' ).
    io_pdf->line_from( iv_x = '27.0' iv_y = '289.734' iv_dx = '0.0' iv_dy = '11.839' ).
    io_pdf->line_from( iv_x = '225.0' iv_y = '289.734' iv_dx = '0.0' iv_dy = '11.839' ).
    io_pdf->line_from( iv_x = '225.0' iv_y = '301.073' iv_dx = '0.0' iv_dy = '11.839' ).
    io_pdf->line_from( iv_x = '27.0' iv_y = '301.073' iv_dx = '0.0' iv_dy = '11.839' ).
    io_pdf->line_from( iv_x = '225.0' iv_y = '312.411' iv_dx = '0.0' iv_dy = '11.839' ).
    io_pdf->line_from( iv_x = '27.0' iv_y = '312.411' iv_dx = '0.0' iv_dy = '11.839' ).
    io_pdf->line_from( iv_x = '225.0' iv_y = '323.75' iv_dx = '0.0' iv_dy = '11.839' ).
    io_pdf->line_from( iv_x = '27.0' iv_y = '323.75' iv_dx = '0.0' iv_dy = '11.839' ).
    io_pdf->line_from( iv_x = '27.0' iv_y = '357.766' iv_dx = '0.0' iv_dy = '11.839' ).
    io_pdf->line_from( iv_x = '225.0' iv_y = '357.766' iv_dx = '0.0' iv_dy = '11.839' ).
    io_pdf->line_from( iv_x = '225.0' iv_y = '369.104' iv_dx = '0.0' iv_dy = '11.839' ).
    io_pdf->line_from( iv_x = '27.0' iv_y = '369.104' iv_dx = '0.0' iv_dy = '11.839' ).
    io_pdf->line_from( iv_x = '225.0' iv_y = '380.443' iv_dx = '0.0' iv_dy = '11.839' ).
    io_pdf->line_from( iv_x = '27.0' iv_y = '380.443' iv_dx = '0.0' iv_dy = '11.839' ).
    io_pdf->line_from( iv_x = '225.0' iv_y = '391.781' iv_dx = '0.0' iv_dy = '11.839' ).
    io_pdf->line_from( iv_x = '27.0' iv_y = '391.781' iv_dx = '0.0' iv_dy = '11.839' ).
    io_pdf->line_from( iv_x = '225.0' iv_y = '448.474' iv_dx = '0.0' iv_dy = '11.839' ).
    io_pdf->line_from( iv_x = '27.0' iv_y = '448.474' iv_dx = '0.0' iv_dy = '11.839' ).
    io_pdf->line_from( iv_x = '225.0' iv_y = '437.136' iv_dx = '0.0' iv_dy = '11.839' ).
    io_pdf->line_from( iv_x = '27.0' iv_y = '437.136' iv_dx = '0.0' iv_dy = '11.839' ).
    io_pdf->line_from( iv_x = '225.0' iv_y = '425.797' iv_dx = '0.0' iv_dy = '11.839' ).
    io_pdf->line_from( iv_x = '27.0' iv_y = '425.797' iv_dx = '0.0' iv_dy = '11.839' ).
    io_pdf->line_from( iv_x = '26.75' iv_y = '346.678' iv_dx = '198.5' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '225.0' iv_y = '335.089' iv_dx = '0.0' iv_dy = '11.839' ).
    io_pdf->line_from( iv_x = '26.75' iv_y = '414.709' iv_dx = '198.5' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '225.0' iv_y = '403.12' iv_dx = '0.0' iv_dy = '11.839' ).
    io_pdf->line_from( iv_x = '225.0' iv_y = '459.813' iv_dx = '0.0' iv_dy = '11.839' ).
    io_pdf->line_from( iv_x = '423.175' iv_y = '321.732' iv_dx = '81.287' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '504.212' iv_y = '305.608' iv_dx = '0.0' iv_dy = '16.374' ).
    io_pdf->line_from( iv_x = '503.126' iv_y = '289.984' iv_dx = '64.28' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '503.126' iv_y = '305.858' iv_dx = '64.28' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '423.175' iv_y = '289.984' iv_dx = '81.287' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '423.175' iv_y = '305.858' iv_dx = '81.287' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '504.212' iv_y = '289.734' iv_dx = '0.0' iv_dy = '16.374' ).
    io_pdf->line_from( iv_x = '503.126' iv_y = '321.732' iv_dx = '64.28' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '423.175' iv_y = '337.606' iv_dx = '81.287' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '504.212' iv_y = '321.482' iv_dx = '0.0' iv_dy = '16.374' ).
    io_pdf->line_from( iv_x = '503.126' iv_y = '337.606' iv_dx = '64.28' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '423.175' iv_y = '353.48' iv_dx = '81.287' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '504.212' iv_y = '337.356' iv_dx = '0.0' iv_dy = '16.374' ).
    io_pdf->line_from( iv_x = '503.126' iv_y = '353.48' iv_dx = '64.28' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '423.175' iv_y = '369.354' iv_dx = '81.287' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '504.212' iv_y = '353.23' iv_dx = '0.0' iv_dy = '16.374' ).
    io_pdf->line_from( iv_x = '503.126' iv_y = '369.354' iv_dx = '64.28' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '323.963' iv_y = '289.984' iv_dx = '99.713' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '323.963' iv_y = '301.323' iv_dx = '99.713' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '324.213' iv_y = '289.734' iv_dx = '0.0' iv_dy = '11.839' ).
    io_pdf->line_from( iv_x = '323.963' iv_y = '301.323' iv_dx = '99.713' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '323.963' iv_y = '312.662' iv_dx = '99.713' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '324.213' iv_y = '301.073' iv_dx = '0.0' iv_dy = '11.839' ).
    io_pdf->line_from( iv_x = '323.963' iv_y = '312.662' iv_dx = '99.713' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '323.963' iv_y = '324.001' iv_dx = '99.713' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '324.213' iv_y = '312.412' iv_dx = '0.0' iv_dy = '11.839' ).
    io_pdf->line_from( iv_x = '323.963' iv_y = '324.001' iv_dx = '99.713' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '323.963' iv_y = '335.34' iv_dx = '99.713' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '324.213' iv_y = '323.751' iv_dx = '0.0' iv_dy = '11.839' ).
    io_pdf->line_from( iv_x = '323.963' iv_y = '335.34' iv_dx = '99.713' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '323.963' iv_y = '346.679' iv_dx = '99.713' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '324.213' iv_y = '335.09' iv_dx = '0.0' iv_dy = '11.839' ).
    io_pdf->line_from( iv_x = '323.963' iv_y = '346.679' iv_dx = '99.713' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '323.963' iv_y = '358.018' iv_dx = '99.713' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '324.213' iv_y = '346.429' iv_dx = '0.0' iv_dy = '11.839' ).
    io_pdf->line_from( iv_x = '323.963' iv_y = '358.018' iv_dx = '99.713' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '323.963' iv_y = '369.357' iv_dx = '99.713' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '324.213' iv_y = '357.768' iv_dx = '0.0' iv_dy = '11.839' ).
    io_pdf->line_from( iv_x = '324.213' iv_y = '368.835' iv_dx = '0.0' iv_dy = '14.612' ).
    io_pdf->line_from( iv_x = '26.75' iv_y = '525.062' iv_dx = '51.524' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '77.774' iv_y = '525.062' iv_dx = '57.193' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '134.467' iv_y = '525.062' iv_dx = '51.524' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '185.491' iv_y = '525.062' iv_dx = '190.421' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '375.412' iv_y = '525.062' iv_dx = '191.839' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '26.75' iv_y = '535.834' iv_dx = '51.524' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '77.774' iv_y = '535.834' iv_dx = '57.193' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '134.467' iv_y = '535.834' iv_dx = '51.524' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '185.491' iv_y = '535.834' iv_dx = '190.421' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '375.412' iv_y = '535.834' iv_dx = '191.839' iv_dy = '0.0' ).

    io_pdf->set_font( iv_name = 'Helvetica' iv_size = '9.0' ).
    io_pdf->text( iv_x = '515.987' iv_y = '65.756' iv_text = 'Page:' ).
    io_pdf->text( iv_x = '542.339' iv_y = '65.806' iv_text = ' 1 / 4' ).
    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = '16.0' ).
    io_pdf->text( iv_x = '241.372' iv_y = '69.515' iv_text = 'Delivery Note' ).
    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = '9.0' ).
    io_pdf->text( iv_x = '29.835' iv_y = '93.171' iv_text = 'Sold-to Address:' ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = '9.0' ).
    io_pdf->text( iv_x = '29.835' iv_y = '105.006' iv_text = 'STILL GMBH' ).
    io_pdf->text( iv_x = '29.835' iv_y = '116.345' iv_text = 'BERZELIUSSTRASSE 4' ).
    io_pdf->text( iv_x = '29.835' iv_y = '127.684' iv_text = '06 22113 HAMBURG' ).
    io_pdf->text( iv_x = '29.835' iv_y = '139.023' iv_text = 'Germany' ).
    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = '9.0' ).
    io_pdf->text( iv_x = '29.835' iv_y = '156.171' iv_text = 'Delivery address / Ship To:' ).
    io_pdf->text( iv_x = '314.646' iv_y = '156.171' iv_text = 'Loading Address:' ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = '9.0' ).
    io_pdf->text( iv_x = '29.835' iv_y = '168.006' iv_text = 'STILL GMBH' ).
    io_pdf->text( iv_x = '314.646' iv_y = '168.006' iv_text = 'Factory Luzzara SAP-LO W002' ).
    io_pdf->text( iv_x = '29.835' iv_y = '179.345' iv_text = 'c/o URBAN-TRANSPORTE GMBH' ).
    io_pdf->text( iv_x = '314.646' iv_y = '179.345' iv_text = 'Strada Bosa 25' ).
    io_pdf->text( iv_x = '29.835' iv_y = '190.684' iv_text = 'LIEBIGSTRASSE 13' ).
    io_pdf->text( iv_x = '314.646' iv_y = '190.684' iv_text = 'RE 42045 Luzzaa' ).
    io_pdf->text( iv_x = '29.835' iv_y = '202.023' iv_text = '02 22113 HAMBURG' ).
    io_pdf->text( iv_x = '314.646' iv_y = '202.023' iv_text = 'Italy' ).
    io_pdf->text( iv_x = '29.835' iv_y = '213.362' iv_text = 'Germany' ).
    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = '9.0' ).
    io_pdf->text( iv_x = '29.835' iv_y = '246.171' iv_text = 'Delivery Note Number' ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = '9.0' ).
    io_pdf->text( iv_x = '158.117' iv_y = '246.171' iv_text = '2000235051' ).
    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = '9.0' ).
    io_pdf->text( iv_x = '418.14' iv_y = '246.171' iv_text = 'Delivery date' ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = '9.0' ).
    io_pdf->text( iv_x = '479.835' iv_y = '246.171' iv_text = '09.07.2025' ).
    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = '9.0' ).
    io_pdf->text( iv_x = '29.835' iv_y = '288.387' iv_text = 'Contact Person' ).
    io_pdf->text( iv_x = '227.835' iv_y = '288.466' iv_text = 'Information' ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = '9.0' ).
    io_pdf->text( iv_x = '29.835' iv_y = '299.371' iv_text = 'Contact person:' ).
    io_pdf->text( iv_x = '101.835' iv_y = '299.371' iv_text = 'STILL GMBH' ).
    io_pdf->text( iv_x = '227.835' iv_y = '299.371' iv_text = 'Customer no.' ).
    io_pdf->text( iv_x = '327.048' iv_y = '299.371' iv_text = '0000000182' ).
    io_pdf->text( iv_x = '426.26' iv_y = '300.252' iv_text = 'Sales Order no.' ).
    io_pdf->text( iv_x = '506.211' iv_y = '300.252' iv_text = '1640000645' ).
    io_pdf->text( iv_x = '29.835' iv_y = '310.71' iv_text = 'Direct tel.:' ).
    io_pdf->text( iv_x = '227.835' iv_y = '310.71' iv_text = 'Terms of payment' ).
    io_pdf->text( iv_x = '327.048' iv_y = '310.71' iv_text = 'Intercompany-15th next' ).
    io_pdf->text( iv_x = '426.26' iv_y = '316.126' iv_text = 'Order date' ).
    io_pdf->text( iv_x = '506.211' iv_y = '316.126' iv_text = '25.04.2024' ).
    io_pdf->text( iv_x = '29.835' iv_y = '322.048' iv_text = 'Direct fax:' ).
    io_pdf->text( iv_x = '227.835' iv_y = '322.049' iv_text = 'Incoterms' ).
    io_pdf->text( iv_x = '327.048' iv_y = '322.049' iv_text = 'DAP-HAMBURG' ).
    io_pdf->text( iv_x = '426.26' iv_y = '332.0' iv_text = 'No. of Packages' ).
    io_pdf->text( iv_x = '29.835' iv_y = '333.387' iv_text = 'E-mail:' ).
    io_pdf->text( iv_x = '227.835' iv_y = '333.388' iv_text = 'Our VAT no.' ).
    io_pdf->text( iv_x = '327.048' iv_y = '333.388' iv_text = 'IT11543160151' ).
    io_pdf->text( iv_x = '227.835' iv_y = '344.727' iv_text = 'Cust. VAT no.' ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = '8.0' ).
    io_pdf->text( iv_x = '506.211' iv_y = '347.615' iv_text = '1.025,000 KG' ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = '9.0' ).
    io_pdf->text( iv_x = '426.26' iv_y = '347.874' iv_text = 'Gross Weight' ).
    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = '9.0' ).
    io_pdf->text( iv_x = '29.835' iv_y = '356.101' iv_text = 'Sales Representative' ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = '9.0' ).
    io_pdf->text( iv_x = '227.835' iv_y = '356.066' iv_text = 'Cust. Registration no:' ).
    io_pdf->text( iv_x = '327.048' iv_y = '356.066' iv_text = 'DE811145412' ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = '8.0' ).
    io_pdf->text( iv_x = '506.211' iv_y = '363.489' iv_text = '1.025,000 KG' ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = '9.0' ).
    io_pdf->text( iv_x = '426.26' iv_y = '363.748' iv_text = 'Net Weight' ).
    io_pdf->text( iv_x = '29.835' iv_y = '367.403' iv_text = 'Contact person:' ).
    io_pdf->text( iv_x = '101.835' iv_y = '367.403' iv_text = 'STILL GMBH' ).
    io_pdf->text( iv_x = '227.835' iv_y = '367.405' iv_text = 'Currency' ).
    io_pdf->text( iv_x = '327.048' iv_y = '367.405' iv_text = 'EUR' ).
    io_pdf->text( iv_x = '227.835' iv_y = '378.472' iv_text = 'Customer reference' ).
    io_pdf->text( iv_x = '29.835' iv_y = '378.741' iv_text = 'Direct tel.:' ).
    io_pdf->text( iv_x = '29.835' iv_y = '390.08' iv_text = 'Direct fax:' ).
    io_pdf->text( iv_x = '29.835' iv_y = '401.418' iv_text = 'E-mail:' ).
    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = '9.0' ).
    io_pdf->text( iv_x = '29.835' iv_y = '424.175' iv_text = 'Your Reference' ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = '9.0' ).
    io_pdf->text( iv_x = '29.835' iv_y = '435.434' iv_text = 'Cust. order no.' ).
    io_pdf->text( iv_x = '101.835' iv_y = '435.434' iv_text = '8506379413' ).
    io_pdf->text( iv_x = '29.835' iv_y = '446.773' iv_text = 'Contact person' ).
    io_pdf->text( iv_x = '29.835' iv_y = '458.111' iv_text = 'Direct tel' ).
    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = '9.0' ).
    io_pdf->text( iv_x = '28.417' iv_y = '510.722' iv_text = 'Delivery Details' ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = '8.0' ).
    io_pdf->text( iv_x = '44.508' iv_y = '521.748' iv_text = 'Pos.' ).
    io_pdf->text( iv_x = '100.147' iv_y = '521.748' iv_text = 'Qty' ).
    io_pdf->text( iv_x = '153.117' iv_y = '521.748' iv_text = 'Unit' ).
    io_pdf->text( iv_x = '187.158' iv_y = '521.748' iv_text = 'Material no.' ).
    io_pdf->text( iv_x = '377.079' iv_y = '521.748' iv_text = 'Description' ).
    io_pdf->text( iv_x = '43.616' iv_y = '532.52' iv_text = '1000' ).
    io_pdf->text( iv_x = '96.363' iv_y = '532.52' iv_text = '1,000' ).
    io_pdf->text( iv_x = '154.673' iv_y = '532.52' iv_text = 'PC' ).
    io_pdf->text( iv_x = '187.158' iv_y = '532.52' iv_text = '45750000030' ).
    io_pdf->text( iv_x = '377.079' iv_y = '532.52' iv_text = 'EXV 14' ).
    io_pdf->text( iv_x = '187.158' iv_y = '543.292' iv_text = 'Truck manfacturer:' ).
    io_pdf->text( iv_x = '377.079' iv_y = '543.292' iv_text = 'STILL S.p.A. Luzzara' ).
    io_pdf->text( iv_x = '187.158' iv_y = '554.064' iv_text = 'Product - STILL' ).
    io_pdf->text( iv_x = '377.079' iv_y = '554.108' iv_text = 'EXV 14-20/-SF/i/D' ).
    io_pdf->text( iv_x = '187.158' iv_y = '564.836' iv_text = 'Basic device for frames' ).
    io_pdf->text( iv_x = '377.079' iv_y = '564.836' iv_text = 'EXV 14 - 000323' ).
    io_pdf->text( iv_x = '187.158' iv_y = '575.608' iv_text = 'Battery compartment' ).
    io_pdf->text( iv_x = '377.079' iv_y = '575.608' iv_text = 'Tray 112' ).
    io_pdf->text( iv_x = '187.158' iv_y = '586.38' iv_text = 'Battery change' ).
    io_pdf->text( iv_x = '377.079' iv_y = '586.424' iv_text = 'vertical / crane' ).
    io_pdf->text( iv_x = '187.158' iv_y = '597.152' iv_text = 'Battery type' ).
    io_pdf->text( iv_x = '377.079' iv_y = '597.196' iv_text = 'PzS/PzQ/TCSM - low maintenance' ).
    io_pdf->text( iv_x = '187.158' iv_y = '607.924' iv_text = 'Truckplug' ).
    io_pdf->text( iv_x = '377.079' iv_y = '607.924' iv_text = '160 A, SBE red' ).
    io_pdf->text( iv_x = '187.158' iv_y = '618.696' iv_text = 'Changing Frame Choice' ).
    io_pdf->text( iv_x = '377.079' iv_y = '618.696' iv_text = 'Standard pricelist' ).
    io_pdf->text( iv_x = '187.158' iv_y = '629.468' iv_text = 'Changing Frame Provider' ).
    io_pdf->text( iv_x = '377.079' iv_y = '629.468' iv_text = 'factory supply' ).
    io_pdf->text( iv_x = '377.079' iv_y = '640.24' iv_text = 'NO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '640.284' iv_text = 'Batt. transport/change frame' ).
    io_pdf->text( iv_x = '187.158' iv_y = '651.012' iv_text = 'Transport change frame LTX' ).
    io_pdf->text( iv_x = '377.079' iv_y = '651.012' iv_text = 'NO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '661.784' iv_text = 'Batt. Maintenance frame' ).
    io_pdf->text( iv_x = '377.079' iv_y = '661.784' iv_text = 'NO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '672.6' iv_text = 'Batt. Transport / change frame' ).
    io_pdf->text( iv_x = '377.079' iv_y = '672.556' iv_text = 'NO' ).
    io_pdf->text( iv_x = '377.079' iv_y = '683.328' iv_text = 'NO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '683.484' iv_text = 'Battery changing frame (EK)' ).
    io_pdf->text( iv_x = '187.158' iv_y = '694.1' iv_text = 'Battery transport frame VNA' ).
    io_pdf->text( iv_x = '377.079' iv_y = '694.1' iv_text = 'NO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '704.872' iv_text = 'Battery maintenance frame VNA' ).
    io_pdf->text( iv_x = '377.079' iv_y = '704.872' iv_text = 'NO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '715.644' iv_text = 'Accessories 1 for batt. frame' ).
    io_pdf->text( iv_x = '377.079' iv_y = '715.644' iv_text = 'NO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '726.416' iv_text = 'Accessories 2 for batt. frame' ).
    io_pdf->text( iv_x = '377.079' iv_y = '726.416' iv_text = 'NO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '737.188' iv_text = 'Accessories 3 for batt. frame' ).
    io_pdf->text( iv_x = '377.079' iv_y = '737.188' iv_text = 'NO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '747.96' iv_text = 'Charger Voltage' ).
    io_pdf->text( iv_x = '377.079' iv_y = '747.96' iv_text = '24 Volt' ).
    io_pdf->text( iv_x = '187.158' iv_y = '758.732' iv_text = 'Battery plug connection' ).
    io_pdf->text( iv_x = '377.079' iv_y = '758.732' iv_text = '160A SBE red grip 1' ).
    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = '7.0' ).
    io_pdf->text( iv_x = '28.417' iv_y = '778.883' iv_text = 'STILL S.p.A.' ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = '7.0' ).
    io_pdf->text( iv_x = '28.417' iv_y = '787.387' iv_text = 'Viale A. de Gasperi 7' ).
    io_pdf->text( iv_x = '184.323' iv_y = '787.387' iv_text = 'Cap. Soc. Euro 21.550.000' ).
    io_pdf->text( iv_x = '340.229' iv_y = '787.387'
                  iv_text = 'Societ' && cl_abap_conv_in_ce=>uccp( '00E0' ) && ' soggetta a direzione e' ).
    io_pdf->text( iv_x = '184.323' iv_y = '795.891' iv_text = 'Registro Imprese di Milano' ).
    io_pdf->text( iv_x = '340.229' iv_y = '795.891' iv_text = 'coordinamento di KION Group AG' ).
    io_pdf->text( iv_x = '28.417' iv_y = '796.164' iv_text = 'I-20045 Lainate (MI)' ).
    io_pdf->text( iv_x = '184.323' iv_y = '804.395' iv_text = 'Cod. Fisc. 01296940214' ).
    io_pdf->text( iv_x = '28.417' iv_y = '804.668' iv_text = 'Tel: +39(02)93765-1' ).
    io_pdf->text( iv_x = '184.323' iv_y = '812.899' iv_text = 'REA di Milano 1351064' ).
    io_pdf->text( iv_x = '340.229' iv_y = '812.899' iv_text = 'PEC: still@pec.still.it' ).
    io_pdf->text( iv_x = '28.417' iv_y = '813.172' iv_text = 'Fax: +39(02)93765-450' ).
    io_pdf->text( iv_x = '28.417' iv_y = '821.403' iv_text = 'info@still.it - www.still.it' ).
    io_pdf->text( iv_x = '184.323' iv_y = '821.403' iv_text = 'Part. I.V.A. IT11543160151' ).
    io_pdf->text( iv_x = '340.229' iv_y = '821.403' iv_text = 'Trading Partner: 1020' ).
  ENDMETHOD.


  METHOD page_2.
    io_pdf->image_base64(
      iv_base64 = logo( )
      iv_x      = '476.504'
      iv_y      = '12.756'
      iv_width  = '93.332'
      iv_height = '28.58' ).

    io_pdf->set_draw_color( iv_r = 0 iv_g = 0 iv_b = 0 ).
    io_pdf->set_line_width( '0.5' ).
    io_pdf->set_fill_color( iv_r = 192 iv_g = 192 iv_b = 192 ).
    io_pdf->rect( iv_x = '27.0' iv_y = '101.339' iv_width = '540.0' iv_height = '11.339' iv_style = 'F' ).
    io_pdf->rect( iv_x = '27.0' iv_y = '101.339' iv_width = '540.0' iv_height = '11.339' iv_style = 'D' ).
    io_pdf->rect( iv_x = '27.0' iv_y = '112.677' iv_width = '540.001' iv_height = '635.548' iv_style = 'D' ).

    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = '8.0' ).
    io_pdf->text( iv_x = '29.88' iv_y = '45.659' iv_text = 'Delivery Note Number' ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = '8.0' ).
    io_pdf->text( iv_x = '118.843' iv_y = '45.659' iv_text = '2000235051' ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = '9.0' ).
    io_pdf->text( iv_x = '515.987' iv_y = '65.756' iv_text = 'Page:' ).
    io_pdf->text( iv_x = '542.339' iv_y = '65.806' iv_text = ' 2 / 4' ).
    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = '9.0' ).
    io_pdf->text( iv_x = '28.417' iv_y = '109.358' iv_text = 'Delivery Details' ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = '8.0' ).
    io_pdf->text( iv_x = '187.158' iv_y = '120.135' iv_text = 'Electrolyte mixing' ).
    io_pdf->text( iv_x = '377.079' iv_y = '120.135' iv_text = 'without' ).
    io_pdf->text( iv_x = '187.158' iv_y = '130.907' iv_text = 'Battery type' ).
    io_pdf->text( iv_x = '377.079' iv_y = '130.951' iv_text = 'PzS/PzQ/TCSM - low maintenance' ).
    io_pdf->text( iv_x = '187.158' iv_y = '141.679' iv_text = 'Battery supplier' ).
    io_pdf->text( iv_x = '377.079' iv_y = '141.679' iv_text = 'STILL' ).
    io_pdf->text( iv_x = '187.158' iv_y = '152.451' iv_text = 'Battery capacity' ).
    io_pdf->text( iv_x = '377.079' iv_y = '152.451' iv_text = '250,00' ).
    io_pdf->text( iv_x = '187.158' iv_y = '163.223' iv_text = 'Loading contacts on the truck' ).
    io_pdf->text( iv_x = '377.079' iv_y = '163.223' iv_text = 'without' ).
    io_pdf->text( iv_x = '187.158' iv_y = '173.995' iv_text = 'Cold store version from Truck' ).
    io_pdf->text( iv_x = '377.079' iv_y = '173.995' iv_text = 'without' ).
    io_pdf->text( iv_x = '187.158' iv_y = '184.767' iv_text = 'Charger' ).
    io_pdf->text( iv_x = '377.079' iv_y = '184.811' iv_text = 'E 24/25 PXS' ).
    io_pdf->text( iv_x = '187.158' iv_y = '195.539' iv_text = 'Charging time' ).
    io_pdf->text( iv_x = '377.079' iv_y = '195.539' iv_text = 'Charging time 9 - 11 hours' ).
    io_pdf->text( iv_x = '187.158' iv_y = '206.311' iv_text = 'Intermediate charging options' ).
    io_pdf->text( iv_x = '377.079' iv_y = '206.311' iv_text = 'NO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '217.083' iv_text = 'Electrolyte mixing' ).
    io_pdf->text( iv_x = '377.079' iv_y = '217.083' iv_text = 'NO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '227.855' iv_text = 'Charger options' ).
    io_pdf->text( iv_x = '377.079' iv_y = '227.855' iv_text = 'NO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '238.627' iv_text = 'Mains connection' ).
    io_pdf->text( iv_x = '377.079' iv_y = '238.627' iv_text = 'S 230V 50Hz.' ).
    io_pdf->text( iv_x = '187.158' iv_y = '249.399' iv_text = 'Charge cable version' ).
    io_pdf->text( iv_x = '377.079' iv_y = '249.399' iv_text = '3 m' ).
    io_pdf->text( iv_x = '187.158' iv_y = '260.171' iv_text = 'Smart Energy Management Ready' ).
    io_pdf->text( iv_x = '377.079' iv_y = '260.171' iv_text = 'NO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '270.943' iv_text = 'Charger connector' ).
    io_pdf->text( iv_x = '377.079' iv_y = '270.943' iv_text = '160A SBE red' ).
    io_pdf->text( iv_x = '187.158' iv_y = '281.715' iv_text = 'CHGR assignment, internal' ).
    io_pdf->text( iv_x = '377.079' iv_y = '281.715' iv_text = 'Without assignment' ).
    io_pdf->text( iv_x = '187.158' iv_y = '292.487' iv_text = 'CHGR assignment, external' ).
    io_pdf->text( iv_x = '377.079' iv_y = '292.487' iv_text = 'Without assignment' ).
    io_pdf->text( iv_x = '187.158' iv_y = '303.259' iv_text = 'Coding pin' ).
    io_pdf->text( iv_x = '377.079' iv_y = '303.259' iv_text = 'Coding pin, grey' ).
    io_pdf->text( iv_x = '187.158' iv_y = '314.031' iv_text = 'Mains plug' ).
    io_pdf->text( iv_x = '377.079' iv_y = '314.031' iv_text = 'Earthed plug' ).
    io_pdf->text( iv_x = '187.158' iv_y = '324.803' iv_text = 'Wall brackets assembly option' ).
    io_pdf->text( iv_x = '377.079' iv_y = '324.803' iv_text = 'external stand device' ).
    io_pdf->text( iv_x = '187.158' iv_y = '335.575' iv_text = 'Air filter Li-ion BC' ).
    io_pdf->text( iv_x = '377.079' iv_y = '335.575' iv_text = 'NO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '346.347' iv_text = 'LED strip charging status' ).
    io_pdf->text( iv_x = '377.079' iv_y = '346.347' iv_text = 'NO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '357.119' iv_text = 'Charger additional equipment' ).
    io_pdf->text( iv_x = '377.079' iv_y = '357.119' iv_text = 'NO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '367.891' iv_text = 'Additional Equipment' ).
    io_pdf->text( iv_x = '377.079' iv_y = '367.891' iv_text = 'NO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '378.663' iv_text = 'Additionel Coating' ).
    io_pdf->text( iv_x = '377.079' iv_y = '378.663' iv_text = 'NO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '389.435' iv_text = 'Time storage' ).
    io_pdf->text( iv_x = '377.079' iv_y = '389.435' iv_text = 'NO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '400.207' iv_text = 'Relay board' ).
    io_pdf->text( iv_x = '377.079' iv_y = '400.207' iv_text = 'NO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '410.979' iv_text = 'Country-specific version' ).
    io_pdf->text( iv_x = '377.079' iv_y = '410.979' iv_text = 'Germany' ).
    io_pdf->text( iv_x = '187.158' iv_y = '421.751' iv_text = 'Charger version' ).
    io_pdf->text( iv_x = '377.079' iv_y = '421.751' iv_text = 'standard' ).
    io_pdf->text( iv_x = '187.158' iv_y = '432.523' iv_text = 'Battery Technology' ).
    io_pdf->text( iv_x = '377.079' iv_y = '432.523' iv_text = 'PzS - low maintenance' ).
    io_pdf->text( iv_x = '187.158' iv_y = '443.295' iv_text = 'Weight kg' ).
    io_pdf->text( iv_x = '377.079' iv_y = '443.295' iv_text = '14,00 kg' ).
    io_pdf->text( iv_x = '187.158' iv_y = '454.067' iv_text = 'Nominal connection power kW' ).
    io_pdf->text( iv_x = '377.079' iv_y = '454.067' iv_text = '0,90' ).
    io_pdf->text( iv_x = '377.079' iv_y = '464.839' iv_text = '360x260x230' ).
    io_pdf->text( iv_x = '187.158' iv_y = '464.995' iv_text = 'Dimensions (mm) [WxDxH]' ).
    io_pdf->text( iv_x = '377.079' iv_y = '475.611' iv_text = '16 A' ).
    io_pdf->text( iv_x = '187.158' iv_y = '475.767' iv_text = 'Main fuse protection (Ampere)' ).
    io_pdf->text( iv_x = '187.158' iv_y = '486.383' iv_text = 'Quantity factory order' ).
    io_pdf->text( iv_x = '377.079' iv_y = '486.383' iv_text = '1' ).
    io_pdf->text( iv_x = '187.158' iv_y = '497.155' iv_text = 'Quantity local order' ).
    io_pdf->text( iv_x = '377.079' iv_y = '497.155' iv_text = '0' ).
    io_pdf->text( iv_x = '187.158' iv_y = '507.927' iv_text = 'Quantity of Chargers' ).
    io_pdf->text( iv_x = '377.079' iv_y = '507.927' iv_text = '1' ).
    io_pdf->text( iv_x = '187.158' iv_y = '518.699' iv_text = 'Charger choice' ).
    io_pdf->text( iv_x = '377.079' iv_y = '518.699' iv_text = 'Standard pricelist' ).
    io_pdf->text( iv_x = '187.158' iv_y = '529.471' iv_text = 'Charger Provider' ).
    io_pdf->text( iv_x = '377.079' iv_y = '529.471' iv_text = 'factory supply' ).
    io_pdf->text( iv_x = '377.079' iv_y = '540.243' iv_text = '24 Volt PXS 25 Single' ).
    io_pdf->text( iv_x = '187.158' iv_y = '540.287' iv_text = 'LEAD/ACID Charger' ).
    io_pdf->text( iv_x = '187.158' iv_y = '551.015' iv_text = 'Li-Ion Charger' ).
    io_pdf->text( iv_x = '377.079' iv_y = '551.015' iv_text = 'NO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '561.831' iv_text = 'LEAD/ACID Charging technologie' ).
    io_pdf->text( iv_x = '377.079' iv_y = '561.787' iv_text = 'PXS' ).
    io_pdf->text( iv_x = '187.158' iv_y = '572.559' iv_text = 'Li-Ion Charger Type' ).
    io_pdf->text( iv_x = '377.079' iv_y = '572.559' iv_text = 'NO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '583.331' iv_text = 'Docking Station' ).
    io_pdf->text( iv_x = '377.079' iv_y = '583.331' iv_text = 'NO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '594.103' iv_text = 'Charger in order' ).
    io_pdf->text( iv_x = '377.079' iv_y = '594.103' iv_text = 'Order incl. charger' ).
    io_pdf->text( iv_x = '187.158' iv_y = '604.875' iv_text = 'Product - STILL' ).
    io_pdf->text( iv_x = '377.079' iv_y = '604.919' iv_text = 'EXV 14-20/-SF/i/D' ).
    io_pdf->text( iv_x = '187.158' iv_y = '615.647' iv_text = 'Basic device for battery' ).
    io_pdf->text( iv_x = '377.079' iv_y = '615.647' iv_text = 'EXV 14 - 000323' ).
    io_pdf->text( iv_x = '187.158' iv_y = '626.419' iv_text = 'Battery compartment' ).
    io_pdf->text( iv_x = '377.079' iv_y = '626.419' iv_text = 'Tray 112' ).
    io_pdf->text( iv_x = '377.079' iv_y = '637.235' iv_text = 'Lead/Acid' ).
    io_pdf->text( iv_x = '187.158' iv_y = '637.347' iv_text = 'Truckversion (Battery)' ).
    io_pdf->text( iv_x = '187.158' iv_y = '647.963' iv_text = 'LI-Ion Ready' ).
    io_pdf->text( iv_x = '377.079' iv_y = '647.963' iv_text = 'without' ).
    io_pdf->text( iv_x = '187.158' iv_y = '658.735' iv_text = 'Instrument cluster' ).
    io_pdf->text( iv_x = '377.079' iv_y = '658.735' iv_text = 'without' ).
    io_pdf->text( iv_x = '187.158' iv_y = '669.507' iv_text = 'Battery Maint.Indicator' ).
    io_pdf->text( iv_x = '377.079' iv_y = '669.507' iv_text = 'without' ).
    io_pdf->text( iv_x = '187.158' iv_y = '680.279' iv_text = 'Cold store version' ).
    io_pdf->text( iv_x = '377.079' iv_y = '680.279' iv_text = 'without' ).
    io_pdf->text( iv_x = '187.158' iv_y = '691.051' iv_text = 'Truckplug -> Batt. Plug' ).
    io_pdf->text( iv_x = '377.079' iv_y = '691.051' iv_text = '160 A, SBE red' ).
    io_pdf->text( iv_x = '187.158' iv_y = '701.823' iv_text = 'Onboard Charger' ).
    io_pdf->text( iv_x = '377.079' iv_y = '701.823' iv_text = 'without' ).
    io_pdf->text( iv_x = '187.158' iv_y = '712.595' iv_text = 'Battery compartment options' ).
    io_pdf->text( iv_x = '377.079' iv_y = '712.595' iv_text = 'without' ).
    io_pdf->text( iv_x = '187.158' iv_y = '723.367' iv_text = 'Battery change' ).
    io_pdf->text( iv_x = '377.079' iv_y = '723.411' iv_text = 'vertical / crane' ).
    io_pdf->text( iv_x = '187.158' iv_y = '734.139' iv_text = 'Loading contacts on the truck' ).
    io_pdf->text( iv_x = '377.079' iv_y = '734.139' iv_text = 'without' ).
    io_pdf->text( iv_x = '187.158' iv_y = '744.911' iv_text = 'Quick Charging Accsess' ).
    io_pdf->text( iv_x = '377.079' iv_y = '744.911' iv_text = 'without' ).
    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = '7.0' ).
    io_pdf->text( iv_x = '28.417' iv_y = '773.214' iv_text = 'STILL S.p.A.' ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = '7.0' ).
    io_pdf->text( iv_x = '28.417' iv_y = '781.718' iv_text = 'Viale A. de Gasperi 7' ).
    io_pdf->text( iv_x = '184.323' iv_y = '781.718' iv_text = 'Cap. Soc. Euro 21.550.000' ).
    io_pdf->text( iv_x = '340.229' iv_y = '781.718'
                  iv_text = 'Societ' && cl_abap_conv_in_ce=>uccp( '00E0' ) && ' soggetta a direzione e' ).
    io_pdf->text( iv_x = '184.323' iv_y = '790.222' iv_text = 'Registro Imprese di Milano' ).
    io_pdf->text( iv_x = '340.229' iv_y = '790.222' iv_text = 'coordinamento di KION Group AG' ).
    io_pdf->text( iv_x = '28.417' iv_y = '790.495' iv_text = 'I-20045 Lainate (MI)' ).
    io_pdf->text( iv_x = '184.323' iv_y = '798.726' iv_text = 'Cod. Fisc. 01296940214' ).
    io_pdf->text( iv_x = '28.417' iv_y = '798.999' iv_text = 'Tel: +39(02)93765-1' ).
    io_pdf->text( iv_x = '184.323' iv_y = '807.23' iv_text = 'REA di Milano 1351064' ).
    io_pdf->text( iv_x = '340.229' iv_y = '807.23' iv_text = 'PEC: still@pec.still.it' ).
    io_pdf->text( iv_x = '28.417' iv_y = '807.503' iv_text = 'Fax: +39(02)93765-450' ).
    io_pdf->text( iv_x = '28.417' iv_y = '815.734' iv_text = 'info@still.it - www.still.it' ).
    io_pdf->text( iv_x = '184.323' iv_y = '815.734' iv_text = 'Part. I.V.A. IT11543160151' ).
    io_pdf->text( iv_x = '340.229' iv_y = '815.734' iv_text = 'Trading Partner: 1020' ).
  ENDMETHOD.


  METHOD page_3.
    io_pdf->image_base64(
      iv_base64 = logo( )
      iv_x      = '476.504'
      iv_y      = '12.756'
      iv_width  = '93.332'
      iv_height = '28.58' ).

    io_pdf->set_draw_color( iv_r = 0 iv_g = 0 iv_b = 0 ).
    io_pdf->set_line_width( '0.5' ).
    io_pdf->set_fill_color( iv_r = 192 iv_g = 192 iv_b = 192 ).
    io_pdf->rect( iv_x = '27.0' iv_y = '101.339' iv_width = '540.0' iv_height = '11.339' iv_style = 'F' ).
    io_pdf->rect( iv_x = '27.0' iv_y = '101.339' iv_width = '540.0' iv_height = '11.339' iv_style = 'D' ).
    io_pdf->rect( iv_x = '27.0' iv_y = '112.677' iv_width = '540.001' iv_height = '635.548' iv_style = 'D' ).

    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = '8.0' ).
    io_pdf->text( iv_x = '29.88' iv_y = '45.659' iv_text = 'Delivery Note Number' ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = '8.0' ).
    io_pdf->text( iv_x = '118.843' iv_y = '45.659' iv_text = '2000235051' ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = '9.0' ).
    io_pdf->text( iv_x = '515.987' iv_y = '65.756' iv_text = 'Page:' ).
    io_pdf->text( iv_x = '542.339' iv_y = '65.806' iv_text = ' 3 / 4' ).
    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = '9.0' ).
    io_pdf->text( iv_x = '28.417' iv_y = '109.358' iv_text = 'Delivery Details' ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = '8.0' ).
    io_pdf->text( iv_x = '187.158' iv_y = '120.135' iv_text = 'Batterie choice' ).
    io_pdf->text( iv_x = '377.079' iv_y = '120.135' iv_text = 'Standard pricelist' ).
    io_pdf->text( iv_x = '187.158' iv_y = '130.907' iv_text = 'Battery Provider' ).
    io_pdf->text( iv_x = '377.079' iv_y = '130.907' iv_text = 'factory supply' ).
    io_pdf->text( iv_x = '187.158' iv_y = '141.679' iv_text = 'Battery maintenance type' ).
    io_pdf->text( iv_x = '377.079' iv_y = '141.679' iv_text = 'low maintenance' ).
    io_pdf->text( iv_x = '187.158' iv_y = '152.451' iv_text = 'Battery' ).
    io_pdf->text( iv_x = '377.079' iv_y = '152.451' iv_text = '24V 2PzS 250 STILL,        112' ).
    io_pdf->text( iv_x = '377.079' iv_y = '163.223' iv_text = '24V 2PzS 250' ).
    io_pdf->text( iv_x = '187.158' iv_y = '163.267' iv_text = 'Battery Lead/Acid' ).
    io_pdf->text( iv_x = '187.158' iv_y = '173.995' iv_text = 'Battery Li-Ion' ).
    io_pdf->text( iv_x = '377.079' iv_y = '173.995' iv_text = 'NO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '184.767' iv_text = 'Water top-up system' ).
    io_pdf->text( iv_x = '377.079' iv_y = '184.767' iv_text = 'STILL 24 V' ).
    io_pdf->text( iv_x = '187.158' iv_y = '195.539' iv_text = 'Fork arm slots' ).
    io_pdf->text( iv_x = '377.079' iv_y = '195.539' iv_text = 'without Fork arm slots' ).
    io_pdf->text( iv_x = '187.158' iv_y = '206.311' iv_text = 'Battery plug connection' ).
    io_pdf->text( iv_x = '377.079' iv_y = '206.311' iv_text = '160A SBE red grip 1' ).
    io_pdf->text( iv_x = '187.158' iv_y = '217.083' iv_text = 'Connector assignment, internal' ).
    io_pdf->text( iv_x = '377.079' iv_y = '217.083' iv_text = 'Without assignment' ).
    io_pdf->text( iv_x = '187.158' iv_y = '227.855' iv_text = 'Connector assignment, external' ).
    io_pdf->text( iv_x = '377.079' iv_y = '227.855' iv_text = 'Without assignment' ).
    io_pdf->text( iv_x = '187.158' iv_y = '238.627' iv_text = 'Coding pin' ).
    io_pdf->text( iv_x = '377.079' iv_y = '238.627' iv_text = 'Coding pin, grey' ).
    io_pdf->text( iv_x = '187.158' iv_y = '249.399' iv_text = 'Traycolour' ).
    io_pdf->text( iv_x = '377.079' iv_y = '249.399' iv_text = 'RAL 7021 dark grey' ).
    io_pdf->text( iv_x = '187.158' iv_y = '260.171' iv_text = 'Tray underside coating' ).
    io_pdf->text( iv_x = '377.079' iv_y = '260.171' iv_text = 'Tray underside coated' ).
    io_pdf->text( iv_x = '377.079' iv_y = '270.987' iv_text = '24 V / 2PzS 250 Ah' ).
    io_pdf->text( iv_x = '187.158' iv_y = '271.099' iv_text = 'Material price increment (MPI)' ).
    io_pdf->text( iv_x = '187.158' iv_y = '281.715' iv_text = 'Low temperature protection' ).
    io_pdf->text( iv_x = '377.079' iv_y = '281.715' iv_text = 'NO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '292.487' iv_text = 'Battery supplier' ).
    io_pdf->text( iv_x = '377.079' iv_y = '292.487' iv_text = 'STILL' ).
    io_pdf->text( iv_x = '187.158' iv_y = '303.259' iv_text = 'Battery cable length' ).
    io_pdf->text( iv_x = '377.079' iv_y = '303.303' iv_text = 'H01N2-E 1x35 +900/-900*' ).
    io_pdf->text( iv_x = '187.158' iv_y = '314.031' iv_text = 'Battery tray' ).
    io_pdf->text( iv_x = '377.079' iv_y = '314.031' iv_text = 'Tray 112' ).
    io_pdf->text( iv_x = '187.158' iv_y = '324.803' iv_text = 'Quantity of Batteries' ).
    io_pdf->text( iv_x = '377.079' iv_y = '324.803' iv_text = '1' ).
    io_pdf->text( iv_x = '187.158' iv_y = '335.575' iv_text = 'Quantity factory order' ).
    io_pdf->text( iv_x = '377.079' iv_y = '335.575' iv_text = '1' ).
    io_pdf->text( iv_x = '187.158' iv_y = '346.347' iv_text = 'Quantity local order' ).
    io_pdf->text( iv_x = '377.079' iv_y = '346.347' iv_text = '0' ).
    io_pdf->text( iv_x = '187.158' iv_y = '357.119' iv_text = 'Battery weight' ).
    io_pdf->text( iv_x = '377.079' iv_y = '357.119' iv_text = '212 kg' ).
    io_pdf->text( iv_x = '187.158' iv_y = '367.891' iv_text = 'Basic device' ).
    io_pdf->text( iv_x = '377.079' iv_y = '367.891' iv_text = 'EXV 14' ).
    io_pdf->text( iv_x = '187.158' iv_y = '378.663' iv_text = 'Mast' ).
    io_pdf->text( iv_x = '377.079' iv_y = '378.663' iv_text = 'TELE 1740' ).
    io_pdf->text( iv_x = '187.158' iv_y = '389.435' iv_text = 'Initial lift' ).
    io_pdf->text( iv_x = '377.079' iv_y = '389.435' iv_text = 'NO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '400.207' iv_text = 'Fork dimension' ).
    io_pdf->text( iv_x = '377.079' iv_y = '400.251' iv_text = 'L/W/H 1150/182/560/55 mm cage' ).
    io_pdf->text( iv_x = '187.158' iv_y = '410.979' iv_text = 'Tyres load rollers' ).
    io_pdf->text( iv_x = '377.079' iv_y = '411.023' iv_text = 'PU/single 85 x 85 mm' ).
    io_pdf->text( iv_x = '187.158' iv_y = '421.751' iv_text = 'Tyres drive wheel' ).
    io_pdf->text( iv_x = '377.079' iv_y = '421.751' iv_text = 'Polyurethane, 230 x 90 mm' ).
    io_pdf->text( iv_x = '187.158' iv_y = '432.523' iv_text = 'Supporting wheel' ).
    io_pdf->text( iv_x = '377.079' iv_y = '432.567' iv_text = 'PU/single 150x50 mm' ).
    io_pdf->text( iv_x = '187.158' iv_y = '443.295' iv_text = 'Mast cover' ).
    io_pdf->text( iv_x = '377.079' iv_y = '443.295' iv_text = 'Mast protection grid' ).
    io_pdf->text( iv_x = '187.158' iv_y = '454.067' iv_text = 'Steering system' ).
    io_pdf->text( iv_x = '377.079' iv_y = '454.067' iv_text = 'Standard tiller LED display' ).
    io_pdf->text( iv_x = '187.158' iv_y = '464.839' iv_text = 'Electric control' ).
    io_pdf->text( iv_x = '377.079' iv_y = '464.839' iv_text = 'Creep speed' ).
    io_pdf->text( iv_x = '187.158' iv_y = '475.611' iv_text = 'Access authorisation' ).
    io_pdf->text( iv_x = '377.079' iv_y = '475.611' iv_text = 'Key switch' ).
    io_pdf->text( iv_x = '187.158' iv_y = '486.383' iv_text = 'Pedestrian operation' ).
    io_pdf->text( iv_x = '377.079' iv_y = '486.469' iv_text = '$Wired remote control' ).
    io_pdf->text( iv_x = '187.158' iv_y = '497.155' iv_text = 'Battery tray' ).
    io_pdf->text( iv_x = '377.079' iv_y = '497.155' iv_text = 'For tray 112, hoistable' ).
    io_pdf->text( iv_x = '187.158' iv_y = '507.927' iv_text = 'Lift cut-out' ).
    io_pdf->text( iv_x = '377.079' iv_y = '507.927' iv_text = 'NO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '518.699' iv_text = 'Truck plug connection' ).
    io_pdf->text( iv_x = '377.079' iv_y = '518.699' iv_text = 'SBE 160 A red' ).
    io_pdf->text( iv_x = '187.158' iv_y = '529.471' iv_text = 'Provision for MMS' ).
    io_pdf->text( iv_x = '377.079' iv_y = '529.471' iv_text = 'NO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '540.243' iv_text = 'Colour code' ).
    io_pdf->text( iv_x = '377.079' iv_y = '540.329' iv_text = '$Ar-silvmet +INOX 8A' ).
    io_pdf->text( iv_x = '187.158' iv_y = '551.015' iv_text = 'Labelling' ).
    io_pdf->text( iv_x = '377.079' iv_y = '551.015' iv_text = 'German' ).
    io_pdf->text( iv_x = '187.158' iv_y = '561.787' iv_text = 'Documentation' ).
    io_pdf->text( iv_x = '377.079' iv_y = '561.787' iv_text = '1 set of documentation' ).
    io_pdf->text( iv_x = '187.158' iv_y = '572.559' iv_text = 'Restraint system' ).
    io_pdf->text( iv_x = '377.079' iv_y = '572.559' iv_text = 'NO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '583.331' iv_text = 'Charging option' ).
    io_pdf->text( iv_x = '377.079' iv_y = '583.331' iv_text = 'NO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '594.103' iv_text = 'Overhead guard' ).
    io_pdf->text( iv_x = '377.079' iv_y = '594.103' iv_text = 'NO' ).
    io_pdf->text( iv_x = '377.079' iv_y = '604.875' iv_text = '1740 mm' ).
    io_pdf->text( iv_x = '187.158' iv_y = '605.031' iv_text = 'closed height h1 (mm)' ).
    io_pdf->text( iv_x = '377.079' iv_y = '615.647' iv_text = '150 mm' ).
    io_pdf->text( iv_x = '187.158' iv_y = '615.803' iv_text = 'Free lift h2 (mm)' ).
    io_pdf->text( iv_x = '377.079' iv_y = '626.419' iv_text = '2344 mm' ).
    io_pdf->text( iv_x = '187.158' iv_y = '626.575' iv_text = 'Rated lift h3 (mm)' ).
    io_pdf->text( iv_x = '377.079' iv_y = '637.191' iv_text = '2864 mm' ).
    io_pdf->text( iv_x = '187.158' iv_y = '637.347' iv_text = 'Maximum height h4 (mm)' ).
    io_pdf->text( iv_x = '187.158' iv_y = '647.963' iv_text = 'Battery Technologie' ).
    io_pdf->text( iv_x = '377.079' iv_y = '647.963' iv_text = 'current Configuration' ).
    io_pdf->text( iv_x = '187.158' iv_y = '658.735' iv_text = 'First time CO content' ).
    io_pdf->text( iv_x = '377.079' iv_y = '658.735' iv_text = '01___SC_500226_1_86_U' ).
    io_pdf->text( iv_x = '187.158' iv_y = '669.507' iv_text = 'First time CO content' ).
    io_pdf->text( iv_x = '377.079' iv_y = '670.134'
                  iv_text = '02DE GABELTR' && cl_abap_conv_in_ce=>uccp( '00C4' ) && 'GER + GABELZINKEN' ).
    io_pdf->text( iv_x = '187.158' iv_y = '680.279' iv_text = 'First time CO content' ).
    io_pdf->text( iv_x = '377.079' iv_y = '680.279' iv_text = '03DE  - Edelstahlverkleidung +' ).
    io_pdf->text( iv_x = '187.158' iv_y = '691.051' iv_text = 'First time CO content' ).
    io_pdf->text( iv_x = '377.079' iv_y = '691.051' iv_text = '04DE  Galvanisierung' ).
    io_pdf->text( iv_x = '187.158' iv_y = '701.823' iv_text = 'First time CO content' ).
    io_pdf->text( iv_x = '377.079' iv_y = '701.867' iv_text = '05DE/TE:18611066' ).
    io_pdf->text( iv_x = '187.158' iv_y = '712.595' iv_text = 'First time CO content' ).
    io_pdf->text( iv_x = '377.079' iv_y = '712.595' iv_text = '06___SC_500226_1_87_U' ).
    io_pdf->text( iv_x = '187.158' iv_y = '723.367' iv_text = 'First time CO content' ).
    io_pdf->text( iv_x = '377.079' iv_y = '723.367' iv_text = '07DE Fernbedienung' ).
    io_pdf->text( iv_x = '187.158' iv_y = '734.139' iv_text = 'First time CO content' ).
    io_pdf->text( iv_x = '377.079' iv_y = '734.183' iv_text = '08DE/TE18621993' ).
    io_pdf->text( iv_x = '187.158' iv_y = '744.911' iv_text = 'First time CO content' ).
    io_pdf->text( iv_x = '377.079' iv_y = '744.911' iv_text = 'wired remote controller' ).
    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = '7.0' ).
    io_pdf->text( iv_x = '28.417' iv_y = '773.214' iv_text = 'STILL S.p.A.' ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = '7.0' ).
    io_pdf->text( iv_x = '28.417' iv_y = '781.718' iv_text = 'Viale A. de Gasperi 7' ).
    io_pdf->text( iv_x = '184.323' iv_y = '781.718' iv_text = 'Cap. Soc. Euro 21.550.000' ).
    io_pdf->text( iv_x = '340.229' iv_y = '781.718'
                  iv_text = 'Societ' && cl_abap_conv_in_ce=>uccp( '00E0' ) && ' soggetta a direzione e' ).
    io_pdf->text( iv_x = '184.323' iv_y = '790.222' iv_text = 'Registro Imprese di Milano' ).
    io_pdf->text( iv_x = '340.229' iv_y = '790.222' iv_text = 'coordinamento di KION Group AG' ).
    io_pdf->text( iv_x = '28.417' iv_y = '790.495' iv_text = 'I-20045 Lainate (MI)' ).
    io_pdf->text( iv_x = '184.323' iv_y = '798.726' iv_text = 'Cod. Fisc. 01296940214' ).
    io_pdf->text( iv_x = '28.417' iv_y = '798.999' iv_text = 'Tel: +39(02)93765-1' ).
    io_pdf->text( iv_x = '184.323' iv_y = '807.23' iv_text = 'REA di Milano 1351064' ).
    io_pdf->text( iv_x = '340.229' iv_y = '807.23' iv_text = 'PEC: still@pec.still.it' ).
    io_pdf->text( iv_x = '28.417' iv_y = '807.503' iv_text = 'Fax: +39(02)93765-450' ).
    io_pdf->text( iv_x = '28.417' iv_y = '815.734' iv_text = 'info@still.it - www.still.it' ).
    io_pdf->text( iv_x = '184.323' iv_y = '815.734' iv_text = 'Part. I.V.A. IT11543160151' ).
    io_pdf->text( iv_x = '340.229' iv_y = '815.734' iv_text = 'Trading Partner: 1020' ).
  ENDMETHOD.


  METHOD page_4.
    io_pdf->image_base64(
      iv_base64 = logo( )
      iv_x      = '476.504'
      iv_y      = '12.756'
      iv_width  = '93.332'
      iv_height = '28.58' ).

    io_pdf->set_draw_color( iv_r = 0 iv_g = 0 iv_b = 0 ).
    io_pdf->set_line_width( '0.5' ).
    io_pdf->set_fill_color( iv_r = 192 iv_g = 192 iv_b = 192 ).
    io_pdf->rect( iv_x = '27.0' iv_y = '101.339' iv_width = '540.0' iv_height = '11.339' iv_style = 'F' ).
    io_pdf->rect( iv_x = '27.0' iv_y = '101.339' iv_width = '540.0' iv_height = '11.339' iv_style = 'D' ).
    io_pdf->rect( iv_x = '27.0' iv_y = '112.677' iv_width = '540.001' iv_height = '64.915' iv_style = 'D' ).
    io_pdf->rect( iv_x = '27.0' iv_y = '177.592' iv_width = '540.001' iv_height = '11.055' iv_style = 'D' ).

    io_pdf->set_line_width( '0.5' ).
    io_pdf->line_from( iv_x = '26.75' iv_y = '188.364' iv_dx = '51.524' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '77.774' iv_y = '188.364' iv_dx = '57.193' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '134.467' iv_y = '188.364' iv_dx = '51.524' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '185.491' iv_y = '188.364' iv_dx = '190.421' iv_dy = '0.0' ).
    io_pdf->line_from( iv_x = '375.412' iv_y = '188.364' iv_dx = '191.839' iv_dy = '0.0' ).

    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = '8.0' ).
    io_pdf->text( iv_x = '29.88' iv_y = '45.659' iv_text = 'Delivery Note Number' ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = '8.0' ).
    io_pdf->text( iv_x = '118.843' iv_y = '45.659' iv_text = '2000235051' ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = '9.0' ).
    io_pdf->text( iv_x = '515.987' iv_y = '65.756' iv_text = 'Page:' ).
    io_pdf->text( iv_x = '542.339' iv_y = '65.806' iv_text = ' 4 / 4' ).
    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = '9.0' ).
    io_pdf->text( iv_x = '28.417' iv_y = '109.358' iv_text = 'Delivery Details' ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = '8.0' ).
    io_pdf->text( iv_x = '187.158' iv_y = '120.135' iv_text = 'First time CO indicator' ).
    io_pdf->text( iv_x = '377.079' iv_y = '120.135' iv_text = 'Configuration with First-CO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '130.907' iv_text = 'Repeat CO indicator' ).
    io_pdf->text( iv_x = '377.079' iv_y = '130.907' iv_text = 'Configuration with Repeat-CO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '141.679' iv_text = 'Technic CO indicator' ).
    io_pdf->text( iv_x = '377.079' iv_y = '141.679' iv_text = 'Configuration with Technic-CO' ).
    io_pdf->text( iv_x = '187.158' iv_y = '152.451' iv_text = 'CO indicator' ).
    io_pdf->text( iv_x = '377.079' iv_y = '152.451' iv_text = 'CO Content' ).
    io_pdf->text( iv_x = '187.158' iv_y = '163.223' iv_text = 'Customer mat. n.:' ).
    io_pdf->text( iv_x = '377.079' iv_y = '163.223' iv_text = '50020000026' ).
    io_pdf->text( iv_x = '187.158' iv_y = '173.995' iv_text = 'Serial number:' ).
    io_pdf->text( iv_x = '377.079' iv_y = '173.995' iv_text = 'F22551P02063' ).
    io_pdf->text( iv_x = '43.616' iv_y = '185.05' iv_text = '1010' ).
    io_pdf->text( iv_x = '96.363' iv_y = '185.05' iv_text = '1,000' ).
    io_pdf->text( iv_x = '154.673' iv_y = '185.05' iv_text = 'PC' ).
    io_pdf->text( iv_x = '187.158' iv_y = '185.05' iv_text = '7999949243' ).
    io_pdf->text( iv_x = '377.079' iv_y = '185.206' iv_text = '(11)dummy ''DCharger' ).
    io_pdf->set_font( iv_name = 'Helvetica-Bold' iv_size = '7.0' ).
    io_pdf->text( iv_x = '28.417' iv_y = '773.214' iv_text = 'STILL S.p.A.' ).
    io_pdf->set_font( iv_name = 'Helvetica' iv_size = '7.0' ).
    io_pdf->text( iv_x = '28.417' iv_y = '781.718' iv_text = 'Viale A. de Gasperi 7' ).
    io_pdf->text( iv_x = '184.323' iv_y = '781.718' iv_text = 'Cap. Soc. Euro 21.550.000' ).
    io_pdf->text( iv_x = '340.229' iv_y = '781.718'
                  iv_text = 'Societ' && cl_abap_conv_in_ce=>uccp( '00E0' ) && ' soggetta a direzione e' ).
    io_pdf->text( iv_x = '184.323' iv_y = '790.222' iv_text = 'Registro Imprese di Milano' ).
    io_pdf->text( iv_x = '340.229' iv_y = '790.222' iv_text = 'coordinamento di KION Group AG' ).
    io_pdf->text( iv_x = '28.417' iv_y = '790.495' iv_text = 'I-20045 Lainate (MI)' ).
    io_pdf->text( iv_x = '184.323' iv_y = '798.726' iv_text = 'Cod. Fisc. 01296940214' ).
    io_pdf->text( iv_x = '28.417' iv_y = '798.999' iv_text = 'Tel: +39(02)93765-1' ).
    io_pdf->text( iv_x = '184.323' iv_y = '807.23' iv_text = 'REA di Milano 1351064' ).
    io_pdf->text( iv_x = '340.229' iv_y = '807.23' iv_text = 'PEC: still@pec.still.it' ).
    io_pdf->text( iv_x = '28.417' iv_y = '807.503' iv_text = 'Fax: +39(02)93765-450' ).
    io_pdf->text( iv_x = '28.417' iv_y = '815.734' iv_text = 'info@still.it - www.still.it' ).
    io_pdf->text( iv_x = '184.323' iv_y = '815.734' iv_text = 'Part. I.V.A. IT11543160151' ).
    io_pdf->text( iv_x = '340.229' iv_y = '815.734' iv_text = 'Trading Partner: 1020' ).
  ENDMETHOD.


  METHOD logo.
    rv_base64 =
      'iVBORw0KGgoAAAANSUhEUgAAANEAAABACAMAAACz3mI7AAADAFBMVEUAAAAGBgYREREXFxcgICApKSkvLy85OTlBQUFHR0dTU1Na' &&
      'WlpkZGRpaWlzc3N9fX2Dg4OXl5ecnJympqasrKy1tbW/v7/Hx8fPz8/V1dXd3d3q6urx8fH3VAD4XQH4XwP4ZAv4aBL4ml34+Pj/' &&
      'WgD/YwD/Ywj/YxD/axD4bRr4cB34eCv4fTH/hDH5gjr5jU35kVL5lVj/nFr5nWP7pG75pnP7qnr8s4X6toz/vYz6vZb7wJv/xpz7' &&
      'z6/80bf/1rX817783Mf84c/95tf869/+8Of99e/+/Pj+/v4AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' &&
      'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' &&
      'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' &&
      'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' &&
      'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' &&
      'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' &&
      'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' &&
      'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABiO4zEAAACaklEQVR42u2Y' &&
      'bXOaQBCAAQmkCkIgQQWDED4lcYyd9CXTTh0TjOX//6KOOG225ICD7uhi7/l4Hnf7yLG3d1J2akjCSBgJI0pGz0scHm5SGkY/l9dh' &&
      'GIWzf+b6YUvD6FsUxRjM7lMaq259hyMUxSsa39FmMUMRisMvRDLD5xBJaL6hYbS+JbLmsIzSBY5QHD0R2Y8ekdbc7OOWhhFW4o7u' &&
      'XmjUDM9YH1H0nUYVtF1i5blHInXdV6SsEC42NIxWaIn7B43aezOnUixgGX3CStyLVxpGqxhrza1pnPjSOVbifspIGL0uwwiF8IbI' &&
      'qRytWLh/IWKUrpDAExJ3QcJIGAkjYSSMSBkFIz48v1H3nHGye8T33gbZt+wZe8XBmfhgQJ/DaKQrvSIKEyvv777vXoqiTXaPDMEg' &&
      'evAngOk5aDdL40yMtxkVo94oGUi87Ce9kBrQy40M0HIGjDTQXh5q0gfd+vVG03Pu8Ib5A04TIzU3MkGLBox0PiP4nw84jD78x0at' &&
      'V91hjRJopJoVGO4+kxiF5h6Mt/CbFRzZyGyxCfz1IVrMLkc0GrYx0ikbWS2MAtJG/UkFfheNZLWCMzvpnlE1stcJowY1g+Se3Dvq' &&
      'hlHmKKdmlHgXpTjOUO6eUTW+empGE1W8o5ZGJl6u89zLCmzlQEa6y2RUMNKY0e66gf1IruJguU5iT28U7w3YYQ6gkU5jPyrB4LsJ' &&
      'GbSrGdCNtGMbcVRB7AOWwTZK+N5R1tSIf9VpzPNEoDUyArdbmc1n5Mi13fow1zkWJ/aYnVzhAMzqPLuy7N9YDjiSTF27ButqN4Nb' &&
      'G9uluMkXRkfiF9PDsOKMgr+nAAAAAElFTkSuQmCC'.
  ENDMETHOD.

ENDCLASS.
