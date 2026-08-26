CLASS zcl_open_abap_pdf_barcode DEFINITION PUBLIC FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    "! Encode a text as Code 128, character set B, with the check digit.
    "! @parameter rv_modules | One character per module, 1 is a bar
    "! @raising zcx_open_abap_pdf | Character outside the printable ASCII range
    CLASS-METHODS code128
      IMPORTING iv_text           TYPE string
      RETURNING VALUE(rv_modules) TYPE string
      RAISING   zcx_open_abap_pdf.

  PRIVATE SECTION.
    CONSTANTS c_start_b TYPE i VALUE 104.
    CONSTANTS c_stop TYPE i VALUE 106.

    CLASS-METHODS patterns
      RETURNING VALUE(rv_table) TYPE string.

    CLASS-METHODS pattern_of
      IMPORTING iv_value          TYPE i
      RETURNING VALUE(rv_pattern) TYPE string.
ENDCLASS.

CLASS zcl_open_abap_pdf_barcode IMPLEMENTATION.

  METHOD patterns.
    " The 107 element widths of Code 128, six digits per symbol, the stop pattern has seven
    rv_table =
      '212222222122222221121223121322131222122213122312132212221213' &&
      '221312231212112232122132122231113222123122123221223211221132' &&
      '221231213212223112312131311222321122321221312212322112322211' &&
      '212123212321232121111323131123131321112313132113132311211313' &&
      '231113231311112133112331132131113123113321133121313121211331' &&
      '231131213113213311213131311123311321331121312113312311332111' &&
      '314111221411431111111224111422121124121421141122141221112214' &&
      '112412122114122411142112142211241211221114413111241112134111' &&
      '111242121142121241114212124112124211411212421112421211212141' &&
      '214121412121111143111341131141114113114311411113411311113141' &&
      '114131311141411131211412211214211232'.
  ENDMETHOD.

  METHOD pattern_of.
    IF iv_value = c_stop.
      rv_pattern = '2331112'.
      RETURN.
    ENDIF.

    DATA(lv_offset) = iv_value * 6.
    DATA(lv_table) = patterns( ).
    rv_pattern = lv_table+lv_offset(6).
  ENDMETHOD.

  METHOD code128.
    DATA lt_values TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
    DATA lv_value TYPE i.
    DATA lv_offset TYPE i.
    DATA lv_width TYPE i.
    DATA lv_dark TYPE abap_bool.

    IF iv_text IS INITIAL.
      zcx_open_abap_pdf=>raise( 'nothing to encode' ).
    ENDIF.

    APPEND c_start_b TO lt_values.

    DATA(lv_checksum) = c_start_b.
    DATA(lv_position) = 0.

    LOOP AT zcl_open_abap_pdf_font=>to_unicode( iv_text ) INTO DATA(lv_cp).
      IF lv_cp < 32 OR lv_cp > 126.
        DATA(lv_message) = |Code 128 B cannot encode the character with code { lv_cp }|.
        zcx_open_abap_pdf=>raise( lv_message ).
      ENDIF.

      lv_position = lv_position + 1.
      lv_value = lv_cp - 32.
      APPEND lv_value TO lt_values.

      " The weight of a character is its position, counted from one
      lv_checksum = lv_checksum + lv_value * lv_position.
    ENDLOOP.

    APPEND lv_checksum MOD 103 TO lt_values.
    APPEND c_stop TO lt_values.

    " Every pattern alternates bar and space, starting with a bar
    LOOP AT lt_values INTO lv_value.
      DATA(lv_pattern) = pattern_of( lv_value ).
      lv_offset = 0.
      lv_dark = abap_true.

      WHILE lv_offset < strlen( lv_pattern ).
        lv_width = CONV i( lv_pattern+lv_offset(1) ).
        DO lv_width TIMES.
          IF lv_dark = abap_true.
            rv_modules = |{ rv_modules }1|.
          ELSE.
            rv_modules = |{ rv_modules }0|.
          ENDIF.
        ENDDO.

        IF lv_dark = abap_true.
          lv_dark = abap_false.
        ELSE.
          lv_dark = abap_true.
        ENDIF.
        lv_offset = lv_offset + 1.
      ENDWHILE.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
