CLASS zcl_open_abap_pdf_writer DEFINITION PUBLIC CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES ty_chunks TYPE STANDARD TABLE OF xstring WITH DEFAULT KEY.

    "! Append 7-bit ASCII text to the byte buffer
    METHODS add_string
      IMPORTING iv_string        TYPE string
      RETURNING VALUE(ro_writer) TYPE REF TO zcl_open_abap_pdf_writer.

    "! Append raw bytes to the byte buffer
    METHODS add_xstring
      IMPORTING iv_data          TYPE xstring
      RETURNING VALUE(ro_writer) TYPE REF TO zcl_open_abap_pdf_writer.

    "! Current buffer length in bytes, used for xref offsets
    METHODS length
      RETURNING VALUE(rv_length) TYPE i.

    "! Concatenated byte buffer
    METHODS get
      RETURNING VALUE(rv_data) TYPE xstring.

    "! Deflate iv_data and wrap it in a zlib stream, which is what the PDF
    "! FlateDecode filter expects. cl_abap_gzip delivers a raw deflate stream,
    "! so the two byte header and the Adler-32 checksum are added here.
    CLASS-METHODS zlib_compress
      IMPORTING iv_data        TYPE xstring
      RETURNING VALUE(rv_data) TYPE xstring.

    "! Adler-32 checksum as four bytes, big endian
    CLASS-METHODS adler32
      IMPORTING iv_data       TYPE xstring
      RETURNING VALUE(rv_sum) TYPE xstring.

  PRIVATE SECTION.
    DATA mt_chunks TYPE ty_chunks.
    DATA mv_length TYPE i.
ENDCLASS.

CLASS zcl_open_abap_pdf_writer IMPLEMENTATION.

  METHOD add_string.
    add_xstring( cl_abap_codepage=>convert_to( iv_string ) ).
    ro_writer = me.
  ENDMETHOD.

  METHOD add_xstring.
    APPEND iv_data TO mt_chunks.
    mv_length = mv_length + xstrlen( iv_data ).
    ro_writer = me.
  ENDMETHOD.

  METHOD length.
    rv_length = mv_length.
  ENDMETHOD.

  METHOD get.
    DATA lv_chunk TYPE xstring.

    LOOP AT mt_chunks INTO lv_chunk.
      CONCATENATE rv_data lv_chunk INTO rv_data IN BYTE MODE.
    ENDLOOP.
  ENDMETHOD.

  METHOD adler32.
    DATA lv_a TYPE i VALUE 1.
    DATA lv_b TYPE i.
    DATA lv_byte TYPE x LENGTH 1.
    DATA lv_value TYPE i.
    DATA lv_offset TYPE i.
    DATA lv_sum TYPE x LENGTH 4.

    WHILE lv_offset < xstrlen( iv_data ).
      lv_byte = iv_data+lv_offset(1).
      lv_value = lv_byte.
      lv_a = ( lv_a + lv_value ) MOD 65521.
      lv_b = ( lv_b + lv_a ) MOD 65521.
      lv_offset = lv_offset + 1.
    ENDWHILE.

    lv_sum = lv_b * 65536 + lv_a.
    rv_sum = lv_sum.
  ENDMETHOD.

  METHOD zlib_compress.
    DATA lv_deflate TYPE xstring.
    DATA lv_sum TYPE xstring.
    " 78 9C is deflate with default compression and a 32k window
    DATA lv_header TYPE x LENGTH 2 VALUE '789C'.

    cl_abap_gzip=>compress_binary(
      EXPORTING raw_in   = iv_data
      IMPORTING gzip_out = lv_deflate ).

    lv_sum = adler32( iv_data ).
    CONCATENATE lv_header lv_deflate lv_sum INTO rv_data IN BYTE MODE.
  ENDMETHOD.

ENDCLASS.
