CLASS zcx_open_abap_pdf DEFINITION PUBLIC INHERITING FROM cx_static_check CREATE PUBLIC.
  PUBLIC SECTION.
    DATA mv_text TYPE string READ-ONLY.

    METHODS constructor
      IMPORTING iv_text     TYPE string
                ix_previous TYPE REF TO cx_root OPTIONAL.

    CLASS-METHODS raise
      IMPORTING iv_text TYPE string
      RAISING   zcx_open_abap_pdf.
ENDCLASS.

CLASS zcx_open_abap_pdf IMPLEMENTATION.

  METHOD constructor.
    super->constructor( previous = ix_previous ).
    mv_text = iv_text.
  ENDMETHOD.

  METHOD raise.
    RAISE EXCEPTION TYPE zcx_open_abap_pdf
      EXPORTING iv_text = iv_text.
  ENDMETHOD.

ENDCLASS.
