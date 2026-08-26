CLASS ltcl_reader DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    METHODS text_fields FOR TESTING RAISING cx_static_check.
    METHODS checkbox_and_radio FOR TESTING RAISING cx_static_check.
    METHODS escaped_name FOR TESTING RAISING cx_static_check.
    METHODS compact_notation FOR TESTING RAISING cx_static_check.
    METHODS hex_string_value FOR TESTING RAISING cx_static_check.
    METHODS pages FOR TESTING RAISING cx_static_check.
    METHODS not_a_pdf FOR TESTING RAISING cx_static_check.
    METHODS empty_form FOR TESTING RAISING cx_static_check.

    METHODS value_of
      IMPORTING it_fields       TYPE zcl_open_abap_pdf_reader=>ty_fields
                iv_name         TYPE string
      RETURNING VALUE(rv_value) TYPE string.

    METHODS as_bytes
      IMPORTING iv_text         TYPE string
      RETURNING VALUE(rv_bytes) TYPE xstring.
ENDCLASS.

CLASS ltcl_reader IMPLEMENTATION.

  METHOD value_of.
    READ TABLE it_fields INTO DATA(ls_field) WITH KEY name = iv_name.
    rv_value = ls_field-value.
  ENDMETHOD.

  METHOD as_bytes.
    rv_bytes = cl_abap_codepage=>convert_to( |%PDF-1.4\n{ iv_text }\n%%EOF| ).
  ENDMETHOD.

  METHOD text_fields.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->add_page( ).
    lo_pdf->set_font( iv_name = 'Helvetica' iv_size = 10 ).
    lo_pdf->text_field( iv_name = 'NAME' iv_x = 10 iv_y = 10 iv_width = 100 iv_value = 'Anna Weber' ).
    lo_pdf->text_field( iv_name = 'CITY' iv_x = 10 iv_y = 40 iv_width = 100 iv_value = 'Walldorf' ).

    DATA(lt_fields) = zcl_open_abap_pdf_reader=>read_fields( lo_pdf->render_binary( ) ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_fields ) exp = 2 ).
    cl_abap_unit_assert=>assert_equals(
      act = value_of( it_fields = lt_fields iv_name = 'NAME' )
      exp = 'Anna Weber' ).
    cl_abap_unit_assert=>assert_equals(
      act = value_of( it_fields = lt_fields iv_name = 'CITY' )
      exp = 'Walldorf' ).
  ENDMETHOD.

  METHOD checkbox_and_radio.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->add_page( ).
    lo_pdf->set_font( iv_name = 'Helvetica' iv_size = 10 ).
    lo_pdf->checkbox( iv_name = 'ON' iv_x = 10 iv_y = 10 iv_checked = abap_true ).
    lo_pdf->checkbox( iv_name = 'OFF' iv_x = 10 iv_y = 40 ).
    lo_pdf->radio_button(
      iv_name     = 'GROUP'
      iv_value    = 'Second'
      iv_x        = 10
      iv_y        = 70
      iv_selected = abap_true ).

    DATA(lt_fields) = zcl_open_abap_pdf_reader=>read_fields( lo_pdf->render_binary( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = value_of( it_fields = lt_fields iv_name = 'ON' )
      exp = 'Yes' ).
    cl_abap_unit_assert=>assert_equals(
      act = value_of( it_fields = lt_fields iv_name = 'OFF' )
      exp = 'Off' ).
    cl_abap_unit_assert=>assert_equals(
      act = value_of( it_fields = lt_fields iv_name = 'GROUP' )
      exp = 'Second' ).
  ENDMETHOD.

  METHOD escaped_name.
    " Parentheses in a value are escaped in the file and have to come back plain
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->add_page( ).
    lo_pdf->set_font( iv_name = 'Helvetica' iv_size = 10 ).
    lo_pdf->text_field(
      iv_name  = 'NOTE'
      iv_x     = 10
      iv_y     = 10
      iv_width = 100
      iv_value = 'Cable (shielded)' ).

    cl_abap_unit_assert=>assert_equals(
      act = value_of(
        it_fields = zcl_open_abap_pdf_reader=>read_fields( lo_pdf->render_binary( ) )
        iv_name   = 'NOTE' )
      exp = 'Cable (shielded)' ).
  ENDMETHOD.

  METHOD compact_notation.
    " Other writers leave out the blank between key and value
    DATA(lt_fields) = zcl_open_abap_pdf_reader=>read_fields(
      as_bytes( '1 0 obj<</Type/Annot/FT/Tx/T(SUPPLIER)/V(Elektronik GmbH)>>endobj' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = value_of( it_fields = lt_fields iv_name = 'SUPPLIER' )
      exp = 'Elektronik GmbH' ).
  ENDMETHOD.

  METHOD hex_string_value.
    " 4F4B is OK in hexadecimal
    DATA(lt_fields) = zcl_open_abap_pdf_reader=>read_fields(
      as_bytes( '1 0 obj<</T(STATUS)/V<4F4B>>>endobj' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = value_of( it_fields = lt_fields iv_name = 'STATUS' )
      exp = 'OK' ).
  ENDMETHOD.

  METHOD pages.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->add_page( ).
    lo_pdf->add_page( ).
    lo_pdf->add_page( ).

    cl_abap_unit_assert=>assert_equals(
      act = zcl_open_abap_pdf_reader=>page_count( lo_pdf->render_binary( ) )
      exp = 3 ).
  ENDMETHOD.

  METHOD not_a_pdf.
    TRY.
        zcl_open_abap_pdf_reader=>read_fields( cl_abap_codepage=>convert_to( 'this is a text file' ) ).
        cl_abap_unit_assert=>fail( 'the header has to be checked' ).
      CATCH zcx_open_abap_pdf INTO DATA(lx_error).
        cl_abap_unit_assert=>assert_char_cp( act = lx_error->mv_text exp = '*not a PDF*' ).
    ENDTRY.
  ENDMETHOD.

  METHOD empty_form.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->add_page( ).
    lo_pdf->set_font( iv_name = 'Helvetica' iv_size = 10 ).
    lo_pdf->cell( iv_text = 'no fields here' ).

    cl_abap_unit_assert=>assert_initial(
      act = zcl_open_abap_pdf_reader=>read_fields( lo_pdf->render_binary( ) ) ).
  ENDMETHOD.

ENDCLASS.


CLASS ltcl_attachments DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    METHODS attachment_objects FOR TESTING RAISING cx_static_check.
    METHODS mime_is_escaped FOR TESTING RAISING cx_static_check.
    METHODS needs_part_three FOR TESTING RAISING cx_static_check.
    METHODS xmp_names_the_xml FOR TESTING RAISING cx_static_check.

    "! The archive copy holds an ICC profile and compressed streams, so it is
    "! searched as bytes instead of being converted to text
    METHODS assert_contains
      IMPORTING iv_bytes TYPE xstring
                iv_text  TYPE string.
ENDCLASS.

CLASS ltcl_attachments IMPLEMENTATION.

  METHOD assert_contains.
    FIND FIRST OCCURRENCE OF cl_abap_codepage=>convert_to( iv_text )
      IN iv_bytes IN BYTE MODE.

    cl_abap_unit_assert=>assert_subrc(
      exp = 0
      act = sy-subrc
      msg = |the document should contain { iv_text }| ).
  ENDMETHOD.

  METHOD attachment_objects.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->add_page( ).
    lo_pdf->attach_file(
      iv_name = 'data.xml'
      iv_data = cl_abap_codepage=>convert_to( '<invoice/>' ) ).

    DATA(lv_pdf) = lo_pdf->render( ).

    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/Type /EmbeddedFile*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/Type /Filespec*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/UF (data.xml)*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/AFRelationship /Alternative*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/EmbeddedFiles*' ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_pdf exp = '*/Params << /Size 10 >>*' ).
  ENDMETHOD.

  METHOD mime_is_escaped.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->add_page( ).
    lo_pdf->attach_file(
      iv_name = 'note.txt'
      iv_data = cl_abap_codepage=>convert_to( 'hello' )
      iv_mime = 'text/plain' ).

    " a name cannot contain a slash
    cl_abap_unit_assert=>assert_char_cp(
      act = lo_pdf->render( )
      exp = '*/Subtype /text##2Fplain*' ).
  ENDMETHOD.

  METHOD needs_part_three.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->register_font( iv_name = 'Sans' iv_data = zcl_pdf_test_font=>ttf( ) ).
    lo_pdf->set_pdfa( iv_icc = zcl_pdf_test_icc=>srgb( ) iv_part = 1 ).
    lo_pdf->set_font( iv_name = 'Sans' iv_size = 10 ).
    lo_pdf->add_page( ).
    lo_pdf->attach_file(
      iv_name = 'data.xml'
      iv_data = cl_abap_codepage=>convert_to( '<invoice/>' ) ).

    TRY.
        lo_pdf->render_pdfa( ).
        cl_abap_unit_assert=>fail( 'PDF/A-1 must not carry an attachment' ).
      CATCH zcx_open_abap_pdf INTO DATA(lx_error).
        cl_abap_unit_assert=>assert_char_cp( act = lx_error->mv_text exp = '*PDF/A-3*' ).
    ENDTRY.
  ENDMETHOD.

  METHOD xmp_names_the_xml.
    DATA(lo_pdf) = zcl_open_abap_pdf=>create( ).
    lo_pdf->register_font( iv_name = 'Sans' iv_data = zcl_pdf_test_font=>ttf( ) ).
    lo_pdf->set_pdfa( iv_icc = zcl_pdf_test_icc=>srgb( ) iv_part = 3 ).

    " a new page states the current font, so select it first
    lo_pdf->set_font( iv_name = 'Sans' iv_size = 10 ).
    lo_pdf->add_page( ).
    lo_pdf->cell( iv_text = 'invoice' ).
    lo_pdf->attach_file(
      iv_name = 'factur-x.xml'
      iv_data = cl_abap_codepage=>convert_to( '<invoice/>' ) ).

    DATA(lv_pdf) = lo_pdf->render_pdfa( ).

    assert_contains( iv_bytes = lv_pdf iv_text = '<pdfaid:part>3</pdfaid:part>' ).
    assert_contains( iv_bytes = lv_pdf iv_text = '<fx:DocumentFileName>factur-x.xml</fx:DocumentFileName>' ).
    assert_contains( iv_bytes = lv_pdf iv_text = '/AFRelationship /Alternative' ).

    " PDF/A-3 builds on PDF 1.7
    cl_abap_unit_assert=>assert_equals(
      act = cl_abap_codepage=>convert_from( lv_pdf(8) )
      exp = '%PDF-1.7' ).
  ENDMETHOD.

ENDCLASS.
