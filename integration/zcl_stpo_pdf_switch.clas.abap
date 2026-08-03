CLASS zcl_stpo_pdf_switch DEFINITION PUBLIC FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    "! Decides per message whether the document is rendered by this library or
    "! by Adobe Document Services, so the change can be switched on for one
    "! output type in one company code and rolled back without a transport.
    "!
    "! Phase one deliberately answers abap_false for print, because the spool
    "! request is created by the FP job and not from the PDF in memory.
    "!
    "! @parameter is_nast | The message that is being processed
    "! @parameter iv_preview | The ent_screen flag of the entry routine
    CLASS-METHODS use_own_renderer
      IMPORTING is_nast          TYPE nast
                iv_preview       TYPE c DEFAULT space
      RETURNING VALUE(rv_own)    TYPE abap_bool.

  PRIVATE SECTION.
    CONSTANTS c_medium_print TYPE nast-nacha VALUE '1'.
ENDCLASS.


CLASS zcl_stpo_pdf_switch IMPLEMENTATION.

  METHOD use_own_renderer.
    " Read this from a Z customizing table once more than one output type is
    " migrated. A constant keeps the pilot obvious and reversible.
    CONSTANTS c_pilot_kappl TYPE nast-kappl VALUE 'EF'.
    CONSTANTS c_pilot_kschl TYPE nast-kschl VALUE 'NEU'.

    IF is_nast-kappl <> c_pilot_kappl OR is_nast-kschl <> c_pilot_kschl.
      RETURN.
    ENDIF.

    " Print still goes through ADS, see the comment above
    IF iv_preview IS INITIAL AND is_nast-nacha = c_medium_print.
      RETURN.
    ENDIF.

    rv_own = abap_true.
  ENDMETHOD.

ENDCLASS.
