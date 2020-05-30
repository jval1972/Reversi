unit rv_crtconsole;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, stdCtrls;

const
  ScreenSizeXMax = 80;
  ScreenSizeYMax = 25;

type
  ScreenChar = record
    Char: Char;
    Color, BackColor: TColor;
  end;

  TScreenBuffer = Array[1..ScreenSizeXMax, 1..ScreenSizeYMax] of ScreenChar; { Maximum window coordinates }

  TCrtConsole = class(TCustomControl)
  private
    { Private declarations }
    ScreenBuffer: TScreenBuffer;
    CharSize: TPoint;
    CharAscent: integer;
    CaretPos: TPoint;
    KeyCount: integer;               { Count of keys in KeyBuffer }
    KeyBuffer: array[0..ScreenSizeXMax - 1] of Char; { Keyboard type-ahead buffer }
    FTransparent: boolean;
    FFocused: boolean;
    FReading: boolean;
    FScreenSizeX,
    FScreenSizeY: word;
    WindowRect: TRect;
    CurColor, CurBackColor: TColor;
    procedure SetTransparent(Value: boolean);
    procedure SetScreenSizeX(Value: word);
    procedure SetScreenSizeY(Value: word);
  protected
    { Protected declarations }
    procedure ShowCaret;
    procedure HideCaret;
    procedure WMSetFocus(var Msg: TMessage); message WM_SETFOCUS;
    procedure WMKillFocus(var Msg: TMessage); message WM_KILLFOCUS;
    procedure WMChar(var Msg: TWMChar); message WM_CHAR;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    procedure CreateWnd; override;
    procedure Paint; override;
    property IsFocused: boolean read FFocused;
    property Reading: boolean read FReading;
    procedure NewLine;
    procedure Write(const Args: array of const);
    procedure Writeln(const Args: array of const);
    function KeyPressed: Boolean;
    function Readkey: Char;
    procedure Readln(var s: string); overload;
    procedure Readln(var x: integer); overload;
    procedure Readln(var x: word); overload;
    procedure Readln(var x: byte); overload;
    procedure Readln(var x: extended); overload;
    procedure TextColor(c: TColor);
    procedure TextBackGround(c: TColor);
    procedure ClrScr;
    procedure ClrEol;
    procedure GoToXY(T: TPoint); overload;
    procedure GoToXY(X, Y: Integer); overload;
    function WhereX: integer;
    function WhereY: integer;
    procedure DelLine;
    procedure InsLine;
    procedure Window(X1,Y1,X2,Y2: word);
  published
    { Published declarations }
    property Width default 640;
    property Height default 375;
    property Align;
    property Anchors;
    property AutoSize;
    property BiDiMode;
    property Caption;
    property Color default clBlack;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ScreenSizeX: word read FScreenSizeX write SetScreenSizeX default 80;
    property ScreenSizeY: word read FScreenSizeY write SetScreenSizeY default 25;
    property ShowHint;
    property TabStop;
    property Transparent: boolean read FTransparent write SetTransparent default false;
    property Visible;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDock;
    property OnStartDrag;
  end;

implementation

{ We can call this function using an open array constructor (see Open array constructors). For example,
  MakeStr(['test', 100, ' ', True, 3.14159, TForm]) returns the string “test100 True3.14159TForm”. }
function MakeStr(const Args: array of const): string;
const
  BoolChars: array[Boolean] of string = ('False', 'True');
var
  i: integer;
begin
  Result := '';
  for i := 0 to High(Args) do
    with Args[I] do
      case VType of
        vtInteger:    Result := Result + IntToStr(VInteger);
        vtBoolean:    Result := Result + BoolChars[VBoolean];
        vtChar:       Result := Result + VChar;
        vtExtended:   Result := Result + FloatToStr(VExtended^);
        vtString:     Result := Result + VString^;
        vtPChar:      Result := Result + VPChar;
        vtObject:     Result := Result + VObject.ClassName;
        vtClass:      Result := Result + VClass.ClassName;
        vtAnsiString: Result := Result + string(VAnsiString);
        vtCurrency:   Result := Result + CurrToStr(VCurrency^);
        vtVariant:    Result := Result + string(VVariant^);
        vtInt64:      Result := Result + IntToStr(VInt64^);
    end;
end;

constructor TCrtConsole.Create(AOwner: TComponent);
var
  i, j: integer;
begin
  Inherited;
  CaretPos.x := 1;
  CaretPos.y := 1;
  FTRansparent := false;
  FFocused := false;
  FReading := false;
  for i := 1 to ScreenSizeX do
    for j := 1 to ScreenSizeY do
    begin
      ScreenBuffer[i,j].Char := ' ';
      ScreenBuffer[i,j].Color := clSilver;
      ScreenBuffer[i,j].BackColor := clBlack;
    end;
  Color := clBlack;
  Font.Name := 'System';
  Font.Pitch := fpFixed;
  Font.Size := 10;
  Font.Color := clSilver;
  Font.Height := -13;
  Width := 640;
  Height := 375;
  FScreenSizeX := 80;
  FScreenSizeY := 25;
  Window(1, 1, 80, 25);
end;

procedure TCrtConsole.CreateWnd;
var
  Metric: TextMetric;
begin
  Inherited;
  CurColor := Font.Color;
  CurBackColor := Color;
  ClrScr;
  Canvas.Font.Assign(Font);
  GetTextMetrics(Canvas.Handle, Metric);
  CharSize.X := Metric.tmMaxCharWidth;
  CharSize.Y := Metric.tmHeight + Metric.tmExternalLeading;
  CharAscent := Metric.tmAscent;
  Width := CharSize.X * ScreenSizeX;
  Height := CharSize.Y * ScreenSizeY;
end;

procedure TCrtConsole.Paint;
var
  i, j: integer;
begin
  Canvas.Font.Assign(Font);
  for j := 1 to ScreenSizeY do
    for i := 1 to ScreenSizeX do
    begin
      Canvas.Brush.Color := ScreenBuffer[i,j].BackColor;
      Canvas.Font.Color := ScreenBuffer[i,j].Color;
      Canvas.TextOut((i - 1) * CharSize.X, (j - 1) * CharSize.Y, ScreenBuffer[i, j].Char);
    end;
end;

procedure TCrtConsole.SetTransparent(Value: boolean);
begin
  if FTransparent <> Value then
  begin
    FTransparent := Value;
    if Value then
      SetBkMode(Canvas.Handle, Windows.TRANSPARENT)
    else
      SetBkMode(Canvas.Handle, Windows.OPAQUE);
    Invalidate
  end;
end;

procedure TCrtConsole.SetScreenSizeX(Value: word);
begin
  if FScreenSizeX <> Value then
  begin
    if (Value <= ScreenSizeXMax) and (Value <> 0) then
    begin
      FScreenSizeX := Value;
      Window(1, 1, FScreenSizeX, FScreenSizeY);
      Invalidate;
    end
    else
      ShowMessage(MakeStr(['Value must be in [1..', ScreenSizeXMax,']']));
  end
end;

procedure TCrtConsole.SetScreenSizeY(Value: word);
begin
  if FScreenSizeY <> Value then
  begin
    if (Value <= ScreenSizeYMax) and (Value <> 0) then
    begin
      FScreenSizeY := Value;
      Window(1, 1, FScreenSizeX, FScreenSizeY);
      Invalidate;
    end
    else
      ShowMessage(MakeStr(['Value must be in [1..', ScreenSizeYMax,']']));
  end
end;

procedure TCrtConsole.ShowCaret;
begin
  CreateCaret(Handle, 0, CharSize.X, 2);
  SetCaretPos((CaretPos.X - 1) * CharSize.X,(CaretPos.Y - 1) * CharSize.Y + CharAscent);
  Windows.ShowCaret(Handle);
end;

{ Hide caret }

procedure TCrtConsole.HideCaret;
begin
  DestroyCaret;
end;

procedure TCrtConsole.WMSetFocus(var Msg: TMessage);
begin
  FFocused := True;
  if FReading then
    ShowCaret;
end;

procedure TCrtConsole.WMKillFocus(var Msg: TMessage);
begin
  if FReading then
    HideCaret;
  FFocused := False;
end;

procedure TCrtConsole.WMChar(var Msg: TWMChar);
begin
  if KeyCount < SizeOf(KeyBuffer) then
  begin
    KeyBuffer[KeyCount] := Char(Msg.CharCode);
    Inc(KeyCount);
  end;
end;

procedure TCrtConsole.NewLine;
var
  i, j: integer;
begin
  CaretPos.X := 1;
  if CaretPos.Y = ScreenSizeY then
  begin
    for j := 2 to ScreenSizeY do
      for i := 1 to ScreenSizeX do
        ScreenBuffer[i, j - 1] := ScreenBuffer[i, j];
    for i := 1 to ScreenSizeX do
    begin
      ScreenBuffer[i, ScreenSizeY].Char := ' ';
      ScreenBuffer[i, ScreenSizeY].Color := CurColor;
      ScreenBuffer[i, ScreenSizeY].BackColor := CurBackColor;
    end;
  end
  else
    inc(CaretPos.Y);
  Invalidate;
end;

procedure TCrtConsole.Write(const Args: array of const);
var
  s: string;
  i, L, R: integer;
begin
  s := MakeStr(Args);
  L := CaretPos.X;
  R := CaretPos.X;
  for i := 1 to Length(s) do
  begin
    case s[i] of
      #32..#255:
      	begin
      	  ScreenBuffer[CaretPos.X, CaretPos.Y].Char := s[i];
          ScreenBuffer[CaretPos.X, CaretPos.Y].Color := CurColor;
          ScreenBuffer[CaretPos.X, CaretPos.Y].BackColor := CurBackColor;
      	  Inc(CaretPos.X);
      	  if CaretPos.X > R then
            R := CaretPos.X;
      	  if CaretPos.X = ScreenSizeX + 1 then
            NewLine;
      	end;
      #13:
      	NewLine;
      #8:
      	if CaretPos.X > 0 then
      	begin
      	  Dec(CaretPos.X);
      	  ScreenBuffer[CaretPos.X, CaretPos.Y].Char := ' ';
      	  if CaretPos.X < L then
            L := CaretPos.X;
      	end;
      #7:
        MessageBeep(0);
    end;
  end;
  Invalidate;
end;

procedure TCrtConsole.Writeln(const Args: array of const);
begin
  Write(Args);
  NewLine;
end;

function TCrtConsole.KeyPressed: Boolean;
var
  M: TMsg;
begin
  while PeekMessage(M, 0, 0, 0, pm_Remove) do
  begin
    if M.Message = wm_Quit then
    begin
      if FFocused and FReading then
        HideCaret;
      Halt(255);
    end;
    TranslateMessage(M);
    DispatchMessage(M);
  end;
  KeyPressed := KeyCount > 0;
end;

function TCrtConsole.ReadKey: Char;
begin
  if not KeyPressed then
  begin
    FReading := True;
    if FFocused then
      ShowCaret;
    repeat
      WaitMessage
    until KeyPressed;
    if FFocused then
      HideCaret;
    FReading := False;
  end;
  ReadKey := KeyBuffer[0];
  Dec(KeyCount);
  Move(KeyBuffer[1], KeyBuffer[0], KeyCount);
end;

procedure TCrtConsole.Readln(var s: string);
var
  Ch: char;
  i: word;
begin
  i := 0;
  s := '';
  repeat
    Ch := ReadKey;
    case Ch of
      #8:
      	if i > 0 then
      	begin
      	  dec(i);
      	  Write([Ch]);
          if Length(s) > 0 then SetLength(s,Length(s)-1);
      	end;
      #13:
        Write([Ch]);
      #32..#255:
      	begin
      	  s := s + Ch;
      	  inc(i);
      	  Write([Ch]);
      	end;
    end;
  until (Ch = #13) or (Ch = #26);
end;

procedure TCrtConsole.Readln(var x: integer);
var
  s: string;
  Ch: char;
  i: word;
  code: integer;
begin
  i := 0;
  s := '';
  repeat
    Ch := ReadKey;
    case Ch of
      #8:
      	if i > 0 then
      	begin
      	  dec(i);
      	  Write([Ch]);
          if Length(s) > 0 then
            SetLength(s, Length(s) - 1);
      	end;
      #13:
        if Length(s) <> 0 then
          Write([Ch]);
      '0'..'9':
      	begin
      	  s := s + Ch;
      	  inc(i);
      	  Write([Ch]);
      	end;
      '+','-':
      	if Length(s) = 0 then
      	begin
      	  s := s + Ch;
      	  inc(i);
      	  Write([Ch]);
      	end;
    end;
  until (Ch = #13) or (Ch = #26);
  Val(s, x, code);
end;

procedure TCrtConsole.Readln(var x: word);
var
  s: string;
  Ch: char;
  i: word;
  code: integer;
begin
  i := 0;
  s := '';
  repeat
    Ch := ReadKey;
    case Ch of
      #8:
      	if i > 0 then
      	begin
      	  dec(i);
      	  Write([Ch]);
          if Length(s) > 0 then
            SetLength(s,Length(s) - 1);
      	end;
      #13:
        if Length(s) <> 0 then
          Write([Ch]);
      '0'..'9':
      	begin
      	  s := s + Ch;
      	  inc(i);
      	  Write([Ch]);
      	end;
    end;
  until (Ch = #13) or (Ch = #26);
  Val(s, x, code);
end;

procedure TCrtConsole.Readln(var x: byte);
var
  s: string;
  Ch: char;
  i: word;
  code: integer;
begin
  i := 0;
  s := '';
  repeat
    Ch := ReadKey;
    case Ch of
      #8:
      	if i > 0 then
      	begin
      	  dec(i);
      	  Write([Ch]);
          if Length(s) > 0 then
            SetLength(s, Length(s) - 1);
      	end;
      #13:
        if Length(s) <> 0 then
          Write([Ch]);
      '0'..'9':
      	begin
      	  s := s + Ch;
      	  inc(i);
      	  Write([Ch]);
      	end;
    end;
  until (Ch = #13) or (Ch = #26);
  Val(s, x, code);
end;

procedure TCrtConsole.Readln(var x: extended);
var
  s: string;
  Ch: char;
  i: word;
  code: integer;
begin
  i := 0;
  s := '';
  repeat
    Ch := ReadKey;
    case Ch of
      #8:
      	if i > 0 then
      	begin
      	  dec(i);
      	  Write([Ch]);
          if Length(s) > 0 then
            SetLength(s, Length(s) - 1);
      	end;
      #13:
        if Length(s) <> 0 then
          Write([Ch]);
      '0'..'9','.':
      	begin
      	  s := s + Ch;
      	  inc(i);
      	  Write([Ch]);
      	end;
      '+','-':
      	if Length(s) = 0 then
      	begin
      	  s := s + Ch;
      	  inc(i);
      	  Write([Ch]);
      	end;
    end;
  until (Ch = #13) or (Ch = #26);
  Val(s, x, code);
end;

procedure TCrtConsole.TextColor(c: TColor);
begin
  CurColor := c;
end;

procedure TCrtConsole.TextBackGround(c: TColor);
begin
  CurBackColor := c;
end;

procedure TCrtConsole.ClrScr;
var
  i, j: integer;
begin
  for i := 1 to ScreenSizeX do
    for j := 1 to ScreenSizeY do
    begin
      ScreenBuffer[i, j].Char := ' ';
      ScreenBuffer[i, j].Color := CurColor;
      ScreenBuffer[i, j].BackColor := CurBackColor;
    end;
  CaretPos.X := 1;
  CaretPos.Y := 1;
  Font.Color := CurColor;
  Color := CurBackColor;
  Invalidate;
end;

procedure TCrtConsole.ClrEol;
var
  i: integer;
begin
  for i := CaretPos.x to ScreenSizeX do
  begin
    ScreenBuffer[i, CaretPos.y].Char := ' ';
    ScreenBuffer[i, CaretPos.y].Color := CurColor;
    ScreenBuffer[i, CaretPos.y].BackColor := CurBackColor;
  end;
  Invalidate;
end;

procedure TCrtConsole.GoToXY(T: TPoint);
begin
  CaretPos := T;
end;

procedure TCrtConsole.GoToXY(X, Y: Integer);
begin
  CaretPos.X := X;
  CaretPos.Y := Y;
end;

function TCrtConsole.WhereX: integer;
begin
  result := CaretPos.X;
end;

function TCrtConsole.WhereY: integer;
begin
  result := CaretPos.Y;
end;

procedure TCrtConsole.DelLine;
var
  i, j: integer;
begin
  for j := CaretPos.y to ScreenSizeY do
    for i := 1 to ScreenSizeX do
      ScreenBuffer[i, j - 1] := ScreenBuffer[i, j];
  for i := 1 to ScreenSizeX do
  begin
    ScreenBuffer[i, ScreenSizeY].Char := ' ';
    ScreenBuffer[i, ScreenSizeY].Color := CurColor;
    ScreenBuffer[i, ScreenSizeY].BackColor := CurBackColor;
  end;
end;

procedure TCrtConsole.InsLine;
var
  i, j: integer;
begin
  for j := ScreenSizeY - 1 downto CaretPos.y do
    for i := 1 to ScreenSizeX do
      ScreenBuffer[i, j + 1] := ScreenBuffer[i, j];
  for i := 1 to ScreenSizeX do
  begin
    ScreenBuffer[i, CaretPos.y].Char := ' ';
    ScreenBuffer[i, CaretPos.y].Color := CurColor;
    ScreenBuffer[i, CaretPos.y].BackColor := CurBackColor;
  end;
  Invalidate;
end;

procedure TCrtConsole.Window(X1,Y1,X2,Y2: word);
begin
  SetRect(WindowRect, X1, Y1, X2, Y2);
  CaretPos.x := 1;
  CaretPos.y := 1;
end;

end.

