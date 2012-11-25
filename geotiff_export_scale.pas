unit geotiff_export_scale;
interface
  uses windows, sysutils, math, messages;

procedure  set_export_geotiffscale(wInches, hInches : double; wPix, hPix, scale : cardinal);

function get_export_hwnd(name : string; return_parent : boolean) : hwnd;
procedure check_global_projection();

implementation
uses main;


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

function get_export_hwnd(name : string; return_parent : boolean) : hwnd;
  var
    wd, hgtiff : hwnd;
  titleLength: Integer;
  title: string;
  name2 : string;

begin
  result := 0;

  if (name = 'GeoTIFF Options') then name2 := 'GeoTIFF настройки'
  else if (name = 'Export Bounds') then name2 := 'Экпорт границ'
  else name2 := name;

  //191,41
  Wd := FindWindow(nil, '');
  While (Wd<>0) do  Begin
    hgtiff := 0;
    hgtiff := FindWindowEx(wd, 0, nil, nil);
    While (hgtiff <> 0) do Begin
      titleLength := GetWindowTextLength(hgtiff);
      SetLength(title, titleLength);
      GetWindowText(hgtiff, PChar(title), titleLength + 1);
      if (title = name) or (title = name2) then begin //window found
        if return_parent then result := wd
          else result := hgtiff;

      end;
      hgtiff := GetNextWindow(hgtiff,GW_HWNDNEXT);
    end;

    Wd := GetNextWindow(Wd,GW_HWNDNEXT);
  end;

end;

procedure click_export_hwnd(wd : hwnd);
var p : Tpoint;
    oldpos : TPoint;
begin
  GetCursorPos(oldpos);
  p.x := 193;
  p.Y := 40 - 21;
  ClientToScreen(wd, p);
  SetForegroundWindow(wd);
  sleep(10);
  SetCursorPos(p.x, p.y);
  mouse_event(MOUSEEVENTF_LEFTDOWN, p.x, p.y, 0, 0);
  mouse_event(MOUSEEVENTF_LEFTUP, p.x, p.y, 0, 0);
  sleep(30);

  check_global_projection();
  Sleep(30);


  p.x := 50;
  p.Y := 40 - 21;
  ClientToScreen(wd, p);
  SetForegroundWindow(wd);
  sleep(10);
  SetCursorPos(p.x, p.y);
  mouse_event(MOUSEEVENTF_LEFTDOWN, p.x, p.y, 0, 0);
  mouse_event(MOUSEEVENTF_LEFTUP, p.x, p.y, 0, 0);
  sleep(10);

  SetCursorPos(oldpos.x, oldpos.y);
end;

procedure get_projection_boundaries(wd : hwnd; var m_fNorth, m_fWest, m_fSouth, m_fEast : double);
var cwd : hwnd;
  r : Trect;
  p : Tpoint;
  l: Integer;
  s: string;
begin
{
  north_edit = Left 47 Top 153  87/23
  west_edit  =  140 153
  south_edit =  86 182
  east_edit  =  179 182
 }
  cwd := FindWindowEx(wd, 0, 'Edit', nil);
  DecimalSeparator := '.';
  while (cwd <> 0) do Begin
    GetWindowRect(cwd, r);
    p.x := r.Left;
    p.y := r.Top;
    ScreenToClient(wd, p);

    SetLength( s, 255 );
    l := SendMessage(cwd, WM_GETTEXT, 255, lparam( @s[ 1 ] ) );
    s := Copy( s, 1, l );

    if (p.x = 47) and (p.y = 153) then m_fNorth := strToFloat(s);
    if (p.x = 140) and (p.y = 153) then m_fWest := strToFloat(s);
    if (p.x = 86) and (p.y = 182) then m_fSouth := strToFloat(s);
    if (p.x = 179) and (p.y = 182) then m_fEast := strToFloat(s);

    cwd := GetNextWindow(cwd, GW_HWNDNEXT);
  end;
end;

procedure set_scale(wd : hwnd; CX, CY : extended);
var cwd : hwnd;
  r : trect;
  p : tpoint;
  s : string;

begin
  cwd := FindWindowEx(wd, 0, 'Edit', nil);
  while (cwd <> 0) do Begin
    GetWindowRect(cwd, r);
    p.x := r.Left;
    p.y := r.Top;
    ScreenToClient(wd, p);


    if (p.x = 63) and (p.y = 195) then begin
      s := extToStr(cx);
      SendMessage(cwd, WM_SETTEXT, Length(s), lParam(s));
      log('x='+inttohex(cwd, 6) );
    end;
    if (p.x = 63) and (p.y = 221) then begin
      s := extToStr(cy);
      SendMessage(cwd, WM_SETTEXT, Length(s), lParam(s));
      log('y='+inttohex(cwd, 6) );
    end;

    cwd := GetNextWindow(cwd, GW_HWNDNEXT);
  end;
end;


procedure uncheck_square_pixels();
var wd, cwd : hwnd;
    p : TPoint;
    r : TRect;
    rr : Lparam;
begin
 wd := get_export_hwnd('GeoTIFF Options', false);
 if (wd = 0) then exit;
// log(inttohex(wd, 6));
  cwd := FindWindowEx(wd, 0, 'Button', nil);
  while (cwd <> 0) do Begin
    GetWindowRect(cwd, r);
    p.x := r.Left;
    p.y := r.Top;
    windows.ScreenToClient(wd, p);


    if (p.x = 20) and (p.y = 245) then begin
      {s := extToStr(cx);
      SendMessage(cwd, WM_SETTEXT, Length(s), lParam(s));}
//      log('x='+inttohex(cwd, 6) );
      rr := SendMessage( cwd, BM_GETCHECK, 0, 0 );
      if (rr <> BST_UNCHECKED) then begin
//        log('chkd, unchking');
        SendMessage(cwd, BM_SETCHECK, BST_UNCHECKED, 0);
      end;
    end;

    cwd := GetNextWindow(cwd, GW_HWNDNEXT);
  end;
end;


procedure check_global_projection();
var wd, cwd : hwnd;
    p : TPoint;
    r : TRect;
    rr : Lparam;
begin
 wd := get_export_hwnd('Export Bounds', false);
 if (wd = 0) then exit;
// log(inttohex(wd, 6));
  cwd := FindWindowEx(wd, 0, 'Button', nil);
  while (cwd <> 0) do Begin
    GetWindowRect(cwd, r);
    p.x := r.Left;
    p.y := r.Top;
    windows.ScreenToClient(wd, p);


    if (p.x = 11) and (p.y = 132) then begin
      {s := extToStr(cx);
      SendMessage(cwd, WM_SETTEXT, Length(s), lParam(s));}
//      log('x='+inttohex(cwd, 6) );
      rr := SendMessage( cwd, BM_GETCHECK, 0, 0 );
      if (rr <> BST_CHECKED) then begin
//        log('unchkd, chking '+inttohex(cwd, 6));
        SendMessage(cwd, BM_SETCHECK, BST_CHECKED, 0);
      end;
    end;

    cwd := GetNextWindow(cwd, GW_HWNDNEXT);
  end;
end;



procedure set_export_geotiffscale(wInches, hInches : double; wPix, hPix, scale : cardinal);
var
  m_fNorth, m_fWest, m_fEast, m_fSouth : double;
  MedianLat, MedianLon : double;
  PixX, PixY : integer;
  fDeviceXRes, fDeviceYRes : double;

  m_fdX, m_fdY : double;

  CX, CY : extended;

  wd : hwnd;
begin

 wd := get_export_hwnd('GeoTIFF Options', true);
 if (wd = 0) then exit;
 click_export_hwnd(wd);
// SetForegroundWindow(fmain.Handle);
 
 wd := get_export_hwnd('Export Bounds', false);
 if (wd = 0) then exit;
 
 get_projection_boundaries(wd, m_fNorth, m_fWest, m_fSouth, m_fEast);



{  m_fNorth := 54.0321094712232; //54,0321094712232
  m_fWest := 29.9502188602652; //29,9502188602652
  m_fSouth := 53.6209132643006; //53,6209132643006
  m_fEast := 30.5417990313822; //30,5417990313822
  scale := 100000;
  CX := 0.000212035903626165554
        0.000211959932324257218
  CY := 0.000125441185760403854
        0.000125402929833060029
  scale := 200000;
  }


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

  uncheck_square_pixels();

  wd := get_export_hwnd('GeoTIFF Options', false);
  set_scale(wd, CX, CY);
end;

end.
