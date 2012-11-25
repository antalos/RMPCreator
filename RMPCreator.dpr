program RMPCreator;

uses
  Forms,
  main in 'main.pas' {Form1},
  convertThread in 'convertThread.pas',
  rmp in 'rmp.pas',
  frmAbout in 'frmAbout.pas' {Form2},
  geo_raster in 'geo_raster.pas',
  calibrate_dlg in 'calibrate_dlg.pas' {Form3},
  geotiff_export_scale in 'geotiff_export_scale.pas',
  fVisualise in 'fVisualise.pas' {Form4};

{$R *.res}
{$R sigs.res}

begin
  Application.Initialize;
  Application.Title := 'RMPCreator';
  Application.CreateForm(TForm1, fMain);
  Application.CreateForm(TForm2, fAbout);
  Application.CreateForm(TForm3, fCalibrate);
  Application.CreateForm(TForm4, fVisual);
  Application.Run;
end.
