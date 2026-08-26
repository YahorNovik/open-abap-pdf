CLASS zcl_stpo_pdf_spool DEFINITION PUBLIC FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    "! Put a PDF that is already in memory into the SAP spool.
    "!
    "! This is the piece that the FP job used to do. ADS_CREATE_PDF_SPOOLJOB
    "! takes the finished bytes and creates a spool request from them, so paper
    "! output, SP01 and SP02, the export as PDF from the spool, and the display
    "! of the original from the document all keep working.
    "!
    "! The output device has to use a device type of format PDF, TSP03D-PATYPE.
    "! Without that the function raises wrong_devtype or not_pdf.
    "!
    "! Example program in the system: FP_TEST_SAVE_PDF_TO_SPOOL.
    "!
    "! @parameter iv_pdf | The document, as returned by render_binary( )
    "! @parameter iv_dest | Output device, in a print program nast-ldest
    "! @parameter iv_pages | Page count, read from the document when left out
    "! @parameter rv_spoolid | The new spool request, log it the way the print
    "!                         program logs the ids returned by FP_JOB_CLOSE
    "! @raising zcx_open_abap_pdf | No document, no device, or a wrong device type
    CLASS-METHODS create
      IMPORTING iv_pdf            TYPE xstring
                iv_dest           TYPE rspopname
                iv_pages          TYPE i DEFAULT 0
      RETURNING VALUE(rv_spoolid) TYPE rspoid
      RAISING   zcx_open_abap_pdf.

  PRIVATE SECTION.
    CLASS-METHODS explain
      IMPORTING iv_subrc       TYPE sysubrc
      RETURNING VALUE(rv_text) TYPE string.
ENDCLASS.


CLASS zcl_stpo_pdf_spool IMPLEMENTATION.

  METHOD explain.
    CASE iv_subrc.
      WHEN 1.
        rv_text = 'there is no document to spool'.
      WHEN 2.
        rv_text = 'the data is not recognised as PDF'.
      WHEN 3.
        rv_text = 'the device type of the output device is not PDF, check TSP03D-PATYPE'.
      WHEN 4.
        rv_text = 'the spool operation failed'.
      WHEN 5.
        rv_text = 'the spool file could not be written'.
      WHEN 6.
        rv_text = 'no output device was given'.
      WHEN 7.
        rv_text = 'the output device does not exist'.
      WHEN OTHERS.
        rv_text = |the spool request was refused, subrc { iv_subrc }|.
    ENDCASE.
  ENDMETHOD.


  METHOD create.
    IF iv_pdf IS INITIAL.
      zcx_open_abap_pdf=>raise( 'there is no document to spool' ).
    ENDIF.
    IF iv_dest IS INITIAL.
      zcx_open_abap_pdf=>raise( 'an output device is needed for a spool request' ).
    ENDIF.

    " The reader counts the pages of a finished document, so the caller does not
    " have to remember how many pages the layout produced
    DATA(lv_pages) = iv_pages.
    IF lv_pages <= 0.
      lv_pages = zcl_open_abap_pdf_reader=>page_count( iv_pdf ).
    ENDIF.

    CALL FUNCTION 'ADS_CREATE_PDF_SPOOLJOB'
      EXPORTING
        dest              = iv_dest
        pages             = lv_pages
        pdf_data          = iv_pdf
      IMPORTING
        spoolid           = rv_spoolid
      EXCEPTIONS
        no_data           = 1
        not_pdf           = 2
        wrong_devtype     = 3
        operation_failed  = 4
        cannot_write_file = 5
        device_missing    = 6
        no_such_device    = 7
        OTHERS            = 8.
    IF sy-subrc <> 0.
      zcx_open_abap_pdf=>raise( explain( sy-subrc ) ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
