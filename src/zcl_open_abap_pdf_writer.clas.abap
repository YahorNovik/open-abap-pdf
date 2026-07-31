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

ENDCLASS.
