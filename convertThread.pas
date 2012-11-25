unit convertThread;

interface

uses
  dialogs, windows, Classes, sysutils, functions, Math, Graphics, Jpeg, Forms, tiff_functions, rmp, geo_raster, gifimage, pngimage, messages;

type




  cconvertThread = class(TThread)
  public
    done : boolean;
    msg : string;
    have_errors : boolean;
    mapProv, mapGroup : string;
    rmpfname  : string;
        forrmp_dir, tile_dir : string;


  private
    tifffiles : array[1..1024] of TGeoRasterRec;
    ntiffs : word;
    { Private declarations }
    max, ndone, rownum : word;
    curtiff : word;

    procedure UpdateProgressBar;
    procedure SetMaxProgress;
    procedure set_status();
    procedure run_next();
    procedure do_abort();

    procedure craft_tiles(  );

  protected
    procedure Execute; override;
  public
    procedure craft_a00( tiff : TGeoRasterRec; layer_num : word  );
    constructor create(prov, group: string; i : word);
    procedure add_tiff( tr : TGeoRasterRec );

    procedure craft_description_file( rmpfname : string );
    procedure craft_ini_file();
    procedure pack_rmp( rmpfname : string);

  end;

implementation
uses main;

constructor cconvertThread.create(prov, group: string; i : word);
begin
  done := false;
  have_errors := false;
  rownum := i;
  msg := '';
  mapProv := prov;
  mapGroup := group;

  ntiffs := 0;
  inherited create(true);
end;

procedure cconvertThread.add_tiff( tr : TGeoRasterRec );
begin
  inc(ntiffs);
  tifffiles[ ntiffs ] := tr;

  if (tr.err <> '') then begin
    have_errors := true;
    msg := tr.err;
    exit;
  end;

end;

procedure cconvertThread.Execute;
  var tmp : string;
      i : word;
begin

  max := 0;
  for i:=1 to ntiffs do begin
    if ( tifffiles[i].err <> '') then begin
      have_errors := true;
      msg := '[err] loading tiff: '+tifffiles[i].err;
      do_abort();
      exit;
    end;
    max := max + tifffiles[i].tilew * tifffiles[i].tileh;
  end;



  try
    tmp := GetTempDir();
    if tmp = '' then tmp := path;
    if not(DirectoryExists(tmp)) then CreateDir(tmp);

    forrmp_dir := tmp + '\forrmp\';
    if not(DirectoryExists(forrmp_dir)) then CreateDir(forrmp_dir);
    tile_dir := tmp + '\tiles\';
    if not(DirectoryExists(tile_dir)) then CreateDir(tile_dir);

    clean_dir(  forrmp_dir, '*.*' );
    clean_dir(  tile_dir, '*.*' );

    if debug = 0 then begin
      clean_dir(  forrmp_dir, '*.*' );
      clean_dir(  tile_dir, '*.*' );
    end;

{    if rmpfname = '' then begin
      rmpfname := tifffiles[1].fname + '.rmp';
      rmpfname := StringReplace(tifffiles[1].fname, '.tiff','.rmp', [rfReplaceAll, rfIgnoreCase]);
      rmpfname := StringReplace(rmpfname, '.tif','.rmp', [rfReplaceAll, rfIgnoreCase]);
    end;}
    if rmpfname = '' then  rmpfname := tifffiles[ 1 ].rmp_fname;

  except
      have_errors := true;
      msg := '[err] preparing dir structure';
      do_abort();
      exit;
  end;


  if FileExists(rmpfname) then begin
      have_errors := true;
      msg := '[err] RMP file "'+rmpfname+'" exists';
      log( msg );
      do_abort();
      exit;
  end;

  
  Synchronize( SetMaxProgress );
  ndone := 1;
  Synchronize( UpdateProgressBar );


  for i:=1 to ntiffs do begin
    curtiff := i;
    Synchronize( craft_tiles );
    if have_errors then begin do_abort(); exit; end;
    craft_a00( tifffiles[i], i );
    if have_errors then begin do_abort(); exit; end;
  end;



  try
    craft_description_file( rmpfname );
    if have_errors then begin do_abort(); exit; end;
    craft_ini_file();
    if have_errors then begin do_abort(); exit; end;

    SaveResourceAsFile('exp_sig', forrmp_dir + '\BMP4BIT.ICS');
    SaveResourceAsFile('triton_sig', forrmp_dir + 'chunk.ics');
    pack_rmp( rmpfname );
  except
    have_errors := true;
    msg := '[ERROR] while packing rmp';
  end;

  do_abort();
end;

procedure cconvertThread.do_abort();
begin
  max := 1;
  Synchronize( SetMaxProgress );

  ndone := 0;
  Synchronize( UpdateProgressBar );

  //running next file
  Synchronize( set_status );
  Synchronize( run_next );


  Terminate;
end;

procedure cconvertThread.set_status();
begin
  if have_errors then fMain.sgStatus.Cells[1, rownum] := 'Error' else fMain.sgStatus.Cells[1, rownum] := 'Ok';
  fMain.sgStatus.Cells[2, rownum] := msg;
end;

procedure cconvertThread.run_next();
begin
  fMain.run_next();
end;






//************************************
//splitting raster into tiles
procedure cconvertThread.craft_tiles( );
var
  //imgbitmap,
  tilebmp, blackbmp, tmpbitmap : TBitmap;
  tilejpg : TJPEGImage;
  ix, iy, x, y, tw, th : dword;
  do_resize : boolean;
  ver_mode, hor_mode : string;
  r, r2 : TRect;
  jpegfname : string;
  filled : boolean;
  c1, c2: PByte;
  icmp : integer;
  cmp, maxcmp : byte;
  tiff : TGeoRasterRec;
  j : TJPEGImage;
  g : tgifimage;
  p : TPNGObject;
  pic : Tpicture;
  cmd : string;
  use_external : boolean;
begin

  tiff := tifffiles[ curtiff ];
  path := ExtractFilePath(ParamStr(0)) + '\gdal\';

  maxcmp  := 20;

  use_external := false;
  if (tiff.w > StrToInt(fMain.inUseExternalX.Text) ) or (tiff.h > StrToInt(fMain.inUseExternalY.Text)) then use_external := true;
  if (fMain.cbUseExternal.Checked) then use_external := true;


  if not(use_external) then begin
    try
      pic := Tpicture.Create;
      if tiff.im_type = IM_TYPE_TIFF then begin
        tmpbitmap := ReadTiffIntoBitmap( tiff.fname );
        pic.Assign(tmpbitmap);
        tmpbitmap.free;
        //pic.bitmap := ReadTiffIntoBitmap( tiff.fname );
      end else if tiff.im_type = IM_TYPE_BMP then begin
        pic.LoadFromFile( tiff.fname );
      end else if tiff.im_type = IM_TYPE_JPEG then begin
        j := TJPEGImage.Create;
        j.LoadFromFile( tiff.fname );
        pic.Bitmap.Assign( j );
        j.free;
      end else if tiff.im_type = IM_TYPE_GIF then begin
        g := TGIFIMAGE.Create;
        g.LoadFromFile( tiff.fname );
        pic.Bitmap.Assign( g );
        g.free;
      end else if tiff.im_type = IM_TYPE_PNG then begin
        p := TPNGObject.Create;
        p.LoadFromFile( tiff.fname );
        pic.bitmap.width := p.width;
        pic.bitmap.height := p.height;
        pic.bitmap.Canvas.Draw(0, 0, p);
        p.free;
      end;
    except
      have_errors := true;
      msg := '[err] while loading raster';
      pic.Free;
      exit;
    end;

    tilebmp := TBitmap.create;
    tilebmp.Width := 256;
    tilebmp.Height := 256;
  
    blackbmp := TBitmap.create;
    blackbmp.Width := 256;
    blackbmp.Height := 256;
    blackbmp.Canvas.Brush.Color := rgb(0,0,0);
    blackbmp.Canvas.Brush.style := bsSolid;
    r.left := 0;
    r.top := 0;
    r.right := 256;
    r.bottom := 256;
    blackbmp.Canvas.FillRect( r );

    tilejpg := TJPEGImage.Create;
    tilejpg.CompressionQuality := jpegQuality;//75;//80;
  end;

//  log('difx='+istr(tiff.x_dif)+'  dify='+istr(tiff.y_dif));

  for ix:=1 to tiff.tilew do begin
    for iy:=1 to tiff.tileh do begin

      do_resize := false;
      x := 0;
      if (ix >= 2) then x := x + tiff.x_dif;
      if (ix >= 3) then x := x + (ix - 2) * 256;

      y := 0;
      if (iy >= 2) then y := y + tiff.y_dif;
      if (iy >= 3) then y := y + (iy - 2) * 256;

      if (ix = 1) and (tiff.x_dif > 0) then tw := tiff.x_dif else tw := 256;
      if (iy = 1) and (tiff.y_dif > 0) then th := tiff.y_dif else th := 256;

      if (tiff.w >= tiff.x_dif) and (x + tw > tiff.w) then tw := tiff.w - x;
      if (tiff.h >= tiff.y_dif) and (y + th > tiff.h) then th := tiff.h - y;

      if (tw <> 256) or (th <> 256) then begin
        if (iy = 1) then ver_mode := 'bottom' else ver_mode := 'top';
        if (ix = 1) then hor_mode := 'right' else hor_mode := 'left';
        do_resize := true;
      end;

//      log('['+istr(ix)+','+istr(iy)+'] '+istr(tw)+','+istr(th));

      try
       if not(use_external) then begin
          tilebmp.Canvas.Lock;
          tilebmp.Canvas.Brush.Color := rgb(0,0,0);
          tilebmp.Canvas.Brush.style := bsSolid;
          r.left := 0;
          r.top := 0;
          r.right := 256;
          r.bottom := 256;
          tilebmp.Canvas.FillRect( r );

          r2.left := x;
          r2.Top := y;
          r2.Right := x + tw;
          r2.Bottom := y + th;  

          if (do_resize = false) then begin
          r.Left := 0;
          r.Top := 0;
          r.Right := 256;
          r.Bottom := 256;

          end else begin
          if (hor_mode = 'left') then begin
            r.left := 0;
            r.Right := tw;
          end else begin
            r.Left := 256 -  tw;
            r.Right := 256;
          end;

          if (ver_mode = 'top') then begin
            r.top := 0;
            r.Bottom := th;
          end else begin
            r.top := 256 - th;
            r.Bottom := 256;
          end;

          end;


          tilebmp.Canvas.CopyRect(r, pic.bitmap.Canvas, r2);
          tilebmp.Canvas.Unlock;

          jpegfname := tile_dir + '\tile-' + inttostr(tiff.num) + '-'+inttostr(ix)+'-'+inttostr(iy)+'.jpg';

          tilejpg.Assign(tilebmp) ;
          tilejpg.Compress;
          tilejpg.SaveToFile(jpegfname);
        end else begin
          cmd := path + 'gdal_translate.exe -of JPEG -co QUALITY=' + inttostr(jpegQuality) + ' -expand rgb -srcwin '+inttostr(x)+' '+inttostr(y)+' '+inttostr(tw)+' '+inttostr(th)+' "'+WinToDos(tiff.fname)+'" ';
          cmd := cmd + ' '+tile_dir + '\tile-' + inttostr(tiff.num) + '-'+inttostr(ix)+'-'+inttostr(iy)+'.jpg';
          file_put_contents(path+'tilify.bat', cmd);
          //log(cmd);
          execcmd(path+'tilify.bat', false, true);
          if do_resize then set_jpeg_padding(tile_dir + '\tile-' + inttostr(tiff.num) + '-'+inttostr(ix)+'-'+inttostr(iy)+'.jpg', hor_mode, ver_mode);
        end;



      except
        have_errors := true;
        msg := '[err] while tiling image';
        pic.Free;
        tilebmp.Free;
        tilejpg.Free;
        exit;
      end;
      Application.ProcessMessages;
      inc(ndone);
      Synchronize( UpdateProgressBar );
    end;
  end;

  if use_external then clean_dir(tile_dir, '*.xml');

  FreeAndNil(pic);
  FreeAndNil(tilebmp);
  FreeAndNil(tilejpg);
  FreeAndNil(blackbmp);
end;




procedure cconvertThread.craft_a00( tiff : TGeoRasterRec; layer_num : word);
var
  num : dword;
  t, s, fTlm : TFileStream;
  i, j, offset, ix, iy, h_in_tiles, w_in_tiles, num_tiles, num_blocks, num_addblocks : dword;
  ss, tilefile : string;
  len, x, y, done, block : dword;
  tile_w, tile_h : double;


  buf : array[0..702400] of byte;
  tile_offsets : array[1..255, 1..255] of dword;
  blocks : array[1..1024] of dword;
begin
  try

      //****** A00 CRAFT
     num := tiff.tilew * tiff.tileh;


      T := TFileStream.Create( forrmp_dir + '\\topo' + istr(layer_num) + '.a00' , fmOpenWrite or fmCreate );
      t.Write(num, 4);
      offset := 4;


      for iy:=1 to tiff.tileh do begin
        for ix:=1 to tiff.tilew do begin
          tilefile := 'tile-'+inttostr(tiff.num)+'-'+inttostr(ix)+'-'+inttostr(iy)+'.jpg';

          len := functions.GetFileSize(tile_dir + '\\' + tilefile);
          t.Write(len, 4);
          offset := offset + len + 4;
          S := TFileStream.Create( tile_dir + '\\' + tilefile, fmOpenRead );
          T.CopyFrom(S, len ) ;
          s.free;
        end;
      end;

      t.free;      

      //****** TLM CRAFT
      fTlm := TFileStream.Create( forrmp_dir + '\\topo' + istr(layer_num) + '.tlm' , fmOpenWrite or fmCreate );

      tile_w := abs(tiff.scalex);
      tile_h := abs(tiff.scaley);

      h_in_tiles := tiff.tileh;
      w_in_tiles := tiff.tilew;

      num_tiles := tiff.tilew * tiff.tileh;

      //header
      i := 1;
      fTlm.Seek(0, soFromBeginning); fTlm.Write(i, 4);

      fTlm.Seek(4, soFromBeginning); fTlm.Write(num_tiles, 4);

      i := $01000100;
      fTlm.Seek(8, soFromBeginning); fTlm.Write(i, 4);

      i := 1;
      fTlm.Seek(12, soFromBeginning); fTlm.Write(i, 4);

      fTlm.Seek(16, soFromBeginning); fTlm.Write(tile_h, 8);
      fTlm.Seek(24, soFromBeginning); fTlm.Write(tile_w, 8);

      //top left
      fTlm.Seek(32, soFromBeginning); fTlm.Write(tiff.tlx, 8);
      fTlm.Seek(40, soFromBeginning); fTlm.Write(tiff.tly, 8);

      //bottom right
      fTlm.Seek(48, soFromBeginning); fTlm.Write(tiff.brx, 8);
      fTlm.Seek(56, soFromBeginning); fTlm.Write(tiff.bry, 8);

      i := 1;
      fTlm.Seek($90 + 8 + 1, soFromBeginning); fTlm.Write(i, 1);

      i := 1;
      fTlm.Seek($100, soFromBeginning); fTlm.Write(i, 1);

      i := $63;
      fTlm.Seek($100 + 4, soFromBeginning); fTlm.Write(i, 1);





      num_blocks := ceil( num_tiles / 70 );
      //additional block;
      if (num_blocks > 1) then begin
        inc(num_blocks);
        num_addblocks := num_blocks - 2;
      end else num_addblocks := 0;




    //loading tile offsets
      x := 0;
      y := 1;
      offset := 4;
      for iy:=1 to tiff.tileh do begin
        for ix:=1 to tiff.tilew do begin
          tilefile := 'tile-'+inttostr(tiff.num)+'-'+inttostr(ix)+'-'+inttostr(iy)+'.jpg';
          done := functions.GetFileSize(tile_dir + '\\' + tilefile);
          tile_offsets[ix][iy] := offset;
          offset := offset + done + 4;
        end;
      end;

      //store tiles nums and offsets
      done := 0;
      for x:=1 to 1024 do blocks[x] := 0;

//      showmessage('w='+inttostr(w_in_tiles)+' h='+inttostr(h_in_tiles)+' blocks='+inttostr(num_blocks) );
      for ix := 1 to w_in_tiles do begin
        for iy := 1 to h_in_tiles do begin
          x := tiff.firstTilex + (ix - 1);
          y := tiff.firstTiley + (iy - 1);

          inc(done);
//          ss := Format('%x / %x => [%d,%d - %d]', [x,y, ix,iy,done]);          log(ss);
          block := 0;

          for j:=3 to num_blocks  do begin
            if (done >= (j-2)*70 + (j-2)) and (done <= (j-1)*70 + (j-2)) then begin
              block := j;
              break;
            end;
          end;

          for j:=1 to num_addblocks  do begin
            if done = 70*j + j then begin
              block := 2;
              break;
            end;
          end;

          if (block = 0) then block := 1;

          inc(blocks[block]);
          offset := $105c + $7c8 * (block - 1) + 8 + 16 * (blocks[block] - 1);

          fTlm.Seek(offset, soFromBeginning); fTlm.Write(x, 4);
          fTlm.Seek(offset + 4, soFromBeginning); fTlm.Write(y, 4);

          i := 0;
          i := tile_offsets[ix][iy];
          //move(i, buf[offset + 12], 4);
          fTlm.Seek(offset + 12, soFromBeginning); fTlm.Write(i, 4);

          //ss := ss + ' b=' + inttostr(block)+' = '+inttohex(offset, 4);
        end;
      end;

      //store amount of tiles in blocks
      for i:=1 to num_blocks  do begin
        offset := $105c + $7c8 * (i - 1);

        if (i = 2) then begin
          x := num_tiles;
          fTlm.Seek(offset, soFromBeginning); fTlm.Write(x, 4);
          x := blocks[i];
          fTlm.Seek(offset + 4, soFromBeginning); fTlm.Write(x, 4);
        end else begin
          x := blocks[i];
          fTlm.Seek(offset, soFromBeginning); fTlm.Write(x, 4);
          fTlm.Seek(offset + 4, soFromBeginning); fTlm.Write(x, 2);
          x := 1;
          fTlm.Seek(offset + 6, soFromBeginning); fTlm.Write(x, 1);
        end;
      end;


      //writing block positions
      if num_addblocks > 0 then begin
        i := $1724;
        //1st block
        fTlm.Seek($100 + 8, soFromBeginning); fTlm.Write(i, 4);

        i := $0F5C;
        fTlm.Seek($1E5C, soFromBeginning); fTlm.Write(i, 4);

        for i:=3 to num_blocks do begin
          offset := $1E5C + (i-2) * 4;
          x := $0F5C + $0f90 + $07c8 * (i-3);
          fTlm.Seek(offset, soFromBeginning); fTlm.Write(x, 4);
        end;

      end else begin
        i := $0F5C;
        //1st block
        fTlm.Seek($100 + 8, soFromBeginning); fTlm.Write(i, 4);

      end;


      //Buf Size to 9c - length of resulting tlm file
      x := $105c + $7c8 * (num_blocks + 2);
      fTlm.Seek($9c, soFromBeginning); fTlm.Write(x, 4);
      //padding file
      i := 0;
      fTlm.Seek(x - 1, soFromBeginning); fTlm.Write(i, 1);

      fTlm.free;
  except
    have_errors := true;
    msg := '[err] while crafting a00/tlm files';
    exit;
  end;
end;


procedure cconvertThread.craft_description_file( rmpfname : string );
var
  f : textfile;
  fnew : string;
begin
  try
     //creating cvg_map.msf
     AssignFile(f, forrmp_dir + '\cvg_map.msf');
     rewrite(f);

     fnew := ExtractFileName(rmpfname);
     fnew := StringReplace(fnew, '.rmp','',[rfReplaceAll, rfIgnoreCase]);

     writeln(f, ';Map Support File : Contains Meta Data Information about the Image');
     writeln(f, 'IMG_NAME =  ' + fnew );
     writeln(f, 'PRODUCT =  ' + mapGroup );
     writeln(f, 'PROVIDER =  ' + mapProv );
     writeln(f, 'IMG_DATE =  ' + DateToStr(Date) +' '+TimeToStr(Time));
     writeln(f, 'IMG_VERSION = 31');
     writeln(f, 'Version = 31');
     writeln(f, 'BUILD=');
     writeln(f, 'VENDOR_ID = -1');
     writeln(f, 'REGION_ID = -1');
     writeln(f, 'MAP_TYPE = TNDB_RASTER_MAP');
     writeln(f, 'ADDITIONAL_COMMENTS = created with antalos.com geoTIFFtoRMP');
     closefile(f);
  except
    have_errors := true;
    msg := '[err] while crafting MSF file';
  end;
end;

procedure cconvertThread.craft_ini_file();
var
  f : textfile;
  i : dword;
begin
    try
       AssignFile(f, forrmp_dir + '\rmp.ini');
       rewrite(f);
       writeln(f, '[T_Layers]');

       for i:=1 to ntiffs do
         writeln(f, istr(i-1) + '=TOPO' + istr(i) );

       write(f, chr(0));
       closefile(f);
    except
      have_errors := true;
      msg := '[err] while crafting INI file';
    end;
end;


procedure cconvertThread.pack_rmp( rmpfname : string);
var
   a : trmp;
   is_ok : boolean;
begin
   a := trmp.create;
   a.rmp_fname := rmpfname;
   is_ok := a.pack_dir( forrmp_dir );
   if not(is_ok) then begin
      have_errors := true;
      msg := '[err] while packing rmp';
      exit;
   end; 

   msg := ExtractFileName( rmpfname );
end;






procedure cconvertThread.SetMaxProgress;
begin

  fMain.pbConvert.min := 1;
  fMain.pbConvert.max := max;
end;


procedure cconvertThread.UpdateProgressBar;
begin
  fMain.pbConvert.Position := ndone;
end;



end.
