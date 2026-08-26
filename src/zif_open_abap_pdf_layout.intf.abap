INTERFACE zif_open_abap_pdf_layout PUBLIC.

  "! Called after a new page was added, draw the page header here
  METHODS header
    IMPORTING io_pdf TYPE REF TO zcl_open_abap_pdf.

  "! Called before a page is left, draw the page footer here
  METHODS footer
    IMPORTING io_pdf TYPE REF TO zcl_open_abap_pdf.

ENDINTERFACE.
