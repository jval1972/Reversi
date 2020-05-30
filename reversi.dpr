program reversi;

uses
  FastMM4 in 'FastMM4.pas',
  FastMM4Messages in 'FastMM4Messages.pas',
  Forms,
  frm_main in 'frm_main.pas' {ReversiForm},
  frm_splash in 'frm_splash.pas' {SplashForm},
  frm_aboutframe in 'frm_aboutframe.pas' {AboutFrame: TFrame},
  frm_settings in 'frm_settings.pas' {SettingsForm},
  frm_about in 'frm_about.pas' {AboutForm},
  rv_engine in 'rv_engine.pas',
  rv_colorpickerbutton in 'rv_colorpickerbutton.pas',
  rv_filemenuhistory in 'rv_filemenuhistory.pas',
  rv_dropdownbutton in 'rv_dropdownbutton.pas',
  rv_crtconsole in 'rv_crtconsole.pas',
  rv_utils in 'rv_utils.pas',
  rv_defs in 'rv_defs.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'Reversi';
  SplashForm := TSplashForm.Create(nil);
  SplashForm.Update;
  Application.CreateForm(TReversiForm, ReversiForm);
  Application.Run;
end.
