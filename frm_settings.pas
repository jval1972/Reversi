unit frm_settings;

interface

uses
  Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ComCtrls, ExtCtrls, Spin, rv_colorpickerbutton,
  rv_engine, Dialogs, ColorGrd, Menus;

type
  TSettingsForm = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    Panel3: TPanel;
    GroupBox1: TGroupBox;
    TabSheet3: TTabSheet;
    StaticText1: TStaticText;
    SpinEdit1: TSpinEdit;
    TrackBar1: TTrackBar;
    StaticText2: TStaticText;
    StaticText3: TStaticText;
    Panel4: TPanel;
    StaticText4: TStaticText;
    ComboBox1: TComboBox;
    Panel5: TPanel;
    OKBtn: TButton;
    CancelBtn: TButton;
    Panel6: TPanel;
    StaticText6: TStaticText;
    StaticText5: TStaticText;
    Panel7: TPanel;
    GroupBox2: TGroupBox;
    CheckBox1: TCheckBox;
    PaintBox1: TPaintBox;
    ColorDialog1: TColorDialog;
    StaticText7: TStaticText;
    StaticText8: TStaticText;
    Bevel1: TBevel;
    ColorPanel1: TPanel;
    ColorPanel2: TPanel;
    ColorPanel3: TPanel;
    ColorPanel4: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject);
  private
    { Private declarations }
    fSettings: TReversiSettings;
    ColorPickerButton1: TColorPickerButton;
    ColorPickerButton2: TColorPickerButton;
    ColorPickerButton3: TColorPickerButton;
    ColorPickerButton4: TColorPickerButton;
    function GetSettings: TReversiSettings;
    procedure SetSettings(Value: TReversiSettings);
    function GetSoundOn: boolean;
    procedure SetSoundOn(Value: boolean);
    procedure ColorPickerButtonChange(Sender: TObject);
    procedure ColorPickerButtonClick(Sender: TObject);
  public
    { Public declarations }
    property Settings: TReversiSettings
      read GetSettings write SetSettings;
    property SoundOn: boolean
      read GetSoundOn write SetSoundOn;
  end;

implementation

uses
  frm_main;

{$R *.DFM}

procedure TSettingsForm.FormCreate(Sender: TObject);
begin
  PageControl1.ActivePage := TabSheet1;
  fSettings := TReversiSettings.Create(nil);

  ColorPickerButton1 := TColorPickerButton.Create(nil);
  ColorPickerButton1.Parent := ColorPanel1;
  ColorPickerButton1.Align := alClient;
  ColorPickerButton1.OnChange := ColorPickerButtonChange;
  ColorPickerButton1.OnClick := ColorPickerButtonClick;

  ColorPickerButton2 := TColorPickerButton.Create(nil);
  ColorPickerButton2.Parent := ColorPanel2;
  ColorPickerButton2.Align := alClient;
  ColorPickerButton2.OnChange := ColorPickerButtonChange;
  ColorPickerButton2.OnClick := ColorPickerButtonClick;

  ColorPickerButton3 := TColorPickerButton.Create(nil);
  ColorPickerButton3.Parent := ColorPanel3;
  ColorPickerButton3.Align := alClient;
  ColorPickerButton3.OnChange := ColorPickerButtonChange;
  ColorPickerButton3.OnClick := ColorPickerButtonClick;

  ColorPickerButton4 := TColorPickerButton.Create(nil);
  ColorPickerButton4.Parent := ColorPanel4;
  ColorPickerButton4.Align := alClient;
  ColorPickerButton4.OnChange := ColorPickerButtonChange;
  ColorPickerButton4.OnClick := ColorPickerButtonClick;
end;

procedure TSettingsForm.FormDestroy(Sender: TObject);
begin
  fSettings.Free;
  ColorPickerButton1.Free;
  ColorPickerButton2.Free;
  ColorPickerButton3.Free;
  ColorPickerButton4.Free;
end;

function TSettingsForm.GetSettings: TReversiSettings;
begin
  fSettings.Depth := SpinEdit1.Value;
  fSettings.Difficulty := TrackBar1.Position;
  fSettings.Player1Color := ColorPickerButton1.Color;
  fSettings.Player2Color := ColorPickerButton2.Color;
  fSettings.BoardColor := ColorPickerButton3.Color;
  fSettings.LineColor := ColorPickerButton4.Color;
  case ComboBox1.ItemIndex of
    0: fSettings.PlayMode := rpmHumanVsComputer;
    1: fSettings.PlayMode := rpmComputerVsHuman;
    2: fSettings.PlayMode := rpmHumanVsHuman;
  else
  end;
  result := fSettings;
end;

procedure TSettingsForm.SetSettings(Value: TReversiSettings);
begin
  fSettings.Assign(Value);
  SpinEdit1.Value := fSettings.Depth;
  TrackBar1.Position := fSettings.Difficulty;
  ColorPickerButton1.Color := fSettings.Player1Color;
  ColorPickerButton2.Color := fSettings.Player2Color;
  ColorPickerButton3.Color := fSettings.BoardColor;
  ColorPickerButton4.Color := fSettings.LineColor;
  case fSettings.PlayMode of
    rpmHumanVsComputer: ComboBox1.ItemIndex := 0;
    rpmComputerVsHuman: ComboBox1.ItemIndex := 1;
    rpmHumanVsHuman: ComboBox1.ItemIndex := 2;
  else
  end;
end;

function TSettingsForm.GetSoundOn: boolean;
begin
  result := CheckBox1.Checked;
end;

procedure TSettingsForm.SetSoundOn(Value: boolean);
begin
  CheckBox1.Checked := Value;
end;

const
  Board: array[1..4, 1..6] of byte = (
    (empty, empty, empty,   empty,   empty,  empty),
    (empty, empty, Player1, Player2, empty,  empty),
    (empty, empty, Player2, Player1, empty,  empty),
    (empty, empty, empty,   empty,   empty,  empty)
  );

procedure TSettingsForm.PaintBox1Paint(Sender: TObject);
var
  Cache: TBitmap;
  i, j: integer;
begin
  Cache := TBitmap.Create;
  try
    fSettings.Player1Color := ColorPickerButton1.Color;
    fSettings.Player2Color := ColorPickerButton2.Color;
    fSettings.BoardColor := ColorPickerButton3.Color;
    fSettings.LineColor := ColorPickerButton4.Color;
    Cache.Width := PaintBox1.Width;
    Cache.Height := PaintBox1.Height;
    Cache.Canvas.Brush.Color := fSettings.BoardColor;
    Cache.Canvas.Pen.Color := fSettings.LineColor;
    Cache.Canvas.FillRect(PaintBox1.Canvas.ClipRect);
    for i := 0 to 4 do
    begin
      Cache.Canvas.MoveTo(i * (PaintBox1.Width div 4), 0);
      Cache.Canvas.LineTo(i * (PaintBox1.Width div 4), PaintBox1.Height);
    end;
    for j := 0 to 6 do
    begin
      Cache.Canvas.MoveTo(0, j * (PaintBox1.Height div 6));
      Cache.Canvas.LineTo(Width, j * (PaintBox1.Height div 6));
    end;
    {Draw a 4x6 STUB REVERSI BOARD }
    for i := 1 to 4 do
      for j := 1 to 6 do
        if Board[i][j]  in [Player1, Player2] then
        begin
          if Board[i][j] = Player2 then
            Cache.Canvas.Brush.Color := fSettings.Player2Color
          else
            Cache.Canvas.Brush.Color := fSettings.Player1Color;
          Cache.Canvas.Ellipse((i - 1) * (PaintBox1.Width div 4) + 2, (j - 1) * (PaintBox1.Height div 6) + 2,
                                i * (PaintBox1.Width div 4) - 2, j * (PaintBox1.Height div 6) - 2);
      end;

    PaintBox1.Canvas.CopyRect(PaintBox1.Canvas.ClipRect, Cache.Canvas, PaintBox1.Canvas.ClipRect);
  finally
    Cache.Free;
  end;
end;

procedure TSettingsForm.ColorPickerButtonChange(Sender: TObject);
begin
  PaintBox1.Invalidate
end;

procedure TSettingsForm.ColorPickerButtonClick(Sender: TObject);
begin
  ColorDialog1.Color := (Sender as TColorPickerButton).Color;
  if ColorDialog1.Execute then
    (Sender as TColorPickerButton).Color := ColorDialog1.Color;
end;

end.
