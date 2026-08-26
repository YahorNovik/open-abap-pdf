CLASS ltcl_writer DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    METHODS byte_length FOR TESTING RAISING cx_static_check.
    METHODS mixed_chunks FOR TESTING RAISING cx_static_check.
    METHODS adler_reference FOR TESTING RAISING cx_static_check.
    METHODS zlib_header FOR TESTING RAISING cx_static_check.
    METHODS zlib_round_trip FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_writer IMPLEMENTATION.

  METHOD byte_length.
    DATA(lo_writer) = NEW zcl_open_abap_pdf_writer( ).

    lo_writer->add_string( 'abc' ).
    cl_abap_unit_assert=>assert_equals( act = lo_writer->length( ) exp = 3 ).

    lo_writer->add_xstring( CONV xstring( 'C2B5C2B6' ) ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_writer->length( )
      exp = 7
      msg = 'length counts bytes, not characters' ).
  ENDMETHOD.

  METHOD mixed_chunks.
    DATA(lo_writer) = NEW zcl_open_abap_pdf_writer( ).

    lo_writer->add_string( 'AB' ).
    lo_writer->add_xstring( CONV xstring( 'FF00' ) ).
    lo_writer->add_string( 'C' ).

    cl_abap_unit_assert=>assert_equals(
      act = lo_writer->get( )
      exp = CONV xstring( '4142FF0043' ) ).
  ENDMETHOD.

  METHOD adler_reference.
    " Adler-32 of 'Wikipedia' is 11E60398, the example of the specification
    cl_abap_unit_assert=>assert_equals(
      act = zcl_open_abap_pdf_writer=>adler32( cl_abap_codepage=>convert_to( 'Wikipedia' ) )
      exp = CONV xstring( '11E60398' ) ).
  ENDMETHOD.

  METHOD zlib_header.
    DATA(lv_out) = zcl_open_abap_pdf_writer=>zlib_compress(
      cl_abap_codepage=>convert_to( 'some content stream' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_out(2)
      exp = CONV xstring( '789C' )
      msg = 'FlateDecode expects a zlib header, not a raw deflate stream' ).
  ENDMETHOD.

  METHOD zlib_round_trip.
    DATA lv_text TYPE string.
    DATA lv_back TYPE xstring.

    DO 40 TIMES.
      lv_text = |{ lv_text }BT 50 700 Td (Item { sy-index }) Tj ET |.
    ENDDO.

    DATA(lv_raw) = cl_abap_codepage=>convert_to( lv_text ).
    DATA(lv_zlib) = zcl_open_abap_pdf_writer=>zlib_compress( lv_raw ).

    cl_abap_unit_assert=>assert_true(
      act = xsdbool( xstrlen( lv_zlib ) < xstrlen( lv_raw ) / 2 )
      msg = 'a repetitive content stream has to shrink clearly' ).

    " cl_abap_gzip decompresses the deflate part again, without header and checksum
    cl_abap_gzip=>decompress_binary(
      EXPORTING gzip_in = lv_zlib+2
      IMPORTING raw_out = lv_back ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_back(30)
      exp = lv_raw(30) ).
  ENDMETHOD.

ENDCLASS.
