{
done:
*++ fixed tlm error + in craft tlm change TLM buf to filestream
*++ comression from 90 to 75
*++ add anchor to statusbar
*++ fix memory leak on internal convertor
++ add log to scale calc


ToDO:
-- add info about scales

D:\TEMP\PROJ4\proj-4.6.1\bin>cs2cs +proj=latlong +ellps=krass +towgs84=28,-130,-95,0,0,0,0 +to  +proj=latlong +ellps=WGS84 +datum=WGS84
}
unit main;
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, convertThread, StdCtrls, Grids, functions, JPEG,
  ExtCtrls, frmAbout, tiff_functions, Math, geo_raster, gifimage, pngimage,
  geotiff_export_Scale, fVisualise, ozi_api
;

type
  TForm1 = class(TForm)
    pbConvert: TProgressBar;
    btnOpenTiffs: TButton;
    openTiff: TOpenDialog;
    sgStatus: TStringGrid;
    memoLog: TMemo;
    inProv: TLabeledEdit;
    inGroup: TLabeledEdit;
    rbAtlas: TRadioButton;
    rbSingle: TRadioButton;
    btnHelp: TButton;
    btnCreateRMP: TButton;
    btnDeleteTiff: TButton;
    btnClearTiffs: TButton;
    lLoading: TLabel;
    btnVisualize: TButton;
    SaveDialog1: TSaveDialog;
    GroupBox1: TGroupBox;
    cbModel: TComboBox;
    Label1: TLabel;
    inExportScale: TLabeledEdit;
    btnSetScale: TButton;
    GroupBox2: TGroupBox;
    inUseExternalX: TLabeledEdit;
    inUseExternalY: TLabeledEdit;
    cbUseExternal: TCheckBox;
    Button1: TButton;
    memoScale: TMemo;
    inJpegQual: TLabeledEdit;
    procedure btnOpenTiffsClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnHelpClick(Sender: TObject);
    procedure rbSingleClick(Sender: TObject);
    procedure rbAtlasClick(Sender: TObject);
    procedure btnCreateRMPClick(Sender: TObject);
    procedure btnDeleteTiffClick(Sender: TObject);
    procedure btnClearTiffsClick(Sender: TObject);
    procedure btnVisualizeClick(Sender: TObject);
    procedure cbModelChange(Sender: TObject);
    procedure inExportScaleChange(Sender: TObject);
    procedure btnSetScaleClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure sgStatusDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure cbUseExternalClick(Sender: TObject);
    procedure inUseExternalXChange(Sender: TObject);
    procedure inUseExternalYChange(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure inJpegQualChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure run_next();
    procedure toggle_controls( state : boolean);
  protected
    procedure WMHotKey(var Message: TMessage); message WM_HOTKEY;

  end;

var
  fMain: TForm1;
  path : string;
  tiff_dir, last_prov, last_group  : string;
  tiffs : array [1..5120] of TGeoRasterRec;
  ntiffs, curline, curtiff : word;
  grid_delta : word;
  jpegQuality : integer;


const
  debug = 0;
  ver = '0.94';


procedure log(s:string);

implementation
{$R *.dfm}


procedure log(s:string);
begin
  if (debug = 1) then   fMain.memoLog.lines.add(s);
end;


procedure TForm1.WMHotKey(var Message: TMessage);
Begin
  btnSetScaleClick(self);
end;

procedure TForm1.FormCreate(Sender: TObject);
  var isatlas  : string;
          s : string;
begin
  sgStatus.Cells[0, 0] := 'File';
  sgStatus.Cells[1, 0] := 'Status';
  sgStatus.Cells[2, 0] := 'Msg';
  sgStatus.Cells[3, 0] := 'Provider';
  sgStatus.Cells[4, 0] := 'Group';
  sgStatus.Cells[5, 0] := 'RMP file';

  sgStatus.ColWidths[2] := 250;
  sgStatus.ColWidths[3] := 115;
  sgStatus.ColWidths[4] := 115;
  sgStatus.ColWidths[5] := 175;


  openTiff.options := [ofAllowMultiSelect, ofFileMustExist];
  path := ExtractFilePath(ParamStr(0))+'\';
  tiff_dir := read_config_val('last_dir');
  last_prov := read_config_val('prov');
  last_group := read_config_val('group');

  s := read_config_val('jpeg_quality');
  if (s = '') then s := '75';
  inJpegQual.Text := s;
  jpegQuality := strtoint(s);

  inProv.Text := last_prov;
  inGroup.Text := last_group;


  if (debug = 0) then begin
    memoLog.Visible := false;
  end else begin
    memoLog.Visible := true;
  end;

  isatlas :=  read_config_val('is_atlas');
  if isatlas = '1' then rbAtlas.Checked := true
    else rbSingle.Checked := true;

  Caption := Caption + ' v'+ver;
  curline := 0;
  curtiff := 0;

  lLoading.Visible := false;

  if read_config_val('gps_model') <> '' then cbModel.ItemIndex := strtoint( read_config_val('gps_model') )
    else cbModel.ItemIndex := 0;
  inExportScale.text := read_config_val('export_scale');
  if (inExportScale.text = '') then inExportScale.text := '100000';


  RegisterHotKey(Handle, 100000, 0, VK_F9);

  inUseExternalX.text := read_config_val('internal_maxw');
  inUseExternalY.text := read_config_val('internal_maxh');
  if inUseExternalX.text = '' then inUseExternalX.text := '10000';
  if inUseExternalY.text = '' then inUseExternalY.text := '10000';

  if read_config_val('useExternal') = '1' then cbUseExternal.Checked := true
    else cbUseExternal.Checked := false;


  grid_delta := width - sgStatus.width;
end;


procedure TForm1.btnOpenTiffsClick(Sender: TObject);
var
  i, j : word;
  have : boolean;

begin
  openTiff.FileName := '*.tif; *.tiff; *.map; *.gif; *.bmp; *.jpg; *.jpef; *.png';
  openTiff.initialdir := tiff_dir;
  if openTiff.execute then begin
    tiff_dir := ExtractFilePath(openTiff.Files[0]);
    write_config_val('last_dir', tiff_dir );
    write_config_val('prov', trim(inProv.Text) );
    write_config_val('group', trim(inGroup.Text) );

    for i:=0 to openTiff.Files.Count - 1 do begin
      path := ExtractFilePath(openTiff.Files[i])+'\'+ExtractFileName(openTiff.Files[i]);
      //check for dupes
      have := false;
      for j:=1 to ntiffs do begin
        if tiffs[j].fname = path then begin
          have := true;
          break;
        end;
      end;

      if (have) then continue;

      inc(curline);
      if ( curline >= sgStatus.RowCount  ) then sgStatus.RowCount  := curline + 1;
      inc(ntiffs);
      tiffs[ ntiffs ] := load_georaster(path);
      tiffs[ ntiffs ].num := curline;

      sgStatus.Cells[0, curline] := ExtractFileName(openTiff.Files[i]);
      sgStatus.Cells[3, curline] := inProv.text;
      sgStatus.Cells[4, curline] := inGroup.text;

      sgStatus.Cells[5, curline] := tiffs[ ntiffs ].rmp_fname;
      if tiffs[ ntiffs ].err <> '' then begin
        sgStatus.Cells[1, curline] := 'err';
        sgStatus.Cells[2, curline] := tiffs[ ntiffs ].err;
      end;
    end;
  end;
end;

procedure TForm1.run_next();
var
  ProgressThread1 : cconvertThread;
  i : word;
  fn : string;
  prov, group : string;
  tmp : string;
begin
  pbConvert.Position := 0;

  if (ntiffs > 0) then begin
    inc(curtiff);
    //done
    if (curtiff > ntiffs) then begin
      toggle_controls(true);

      //delete temp files
      if ( debug = 0   ) then begin
        tmp := GetTempDir();
        if tmp = '' then tmp := path;
        clean_dir(  tmp + '\forrmp\', '*.*' );
        clean_dir(  tmp + '\tiles\', '*.*' );
      end;
      exit;
    end;
    savedialog1.initialdir := openTiff.InitialDir;

    //RMP for every TIFF
    if rbSingle.Checked then begin

      sgStatus.Cells[1, tiffs[curtiff].num ] := 'in progress';
      prov := sgStatus.Cells[3, tiffs[curtiff].num ];
      group := sgStatus.Cells[4, tiffs[curtiff].num ];
      ProgressThread1 := cconvertThread.Create( prov, group, tiffs[curtiff].num );
      ProgressThread1.rmpfname := sgStatus.Cells[5, tiffs[curtiff].num ];
      ProgressThread1.add_tiff( tiffs[ curtiff  ] );
    end
    //atlas
    else begin
      sgStatus.cells[0,1] := 'Atlas';

      
      if (SaveDialog1.execute) then begin
        fn := savedialog1.FileName;
        if pos('.rmp', LowerCase(fn) ) = 0 then fn := fn + '.rmp';
         
        ProgressThread1 := cconvertThread.Create( trim(inProv.Text), trim(inGroup.Text), 1);
        for i := 1 to ntiffs do ProgressThread1.add_tiff( tiffs[i] );
        ProgressThread1.rmpfname := fn;
        curtiff := ntiffs  + 1;
      end else begin
        curtiff := ntiffs  + 1;
        run_next();
        exit;

      end;
    end;
    ProgressThread1.Resume;
    ProgressThread1.FreeOnTerminate := true;
  end else begin
    pbConvert.Position := 0;
    toggle_controls(true);
    exit;
  end;
end;




procedure TForm1.btnHelpClick(Sender: TObject);
begin
  fAbout.visible := true;
end;

procedure TForm1.rbSingleClick(Sender: TObject);
begin
  if rbSingle.Checked then write_config_val('is_atlas', '0')
    else write_config_val('is_atlas', '1');
end;

procedure TForm1.rbAtlasClick(Sender: TObject);
begin
  if rbSingle.Checked then write_config_val('is_atlas', '0')
    else write_config_val('is_atlas', '1');
end;

procedure TForm1.btnCreateRMPClick(Sender: TObject);
begin
  jpegQuality := strToInt( inJpegQual.text );
  toggle_controls( false );
  run_next();
end;


procedure TForm1.toggle_controls( state : boolean);
begin
  btnOpenTiffs.Enabled := state;
  btnCreateRMP.Enabled := state;
  btnDeleteTiff.Enabled := state;
  btnClearTiffs.Enabled := state;
  btnVisualize.Enabled := state;

  inGroup.Enabled := state;
  inProv.Enabled := state;

  if (state) then curtiff := 0;

end;



procedure TForm1.btnDeleteTiffClick(Sender: TObject);
var row : word;
  a : array [1..5012] of TGeoRasterRec;
  i, na : word;
begin
  na := 0;
  row := sgStatus.Row;
  for i := 1 to ntiffs do begin
    if tiffs[i].num = row then continue;
    inc(na);
    a[ na ] := tiffs[i];
  end;

    for i:=1 to sgStatus.RowCount do begin
      sgStatus.Cells[0, i] := '';
      sgStatus.Cells[1, i] := '';
      sgStatus.Cells[2, i] := '';
    end;
    for i:=1 to na do begin
      tiffs[i] := a[i];
      tiffs[i].num := i;
      sgStatus.Cells[0, i] := ExtractFileName( tiffs[i].fname );
      if ( tiffs[i].err <> '' ) then begin
        sgStatus.Cells[1, i] := 'err';
        sgStatus.Cells[2, i] := tiffs[i].err;
      end;
    end;
    ntiffs := na;
    curline := na;

end;

procedure TForm1.btnClearTiffsClick(Sender: TObject);
  var i : word;
     isok : boolean;
     w, h : dword;

     lat, lon : double;
     r : integer;
     from, dto : pchar; 
begin
{  g := tgifimage.create;
  g.LoadFromFile('f:\!dig\!new_rastr\tiff\test\test2.gif');
  image1.Picture.Assign( g.Bitmap );
  b := TPNGObject.Create;
  b.LoadFromFile('f:\!dig\!new_rastr\tiff\test\test2.png');
  image1.Width := b.Width;
  image1.Height := b.Height;
  image1.Canvas.Draw( 0, 0, b);
}

  for i:=1 to sgStatus.RowCount do begin
    sgStatus.Cells[0, i] := '';
    sgStatus.Cells[1, i] := '';
    sgStatus.Cells[2, i] := '';
    sgStatus.Cells[3, i] := '';
    sgStatus.Cells[4, i] := '';
    sgStatus.Cells[5, i] := '';
  end;
  ntiffs := 0;
  curline := 0;
  curtiff := 0;
end;




procedure TForm1.btnVisualizeClick(Sender: TObject);

begin
  fVisual.show;
  exit;
end;



procedure TForm1.cbModelChange(Sender: TObject);
begin
  write_config_val('gps_model', inttostr(cbModel.ItemIndex) );
end;

procedure TForm1.inExportScaleChange(Sender: TObject);
begin
  write_config_val('export_scale', inExportScale.text );
end;

procedure TForm1.btnSetScaleClick(Sender: TObject);
var
  wInches, hInches, qf, h : double;
  wPix, hPix, scale : cardinal;
  s : string;
begin
  if (cbModel.text = 'eXp 110/GC/310') or (cbModel.text = 'Triton 300/400/500') then begin
    wInches := 1.32;
    hInches := 1.76;
    wPix := 240;
    hPix := 320;
  end;
  if (cbModel.text = 'Triton 1500/2000') then begin
    wInches := 1.62;
    hInches := 2.16;
    wPix := 240;
    hPix := 320;
  end;
  if (cbModel.text = 'eXp 510/610') then begin
    //3" | 0.6 = 420/400
    h := sqrt( 3*3/(1+0.6*0.6) );

    wInches := 0.6 * h;
    hInches := h;
    wPix := 240;
    hPix := 400;
  end;
  if (cbModel.text = 'eXp 710') then begin
    //3"
    qf := 340 / 432;

    h := sqrt( 3*3/(1 + qf*qf) );

    wInches := 0.6 * h;
    hInches := h;
    wPix := 340;
    hPix := 432;
  end;


  s := trim(inExportScale.text);
  s := StringReplace(s, ' ', '', [rfReplaceAll]);
  scale := strtoint(s);

  set_export_geotiffscale(wInches, hInches, wPix, hPix, scale);
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  UnregisterHotKey(Handle, 100000);
end;

procedure TForm1.sgStatusDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
Var
  StringGrid: TStringGrid;
  Can: TCanvas;
begin
  StringGrid := Sender as TStringGrid;
  Can := StringGrid.Canvas;
  Can.Font := StringGrid.Font;

  if ARow =  0 then Can.Brush.Color := clMenu
    else Can.Brush.Color := clWhite;

  if (gdSelected in State) then
  begin
    Can.Font.Color := clHighlightText;
    Can.Brush.Color := clHighlight;
  end;

  Can.FillRect(Rect);
  Can.TextOut(Rect.Left + 2, Rect.Top +2, StringGrid.Cells[ACol, ARow] );

end;

procedure TForm1.cbUseExternalClick(Sender: TObject);
begin
  if cbUseExternal.Checked then write_config_val('useExternal', '1')
    else write_config_val('useExternal', '0');
end;

procedure TForm1.inUseExternalXChange(Sender: TObject);
begin
  write_config_val('internal_maxw', inUseExternalX.text );
end;

procedure TForm1.inUseExternalYChange(Sender: TObject);
begin
  write_config_val('internal_maxh', inUseExternalY.text );
end;

procedure TForm1.FormResize(Sender: TObject);
var scale, newSgwidth, new2 : word;
    ratio : real;
begin
  newSgwidth :=   width - grid_delta;


  sgStatus.ColWidths[0] :=  round(newSgwidth * (sgStatus.ColWidths[0] / sgStatus.width) ) ;
  sgStatus.ColWidths[1] :=  round(newSgwidth * (sgStatus.ColWidths[1] / sgStatus.width) ) ;
  sgStatus.ColWidths[2] :=  round(newSgwidth * (sgStatus.ColWidths[2] / sgStatus.width) ) ;
  sgStatus.ColWidths[3] :=  round(newSgwidth * (sgStatus.ColWidths[3] / sgStatus.width) ) ;
  sgStatus.ColWidths[4] :=  round(newSgwidth * (sgStatus.ColWidths[4] / sgStatus.width) ) ;
  sgStatus.ColWidths[5] :=  round(newSgwidth * (sgStatus.ColWidths[5] / sgStatus.width) ) ;




  sgStatus.width := newSgwidth;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  ProgressThread1 : cconvertThread;
  tmp : string;
begin
 ProgressThread1 := cconvertThread.Create( 'genshtab', 'mogilev', tiffs[1].num );
 ProgressThread1.rmpfname := sgStatus.Cells[5, tiffs[1].num ];
 ProgressThread1.add_tiff( tiffs[ 1 ] );
   tmp := GetTempDir();
    if tmp = '' then tmp := path;
    if not(DirectoryExists(tmp)) then CreateDir(tmp);

    ProgressThread1.forrmp_dir := tmp + '\forrmp\';
    ProgressThread1.tile_dir := tmp + '\tiles\';

  ProgressThread1.craft_description_file( ProgressThread1.rmpfname );
  ProgressThread1.craft_ini_file();
   ProgressThread1.craft_a00( tiffs[1] , 1);
   showmessage('a00 done'); 
   SaveResourceAsFile('exp_sig', ProgressThread1.forrmp_dir + '\BMP4BIT.ICS');
    SaveResourceAsFile('triton_sig', ProgressThread1.forrmp_dir + 'chunk.ics');
    ProgressThread1.pack_rmp( ProgressThread1.rmpfname );
end;

procedure TForm1.inJpegQualChange(Sender: TObject);
begin
    write_config_val('jpeg_quality', trim(inJpegQual.Text) );
end;

end.

