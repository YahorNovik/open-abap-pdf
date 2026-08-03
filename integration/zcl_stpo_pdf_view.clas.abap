CLASS zcl_stpo_pdf_view DEFINITION PUBLIC FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    "! Show a PDF that is already in memory.
    "!
    "! ADS never displayed anything either. It rendered the form and handed the
    "! bytes to the frontend, and the PDF viewer installed on the PC drew them.
    "! This class does the same handover for a document that was built in ABAP.
    "!
    "! @parameter iv_pdf | The document, as returned by render_binary( )
    "! @parameter iv_name | File name without extension, shown in the viewer
    "! @raising zcx_open_abap_pdf | No frontend, or the frontend refused
    CLASS-METHODS display
      IMPORTING iv_pdf  TYPE xstring
                iv_name TYPE string DEFAULT 'document'
      RAISING   zcx_open_abap_pdf.

    "! abap_true when a SAP GUI is attached, so a batch run never tries to display
    CLASS-METHODS is_frontend_available
      RETURNING VALUE(rv_available) TYPE abap_bool.

    "! Write the document to the workstation without opening it
    CLASS-METHODS download
      IMPORTING iv_pdf         TYPE xstring
                iv_path        TYPE string
      RETURNING VALUE(rv_done) TYPE abap_bool
      RAISING   zcx_open_abap_pdf.

  PRIVATE SECTION.
    CLASS-METHODS to_binary
      IMPORTING iv_pdf          TYPE xstring
      EXPORTING et_data         TYPE solix_tab
                ev_length       TYPE i.

    CLASS-METHODS temp_file
      IMPORTING iv_name        TYPE string
      RETURNING VALUE(rv_path) TYPE string
      RAISING   zcx_open_abap_pdf.
ENDCLASS.


CLASS zcl_stpo_pdf_view IMPLEMENTATION.

  METHOD is_frontend_available.
    " sy-batch is set in a background job, sy-binpt during a batch input,
    " and both mean there is nobody to show a document to
    rv_available = xsdbool( sy-batch IS INITIAL AND sy-binpt IS INITIAL ).
  ENDMETHOD.


  METHOD to_binary.
    et_data = cl_bcs_convert=>xstring_to_solix( iv_pdf ).
    ev_length = xstrlen( iv_pdf ).
  ENDMETHOD.


  METHOD temp_file.
    DATA lv_dir TYPE string.
    DATA lv_separator TYPE c LENGTH 1.

    cl_gui_frontend_services=>get_temp_directory(
      CHANGING  temp_dir             = lv_dir
      EXCEPTIONS cntl_error           = 1
                 error_no_gui         = 2
                 not_supported_by_gui = 3
                 OTHERS               = 4 ).
    IF sy-subrc <> 0 OR lv_dir IS INITIAL.
      zcx_open_abap_pdf=>raise( 'no temporary directory on the workstation' ).
    ENDIF.

    cl_gui_frontend_services=>get_file_separator(
      CHANGING  file_separator       = lv_separator
      EXCEPTIONS cntl_error           = 1
                 error_no_gui         = 2
                 not_supported_by_gui = 3
                 OTHERS               = 4 ).
    IF sy-subrc <> 0.
      lv_separator = '\'.
    ENDIF.

    " The document number alone would collide when two users preview at once
    rv_path = |{ lv_dir }{ lv_separator }{ iv_name }_{ sy-uname }_{ sy-uzeit }.pdf|.
  ENDMETHOD.


  METHOD download.
    DATA lt_data TYPE solix_tab.
    DATA lv_length TYPE i.

    to_binary(
      EXPORTING iv_pdf    = iv_pdf
      IMPORTING et_data   = lt_data
                ev_length = lv_length ).

    cl_gui_frontend_services=>gui_download(
      EXPORTING  bin_filesize            = lv_length
                 filename                = iv_path
                 filetype                = 'BIN'
      CHANGING   data_tab                = lt_data
      EXCEPTIONS file_write_error        = 1
                 no_batch                = 2
                 gui_refuse_filetransfer = 3
                 invalid_type            = 4
                 no_authority            = 5
                 unknown_error           = 6
                 access_denied           = 15
                 OTHERS                  = 24 ).
    IF sy-subrc <> 0.
      zcx_open_abap_pdf=>raise( |the workstation refused the file, subrc { sy-subrc }| ).
    ENDIF.

    rv_done = abap_true.
  ENDMETHOD.


  METHOD display.
    IF iv_pdf IS INITIAL.
      zcx_open_abap_pdf=>raise( 'there is no document to display' ).
    ENDIF.

    IF is_frontend_available( ) = abap_false.
      zcx_open_abap_pdf=>raise( 'a document cannot be displayed in a background run' ).
    ENDIF.

    DATA(lv_path) = temp_file( iv_name ).
    IF download( iv_pdf = iv_pdf iv_path = lv_path ) = abap_false.
      RETURN.
    ENDIF.

    " Hands the file to the shell, which opens whatever PDF viewer the user has.
    " This is the same end result as the print preview of an Adobe form.
    cl_gui_frontend_services=>execute(
      EXPORTING  document               = lv_path
      EXCEPTIONS cntl_error             = 1
                 error_no_gui           = 2
                 bad_parameter          = 3
                 file_not_found         = 4
                 path_not_found         = 5
                 file_extension_unknown = 6
                 error_execute_failed   = 7
                 synchronous_failed     = 8
                 not_supported_by_gui   = 9
                 OTHERS                 = 10 ).
    IF sy-subrc <> 0.
      zcx_open_abap_pdf=>raise( |the workstation could not open the document, subrc { sy-subrc }| ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
