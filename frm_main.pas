unit frm_main;

interface

{$R ReversiWav.res}
{$R ReversiGames.res}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, Buttons, ToolWin, ExtCtrls, Menus, AppEvnts, MMSystem,
  ImgList, ShellApi, rv_engine, rv_crtconsole, rv_filemenuhistory,
  rv_dropdownbutton;

resourceString
  rsMovesFormat = '%2d. %s';
  rsReversi = 'Reversi';
  rsCorner = 'CORNER';
  rsCross = 'CROSS';
  rsScrew = 'SCREW';
  rsCircle = 'CIRCLE';
  rsPieces  = ' Pieces:%6d (%s)';
  rsScore   = ' Score: %6d (%s)';
  rsPlayer0 = 'TIE';
  rsPlayer1 = 'Player 1';
  rsPlayer2 = 'Player 2';
  rsGameOver0 = 'Game Over. TIE.';
  rsGameOver1 = 'Game Over. Player 1 Wins.';
  rsGameOver2 = 'Game Over. Player 2 Wins.';

type
  TReversiForm = class(TForm)
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    Load2: TSpeedButton;
    Save2: TSpeedButton;
    ToolButton2: TToolButton;
    StatusBar1: TStatusBar;
    MainMenu1: TMainMenu;
    MainMenu2: TMainMenu;
    Game1: TMenuItem;
    Game2: TMenuItem;
    New1: TMenuItem;
    Load1: TMenuItem;
    Save1: TMenuItem;
    SaveAs1: TMenuItem;
    SaveAs2: TMenuItem;
    Exit1: TMenuItem;
    Exit2: TMenuItem;
    Moves1: TMenuItem;
    Find1: TMenuItem;
    Pass1: TMenuItem;
    Tools1: TMenuItem;
    Tools2: TMenuItem;
    Options1: TMenuItem;
    Options2: TMenuItem;
    Design1: TMenuItem;
    Return1: TMenuItem;
    Help1: TMenuItem;
    Help2: TMenuItem;
    About1: TMenuItem;
    About2: TMenuItem;
    Separator1: TMenuItem;
    Separator2: TMenuItem;
    Separator3: TMenuItem;
    PopupMenu1: TPopupMenu;
    SaveAsText1: TMenuItem;
    ApplicationEvents1: TApplicationEvents;
    Panel1: TPanel;
    Panel2: TPanel;
    CrtPanel1: TPanel;
    CrtPanel2: TPanel;
    Panel5: TPanel;
    MovesList: TListBox;
    SaveDialog1: TSaveDialog;
    ImageList1: TImageList;
    NewPopupMenu: TPopupMenu;
    NewClassic1: TMenuItem;
    NewCorner1: TMenuItem;
    NewCross1: TMenuItem;
    NewScew1: TMenuItem;
    NewCircle1: TMenuItem;
    Separator4: TMenuItem;
    AutoPlay1: TMenuItem;
    MainMenu3: TMainMenu;
    Tools3: TMenuItem;
    Options3: TMenuItem;
    Help3: TMenuItem;
    About3: TMenuItem;
    Stop1: TMenuItem;
    ToolButton3: TToolButton;
    PopupMenu2: TPopupMenu;
    PresetBegginer1: TMenuItem;
    PresetAdvanced1: TMenuItem;
    PresetExpert1: TMenuItem;
    PresetSuperHuman1: TMenuItem;
    N11: TMenuItem;
    N21: TMenuItem;
    N31: TMenuItem;
    N41: TMenuItem;
    N51: TMenuItem;
    N61: TMenuItem;
    N71: TMenuItem;
    N81: TMenuItem;
    N91: TMenuItem;
    N1: TMenuItem;
    N101: TMenuItem;
    NewButtonImage: TImage;
    procedure Reversi1UpdateInfo(Sender: TObject; Info: TReversiInfo);
    procedure LoadClick(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    procedure AboutClick(Sender: TObject);
    procedure FindClick(Sender: TObject);
    procedure PassClick(Sender: TObject);
    procedure NewClick(Sender: TObject);
    procedure SaveAsClick(Sender: TObject);
    procedure ExitClick(Sender: TObject);
    procedure ApplicationEvents1Hint(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Reversi1Move(Sender: TObject; const move: String);
    procedure DesignClick(Sender: TObject);
    procedure ReturnClick(Sender: TObject);
    procedure Crt2DblClick(Sender: TObject);
    procedure Reversi1GameOver(Sender: TObject; Player: Byte);
    procedure SaveAsTextClick(Sender: TObject);
    procedure PopupMenu1Popup(Sender: TObject);
    procedure OptionsClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure NewCorner1Click(Sender: TObject);
    procedure NewCross1Click(Sender: TObject);
    procedure NewScew1Click(Sender: TObject);
    procedure NewCircle1Click(Sender: TObject);
    procedure AutoPlay1Click(Sender: TObject);
    procedure Stop1Click(Sender: TObject);
    procedure PresetBegginer1Click(Sender: TObject);
    procedure PopupMenu2Popup(Sender: TObject);
    procedure PresetAdvanced1Click(Sender: TObject);
    procedure PresetExpert1Click(Sender: TObject);
    procedure PresetSuperHuman1Click(Sender: TObject);
    procedure FileMenuHistory1Open(Sender: TObject;
      const FileName: string);
    procedure Game1Click(Sender: TObject);
  private
    { Private declarations }
    lastInfoMsg: string;
    Reversi1: TReversiBoard;
    ReversiPanel1: TReversiPanel;
    Crt1: TCrtConsole;
    Crt2: TCrtConsole;
    FileMenuHistory1: TFileMenuHistory;
    New2: TMenuButton;
    MenuTool1: TMenuTool;
    procedure LoadRegSettings;
    procedure SaveRegSettings;
  public
    { Public declarations }
  end;

var
  ReversiForm: TReversiForm;

implementation

uses
  rv_defs, frm_settings, frm_about;

{$R *.DFM}

procedure TReversiForm.Reversi1UpdateInfo(Sender: TObject; Info: TReversiInfo);

  function GetLeadingPlayer(Value: integer): string;
  begin
    if Value > 0 then
      result := rsPlayer1
    else if Value < 0 then
      result := rsPlayer2
    else
      result := rsPlayer0;
  end;

begin
  Crt1.TextColor(clSilver);
  Crt1.TextBackGround(clBlack);
  Crt1.ClrScr;
  Crt1.Write([Format(rsPieces, [Info.Value, GetLeadingPlayer(Info.Value)])]);
  Crt1.ClrEol;
  Crt1.Writeln(['']);
  Crt1.Write([Format(rsScore, [Info.Score, GetLeadingPlayer(Info.Score)])]);
  Crt1.ClrEol;

  if Info.Msg <> lastInfoMsg then
  begin
    lastInfoMsg := Info.Msg;
    if Info.Msg <> '' then
    begin
      Crt2.TextColor(clYellow);
      Crt2.TextBackGround(clBlack);
      Crt2.Write([Info.Msg]);
      Crt2.ClrEol;
      Crt2.Writeln(['']);
    end;
  end;
end;

procedure TReversiForm.LoadClick(Sender: TObject);
begin
  if Reversi1.CMLoadGame then
  begin
    FileMenuHistory1.AddPath(Reversi1.FileName);
    MovesList.Items.Clear;
  end;
end;

procedure TReversiForm.SaveClick(Sender: TObject);
begin
  if Reversi1.CMSaveGame then
    FileMenuHistory1.AddPath(Reversi1.FileName);
end;

procedure TReversiForm.AboutClick(Sender: TObject);
var
  f: TAboutForm;
begin
  f := TAboutForm.Create(nil);
  try
    f.ShowModal;
  finally
    f.free;
  end;
end;

procedure TReversiForm.FindClick(Sender: TObject);
begin
  Reversi1.CMShowHint;
end;

procedure TReversiForm.PassClick(Sender: TObject);
begin
  Reversi1.CMPass;
end;

procedure TReversiForm.NewClick(Sender: TObject);
begin
  MovesList.Items.Clear;
  Reversi1.CMNewGame;
end;

procedure TReversiForm.SaveAsClick(Sender: TObject);
begin
  Reversi1.CMSaveGameAs;
end;

procedure TReversiForm.ExitClick(Sender: TObject);
begin
  Close;
end;

procedure TReversiForm.ApplicationEvents1Hint(Sender: TObject);
begin
  StatusBar1.Panels[1].Text := Application.Hint;
end;

procedure TReversiForm.FormCreate(Sender: TObject);
var
  s: TFileStream;
begin
  ReversiPanel1 := TReversiPanel.Create(nil);
  ReversiPanel1.Parent := Self;
  ReversiPanel1.Align := alLeft;
  ReversiPanel1.Width := ReversiPanel1.Height;
  ReversiPanel1.Bevel := bvNone;
  ReversiPanel1.TabOrder := 1;

  Reversi1 := TReversiBoard.Create(nil);
  Reversi1.Parent := ReversiPanel1;
  Reversi1.Align := alClient;
  Reversi1.OnMove := Reversi1Move;
  Reversi1.OnUpdateInfo := Reversi1UpdateInfo;
  Reversi1.OnGameOver := Reversi1GameOver;
  ReversiPanel1.Board := Reversi1;

  Crt1 := TCrtConsole.Create(nil);
  Crt1.Parent := CrtPanel1;
  Crt1.Align := alClient;
  Crt1.ScreenSizeX := 26;
  Crt1.ScreenSizeY := 2;

  Crt2 := TCrtConsole.Create(nil);
  Crt2.Parent := CrtPanel2;
  Crt2.Align := alClient;
  Crt2.ScreenSizeX := 26;
  Crt2.ScreenSizeY := 6;
  Crt2.OnDblClick := Crt2DblClick;

  FileMenuHistory1 := TFileMenuHistory.Create(nil);
  FileMenuHistory1.OnOpen := FileMenuHistory1Open;
  FileMenuHistory1.MenuItem0 := N11;
  FileMenuHistory1.MenuItem1 := N21;
  FileMenuHistory1.MenuItem2 := N31;
  FileMenuHistory1.MenuItem3 := N41;
  FileMenuHistory1.MenuItem4 := N51;
  FileMenuHistory1.MenuItem5 := N61;
  FileMenuHistory1.MenuItem6 := N71;
  FileMenuHistory1.MenuItem7 := N81;
  FileMenuHistory1.MenuItem8 := N91;
  FileMenuHistory1.MenuItem9 := N101;

  LoadRegSettings;

  New2 := TMenuButton.Create(nil);
  New2.Parent := ToolBar1;
  New2.Left := 8;
  New2.Top := 2;
  New2.Width := 39;
  New2.Height := 25;
  New2.Hint := 'Start a new game';
  New2.Flat := True;
  New2.Glyph.Assign(NewButtonImage.Picture.Bitmap);
  New2.Glyph.Transparent := True;
  New2.Glyph.TransparentColor := RGB(255, 0, 255);
  New2.OnClick := NewClick;
  New2.Menu := NewPopupMenu;

  MenuTool1 := TMenuTool.Create(nil);
  MenuTool1.Parent := ToolBar1;
  MenuTool1.Left := 113;
  MenuTool1.Top := 2;
  MenuTool1.Width := 100;
  MenuTool1.Height := 25;
  MenuTool1.Menu := PopupMenu2;
  MenuTool1.Caption := 'Difficulty Level';
  MenuTool1.ParentFont := False;
  MenuTool1.Font := Screen.MenuFont;

  ToolButton1.Left := 0;
  ToolButton2.Left := 47;
  Load2.Left := 55;
  Save2.Left := 80;
  ToolButton3.Left := 105;

  StatusBar1.Panels[0].Text := 'Reversi 1.0';

  lastInfoMsg := '';
  if ParamCount = 1 then
  begin
    s := TFileStream.Create(ParamStr(1), fmOpenRead);
    try
      Reversi1.LoadFromStream(s);
      Reversi1.FileName := ParamStr(1);
    finally
      s.Free;
    end;
  end;
end;

procedure TReversiForm.Reversi1Move(Sender: TObject; const move: String);
begin
  if opt_soundon then
    PlaySound('REVERSI_1', HInstance, SND_RESOURCE or SND_ASYNC);
  if Reversi1.Player = Player1 then
    MovesList.Items.Add(Format(rsMovesFormat, [MovesList.Items.Count+1,move]))
  else
    MovesList.Items[MovesList.Items.Count - 1] :=
      MovesList.Items[MovesList.Items.Count - 1] + '-' + move;
  MovesList.ItemIndex := MovesList.Items.Count - 1;
end;

procedure TReversiForm.DesignClick(Sender: TObject);
begin
//  New2.Enabled := false;
  Load2.Enabled := false;
  Save2.OnClick := SaveAsClick;
  Reversi1.InDesignMode := true;
  Menu := MainMenu2;
end;

procedure TReversiForm.ReturnClick(Sender: TObject);
begin
//  New2.Enabled := true;
  Load2.Enabled := true;
  Save2.OnClick := SaveClick;
  Reversi1.InDesignMode := false;
  Menu := MainMenu1;
end;

procedure TReversiForm.Crt2DblClick(Sender: TObject);
begin
  Crt2.ClrScr;
  lastInfoMsg := '';
end;

procedure TReversiForm.Reversi1GameOver(Sender: TObject; Player: Byte);
begin
// Restore the menu if was in Autoplay mode
  Menu := MainMenu1;
// Display the corresponting message
  case Player of
    Player1: MessageBox(GetFocus, PChar(rsGameOver1), PChar(rsReversi),
      mb_OK or mb_IconInformation);
    Player2: MessageBox(GetFocus, PChar(rsGameOver2), PChar(rsReversi),
      mb_OK or mb_IconInformation);
  else
    MessageBox(GetFocus, PChar(rsGameOver0), PChar(rsReversi),
      mb_OK or mb_IconInformation);
  end;
end;

procedure TReversiForm.SaveAsTextClick(Sender: TObject);
begin
  if SaveDialog1.Execute then
    MovesList.Items.SaveToFile(SaveDialog1.Filename)
end;

procedure TReversiForm.PopupMenu1Popup(Sender: TObject);
begin
  SaveAsText1.Visible := MovesList.Items.Count <> 0;
end;

procedure TReversiForm.OptionsClick(Sender: TObject);
var
  SettingsForm: TSettingsForm;
begin
  SettingsForm := TSettingsForm.Create(self);
  try
    SettingsForm.Settings := Reversi1.Settings;
    SettingsForm.SoundOn := opt_soundon;
    SettingsForm.ShowModal;
    if SettingsForm.ModalResult = mrOK then
    begin
      Reversi1.Settings := SettingsForm.Settings;
      opt_soundon := SettingsForm.SoundOn;
    end;
  finally
    SettingsForm.Free;
  end;
end;

procedure TReversiForm.LoadRegSettings;
begin
  if not rv_LoadSettingFromFile(ChangeFileExt(ParamStr(0), '.ini')) then
    Exit;

  Reversi1.Settings.Depth := opt_reversi_depth;
  Reversi1.Settings.Difficulty := opt_reversi_difficulty;
  Reversi1.Settings.Player1Color := opt_reversi_player1color;
  Reversi1.Settings.Player2Color := opt_reversi_player2color;
  Reversi1.Settings.BoardColor := opt_reversi_boardcolor;
  Reversi1.Settings.LineColor := opt_reversi_linecolor;
  Reversi1.Settings.PlayMode := TReversiPlayMode(opt_reversi_playmode);

  FileMenuHistory1.AddPath(bigstringtostring(@opt_filemenuhistory10));
  FileMenuHistory1.AddPath(bigstringtostring(@opt_filemenuhistory9));
  FileMenuHistory1.AddPath(bigstringtostring(@opt_filemenuhistory8));
  FileMenuHistory1.AddPath(bigstringtostring(@opt_filemenuhistory7));
  FileMenuHistory1.AddPath(bigstringtostring(@opt_filemenuhistory6));
  FileMenuHistory1.AddPath(bigstringtostring(@opt_filemenuhistory5));
  FileMenuHistory1.AddPath(bigstringtostring(@opt_filemenuhistory4));
  FileMenuHistory1.AddPath(bigstringtostring(@opt_filemenuhistory3));
  FileMenuHistory1.AddPath(bigstringtostring(@opt_filemenuhistory2));
  FileMenuHistory1.AddPath(bigstringtostring(@opt_filemenuhistory1));

  FileMenuHistory1.RefreshMenuItems;
end;

procedure TReversiForm.SaveRegSettings;
begin
  opt_reversi_depth := Reversi1.Settings.Depth;
  opt_reversi_difficulty := Reversi1.Settings.Difficulty;
  opt_reversi_player1color := Reversi1.Settings.Player1Color;
  opt_reversi_player2color := Reversi1.Settings.Player2Color;
  opt_reversi_boardcolor := Reversi1.Settings.BoardColor;
  opt_reversi_linecolor := Reversi1.Settings.LineColor;
  opt_reversi_playmode := Ord(Reversi1.Settings.PlayMode);

  stringtobigstring(FileMenuHistory1.PathStringIdx(0), @opt_filemenuhistory1);
  stringtobigstring(FileMenuHistory1.PathStringIdx(1), @opt_filemenuhistory2);
  stringtobigstring(FileMenuHistory1.PathStringIdx(2), @opt_filemenuhistory3);
  stringtobigstring(FileMenuHistory1.PathStringIdx(3), @opt_filemenuhistory4);
  stringtobigstring(FileMenuHistory1.PathStringIdx(4), @opt_filemenuhistory5);
  stringtobigstring(FileMenuHistory1.PathStringIdx(5), @opt_filemenuhistory6);
  stringtobigstring(FileMenuHistory1.PathStringIdx(6), @opt_filemenuhistory7);
  stringtobigstring(FileMenuHistory1.PathStringIdx(7), @opt_filemenuhistory8);
  stringtobigstring(FileMenuHistory1.PathStringIdx(8), @opt_filemenuhistory9);
  stringtobigstring(FileMenuHistory1.PathStringIdx(9), @opt_filemenuhistory10);

  rv_SaveSettingsToFile(ChangeFileExt(ParamStr(0), '.ini'));
end;

procedure TReversiForm.FormDestroy(Sender: TObject);
begin
  SaveRegSettings;
  Reversi1.Free;
  ReversiPanel1.Free;
  Crt1.Free;
  Crt2.Free;
  FileMenuHistory1.Free;
  New2.Free;
end;

procedure TReversiForm.NewCorner1Click(Sender: TObject);
begin
  Reversi1.LoadFromResource(rsCorner);
end;

procedure TReversiForm.NewCross1Click(Sender: TObject);
begin
  Reversi1.LoadFromResource(rsCross);
end;

procedure TReversiForm.NewScew1Click(Sender: TObject);
begin
  Reversi1.LoadFromResource(rsScrew);
end;

procedure TReversiForm.NewCircle1Click(Sender: TObject);
begin
  Reversi1.LoadFromResource(rsCircle);
end;

procedure TReversiForm.AutoPlay1Click(Sender: TObject);
begin
  Menu := MainMenu3;
  if Reversi1.GameOver then
    MovesList.Items.Clear;
  Reversi1.CMAutoPlay(100);
end;

procedure TReversiForm.Stop1Click(Sender: TObject);
begin
  Reversi1.CMStop;
  Menu := MainMenu1;
end;

procedure TReversiForm.PopupMenu2Popup(Sender: TObject);
begin
  PresetBegginer1.Checked := (Reversi1.Settings.Depth = 1) and (Reversi1.Settings.Difficulty = 0);
  PresetAdvanced1.Checked := (Reversi1.Settings.Depth = 3) and (Reversi1.Settings.Difficulty = 8);
  PresetExpert1.Checked := (Reversi1.Settings.Depth = 6) and (Reversi1.Settings.Difficulty = 10);
  PresetSuperHuman1.Checked := (Reversi1.Settings.Depth >= 9) and (Reversi1.Settings.Difficulty = 10);
end;

procedure TReversiForm.PresetBegginer1Click(Sender: TObject);
begin
  Reversi1.Settings.Depth := 1;
  Reversi1.Settings.Difficulty := 0;
end;

procedure TReversiForm.PresetAdvanced1Click(Sender: TObject);
begin
  Reversi1.Settings.Depth := 3;
  Reversi1.Settings.Difficulty := 8;
end;

procedure TReversiForm.PresetExpert1Click(Sender: TObject);
begin
  Reversi1.Settings.Depth := 6;
  Reversi1.Settings.Difficulty := 10;
end;

procedure TReversiForm.PresetSuperHuman1Click(Sender: TObject);
begin
  Reversi1.Settings.Depth := 9;
  Reversi1.Settings.Difficulty := 10;
end;

procedure TReversiForm.FileMenuHistory1Open(Sender: TObject;
  const FileName: string);
begin
  Reversi1.LoadFromFile(FileName);
end;

procedure TReversiForm.Game1Click(Sender: TObject);
begin
  FileMenuHistory1.RefreshMenuItems;
end;

end.
