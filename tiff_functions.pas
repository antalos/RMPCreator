unit tiff_functions;

interface
uses SysUtils, classes, windows, math, LibTiffDelphi, Graphics;

type



  
  TIFDEntry = packed record
                 Tag     : word;
                 DataType: word;
                 Count   : cardinal;
                 Offset  : cardinal;
               end;

const
  // TIFF data types. Rationals are not supported (except for IFDs)
  TIFF_NOTYPE    = 0;      // placeholder
  TIFF_BYTE      = 1;      // dspUInt8
  TIFF_ASCII     = 2;      // dspUInt8 (7-bit ASCII)
  TIFF_SHORT     = 3;      // dspUInt16
  TIFF_LONG      = 4;      // dspUInt32
  TIFF_RATIONAL  = 5;      // unsupported
  TIFF_SBYTE     = 6;      // 8-bit signed integer
  TIFF_UNDEFINED = 7;      // dspUInt8 (raw data)
  TIFF_SSHORT    = 8;      // dspInt16
  TIFF_SLONG     = 9;      // dspInt32
  TIFF_SRATIONAL = 10;     // unsupported
  TIFF_FLOAT     = 11;     // dspFloat32
  TIFF_DOUBLE    = 12;     // dspFloat64
  TIFF_IFD       = 13;     // offset, dspUInt32

  // Supported baseline TIFF tags
  TIFFTAG_IMAGEWIDTH      = 256;
  TIFFTAG_IMAGELENGTH     = 257;
  TIFFTAG_BITSPERSAMPLE   = 258;
  TIFFTAG_COMPRESSION     = 259;
  TIFFTAG_PHOTOMETRIC     = 262;
  TIFFTAG_IMAGEDESCRIPTION= 270;
  TIFFTAG_STRIPOFFSETS    = 273;
  TIFFTAG_SAMPLESPERPIXEL = 277;
  TIFFTAG_ROWSPERSTRIP    = 278;
  TIFFTAG_STRIPBYTECOUNTS = 279;
  TIFFTAG_XRESOLUTION     = 282;
  TIFFTAG_YRESOLUTION     = 283;
  TIFFTAG_PLANARCONFIG    = 284;
  TIFFTAG_RESOLUTIONUNIT  = 296;
  TIFFTAG_COLORMAP        = 320;
  TIFFTAG_SAMPLEFORMAT    = 339;
  TIFFTAG_SMINSAMPLEVALUE = 340;
  TIFFTAG_SMAXSAMPLEVALUE = 341;

  // GeoTIFF tags
  GEOTAG_MODELPIXELSCALE     = 33550;
  GEOTAG_MODELTIEPOINT       = 33922;
  GEOTAG_MODELTRANSFORMATION = 34264;
  GEOTAG_KEYDIRECTORY        = 34735;
  GEOTAG_DOUBLEPARAMS        = 34736;
  GEOTAG_ASCIIPARAMS         = 34737;



    
  
DataSize: array[TIFF_NOTYPE..TIFF_IFD] of cardinal = (0, 1, 1, 2, 4, 8, 1, 1, 2, 4, 8, 4, 8, 4);

function get_tiff_options(fn : string; var tiffw, tiffh : dword; var scalex, scaley, leftx, lefty : double; var msg : string) : boolean;



procedure SwapBytes(var x : double); overload;
procedure SwapBytes(var x : word); overload;
procedure SwapBytes(var x : cardinal); overload;
function EndianSwap(n : integer) : integer;


procedure TIFFReadRGBAImageSwapRB(Width,Height: Cardinal; Memory: Pointer);
function ReadTiffIntoBitmap(Filename: String): TBitmap;


implementation
uses main, functions;


procedure SwapBytes(var x : double);
asm
  MOV   ECX,[EAX+4]
  BSWAP ECX
  MOV   EDX,[EAX]
  BSWAP EDX
  MOV   [EAX],ECX
  MOV   [EAX+4],EDX
end;
procedure SwapBytes(var x : word);
asm
  MOV   ECX,[EAX]
  XCHG  CL, CH
  MOV   [EAX],CX
end;
procedure SwapBytes(var x : cardinal);
asm
  MOV   ECX,[EAX]
  BSWAP ECX
  MOV   [EAX],ECX
end;
function EndianSwap(n : integer) : integer;
// Swaps 32bit integer value in big endian to little endian and vice versa
asm
  BSWAP EAX
end;

procedure SwapIFD2(var IFD: TIFDEntry);
  var size: cardinal;
begin
  SwapBytes(ifd.Tag);
  SwapBytes(ifd.DataType);
  SwapBytes(ifd.Count);

  size := DataSize[ifd.DataType] * ifd.Count;
  if size > 4 then SwapBytes(ifd.Offset)        // Offset contain offset to data
  else
    case ifd.DataType of                        // Offset contains data
      // Nothing required for byte sized data
      TIFF_SHORT, TIFF_SSHORT: begin
        size := EndianSwap(ifd.Offset);
        ifd.Offset := (size shr 16) or (size shl 16);
      end;
      TIFF_LONG, TIFF_SLONG, TIFF_FLOAT: SwapBytes(ifd.Offset);
      // Other types not supported or they don't fit
    end;

end;


function get_tiff_options(fn : string; var tiffw, tiffh : dword; var scalex, scaley, leftx, lefty : double; var msg : string) : boolean;
var
    ts : tfilestream;
    FBigEndian : boolean;
    w : word;
    c : cardinal;
    i, j, offset : cardinal;
    count: word;
    entries: array of TIFDEntry;
    scale,     tiepoints  : array of double;
begin
  result := true;

  try
      ts := TFileStream.Create(fn, fmOpenRead or fmShareDenyNone);
      ts.Read(w, 2);
      FBigEndian := w = $4D4D;
      ts.Read(w, 2);
      if FBigEndian then SwapBytes(w);


      if w <> 42 then begin
        result := false;
        msg := 'Seems that it''s not a valid TIFF file';
        exit;
      end;

      ts.Read(c, 4);
      if FBigEndian then SwapBytes(c);

      repeat
        offset := c;
        // Read the image directory
        ts.Seek(offset, soFromBeginning);
        ts.Read(count, 2);
        if FBigEndian then SwapBytes(count);
        SetLength(entries, count);
        ts.Read(entries[0], count * 12);
        if FBigEndian then
        for i := 0 to count - 1 do SwapIFD2(entries[i]);

        ts.Read(c, 4);                 // Get the offset to the next IFD, if any
        if FBigEndian then SwapBytes(c);

        for i := 0 to High(entries) do
          case entries[i].Tag of
          TIFFTAG_IMAGEWIDTH         : tiffw := entries[i].Offset;
          TIFFTAG_IMAGELENGTH        : tiffh := entries[i].Offset;

          GEOTAG_MODELPIXELSCALE     : begin
                                     SetLength(scale, 3);
                                     ts.Position := entries[i].Offset;
                                     ts.Read(scale[0], entries[i].Count * 8);
                                     if FBigEndian then  for j := 0 to entries[j].Count - 1 do SwapBytes( scale[j] );
                                   end;
          GEOTAG_MODELTIEPOINT       : begin
                                     SetLength(tiepoints, entries[i].Count);
                                     ts.Position := entries[i].Offset;
                                     ts.Read(tiepoints[0], entries[i].Count * 8);
                                     if FBigEndian then  for j := 0 to entries[j].Count - 1 do SwapBytes( tiepoints[j] );

                                  //   ReadIFDArray(Str, IFDs[i], FModelTiePoints);
                                   end;
        end;


        scalex := scale[0];
        scaley := scale[1];
        leftx  := tiepoints[3];
        lefty  := tiepoints[4];

        lefty := 0 - lefty;
        if (scaley > 0) then scaley := 0 - scaley;

        SetLength(entries, 0);
      until c = 0;
  except
    result := false;
    msg := 'Err while parsing TIFF file';
    exit;
  end;


end;


procedure TIFFReadRGBAImageSwapRB(Width,Height: Cardinal; Memory: Pointer);
{$IFDEF DELPHI_5}
type
  PCardinal = ^Cardinal;
{$ENDIF}
var
  m: PCardinal;
  n: Cardinal;
  o: Cardinal;
begin
  m:=Memory;
  for n:=0 to Width*Height-1 do
  begin
    o:=m^;
    m^:= (o and $FF00FF00) or                {G and A}
        ((o and $00FF0000) shr 16) or        {B}
        ((o and $000000FF) shl 16);          {R}
    Inc(m);
  end;
end;

function ReadTiffIntoBitmap(Filename: String): TBitmap;
var
  OpenTiff: PTIFF;
  FirstPageWidth, FirstPageHeight: Cardinal;
  FirstPageBitmap: TBitmap;
begin
  OpenTiff := TIFFOpen(Filename, 'r');
  if OpenTiff = nil then raise Exception.Create( 'Unable to open file '''+Filename+'''');

  TIFFGetField(OpenTiff, TIFFTAG_IMAGEWIDTH, @FirstPageWidth);
  TIFFGetField(OpenTiff, TIFFTAG_IMAGELENGTH, @FirstPageHeight);
  FirstPageBitmap := nil;
  try
    FirstPageBitmap := TBitmap.Create;
    FirstPageBitmap.PixelFormat := pf32bit;
    FirstPageBitmap.Width := FirstPageWidth;
    FirstPageBitmap.Height := FirstPageHeight;
  except
    if FirstPageBitmap <> nil then FirstPageBitmap.Destroy;
    TIFFClose(OpenTiff);
    raise Exception.Create('Unable to create TBitmap buffer');
  end;
  TIFFReadRGBAImage(OpenTiff, FirstPageWidth, FirstPageHeight, FirstPageBitmap.Scanline[FirstPageHeight-1],0);
  TIFFClose(OpenTiff);
  TIFFReadRGBAImageSwapRB(FirstPageWidth, FirstPageheight, FirstPageBitmap.Scanline[FirstPageHeight-1]);
  Result:=FirstPageBitmap;
end;

end.
