unit rmp;

interface
uses classes, sysutils, windows, functions;

type
  TRMP = class(TObject)
    files : TStrings;
    rmp_fname : string;

    constructor create(); 
    procedure add_file(s:string);
    function pack() : boolean;
    function pack_dir(dir : string) : boolean;
    procedure unpack_to_dir();
  end;

implementation


constructor TRMP.create(); 
begin
  files := TStringList.create;
  files.clear();
  inherited create;
end;

procedure TRMP.add_file(s:string);
begin
  files.add(s);
end;

function TRMP.pack_dir(dir : string) : boolean;
var
   Res: TSearchRec;
   EOFound: Boolean;

begin
  result := true;
  files.clear();
  try
    EOFound:= False;
    if FindFirst(dir+'*.*', faAnyFile, Res) < 0 then exit
    else
     while not EOFound do begin
       if (Res.Name <> '.') and (Res.Name <> '..') then files.add( dir + '\' + res.name);
       EOFound:= FindNext(Res) <> 0;
     end;
    sysutils.FindClose(Res) ;
    result := pack();
  except
    result := false;
  end;

end;

function TRMP.pack() : boolean;
  var  s, T : TFileStream;
    i, offset, size, j, nfiles : dword;
    name, ext : string;
    fsizes : array[0..1024] of dword;

begin
   result := true;
   try
     T := TFileStream.Create( rmp_fname, fmOpenWrite or fmCreate );
     nfiles := files.count;
     t.Write(nfiles, 4);
     t.Write(nfiles, 4);

     offset := 8;
     offset := offset + 24 * nfiles;
     offset := offset + 32 ;

     for i:=0 to files.Count - 1 do begin
        name := extractFileName(files[i]);
        name := copy(name, 1, pos('.', name) - 1);
        ext := copy(files[i], pos('.', files[i]) + 1, length(files[i]) - pos('.', files[i]));


        size := functions.GetFileSize( files[i]);
        fsizes[i] := size;

        write_str(@t, name, 9);
        write_str(@t, ext, 7);
        t.Write(offset, 4);
        t.Write(size, 4);

        offset := offset + size;
        if (size mod 2 <> 0) then offset := offset + 1;
     end;

     i := 58853;
     t.Write(i, 2);
     write_str(@t, 'MAGELLAN', 30);


     for i:=0 to files.Count - 1 do begin
        S := TFileStream.Create( files[i], fmOpenRead );
        T.CopyFrom(S, fsizes[i] ) ;
        s.free;

        if ( fsizes[i] mod 2 <> 0) then begin
          j := 0;
          t.Write(j, 1);
        end;
     end;


     write_str(@t, 'MAGELLAN};', 10);

     t.free;
   except
     result := false;
   end;
  
end;

procedure TRMP.unpack_to_dir();
begin
end;


end.
