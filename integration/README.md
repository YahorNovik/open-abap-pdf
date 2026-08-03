# Testing open-abap-pdf in a real SAP system

Everything in this folder is SAP only. It uses `cl_gui_frontend_services` and DDIC types, so it is
not part of `src/`, is not checked by abaplint and is not transpiled. `src/` stays free of frontend
and DDIC dependencies so that it keeps running on ABAP Cloud and in the Node preview loop.

| Object | Purpose |
|--------|---------|
| `ZCL_STPO_PDF_VIEW` | hands a PDF that is in memory to the PDF viewer of the workstation |
| `ZSTPO_PDF_PREVIEW_DEMO` | standalone report, renders a purchase order and previews it |
| `ZCL_STPO_PDF_SWITCH` | decides per message whether this library or ADS renders |

## 1. Install

Two abapGit repositories from the same URL, because the starting folder differs:

| Repository | Starting folder | Package | Contains |
|------------|-----------------|---------|----------|
| open-abap-pdf | `/src/` | `ZOPEN_ABAP_PDF` | the library, 11 classes, one interface, one exception |
| open-abap-pdf | `/integration/` | `ZSTPO_PDF_OUT` | the three objects above |

The starting folder is set in the abapGit repository settings. Nothing else is needed: the library
has no DDIC objects, no tables, no configuration, no ADS, no printer setup.

The library uses exactly two non language APIs, `cl_abap_codepage` and
`cl_http_utility=>decode_x_base64`. On ABAP Cloud swap them for `cl_abap_conv_codepage` and
`cl_web_http_utility`.

## 2. First test, no output determination involved

Run `ZSTPO_PDF_PREVIEW_DEMO`. It renders a purchase order and opens it in the viewer of the
workstation. Nothing is printed, no spool request is created, no output type is touched.

| Field | Meaning |
|-------|---------|
| Purchasing document | the document to read |
| Read the document from the database | off shows the layout with sample values, useful on an empty client |
| Show in the viewer / Save to a file | preview, or write the file and inspect it |

What this proves in one run: the library activates and runs on the real kernel, the fonts and the
layout are correct, and the preview handover works on your desktops.

If the viewer does not open, run it again with **Save to a file** and open the file by hand. That
separates a rendering problem from a frontend problem.

## 3. Wiring it into ZSTPO_PRINT_PO_SA_CC

Everything in that program funnels through `adobe_print_output`, and the document leaves the routine
in one variable, `os_formout-pdf` of type `fpformoutput`. Three of the four channels already read
that variable, so they need no change at all:

| Channel | Reads `os_formout-pdf` | After the swap |
|---------|------------------------|----------------|
| e-mail and fax, `nast-nacha` 5 and 2 | yes, `cl_document_bcs` and `cl_bcs` | works unchanged, including the four BAdI hooks |
| archive, `nast-tdarmod` 2 and 3 | yes, `ARCHIV_CREATE_OUTGOINGDOCUMENT` | works unchanged |
| web preview, `if_preview` = `W` | yes, `EXPORT lv_pdf_file ... TO MEMORY ID 'PDF_FILE'` | works unchanged |
| print, `nast-nacha` 1 | no, the spool request comes from the FP job | keep on ADS in phase one |

The change is one block around the existing `CALL FUNCTION ls_function`:

```abap
IF zcl_stpo_pdf_switch=>use_own_renderer( is_nast    = nast
                                          iv_preview = if_preview ) = abap_true.

  os_formout-pdf = zcl_stpo_po_form=>render( io_output    = cl_output_po
                                             is_docparams = fp_docparams ).

  " the screen preview used to be opened by the FP framework, so it has to be
  " opened here now. 'W' is already handled at the end of the routine.
  IF if_preview IS NOT INITIAL AND if_preview <> 'W'.
    zcl_stpo_pdf_view=>display( iv_pdf  = os_formout-pdf
                                iv_name = |PO_{ nast-objky }| ).
  ENDIF.

ELSE.

  CALL FUNCTION ls_function
    EXPORTING /1bcdwb/docparams = fp_docparams
              header            = cl_output_po->is_ekko
              " ... the existing parameters, unchanged
    IMPORTING /1bcdwb/formoutput = os_formout.

ENDIF.
```

`ZCL_STPO_PO_FORM` is the layout class you write once, against the same data the Adobe form gets
today. `CL_PURCHASE_ORDER_OUTPUT` has already collected all of it, so no new selects and no new
authorisation checks:

| Data | Attribute | Used for |
|------|-----------|----------|
| header | `is_ekko` | document number, date, vendor, currency, incoterms |
| items | `it_ekpo` | the item table |
| schedule | `it_eket` | delivery dates |
| conditions | `it_komvd` | prices and surcharges |
| address | `is_t024e`, `is_t024` | purchasing organisation and buyer |
| texts | `it_t166k`, `it_t166p`, `it_t166a`, `it_t166t` | the text modules per company and document type |

There are fourteen entry routines in the program, `adobe_entry_neu`, `_absa`, `_mahn`, `_lpet`,
`_lphe`, `_lpje`, `_lpma`, `_aufb`, `_lpfz` and three `entry_*_auto`, and all of them call
`adobe_print_output`. One swap covers every output type.

## 4. Two traps in that program

- There is a commented out copy of the whole routine of about 1100 lines further down. Patch the
  live one.
- `cl_mmpur_constants=>if_mmpur_constants_func_switch~output_control_brf_bopf` is checked in more
  than thirty places, so the program also runs under the newer output control. Check which of your
  purchasing output types take which path before you switch anything on.

## 5. Rollback

`ZCL_STPO_PDF_SWITCH` answers `abap_false` for everything except the piloted application and output
type, and never for print. Reverting means changing that method, or the customizing table it reads
once you replace the constants.
