unit geotiff_export_scale;
interface
  uses windows, sysutils, math, messages, dialogs;

procedure  set_export_geotiffscale(wInches, hInches : double; wPix, hPix, scale : cardinal);

function get_export_hwnd(wd : hwnd; name : string) : hwnd;
procedure get_projection_boundaries(wd : hwnd; var m_fNorth, m_fWest, m_fSouth, m_fEast : double);
function CalcP(LatA, LonA, LatB, LonB, PixM : double; Scale : integer) : integer;
function CalcC(dX : double; Pix : integer) : extended;
function extToStr(i : extended) : string;
procedure set_scale(wd : hwnd; CX, CY : extended);

const
 TCM_FIRST               = $1300;
 TCM_SETCURFOCUS        = TCM_FIRST + 48;

implementation
uses main;

procedure set_export_geotiffscale(wInches, hInches : double; wPix, hPix, scale : cardinal);
var
  m_fNorth, m_fWest, m_fEast, m_fSouth : double;
  MedianLat, MedianLon : double;
  PixX, PixY : integer;
  fDeviceXRes, fDeviceYRes : double;

  m_fdX, m_fdY : double;

  CX, CY : extended;

  wd : hwnd;
  titleLength : integer;
  title : string;

begin

  wd := GetForegroundWindow();
  titleLength := GetWindowTextLength(wd);
  SetLength(title, titleLength);
  GetWindowText(wd, PChar(title), titleLength + 1);
  if (title <> 'GeoTIFF Export Options') then Begin
    ShowMessage('Press F9 in GeoTIFF Export Options window');
    exit;
  end;


  get_projection_boundaries(wd, m_fNorth, m_fWest, m_fSouth, m_fEast);
  log( FloatToStr(m_fNorth) );
  log( FloatToStr(m_fWest) );
  log( FloatToStr(m_fSouth) );
  log( FloatToStr(m_fEast) );

  fDeviceXRes := wPix / (wInches * 0.0254); //240 pix x 1.32"
  fDeviceYRes := hPix / (hInches * 0.0254); //320 pix x 1.76"

  MedianLat := (m_fNorth + m_fSouth) / 2.0;
  MedianLon := (m_fWest + m_fEast) / 2.0;

  PixX := CalcP(MedianLat, m_fWest, MedianLat, m_fEast, fDeviceXRes, scale);
  PixY := CalcP(m_fNorth, MedianLon, m_fSouth, MedianLon, fDeviceYRes, scale);


  m_fdX := abs(m_fWest - m_fEast);
  m_fdY := abs(m_fNorth - m_fSouth);


  CX := CalcC(m_fdX, PixX);
  CY := CalcC(m_fdY, PixY);



  log (  extToStr(CX) );
  log (  extToStr(CY) );
  fMain.memoScale.lines.add('x:' + extToStr(CX));
  fMain.memoScale.lines.add('y:' + extToStr(CY));

  set_scale(wd, CX, CY);
end;




procedure get_projection_boundaries(wd : hwnd; var m_fNorth, m_fWest, m_fSouth, m_fEast : double);
var cwd, hw2 : hwnd;
  l, i: Integer;
  s: string;
  rr : Lparam;
  win_w : hwnd;
  elements : array[1..1024] of hwnd;
begin
  //enable bounds tab
  hw2 := FindWindowEx(Wd, 0, 'SysTabControl32', nil);
  if (hw2 = 0) then begin
    log('tabs contol not wound');
    exit;
  end;
  SendMessage(hw2, TCM_SETCURFOCUS, 2, 0);
  sleep(20);
  
  win_w := get_export_hwnd(wd, 'Export Bounds');
  if (win_w = 0) then begin
    log('bounds not found');
    exit;
  end;
  
  cwd := FindWindowEx(win_w, 0, 'Button', nil);
  i:=0;
  while (cwd <> 0) do Begin
    inc(i);
    elements[i] := cwd; //hwnd
    cwd := GetNextWindow(cwd, GW_HWNDNEXT);
  end;  



  //check global projection
  rr := SendMessage( elements[4] , BM_GETCHECK, 0, 0 );
  if (rr <> BST_CHECKED) then SendMessage(elements[4], BM_SETCHECK, BST_CHECKED, 0);
  sleep(20);


  DecimalSeparator := '.';
  SetLength( s, 255 );
  l := SendMessage(elements[17], WM_GETTEXT, 255, lparam( @s[ 1 ] ) ); s := Copy( s, 1, l );
  m_fNorth := strToFloat(s);

  SetLength( s, 255 );
  l := SendMessage(elements[18], WM_GETTEXT, 255, lparam( @s[ 1 ] ) ); s := Copy( s, 1, l );
  m_fWest := strToFloat(s);

  SetLength( s, 255 );
  l := SendMessage(elements[21], WM_GETTEXT, 255, lparam( @s[ 1 ] ) ); s := Copy( s, 1, l );
  m_fSouth := strToFloat(s);

  SetLength( s, 255 );
  l := SendMessage(elements[22], WM_GETTEXT, 255, lparam( @s[ 1 ] ) ); s := Copy( s, 1, l );
  m_fEast := strToFloat(s);


  //switch back to first tab
  SendMessage(hw2, TCM_SETCURFOCUS, 0, 0);
  sleep(20);
end;




procedure set_scale(wd : hwnd; CX, CY : extended);
var cwd : hwnd;
  s : string;
  win_w : hwnd;
  elements : array[1..1024] of hwnd;
  i : integer;
  rr : Lparam;
begin

  win_w := get_export_hwnd(wd, 'GeoTIFF Options');
  if (win_w = 0) then begin
    log('bounds not found');
    exit;
  end;
  
  cwd := FindWindowEx(win_w, 0, 'Button', nil);
  i:=0;
  while (cwd <> 0) do Begin
    inc(i);
    elements[i] := cwd; //hwnd
    cwd := GetNextWindow(cwd, GW_HWNDNEXT);
  end;  

  s := extToStr(cx);
  SendMessage(elements[17], WM_SETTEXT, Length(s), lParam(s));

  s := extToStr(cy);
  SendMessage(elements[20], WM_SETTEXT, Length(s), lParam(s));

  rr := SendMessage( elements[22], BM_GETCHECK, 0, 0 );
  if (rr <> BST_UNCHECKED) then SendMessage(elements[22], BM_SETCHECK, BST_UNCHECKED, 0);
end;


function get_export_hwnd(wd : hwnd; name : string) : hwnd;
var
  hgtiff : hwnd;
  titleLength: Integer;
  title: string;
  name2 : string;

begin
  result := 0;

  if (name = 'GeoTIFF Options') then name2 := 'GeoTIFF настройки'
  else if (name = 'Export Bounds') then name2 := 'Экпорт границ'
  else name2 := name;

  hgtiff := FindWindowEx(wd, 0, nil, nil);
  While (hgtiff <> 0) do Begin
    titleLength := GetWindowTextLength(hgtiff);
    SetLength(title, titleLength);
    GetWindowText(hgtiff, PChar(title), titleLength + 1);
    //log(inttohex(wd, 6)+':'+title);
    if (title = name) or (title = name2) then begin //window found
      result := hgtiff;
    end;
    hgtiff := GetNextWindow(hgtiff,GW_HWNDNEXT);
  end; 

end;




function extToStr(i : extended) : string;
  var ib : extended;
    s, s2 : string;                                          
begin
  ib := i * 1000;
  DecimalSeparator := '.';
  s := FloatToStrF(i, ffFixed, 5, 3);
  s2 := FloatToStrF(ib, ffFixed, 19, 18);
  s2 := copy(s2, pos('.', s2)+1, length(s2) );
  result := s +  s2;
end;



//double DistanceLL(double LatA, double LonA, double LatB, double LonB)
function DistanceLL(LatA, LonA, LatB, LonB : double) : double;
  const
    Pi = 3.14159265358979;
    dEarthRadius = 6378.135;
    dFlat = 0.993291;
    M_PI_2 = 1.57079632679489661923;

  var
  TanA, TanB, GeoA, GeoB, ColA, ColB : double;
  Sin_ColA, Cos_ColA, Sin_ColB, Cos_ColB : double ;
  DLon, CosDelta, DeltaRad : double;
  Cos_DLon, CoLat, Cos_CoLat, DeltaM : double ;

begin


  // Conversation to radiants
  LatA := LatA * Pi / 180.0;
  LonA := LonA * Pi / 180.0;
  LatB := LatB * Pi / 180.0;
  LonB := LonB * Pi / 180.0;

  // Determning latitutes in co latitudes Point A and Sine & Cosine values
  TanA := tan(LatA) * dFlat;
  GeoA := ArcTan(TanA);//;atan(TanA);
  ColA := M_PI_2 - GeoA;
  Sin_ColA := sin(ColA);
  Cos_ColA := cos(ColA);

  // Determning latitutes in co latitudes Point A and Sine & Cosine values 
  TanB := tan(LatB) * dFlat;
  GeoB := ArcTan(TanB);//atan(TanB);
  ColB := M_PI_2 - GeoB;
  Sin_ColB := sin(ColB);
  Cos_ColB := cos(ColB);

  // Determening Distance  between A and B
  DLon := LonB - LonA;
  Cos_DLon := cos(DLon);
  CosDelta := Sin_ColA * Sin_ColB * Cos_DLon + Cos_ColA * Cos_ColB;

  if (CosDelta > 1.0) then CosDelta := 1.0
    else if(CosDelta < -1.0) then CosDelta := -1.0;

  DeltaRad := ArcCos(CosDelta);//acos(CosDelta);

  // Determening distance in meter
  CoLat := M_PI_2 - (LatA + LatB) / 2.0;
  Cos_CoLat := cos(CoLat);
  DeltaM := DeltaRad * ((1.0/3.0 - Cos_CoLat * Cos_CoLat) * 0.00335278 + 1.0) * dEarthRadius * 1000;

  result := DeltaM;
end;

function CalcC(dX : double; Pix : integer) : extended;
begin
  result := dX / Pix;
end;


function CalcP(LatA, LonA, LatB, LonB, PixM : double; Scale : integer) : integer;
begin
  result := round(  ((DistanceLL(LatA, LonA, LatB, LonB) / Scale) * PixM) - 1 );
end;





end.
