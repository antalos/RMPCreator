unit ozi_api;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, clipbrd, ComCtrls, ExtCtrls, ExtDlgs;


  {
function oziFindOzi:integer; stdcall; external 'oziapi.dll';
function oziCloseProgram:integer; stdcall; external 'oziapi.dll';
function oziGetExePath(var p:pchar;var DataLength:integer): integer; stdcall; external 'oziapi.dll';
function oziCenterMapAtPosition(lat,lon:double): integer; stdcall; external 'oziapi.dll';
function oziFindMapAtPosition(lat,lon:double): integer; stdcall; external 'oziapi.dll';
function oziGetMapDatum(var p:pchar;var DataLength:integer): integer; stdcall; external 'oziapi.dll';
function oziConvertDatum(var DatumFrom:pchar; var DatumTo:pchar; var lat:double; var lon:double):integer;stdcall; external 'oziapi.dll';

function oziMapSingleClickON(CallbackProc:pointer):integer; stdcall; external 'oziapi.dll';
function oziMapSingleClickOFF:integer; stdcall; external 'oziapi.dll';
function oziMapDblClickON(CallbackProc:pointer):integer; stdcall; external 'oziapi.dll';
function oziMapDblClickOFF:integer; stdcall; external 'oziapi.dll';
function oziObjectClickON(CallbackProc:pointer):integer; stdcall; external 'oziapi.dll';
function oziObjectClickOFF:integer; stdcall; external 'oziapi.dll';

function oziClearWPs:integer; stdcall; external 'oziapi.dll';
function oziClearEVs:integer; stdcall; external 'oziapi.dll';
function oziClearRTEs:integer; stdcall; external 'oziapi.dll';
function oziClearAllTracks:integer; stdcall; external 'oziapi.dll';
function oziClearPTs:integer; stdcall; external 'oziapi.dll';
function oziClearMFs:integer; stdcall; external 'oziapi.dll';
function oziClearMCs:integer; stdcall; external 'oziapi.dll';

function oziSaveMapFlag(Flag:boolean):integer; stdcall; external 'oziapi.dll';

function oziCreateWP(var Name:pchar;Symbol:integer;lat,lon:double;Altitude:double;wpDate:double
                      ;MapDisplayFormat:integer;PointerDirection:integer;GarminDisplayFormat:integer
                      ;ForeColor,BackColor:integer;ProximityDistance:integer;var Description:pchar
                      ;FontSize:integer;FontStyle:integer;SymbolSize:integer):integer;stdcall; external 'oziapi.dll';

function oziCreateWPex(var Name:pchar;Symbol:integer;lat,lon:double;Altitude:double;wpDate:double
                      ;MapDisplayFormat:integer;PointerDirection:integer;GarminDisplayFormat:integer
                      ;ForeColor,BackColor:integer;ProximityDistance:integer;var Description:pchar
                      ;FontSize:integer;FontStyle:integer;SymbolSize:integer
                      ;ProximitySymbolPos:integer;ProximityTime:double;ProximityRoute:integer
                      ;var FileAttachmentName:pchar;var ProximityFileAttachmentName:pchar
                      ;var ProximitySymbolName:pchar ):integer;stdcall; external 'oziapi.dll';

function oziCreateMF(var Name:pchar;lat,lon:double;var Description:pchar;var PictureName:pchar
                      ;var SymbolName:pchar; CreateWp:integer;var WpName:pchar):integer;stdcall; external 'oziapi.dll';
function oziCreateMC(var Name:pchar;lat,lon:double; ForeColor, BackColor, Width, Height,
                      FontSize, FontStyle:integer):integer;stdcall; external 'oziapi.dll';

function oziRepositionMF(Number:integer;lat,lon:double):integer;stdcall; external 'oziapi.dll';

function oziConvertLL2Grid(GridNumber:integer;lat,lon:double;var Datum:pchar;
                 var Zone:pchar; var Easting,Northing:double;
                 lat0,Lon0,lat1,Lat2,K0,X0,Y0:double):integer;stdcall;external 'oziapi.dll';


function oziStartMMapi:integer;stdcall;external 'oziapi.dll';
function oziStopMM:integer;stdcall;external 'oziapi.dll';
function oziSendMMstring(var NmeaString:pchar):integer;stdcall;external 'oziapi.dll';

function oziRefreshMap:integer;stdcall;external 'oziapi.dll';
function oziCreateTrackPoint(TrackNum,Code:integer;lat,lon,altitude,tpDate:double):integer;stdcall;external 'oziapi.dll';

// waypoints //////////
function oziGetWpNumberFromName(var name:pansichar):integer;stdcall;external 'oziapi.dll';
function oziDeleteWpByName(var name:pansichar):integer;stdcall;external 'oziapi.dll';
function oziDeleteWpByNumber(wpNum:integer):integer;stdcall;external 'oziapi.dll';
///////////////////////

function oziDeleteMcByNumber(mcNum:integer):integer;stdcall;external 'oziapi.dll';
function oziDeleteMfByNumber(mfNum:integer):integer;stdcall;external 'oziapi.dll';



function oziConvertGrid2LL(GridNumber:integer;var Zone:pchar;var ns:pchar; Easting,Northing:double;var Datum:pchar;var lat,lon:double;lat0,Lon0,lat1,Lat2,K0,X0,Y0:double):integer;stdcall;external 'oziapi.dll';
}
implementation
end.


