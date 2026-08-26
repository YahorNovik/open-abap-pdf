CLASS zcl_open_abap_pdf_image DEFINITION PUBLIC FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_info,
        format       TYPE string,
        width        TYPE i,
        height       TYPE i,
        bpc          TYPE i,
        colorspace   TYPE string,
        filter       TYPE string,
        decode_parms TYPE string,
        palette      TYPE xstring,
        data         TYPE xstring,
      END OF ty_info.

    "! Read width, height and the PDF image dictionary values out of the raw file.
    "! JPEG is embedded as DCTDecode, PNG without alpha channel as FlateDecode.
    "! @raising zcx_open_abap_pdf | Unsupported or broken image
    CLASS-METHODS parse
      IMPORTING iv_data        TYPE xstring
      RETURNING VALUE(rs_info) TYPE ty_info
      RAISING   zcx_open_abap_pdf.

  PRIVATE SECTION.
    CLASS-METHODS parse_jpeg
      IMPORTING iv_data        TYPE xstring
      RETURNING VALUE(rs_info) TYPE ty_info
      RAISING   zcx_open_abap_pdf.

    CLASS-METHODS parse_png
      IMPORTING iv_data        TYPE xstring
      RETURNING VALUE(rs_info) TYPE ty_info
      RAISING   zcx_open_abap_pdf.

    CLASS-METHODS uint
      IMPORTING iv_data         TYPE xstring
                iv_offset       TYPE i
                iv_length       TYPE i
      RETURNING VALUE(rv_value) TYPE i.
ENDCLASS.

CLASS zcl_open_abap_pdf_image IMPLEMENTATION.

  METHOD parse.
    IF xstrlen( iv_data ) < 12.
      zcx_open_abap_pdf=>raise( 'image is too short' ).
    ENDIF.

    IF iv_data(2) = 'FFD8'.
      rs_info = parse_jpeg( iv_data ).
    ELSEIF iv_data(8) = '89504E470D0A1A0A'.
      rs_info = parse_png( iv_data ).
    ELSE.
      zcx_open_abap_pdf=>raise( 'only JPEG and PNG images are supported' ).
    ENDIF.
  ENDMETHOD.

  METHOD uint.
    DATA lv_i TYPE i.
    DATA lv_byte TYPE x LENGTH 1.

    DATA(lv_offset) = iv_offset.
    DO iv_length TIMES.
      lv_byte = iv_data+lv_offset(1).
      lv_i = lv_byte.
      rv_value = rv_value * 256 + lv_i.
      lv_offset = lv_offset + 1.
    ENDDO.
  ENDMETHOD.

  METHOD parse_jpeg.
    DATA lv_offset TYPE i.
    DATA lv_marker TYPE string.
    DATA lv_length TYPE i.
    DATA lv_components TYPE i.

    rs_info-format = 'JPEG'.
    rs_info-filter = '/DCTDecode'.
    rs_info-bpc = 8.
    rs_info-data = iv_data.

    lv_offset = 2.
    WHILE lv_offset + 4 <= xstrlen( iv_data ).
      IF iv_data+lv_offset(1) <> 'FF'.
        zcx_open_abap_pdf=>raise( 'broken JPEG, marker expected' ).
      ENDIF.

      lv_marker = iv_data+lv_offset(2).
      lv_length = uint( iv_data = iv_data iv_offset = lv_offset + 2 iv_length = 2 ).

      IF lv_marker = 'FFC0' OR lv_marker = 'FFC1' OR lv_marker = 'FFC2'.
        rs_info-height = uint( iv_data = iv_data iv_offset = lv_offset + 5 iv_length = 2 ).
        rs_info-width = uint( iv_data = iv_data iv_offset = lv_offset + 7 iv_length = 2 ).
        lv_components = uint( iv_data = iv_data iv_offset = lv_offset + 9 iv_length = 1 ).

        CASE lv_components.
          WHEN 1.
            rs_info-colorspace = '/DeviceGray'.
          WHEN 3.
            rs_info-colorspace = '/DeviceRGB'.
          WHEN 4.
            rs_info-colorspace = '/DeviceCMYK'.
          WHEN OTHERS.
            zcx_open_abap_pdf=>raise( |JPEG with { lv_components } components is not supported| ).
        ENDCASE.
        RETURN.
      ENDIF.

      lv_offset = lv_offset + 2 + lv_length.
    ENDWHILE.

    zcx_open_abap_pdf=>raise( 'no JPEG frame header found' ).
  ENDMETHOD.

  METHOD parse_png.
    DATA lv_offset TYPE i.
    DATA lv_length TYPE i.
    DATA lv_type TYPE string.
    DATA lv_type_offset TYPE i.
    DATA lv_color_type TYPE i.
    DATA lv_colors TYPE i.

    rs_info-format = 'PNG'.
    rs_info-filter = '/FlateDecode'.

    lv_offset = 8.
    WHILE lv_offset + 8 <= xstrlen( iv_data ).
      lv_length = uint( iv_data = iv_data iv_offset = lv_offset iv_length = 4 ).
      lv_type_offset = lv_offset + 4.
      lv_type = cl_abap_codepage=>convert_from( iv_data+lv_type_offset(4) ).
      lv_offset = lv_offset + 8.

      CASE lv_type.
        WHEN 'IHDR'.
          rs_info-width = uint( iv_data = iv_data iv_offset = lv_offset iv_length = 4 ).
          rs_info-height = uint( iv_data = iv_data iv_offset = lv_offset + 4 iv_length = 4 ).
          rs_info-bpc = uint( iv_data = iv_data iv_offset = lv_offset + 8 iv_length = 1 ).
          lv_color_type = uint( iv_data = iv_data iv_offset = lv_offset + 9 iv_length = 1 ).

          IF uint( iv_data = iv_data iv_offset = lv_offset + 12 iv_length = 1 ) <> 0.
            zcx_open_abap_pdf=>raise( 'interlaced PNG is not supported' ).
          ENDIF.

          CASE lv_color_type.
            WHEN 0.
              rs_info-colorspace = '/DeviceGray'.
              lv_colors = 1.
            WHEN 2.
              rs_info-colorspace = '/DeviceRGB'.
              lv_colors = 3.
            WHEN 3.
              rs_info-colorspace = '/Indexed'.
              lv_colors = 1.
            WHEN OTHERS.
              zcx_open_abap_pdf=>raise( 'PNG with alpha channel is not supported' ).
          ENDCASE.

          rs_info-decode_parms = |<< /Predictor 15 /Colors { lv_colors } | &&
                                 |/BitsPerComponent { rs_info-bpc } /Columns { rs_info-width } >>|.
        WHEN 'PLTE'.
          rs_info-palette = iv_data+lv_offset(lv_length).
        WHEN 'IDAT'.
          CONCATENATE rs_info-data iv_data+lv_offset(lv_length) INTO rs_info-data IN BYTE MODE.
        WHEN 'IEND'.
          " tRNS, gAMA, pHYs and the checksums are not needed for placing the image
          EXIT.
      ENDCASE.

      lv_offset = lv_offset + lv_length + 4.
    ENDWHILE.

    IF rs_info-width = 0 OR rs_info-data IS INITIAL.
      zcx_open_abap_pdf=>raise( 'broken PNG, no header or no image data' ).
    ENDIF.

    IF rs_info-colorspace = '/Indexed' AND rs_info-palette IS INITIAL.
      zcx_open_abap_pdf=>raise( 'indexed PNG without palette' ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
