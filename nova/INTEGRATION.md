# Integrating open-abap-pdf into a real ABAP implementation

## 1. What the library actually depends on

The whole `src/` folder uses exactly two non-language APIs:

| API | Used in | Purpose |
|-----|---------|---------|
| `cl_abap_codepage` | writer, font, image, document (7 call sites) | string <-> xstring |
| `cl_http_utility=>decode_x_base64` | `image_base64( )` only (1 call site) | convenience for base64 images |

Everything else is pure ABAP language: strings, xstrings, internal tables, `CONCATENATE ... IN BYTE MODE`,
`xstrlen`, string templates. No DDIC objects, no database, no RFC, no file system, no ADS.

Consequences:

- Installation is one abapGit pull into a Z package, nothing else. No configuration, no printer setup,
  no BTP service, no licence.
- On ABAP Cloud / Steampunk the two call sites above should be swapped for
  `cl_abap_conv_codepage` and `cl_web_http_utility` (or drop `image_base64` and pass the xstring).
  Both are one-line changes and can be hidden behind a private helper method.
- The library never decides where the document goes. `render_binary( )` returns an `xstring`, the
  calling application owns the channel.

## 2. Where the xstring can go

| Channel | On premise (ECC / S/4) | ABAP Cloud / Steampunk | Notes |
|---------|------------------------|------------------------|-------|
| E-mail | `cl_bcs` | `cl_bcs_mail_message` | most common for invoices, order confirmations |
| Fiori download / preview | RAP action returning the xstring, or a media custom entity | same | Elements shows it in a new tab, no extra service |
| HTTP endpoint | SICF / ICF handler, `if_http_extension` | HTTP service, `if_http_service_extension` | set `application/pdf` |
| Attachment on a business object | GOS / ArchiveLink / DMS | attachment BO or CMIS / Document Management service | ArchiveLink is on premise only |
| Archive | ArchiveLink content repository | external store via API | see PDF/A gap below |
| File | `cl_gui_frontend_services` (SAP GUI), AL11 | none, cloud has no file system | use HTTP download instead |
| Database | any Z table with a RAWSTRING field | same | good for reprint and audit |
| Printer | only via a PDF capable output device / pass through device type | not available | this is the weak spot, see below |

## 3. Recommended implementation shape

Three layers, so the layout can be regenerated and unit tested independently:

```abap
" 1. data collector - reads the business data, no PDF knowledge
zcl_inv_data=>read( iv_vbeln ) -> ty_invoice

" 2. layout class - takes the data structure, returns bytes, no SELECT inside
zcl_inv_pdf_form=>render( is_invoice ) -> xstring

" 3. channel - decides what happens with the bytes
zcl_inv_output=>email( ) / archive( ) / download( )
```

Why the split matters:

- The layout class is deterministic, so a unit test can assert on the rendered content without a
  database and the local Node preview loop can run it without an SAP system.
- Reprint, resend and archive all reuse the same layout class, no copy of the drawing code.
- Data collection is the part that has to be Clean Core compliant (released CDS views, RAP),
  the layout part has no dependency on SAP objects at all.

Interface to keep the channel replaceable:

```abap
INTERFACE zif_doc_renderer.
  METHODS render IMPORTING is_data TYPE any RETURNING VALUE(rv_pdf) TYPE xstring.
ENDINTERFACE.
```

## 4. Integration with SAP output management

| Scenario | Possible | How |
|----------|----------|-----|
| S/4 Output Control as form technology | No | Output Control supports SmartForms, Adobe Forms and Adobe Forms with fragments only, there is no registration point for a custom renderer |
| Output Control for determination, own rendering | Yes | let Output Control determine recipients, channel and rules, then generate the PDF in your own code and send it with `cl_bcs` |
| NAST / classic output types (ECC, VBELN based) | Yes | the output type calls a Z print program, that program calls the layout class |
| Correspondence, dunning, payment advice frameworks | Partly | wherever the framework calls a Z form routine, the class can be called there; where it insists on a SAPscript or Smart Form name, it cannot |
| Spool and physical printing | Yes | `ADS_CREATE_PDF_SPOOLJOB` creates a spool request from a PDF in memory, example program `FP_TEST_SAVE_PDF_TO_SPOOL`. The output device has to use a device type of format PDF. A system that already prints Adobe forms has that, because ADS output is PDF in the spool |
| e-invoicing (Peppol, KSeF, FatturaPA, ZUGFeRD) | Yes, as the readable half | the legal artifact is XML. `attach_file( )` with PDF/A-3 embeds it, which is what ZUGFeRD and Factur-X require |

### Injecting into a classic ADS print program

Measured on a real custom copy of `SAPFM06P`, a purchasing print program of about 6300 lines. All
fourteen entry routines converge on one routine, and the document leaves it in a single variable,
`os_formout-pdf` of type `fpformoutput`, filled by `CALL FUNCTION ls_function` where `ls_function`
comes from `FP_FUNCTION_MODULE_NAME( tnapr-sform )`.

| Channel | Reads `os_formout-pdf` | After filling it from this library |
|---------|------------------------|-----------------------------------|
| e-mail and fax, `nacha` 5 and 2 | yes, `cl_document_bcs` plus `cl_bcs` | works unchanged, BAdI hooks included |
| archive, `tdarmod` 2 and 3 | yes, `ARCHIV_CREATE_OUTGOINGDOCUMENT` | works unchanged |
| web preview, `ent_screen` = `W` | yes, `EXPORT ... TO MEMORY ID 'PDF_FILE'` | works unchanged |
| screen preview, `ent_screen` = `X` | no, the FP framework opened the viewer | needs a display handover, see `integration/` |
| print, `nacha` 1 | no, the spool request comes from the FP job | keep on ADS first |

So three of the four channels need no change at all, because the program already treats the rendered
document as a PDF in memory. The data does not have to be collected again either: the form interface
is filled from `cl_purchase_order_output`, and a layout class can take the same structures.

## 5. Feature gaps that decide whether it fits

Closed since the first assessment:

| Was a gap | Now |
|-----------|-----|
| Only WinAnsi text | TrueType embedding, Type0 / Identity-H, subsetting, so Polish, Czech, Turkish, Cyrillic and Greek render |
| No PDF/A | PDF/A-1b and PDF/A-3b with XMP, sRGB output intent and rule checks |
| No stream compression | FlateDecode for content, fonts and ToUnicode maps, about a fifth of the size |
| No barcodes or QR codes | Code 128 and a QR encoder, both verified by decoding the rendered raster |
| No justified text | `c_align_justify` in `multi_cell( )` |
| No rotation | `text_rotated( )` |
| Cannot read a PDF | `zcl_open_abap_pdf_reader` reads form values and the page count, also from compressed object streams |
| No ZUGFeRD or Factur-X | `attach_file( )` with PDF/A-3, the XML is named in the metadata |

Still open:

| Gap | Impact | Effort to close |
|-----|--------|-----------------|
| No tagged PDF, no structure tree | no screen reader support, and PDF/A-1a and PDF/UA are out of reach. Documents produced by Adobe LiveCycle are tagged, so a redraw loses that layer | medium, marked content operators plus a structure tree and a parent tree |
| No digital signature | no qualified signing inside ABAP | large, needs CMS and key handling |
| Cannot fill an existing PDF template | an authority form that must be used as a template cannot be filled | large, needs a full parser |
| Spool needs one standard call | `ADS_CREATE_PDF_SPOOLJOB` takes the finished bytes and creates the spool request, so this is no longer a gap, but the output device has to use a device type of format PDF | done, see `integration/zcl_stpo_pdf_spool.clas.abap` |
| No hyphenation, no RTL | dense letter layouts differ from Word output | medium |
| No clipping, dashes, gradients, transparency | stamps and effects need workarounds | small per feature |
| Layout is code, not a design tool | a key user cannot adapt the layout, a developer and a transport are needed | by design |
| Performance | string based assembly, a 5000 row table costs memory and time | medium, streaming writer |

## 6. What is genuinely better than the standard options

- No Adobe Document Services, no BTP Forms Service, no licence, no extra infrastructure, and the same
  code runs on ECC 7.40, S/4 on premise and ABAP Cloud.
- The layout is ABAP source, so it is transportable, diffable, reviewable in a pull request and
  testable with ABAP Unit. Smart Form and Adobe Form transports are binary and cannot be reviewed.
- A layout can be generated from a specification or a screenshot and iterated on in seconds outside
  SAP, which is what the local preview loop is for.
- Unit tests can assert on the content of the document, not only on the fact that something was
  produced.

## 7. Verification split

| Verified without SAP | Must be verified in the system |
|----------------------|--------------------------------|
| geometry, fonts, wrapping, page breaks, tables, images, form fields | data selection and authorisations |
| ABAP Unit tests, abaplint static checks | activation and syntax for the real release and language version |
| PDF structural validity, text layer | behaviour where the open-abap runtime differs from the SAP kernel |

Known runtime difference found so far: `WRITE ... CURRENCY` is not implemented by the transpiler and
silently produced unformatted numbers. Format numbers explicitly.

Also pin the abaplint syntax version to the target release, currently the repository uses
`"version": "open-abap"` which is more permissive than a 7.40 system.
