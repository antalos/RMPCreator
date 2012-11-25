unit calibrate_dlg;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, tiff_functions, JPEG, gifimage, pngimage, functions;

type
  TForm3 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    GroupBox1: TGroupBox;
    tly1: TLabeledEdit;
    tly2: TLabeledEdit;
    tlyType: TComboBox;
    tlxType: TComboBox;
    tlx1: TLabeledEdit;
    tlx2: TLabeledEdit;
    GroupBox2: TGroupBox;
    bry1: TLabeledEdit;
    bry2: TLabeledEdit;
    bryType: TComboBox;
    brxType: TComboBox;
    brx1: TLabeledEdit;
    brx2: TLabeledEdit;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    procedure WMSYSCOMMAND(var Msg: TWMSYSCOMMAND); message WM_SYSCOMMAND;
    procedure WMACTIVATEAPP(var Msg: TWMACTIVATEAPP); message WM_ACTIVATEAPP;    
  public
    { Public declarations }
    fname : string;
    im_type : cardinal;
    imw, imh : dword;
    tlx, tly : double;
    scalex, scaley : double;

    procedure test;
  end;

var
  fCalibrate: TForm3;
  

implementation
uses geo_raster;
{$R *.dfm}

procedure TForm3.WMACTIVATEAPP(var Msg: TWMACTIVATEAPP);
begin
  if IsIconic(Application.Handle) then ShowWindow(Application.Handle, SW_RESTORE);
  inherited;
end;

procedure TForm3.WMSYSCOMMAND(var Msg: TWMSYSCOMMAND);
begin
  if Msg.CmdType = SC_MINIMIZE then ShowWindow(Application.Handle, SW_MINIMIZE)
    else inherited;
end;

procedure TForm3.Button1Click(Sender: TObject);
var brx, bry : double;
begin
  DecimalSeparator := '.';
  tlx := StrToFloat( tlx1.text ) + StrToFloat( stringReplace(tlx2.text, ',', '.',  [rfReplaceAll]) ) / 60;
  tly := StrToFloat( tly1.text ) + StrToFloat( stringReplace(tly2.text, ',', '.',  [rfReplaceAll]) ) / 60;
  if (tlxType.Text = 'W') then tlx := 0 - tlx; //west
  if (tlyType.Text = 'N') then tly := 0 - tly; //north

  brx := StrToFloat( brx1.text ) + StrToFloat( stringReplace(brx2.text, ',', '.',  [rfReplaceAll]) ) / 60;
  bry := StrToFloat( bry1.text ) + StrToFloat( stringReplace(bry2.text, ',', '.',  [rfReplaceAll]) ) / 60;
  if (brxType.Text = 'W') then brx := 0 - brx; //west
  if (bryType.Text = 'N') then bry := 0 - bry; //north

  scalex := abs( (brx - tlx) / imw );
  scaley := abs( (bry - tly) / imh );
  scaley := 0 - scaley;

  write_config_val('tlx1', tlx1.Text);
  write_config_val('tlx2', tlx2.Text);
  write_config_val('tly1', tly1.Text);
  write_config_val('tly2', tly2.Text);

  write_config_val('brx1', brx1.Text);
  write_config_val('brx2', brx2.Text);
  write_config_val('bry1', bry1.Text);
  write_config_val('bry2', bry2.Text);

  write_config_val('tlxType', tlxType.Text);
  write_config_val('brxType', brxType.Text);
  write_config_val('tlyType', tlyType.Text);
  write_config_val('bryType', bryType.Text);


  ModalResult := mrOk;
end;

procedure TForm3.Button2Click(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TForm3.FormShow(Sender: TObject);
  var j : TJPEGImage;
    g : tgifimage;
    P : TPNGObject;
    b : TBitmap;
    a, bb, c, d : double;
    s : string;
    isok : boolean;
    w, h : dword;
begin
  button1.Enabled := true;
  tlx1.Text := read_config_val('tlx1');
  tlx2.Text := read_config_val('tlx2');
  tly1.Text := read_config_val('tly1');
  tly2.Text := read_config_val('tly2');

  brx1.Text := read_config_val('brx1');
  brx2.Text := read_config_val('brx2');
  bry1.Text := read_config_val('bry1');
  bry2.Text := read_config_val('bry2');

  if read_config_val('tlxType') <> '' then tlxType.text := read_config_val('tlxType');
  if read_config_val('brxType') <> '' then brxType.text := read_config_val('brxType');
  if read_config_val('tlyType') <> '' then tlyType.text := read_config_val('tlyType');
  if read_config_val('bryType') <> '' then bryType.text := read_config_val('bryType');


  isok := get_img_options(fname, w, h);
  if not(isok) then begin
    button1.Enabled := false;
    showmessage('Error while loading image');
  end;
  imw := w;
  imh := h;

   {
   try
   if im_type = IM_TYPE_TIFF then begin
  //    image1.Picture.Assign( ReadTiffIntoBitmap( fname ) );
      get_tiff_options(fname, imw, imh, a, bb, c, d, s);
    end;

    if im_type = IM_TYPE_JPEG then begin
      j := TJPEGImage.Create;
      j.LoadFromFile( fname );
  //    image1.Picture.Assign( j );
      imw := j.Width;
      imh := j.Height;
      j.free;
    end;

    if im_type = IM_TYPE_GIF then begin
      g := tgifimage.create;
      g.LoadFromFile(  fname  );
  //    image1.Picture.Assign( g.Bitmap );
      imw := g.Width;
      imh := g.Height;
      g.free;
    end;

    if im_type = IM_TYPE_PNG then begin
      p := TPNGObject.Create;
      p.LoadFromFile( fname );
      imw := p.Width;
      imh := p.Height;
      p.Free;
  //    image1.picture.loadFromFile( fname );
    end;

    if im_type = IM_TYPE_BMP then begin
      b := TBitmap.create;
      b.LoadFromFile( fname );
      imw := b.Width;
      imh := b.Height;
      b.free;
  //    image1.Picture.LoadFromFile( fname );
    end;
  except
    button1.Enabled := false;
    showmessage('Error while loading image');
  end;     }

end;

procedure TForm3.test();
begin
    ModalResult := mrNone;
    self.Close;
end;
end.
