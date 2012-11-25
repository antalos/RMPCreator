unit functions;

interface
uses Classes, windows, math, sysutils, Graphics, JPEG,   inifiles;

type
  PTFileStream = ^TFileStream;


function get_degree(coord : double) : string;
function get_minues(coord : double) : string;

procedure zerofy(var a : array of byte);
function GetFileSize( const Path : String ) : Integer;

function read_dword(a:PTFileStream; offset:dword) : dword;
function read_double(a:PTFileStream; offset:dword) : double;
function read_str(a:PTFileStream; offset, len:dword) : AnsiString;

procedure write_str(a:PTFileStream; s : AnsiString; len : dword);

function dump_coordx(coord : double) : string;
function dump_coordy(coord : double) : string;

function execcmd(const acommand: string;const ashow, awaitexit: boolean): boolean;
procedure stringsToArray(s : string; delimiter: string; var a : array of string; var n : word);
function getfloat(s:string) : double	;
procedure file_put_contents(fn,data:string);
procedure clean_dir(dir,mask : string);

function fstr(a:double) : string;
function istr(i:integer) : string;




function read_config_val(key:string):string;
procedure write_config_val(key,val:string);
function GetTempDir: string;
procedure SaveResourceAsFile(ResName, FileName: string);

Function WinToDos(Const S: String) : String;
Function DosToWin(Const S: String) : String;


procedure set_jpeg_padding(fn, hor_mode, ver_mode:string);
procedure writeToOffset(f:TFilestream; const Buffer; offset, Count: Longint);

implementation



function read_config_val(key:string):string;
Var IniFile : TIniFile;
begin
  IniFile := TIniFile.Create( ExtractFilePath(ParamStr(0))+ '\config.ini' );
  result := IniFile.ReadString('common',key, '');
  iniFile.Free;
end;

procedure write_config_val(key,val:string);
Var IniFile : TIniFile;
begin
  IniFile := TIniFile.Create( ExtractFilePath(ParamStr(0))+ '\config.ini' );
  IniFile.writestring('common',key,val);
  iniFile.Free;
end;

function fstr(a:double) : string;
begin
  result := FloatToStrF(a, ffFixed, 8,8);
end;
function istr(i : integer) : string;
begin
  result := inttostr(i);
end;

function GetFileSize( const Path : String ) : Integer;
var FD : TWin32FindData;
    FH : THandle;
begin
  FH := FindFirstFile( PChar( Path ), FD );
  Result := 0;
  if FH = INVALID_HANDLE_VALUE then exit;
  Result := FD.nFileSizeLow;
  if ((FD.nFileSizeLow and $80000000) <> 0) or
     (FD.nFileSizeHigh <> 0) then Result := -1;
  Windows.FindClose( FH );
end;



procedure zerofy(var a : array of byte);
var i : byte;
begin
  for i:=0 to sizeof(a) do begin
    a[i] := 0;
  end;
end;




function get_degree(coord : double) : string;
begin
  if coord < 0 then coord := 0 - coord;
  result := FloatToStr( Floor(coord) );
end;



function get_minues(coord : double) : string;
begin
  if coord < 0 then coord := 0 - coord;
  coord := coord - Floor(coord) ; //remove degrees
  coord := coord * 60;
  result := FloatToStrF( coord, ffFixed, 5, 2 );
end;



function read_dword(a:PTFileStream; offset:dword) : dword;
var buf : array [0..3] of byte;
    d : dword;
begin
  zerofy(buf);
  a^.Seek(offset, soFromBeginning);
  a^.read(buf[0], 4);
  move(buf[0], d, 4);
  result := d;
end;

function read_double(a:PTFileStream; offset:dword) : double;
var buf : array [0..7] of byte;
    d : double;
begin
  zerofy(buf);
  a^.Seek(offset, soFromBeginning);
  a^.read(buf[0], 8);
  move(buf[0], d, 8);
  result := d;
end;


function read_str(a:PTFileStream; offset, len:dword) : AnsiString;
var buf : array [0..1024] of byte;
    r : ansistring;
    j : dword;
begin
  zerofy(buf);
  a^.Seek(offset, soFromBeginning);
  a^.read(buf[0], len);
  r := '';
  for j:=0 to len-1 do
    if buf[j] <> 0 then r := r + chr(buf[j]);

  result := r;
end;

procedure write_str(a:PTFileStream; s : AnsiString; len : dword);
var buf : array [0..1024] of char;
  j : dword;

begin
  for j:=1 to len do buf[j] := chr(0);
  for j:=1 to length(s) do buf[j-1] := s[j];
  a^.Write(buf, len);
end;


function dump_coordx(coord : double) : string;
var  res : string;
begin
  if (coord >= 0 ) then res := res + 'E' else res := res +'W';
  res := res + ' '+get_degree(coord)+'°';
  res := res + get_minues(coord)+'''';

  result := res;
end;

function dump_coordy(coord : double) : string;
var  res : string;
begin
  if (coord >= 0 ) then res := res + 'S' else res := res +'N';
  res := res + ' '+get_degree(coord)+'°';
  res := res + get_minues(coord)+'''';

  result := res;
end;


procedure clean_dir(dir,mask : string);
var MySearch: TSearchRec;

begin
  FindFirst(dir+'\'+mask, faAnyFile, MySearch);
  DeleteFile(dir+'\'+MySearch.Name);
  while FindNext(MySearch)=0 do DeleteFile(dir+'\'+MySearch.Name);
  FindClose(MySearch);
end;

function getfloat(s:string) : double ;
begin
  s := StringReplace(s, '.', ',', [rfReplaceAll]);
  try
    result := strtoFloat(s);
  except
    s := StringReplace(s, ',', '.', [rfReplaceAll]); //change delimiter
    try
      result := strtoFloat(s);
    except
      result := -1;
    end;
  end;
end;

//turning string into array of strings
procedure stringsToArray(s : string; delimiter: string; var a : array of string; var n : word);
  var i : integer;
      r : string;
begin
 n := 0;
 r := delimiter;
 for i:=1 to High(A) do a[i] := '';

 while s <> '' do begin
    i := Pos(r,s);
    if i=0 then i := Length(s) + 1;
    a[n] := trim(Copy(s,1,i-1));
    Delete(s,1,i+length(r)-1);
    inc(n);
 end;
end;


function execcmd(const acommand: string;const ashow, awaitexit: boolean): boolean;
var
  pi:process_information;
  si:startupinfo;
  cmdline,path: string;
begin
  zeromemory(@si,sizeof(si));
  si.cb:=sizeof(si);
  si.dwflags := startf_forceonfeedback+startf_useshowwindow;
  if ashow then si.wshowwindow := sw_shownormal else si.wshowwindow := sw_hide;
  path := extractfilepath(acommand);
  cmdline := acommand;

  result := createprocess(nil, pchar(cmdline), nil, nil, false, 0, nil, pchar(path), si, pi );
  if result then
  begin
    closehandle(pi.hthread);
    if awaitexit then waitforsingleobject( pi.hprocess, infinite );
    closehandle(pi.hprocess);
  end;
end;



procedure file_put_contents(fn, data:string);
var
  f : textfile;
begin
try
  assignfile(f, fn);
  rewrite(f);
  writeln(f, data);
  closefile(f);
except
  file_put_contents(fn, data);
end;
end;



function GetTempDir: string;
var
  Buffer: array[0..MAX_PATH] of Char;
begin
  GetTempPath(SizeOf(Buffer) - 1, Buffer);
  Result := StrPas(Buffer);
end;


procedure SaveResourceAsFile(ResName, FileName: string);
  var ResType: pchar;
begin
  ResType := 'BIN';
  with TResourceStream.Create(hInstance, ResName, ResType) do
    try
      SaveToFile(FileName);
    finally
      Free;
    end;
end;


Function WinToDos(Const S: String) : String;
begin
 SetLength(Result,Length(S));
 if  Length(S) <> 0  then
   CharToOem(pChar(S),pChar(Result));
end;

Function DosToWin(Const S: String) : String;
begin
 SetLength(Result,Length(S));
 if  Length(S) <> 0  then
   OemToChar(pChar(S),pChar(Result));
end;

procedure set_jpeg_padding(fn, hor_mode, ver_mode:string);
  var f : string;
    Dest,Source:TBitmap;
    jpg:TJPEGImage;
    r, r2 : trect;
begin

  Dest:=TBitmap.Create;
  Source:=TBitmap.Create;

  jpg:=TJPEGImage.Create;
  jpg.LoadFromFile(fn);
  Source.Assign(jpg);
  jpg.free;

  dest.width:=  256;
  dest.height:= 256;

  r.left := 0;
  r.top := 0;
  r.Bottom := 256;
  r.Right := 256;
  dest.Canvas.Brush.Color := rgb(0,0,0);
  dest.Canvas.Brush.style := bsSolid;
  dest.Canvas.FillRect( r );


  if (hor_mode = 'left') then begin
    r.left := 0;
    r.Right := Source.Width;
  end else begin
    r.Left := 256 -  Source.Width;
    r.Right := 256;
  end;

  if (ver_mode = 'top') then begin
    r.top := 0;
    r.Bottom := Source.Height;
  end else begin
    r.top := 256 - Source.Height;
    r.Bottom := 256;

  end;

  r2.left := 0;
  r2.top := 0;
  r2.Bottom := Source.Height;
  r2.Right := Source.Width;

  dest.Canvas.CopyRect(r, Source.Canvas, r2);


  jpg:=TJPEGImage.Create;
  jpg.Assign(dest);
  jpg.CompressionQuality := 100;
  jpg.SaveToFile(fn);
  jpg.Free;
  Source.Free;
  Dest.Free;

end;

procedure writeToOffset(f:TFilestream; const Buffer; offset, Count: Longint);
begin
  f.Seek(offset, soFromBeginning);
  f.Write(buffer, count);
end;

end.
