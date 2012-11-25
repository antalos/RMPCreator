unit fVisualise;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, geo_raster, functions
  ;

type
  TForm4 = class(TForm)
    Image1: TImage;
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fVisual: TForm4;

implementation
uses main;

{$R *.dfm}

procedure SortArray( var a: array of TGeoRasterRec; na : word);
var i, j : word;
    c, min : dword;
    t : TGeoRasterRec;
begin
  for i:=0 to na-1 do begin
    min := 0;
    for j:=i to na-1 do begin
      c := a[j].w * a[j].h;
      if (c > min) or (min = 0) then begin
        min := c;
        t := a[j];
        a[j] := a[i];
        a[i] := t;
      end;
    end;
  end;
end;

procedure TForm4.FormShow(Sender: TObject);
  var
    tlx, tly, brx, bry, w, h, pixx, pixy : double;
    i : word;
    b : Tbitmap;
    t : trect;
    cx, cy : word;
    x, y : double;
    tmp : array[1..5012] of TGeoRasterRec;
    ntmp : word;
begin
  ntmp := 0;
  if ntiffs = 0 then exit;

  for i:=1 to ntiffs do begin
    if tiffs[i].err = '' then begin
      inc(ntmp);
      tmp[ntmp] := tiffs[i];
    end;
  end;
  SortArray(tmp, ntmp);

  
  tlx := -111;
  tly := -111;
  brx := -111;
  bry := -111;

  for i:=1 to ntmp do begin
    if (tmp[i].tlx <= tlx) or (tlx = -111) then tlx := tmp[i].tlx;
    if (tmp[i].tly <= tly) or (tly = -111) then tly := tmp[i].tly;

    if (tmp[i].brx >= brx) or (brx = -111) then brx := tmp[i].brx;
    if (tmp[i].bry >= bry) or (bry = -111) then bry := tmp[i].bry;
  end;


//  log('TL: '+fstr(tlx)+' '+fstr(tly));
//  log('BR: '+fstr(brx)+' '+fstr(bry));

  w := brx - tlx;
  h := bry - tly;

//  log( 'w = '+fstr(w)+' h='+fstr(h) );

  image1.Transparent := false;
  b := TBitmap.create;
  b.width := 840;
  b.Height := 640;
  b.Canvas.Brush.Color := rgb(255, 255, 255);
  b.Canvas.Brush.Style := bsSolid;
  t.left := 0;
  t.top := 0;
  t.Right := 840;
  t.Bottom := 640;
  b.Canvas.FillRect(t);



  pixx := (w / 800) ;
  pixy := (h / 600) ;
//  log( 'pixx = '+fstr(pixx)+' pixy='+fstr(pixy) );

  


  for i:=1 to ntmp do begin
//    log( tmp[i].fname );
//    log('  '+fstr(tmp[i].tlx)+' , '+fstr(tmp[i].tly) );
    x := tlx - tmp[i].tlx;
    y := tly - tmp[i].tly;

    w := (tmp[i].brx  - tmp[i].tlx) / pixx;
    h := (tmp[i].bry  - tmp[i].tly) / pixy;
    w := abs(w);
    h := abs(h);

//    log('   '+istr(i)+': '+fstr(x)+ ' ' +fstr(y) +' w='+fstr(w)+' h='+fstr(h));

    cx := round( abs(x) / pixx );
    cy := round( abs(y) / pixy );

//    log('   '+ istr(cx)+','+istr(cy) + ' w = '+istr( round(w)) +' h = '+istr( round(h) ));


    t.Left := cx;
    t.Top := cy;
    t.Right := cx + round(w);
    t.Bottom := cy + round(h);

//    if tmp[i].num = sgStatus.Row then b.Canvas.Brush.color := clRed      else
    b.Canvas.Brush.color := clNavy;
    b.Canvas.Brush.Style := bsBDiagonal;
    SetBkColor(b.Canvas.Handle, rgb(255, 255, 255));
    b.Canvas.FillRect(t);

//    if tmp[i].num = sgStatus.Row then b.Canvas.Pen.color := clRed      else
    b.Canvas.Pen.color := clNavy;
    b.canvas.moveto(cx,cy);
    b.canvas.lineto(cx + round(w), cy);
    b.canvas.lineto(cx + round(w), cy + round(h));
    b.canvas.lineto(cx, cy + round(h));
    b.canvas.lineto(cx, cy);

//    if tmp[i].num = sgStatus.Row then begin      b.canvas.Font.Color := clRed;    end else begin

    b.canvas.Font.Color := clNavy;
    b.canvas.Brush.Color := clWhite;
    b.canvas.Brush.Style := bsSolid;
    b.canvas.Font.Size   := 6;
    b.canvas.TextOut(cx + 3, cy + 3, ExtractFileName(tmp[i].fname) );
  end;


  image1.Picture.Assign(b);

end;

end.
