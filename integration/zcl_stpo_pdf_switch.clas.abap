CLASS zcl_stpo_pdf_switch DEFINITION PUBLIC FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    "! Decides per message whether the document is rendered by this library or
    "! by Adobe Document Services, so the change can be switched on for one
    "! output type in one company code and rolled back without a transport.
    "!
    "! Print is off by default, not because the spool cannot be written any more
    "! but because it needs an output device with a device type of format PDF.
    "! Switch iv_allow_print on once that device exists, see ZCL_STPO_PDF_SPOOL.
    "!
    "! @parameter is_nast | The message that is being processed
    "! @parameter iv_preview | The ent_screen flag of the entry routine
    CLASS-METHODS use_own_renderer
      IMPORTING is_nast       TYPE nast
                iv_preview    TYPE c DEFAULT space
      RETURNING VALUE(rv_own) TYPE abap_bool.

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

    " Print needs an output device of format PDF, see the comment above
    CONSTANTS c_allow_print TYPE abap_bool VALUE abap_false.

    IF iv_preview IS INITIAL
       AND is_nast-nacha = c_medium_print
       AND c_allow_print = abap_false.
      RETURN.
    ENDIF.

    rv_own = abap_true.
  ENDMETHOD.

ENDCLASS.
