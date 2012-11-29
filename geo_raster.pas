unit geo_raster;
interface
uses sysutils, classes, windows, tiff_functions, functions, math, graphics, jpeg, GifImage, calibrate_dlg, Forms, Controls, ozi_api;

const
  GR_TYPE_GTIFF = 0;
  GR_TYPE_OZI = 1;

  IM_TYPE_TIFF = 0;
  IM_TYPE_JPEG = 1;
  IM_TYPE_GIF  = 2;
  IM_TYPE_PNG  = 3;
  IM_TYPE_BMP  = 4;

type

  TGeoRasterRec = record
    gr_type : integer;
    im_type : integer;

    fname : string;
    rmp_fname : string;
    
    w, h : dword;
    tilew, tileh : dword;
    firstTilex, firstTiley : dword;
    x_dif, y_dif : dword;

    scalex, scaley : double;
    tlx, tly : double;
    brx, bry : double;
    err : string;

    num : dword;
    isok : boolean;
  end;



function load_georaster(fn : string) : TGeoRasterRec;
function get_ozi_options(fn : string; var raster_fname : string;  var imgw, imgh : dword; var scalex, scaley, leftx, lefty : double; var msg : string) : boolean;
function get_img_options(fn : string; var w,h : dword ) : boolean;

implementation

uses main;


function load_georaster(fn : string) : TGeoRasterRec;
  var res : TGeoRasterRec;
      isok : boolean;
      w, h : dword;
      pixx, pixy, tlx, tly : double;
      brx, bry, scalex, scaley : double;
      i, x, y, firstTilex, firstTiley : dword;
      tx, ty, cmin, cmax : double;
      x_dif, y_dif : dword;
      msg : string;
      s : string;
      calibrate_res : integer;
begin
  res.err := '';

  //determing raster type
  s := lowercase(fn);
  if (pos('.jpg', s) = length(s) - 3) or ( pos('.jpeg', s) = length(s) - 4 ) then res.im_type := IM_TYPE_JPEG;
  if (pos('.tif', s) = length(s) - 3) or ( pos('.tiff', s) = length(s) - 4 ) then res.im_type := IM_TYPE_TIFF;
  if (pos('.gif', s) = length(s) - 3)  then res.im_type := IM_TYPE_GIF;
  if (pos('.png', s) = length(s) - 3)  then res.im_type := IM_TYPE_PNG;
  if (pos('.bmp', s) = length(s) - 3)  then res.im_type := IM_TYPE_BMP;

  if ( pos('.map', s) = length(s) - 3) then begin
    log(fn + ' - ozi');
    res.gr_type := GR_TYPE_OZI;
    isok := get_ozi_options(fn, res.fname, w, h, pixx, pixy, tlx, tly, msg);
  end else begin
    log(fn + ' - gtiff');
    res.gr_type := GR_TYPE_GTIFF;
    res.fname := fn;

    isok := get_tiff_options(fn, w, h, pixx, pixy, tlx, tly, msg);
    if not(isok) then begin
      log('geo information not found, manual calibration');
      fcalibrate.fname := fn;
      fcalibrate.im_type := res.im_type;
      fcalibrate.caption := ExtractFileName( fn );

      calibrate_res := fcalibrate.ShowModal;
      if (calibrate_res = mrOk) then begin
        w := fcalibrate.imw;
        h := fcalibrate.imh;
        pixx := fcalibrate.scalex;
        pixy := fcalibrate.scaley;
        tlx := fcalibrate.tlx;
        tly := fcalibrate.tly;
        isok := true;
      end else begin
        isok := false;
        if calibrate_res = mrNone then res.err := 'Err while loading image'
          else res.err := 'Manual calibration failed';
        result := res;
        exit;
      end;
    end;
  end;


  if not(isok) then begin
    res.err := msg;
    result := res;
    exit;
  end;

  s := lowercase(res.fname);
  if (pos('.jpg', s) = length(s) - 3) or ( pos('.jpeg', s) = length(s) - 4 ) then res.im_type := IM_TYPE_JPEG;
  if (pos('.tif', s) = length(s) - 3) or ( pos('.tiff', s) = length(s) - 4 ) then res.im_type := IM_TYPE_TIFF;
  if (pos('.gif', s) = length(s) - 3)  then res.im_type := IM_TYPE_GIF;
  if (pos('.png', s) = length(s) - 3)  then res.im_type := IM_TYPE_PNG;
  if (pos('.bmp', s) = length(s) - 3)  then res.im_type := IM_TYPE_BMP;
  
  


  

  brx := tlx + abs(pixx) * w;
  bry := tly + abs(pixy) * h;
  scalex := pixx * 256;
  scaley := pixy * 256;


  {log( Format('Image Size = %dx%d ', [w,h])+'  Scale X:'+fstr(scalex)+' Scale Y:'+fstr(scaley)+' pixX='+fstr(pixx)+' pixY='+fstr(pixy));
  log( 'Top left: '+dump_coordx(tlx)+' , '+dump_coordy(tly)+'   =   '+fstr(tlx)+' , '+fstr(tly));
  log( 'Bot righ: '+dump_coordx(brx)+' , '+dump_coordy(bry)+'   =   '+fstr(brx)+' , '+fstr(bry));      }


  if (w = 0) or (h = 0) or (pixx = 0) or (pixy = 0) then begin
    res.err := '[ERROR] while parsing image info';
    result := res;
    exit;
  end;

  res.w := w;
  res.h := h;

  res.scalex := scalex;
  res.scaley := scaley;

  res.tlx := tlx;
  res.tly := tly;
  res.brx := brx;
  res.bry := bry;

  //************************************
  //calculating coordinates of first tile
  firstTilex := 0;
  firstTiley := 0;
  tx := ceil( (tlx + 180) / abs(scalex) ) - 10;
  x := Round(tx);
  y := 22;
  for i:=x to x + 20 do begin
    cmin := i * scalex;     if (cmin < 0) then cmin := 0 - (cmin + 180) else cmin := cmin - 180;
    cmax := (i + 1) * scalex;     if (cmax < 0) then cmax := 0 - (cmax + 180) else cmax := cmax - 180;
      
    if (cmin <= tlx) and (tlx < cmax ) then begin
      firstTilex := i;
      y := 1;
      break;
    end;
  end;

  if (y = 22) then begin
    res.err := '[err] can''t get tile X';
    result := res;
    exit;
  end;

  ty := ceil( (tly + 90) / abs(scaley) ) - 10;
  y := Round(ty);
  x := 22;
  for i:=y to y + 20 do begin
    cmin := i * scaley;     if (cmin < 0) then cmin := 0 - (cmin + 90) else cmin := cmin - 90;
    cmax := (i + 1) * scaley;     if (cmax < 0) then cmax := 0 - (cmax + 90) else cmax := cmax - 90;
    if (cmin <= tly) and (tly < cmax ) then begin
      firstTiley := i;
      x := 1;
      break;
    end;
  end;
  if (x = 22) then begin
    res.err := '[err] can''t get tile Y';
    result := res;
    exit;
  end;

  log( 'First tile: '+istr(firstTilex)+','+istr(firstTiley));


  res.firstTilex := firstTilex;
  res.firstTiley := firstTiley;


  //************************************
  //calculating x_dif y_dif (movement of raster according to tile)
  tx := firstTilex * scalex;
  if (tx > 0) then tx := tx - 180 else tx := 0 - (tx + 180);
  ty := firstTiley * scaley;
  if (ty > 0) then ty := ty - 90 else ty := 0 - (ty + 90);
  tx := tlx - tx;
  ty := tly - ty;
  tx := abs(tx / pixx);
  ty := abs(ty / pixy);
  x_dif := 256 - round(tx);
  y_dif := 256 - round(ty);

{  x_dif := 256 - floor(tx);
  y_dif := 256 - floor(ty);}

  res.x_dif := x_dif;
  res.y_dif := y_dif;

//  log('w='+istr(w)+'  x_dif='+istr(x_dif));
//  log('h='+istr(h)+'  y_dif='+istr(y_dif));

  if (w < x_dif) then begin
    if (x_dif + w > 256) then res.tilew := 2
      else res.tilew := 1;
  end
    else res.tilew := ceil( (w - x_dif) / 256) + 1;

  if (h < y_dif) then begin
    if (y_dif + h > 256) then res.tileh := 2
      else res.tileh := 1;
  end
    else res.tileh := ceil( (h - y_dif) / 256) + 1;

//  log( 'difs: '+istr(x_dif)+','+istr(y_dif));
//  log( 'tile wh: '+istr(res.tilew)+','+istr(res.tileh));

  res.rmp_fname := StringReplace(res.fname + '.rmp', '\\', '\', [rfReplaceAll, rfIgnoreCase]);

  result := res;
end;



function get_ozi_options(fn : string; var raster_fname : string;  var imgw, imgh : dword; var scalex, scaley, leftx, lefty : double; var msg : string) : boolean;
type
  tprojsetup = record
    Latitude_Origin: double;
    Longitude_Origin: double;
    K_Factor : double;
    False_Easting : double;
    False_Northing : double;
    Latitude_1 : double;
    Latitude_2 : double;
  end;

var s, p : String;
    datumFrom, datumTo : Pchar;
    i,j : integer;
    f : textfile;
    ndots : byte;
    pixx, pixy : array[1..30] of dword;

    coordx, coordy : array[1..30] of double;
    gridx, gridy : array[1..30] of double;
    dotn, dotw : array[1..30] of char;

    arrs : array [1..255] of string;
    ns : word;

    r, min, max : double;
    mini, maxi : integer;
    apir : integer;
    projsetup : tprojsetup;
    tst : Pchar;
    uDatumFrom: Pchar;


begin
DecimalSeparator := '.';
  result := true;
  try
    assignfile(f, fn);
    reset(f);
    ndots := 0;
    imgw := 0;
    imgh := 0;
    for i:=1 to 30 do begin
      coordx[i] := -11;
      coordy[i] := -11;
      gridx[i] := -11;
      gridy[i] := -11;
    end;

    i := 0;    
    while not( eof(f) ) do begin
      inc(i);
      readln(f, s);


      //datum
      if i = 5 then begin
        s := copy(s, 1, pos(',', s)-1 );;
        p := s;
        datumFrom := Pchar(p);
      end;

      //projection setup
      if pos('Projection Setup', s) > 0 then begin
        s := StringReplace(s, 'Projection Setup,', '', [rfReplaceAll, rfIgnoreCase]);
        s := trim(s);
        stringsToArray(s, ',', arrs, ns);
        if (arrs[1] <> '') then projsetup.Latitude_Origin := StrToFloat(arrs[1]) else projsetup.Latitude_Origin := 0;
        if (arrs[2] <> '') then projsetup.Longitude_Origin := StrToFloat(arrs[2]) else projsetup.Latitude_Origin := 0;
        if (arrs[3] <> '') then projsetup.K_Factor := StrToFloat(arrs[3]) else projsetup.Latitude_Origin := 0;
        if (arrs[4] <> '') then projsetup.False_Easting := StrToFloat(arrs[4]) else projsetup.Latitude_Origin := 0;
        if (arrs[5] <> '') then projsetup.False_Northing := StrToFloat(arrs[5]) else projsetup.Latitude_Origin := 0;
        if (arrs[6] <> '') then projsetup.Latitude_1 := StrToFloat(arrs[6]) else projsetup.Latitude_Origin := 0;
        if (arrs[7] <> '') then projsetup.Latitude_2 := StrToFloat(arrs[7]) else projsetup.Latitude_Origin := 0;
      end;

      //img file
      if i = 3 then begin
        if FileExists(s) then raster_fname := s
        else begin
          p := ExtractFilePath(fn);
          s := p + '\' + s;
          if FileExists(s) then raster_fname := s
          else begin
            result := false;
            msg := 'img file not found';
            exit;
          end;
        end;
      end;

      //cordinates
      if (pos('Point', s) = 1) then begin
        stringsToArray(s, ',', arrs, ns);
        for j:=1 to ns do arrs[j] := trim( arrs[j] );
        if ( arrs[3] <> '') and ( arrs[4] <> '' ) then begin
          inc(ndots);
          pixy[ ndots ] := StrToInt( arrs[3] );
          pixx[ ndots ] := StrToInt( arrs[4] );

          if (arrs[7] <> '') then begin
            coordy[ ndots ] := StrToFloat( arrs[7] ) + StrToFloat( arrs[8] ) / 60;
            coordx[ ndots ] := StrToFloat( arrs[10] ) + StrToFloat( arrs[11] ) / 60;
            if ( arrs[9] = 'N') then coordy[ ndots ] := 0 - coordy[ ndots ];
            if ( arrs[12] = 'W') then coordx[ ndots ] := 0 - coordx[ ndots ];
          end else begin
            gridx[ ndots ] := StrToFloat( arrs[15] );
            gridy[ ndots ] := StrToFloat( arrs[16] );
            dotn[ ndots ] := arrs[9][1];
            dotw[ ndots ] := arrs[12][1];

          end;

        end;
      end;

      //IWH,Map Image Width/Height,4227,4760
      if pos('IWH,Map Image Width/Height', s) > 0 then begin
        stringsToArray(s, ',', arrs, ns);
        imgw := StrToInt( arrs[3] );
        imgh := StrToInt( arrs[4] );
      end;

    end;
    closefile(f);

    if (imgw = 0) or (imgh = 0) then begin
      result := false;
      msg := 'Can''t get img width/height';
      exit;
    end;

    if (ndots = 0) then begin
      result := false;
      msg := 'Can''t get calibration info';
      exit;
    end;

    //converting from grid to latlon
 {   if (abs(coordx[1]) = 11) and (abs(coordy[1]) = 11) then begin
      datumTo := 'WGS 84';
      min := 0;
      max := 0;
      tst := '';
      uDatumFrom := datumFrom;
      apir := oziConvertGrid2LL(2, tst, tst, gridx[1], gridy[1], uDatumFrom, coordx[1],coordy[1], projsetup.Latitude_Origin, projsetup.Longitude_Origin, 0,0,projsetup.K_Factor,projsetup.False_Easting,projsetup.False_Northing);
      if apir <> 1 then begin
        result := false;
        //msg := datumFrom + ' is not supported, use wgs84';
        msg := 'run Ozi to use '+datumFrom;
        exit;
      end;


      for i:=1 to ndots do begin
        uDatumFrom := datumFrom;
        apir := oziConvertGrid2LL(2, tst, tst, gridx[i], gridy[i], uDatumFrom, coordx[i], coordy[i], projsetup.Latitude_Origin, projsetup.Longitude_Origin, 0,0,projsetup.K_Factor,projsetup.False_Easting,projsetup.False_Northing);
        min := coordy[i];
        coordy[i] := coordx[i];
        coordx[i] := min;

        if ( dotn[i] = 'N') then coordy[ i ] := 0 - coordy[ i ];
        if ( dotw[i] = 'W') then coordx[ i ] := 0 - coordx[ i ];

        log( istr(i) + '  '+dump_coordx( coordx[i] ) +' , '+dump_coordy( coordy[i] ) );



      end;
    end;       }



    //converting datum to wgs84
    if lowercase(datumFrom) <> 'wgs 84' then begin
{      datumTo := 'WGS 84';
      min := 0;
      max := 0;
      uDatumFrom := datumFrom;
      apir := oziConvertDatum(uDatumFrom, datumTo, min, max);
      if apir <> 1 then begin
        result := false;
        //msg := datumFrom + ' is not supported, use wgs84';
        msg := 'run Ozi to use '+datumFrom;
        exit;
      end;
      //converting to WGS84
      for i:=1 to ndots do begin
        oziConvertDatum(datumFrom, datumTo, coordx[i], coordy[i]);
      end;        }

      result := false;
      msg := datumFrom + ' is not supported, use wgs84';
        exit;
    end;


    min := -1;
    max := -1;
    mini := 0;
    maxi := 0;

    for i:=1 to ndots do begin
      r := sqrt( pixx[i]*pixx[i] +  pixy[i]*pixy[i] );
      if (r < min) or (min = -1) then begin
        min := r;
        mini := i;
      end;
      if (r > max) or (max = -1) then begin
        max := r;
        maxi := i;
      end;
    end;

    log( 'min X = '+fstr(coordx[mini]) );
    log( 'max X = '+fstr(coordx[maxi]) );

    r := abs( coordx[maxi] - coordx[mini] );
    scalex := r / ( pixx[maxi] - pixx[mini]);
    if (scaley > 0) then scaley := 0 - scaley;

    r := abs( coordy[maxi] - coordy[mini] );
    scaley := r / ( pixy[maxi] - pixy[mini]);

    log(' scalex = '+fstr(scalex) );
    log(' scaley = '+fstr(scaley) );

    leftx := coordx[mini] - abs(scalex) * pixx[mini];
    lefty := coordy[mini] - abs(scaley) * pixy[mini];

    //log( fstr(coordx[mini]) + ',' + fstr(coordy[mini]));
    //log( fstr(leftx) + ',' + fstr(lefty));

  except
    closefile(f);
    result := false;
    msg := 'Err while loading .map';
  end;

end;



function get_img_options(fn : string; var w,h : dword ) : boolean;
  var f : textfile;
      s : string;
      dir : string;
      arrs : array [1..255] of string;
      ns : word;

begin
  result := true;
  dir := ExtractFilePath(ParamStr(0));
  w := 0;
  h := 0;
  if FileExists(dir+'\gdal\info.txt') then DeleteFile( PChar(dir+'\gdal\info.txt') );

  s := dir+'\gdal\gdalinfo.exe "' + (WinToDos(fn)) + '" > '+dir+'\gdal\info.txt';
  file_put_contents( dir+'\gdal\sys.bat', s );
  execcmd( dir+'\gdal\sys.bat', false, true);

  if not( FileExists(dir+'\gdal\info.txt') ) then begin
    result := false;
    exit;
  end;

  AssignFile(f, dir+'\gdal\info.txt');
  reset(f);

  while not( eof(f) ) do begin
    readln(f, s);
    if pos('Size is ', s) > 0 then begin
      s := StringReplace(s, 'Size is ', '', [rfReplaceAll, rfIgnoreCase]);
      s := StringReplace(s, ', ', ',', [rfReplaceAll, rfIgnoreCase]);
      s := trim(s);
      stringsToArray(s, ',', arrs, ns);
      w := StrToInt( arrs[1] );
      h := StrToInt( arrs[2] );
    end;
  end;
  closefile(f);

  if (w = 0) or (h = 0) then  result := false;
end;

end.
