unit frmAbout;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, SHELLAPI;

type
  TForm2 = class(TForm)
    Label1: TLabel;
    lVer: TLabel;
    Label2: TLabel;
    lUrl: TLabel;
    Label4: TLabel;
    lMail: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure lUrlClick(Sender: TObject);
    procedure lMailClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fAbout: TForm2;

implementation
uses main;

{$R *.dfm}

procedure TForm2.FormCreate(Sender: TObject);
begin

  Caption := Caption + ' v'+ver;
  lver.Caption := 'Version: '+ver;
  lUrl.Font.Style := [fsUnderline];
  lMail.Font.Style := [fsUnderline];
end;

procedure TForm2.lUrlClick(Sender: TObject);
begin
 ShellExecute(Application.Handle, PChar('open'), PChar(lUrl.Caption),PChar(0), nil, SW_NORMAL);
end;

procedure TForm2.lMailClick(Sender: TObject);
begin
 ShellExecute(Application.Handle, PChar('open'), PChar('mailto:'+lMail.Caption),PChar(0), nil, SW_NORMAL);
end;

end.


