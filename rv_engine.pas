unit rv_engine;

interface

uses
  Windows, Controls, Classes, Messages, Forms, Dialogs, Graphics,
  Math, SysUtils, ExtCtrls;

resourceString
  rsReversiFileExtention = 'rvs';
  rsResourcePrefix = 'REVERSI';
  rsReversiFileFilter = 'Reversi Files (*.rvs)|*.rvs';
  rsIllegalMove = 'Illegal move';
  rsPlayer1Win = 'Player 1 wins';
  rsPlayer2Win = 'Player 2 wins';
  rsNoPlayerWin = 'TIE';
  rsMustPass = 'You must pass';
  rsPass = 'Pass';
  rsHint = 'Hint';
  rsInvalidSaveGame = 'Invalid Saved Game';

const
  ReversiSignature : array [0..23] of char = 'Reversi saved game'#10#13#26#0#0;

const
  CM_STOP = 101;

  BoardSize      = 100;
  NoPlayer       = 0;
  edge           = 0;
  empty          = 1;
  Player1        = 2;
  Player2        = 3;
  MAXVALUE       = 32767;
  win            = 32000;
  loss           = -win;
  max_depth      = 12;
  max_difficulty = 10;
  PASS           = 20;

  Moves: array[0..60] of integer =
    (11, 18, 81, 88, 13, 31, 16, 61,
     38, 83, 68, 86, 14, 41, 15, 51,
     48, 84, 58, 85, 33, 36, 63, 66,
     34, 35, 43, 46, 53, 56, 64, 65,
     24, 25, 42, 47, 52, 57, 74, 75,
     23, 26, 32, 37, 62, 67, 73, 76,
     12, 17, 21, 28, 71, 78, 82, 87,
     22, 27, 72, 77, 0);

  CV1: array[0..78] of integer =
    ( 99, -8,  8,  6,  6,  8, -8, 99,  0,
       0, -8,-24, -4, -3, -3, -4,-24, -8,  0,
       0,  8, -4,  7,  4,  4,  7, -4,  8,  0,
       0,  6, -3,  4,  0,  0,  4, -3,  6,  0,
       0,  6, -3,  4,  0,  0,  4, -3,  6,  0,
       0,  8, -4,  7,  4,  4,  7, -4,  8,  0,
       0, -8,-24, -4, -3, -3, -4,-24, -8,  0,
       0, 99, -8,  8,  6,  6,  8, -8, 99,  MAXVALUE);

  CV2: array[0..78] of integer =
    ( 99, -8,  8,  6,  6,  8, -8, 99,  0,
       0, -8,-24,  0,  1,  1,  0,-24, -8,  0,
       0,  8,  0,  7,  4,  4,  7,  0,  8,  0,
       0,  6,  1,  4,  1,  1,  4,  1,  6,  0,
       0,  6,  1,  4,  1,  1,  4,  1,  6,  0,
       0,  8,  0,  7,  4,  4,  7,  0,  8,  0,
       0, -8,-24,  0,  1,  1,  1,-24, -8,  0,
       0, 99, -8,  8,  6,  6,  8, -8, 99,  MAXVALUE);

  Direc: array[0..8] of integer = (1, 9, 10, 11, -1, -9, -10, -11, 0);

  FirstMoves: array[0..3] of TPoint = ((X: 4; Y:2), (X: 2; Y:4), (X:3; Y:5), (X:5; Y:3));

//
//  The scoring tables are used to evaluate the board
//  position. The corners of the board change value
//  according to whether a given square is occupied or
//  not. This can be done dynamically, saving ~ 1K
//  worth of data space but costing an as of yet
//  undetermined performance hit.
//

type
  TIntegerArray = array[0..0] of integer;
  PIntegerArray = ^TIntegerArray;

  TReversiPlayMode = (rpmHumanVsComputer, rpmComputerVsHuman, rpmHumanVsHuman);

  TReversiInfo = class(TPersistent)
  public
    Msg: string;
    Score: integer;
    Value: integer;
    constructor Create; virtual;
    procedure Reset;
    procedure Update(AMsg: string; AScore, AValue: integer);
  end;

  TReversiSettings = class(TPersistent)
  private
    fDepth: integer;
    fPlayer1Color,
    fPlayer2Color: TColor;
    fBoardColor: TColor;
    fLineColor: TColor;
    fParent: TCustomControl;
    fDifficulty: byte;
    fPlayMode: TReversiPlayMode;
    procedure SetDepth(Value: integer);
    procedure SetPlayer1Color(Value: TColor);
    procedure SetPlayer2Color(Value: TColor);
    procedure SetBoardColor(Value: TColor);
    procedure SetLineColor(Value: TColor);
    procedure SetDifficulty(Value: byte);
    procedure SetPlayMode(Value: TReversiPlayMode);
  public
    constructor Create(AParent: TCustomControl); virtual;
    procedure Assign(Source: TPersistent); override;
    procedure LoadFromStream(s: TStream);
    procedure SaveToStream(s: TStream);
  published
    property Depth: integer
      read fDepth write SetDepth default 3;
    property Player1Color: TColor
      read fPlayer1Color write SetPlayer1Color default clRed;
    property Player2Color: TColor
      read fPlayer2Color write SetPlayer2Color default clBlue;
    property BoardColor: TColor
      read fBoardColor write SetBoardColor default clBlack;
    property LineColor: TColor
      read fLineColor write SetLineColor default clBtnFace;
    property Difficulty: byte
      read fDifficulty write SetDifficulty default 10;
    property PlayMode: TReversiPlayMode
      read fPlayMode write SetPlayMode default rpmHumanVsComputer;
  end;

  TReversiUpdateEvent =
    procedure(Sender: TObject; Info: TReversiInfo) of object;

  TReversiMoveEvent =
    procedure(Sender: TObject; const mv: string) of object;

  TReversiGameOverEvent =
    procedure(Sender: TObject; Player: byte) of object;

  TReversiBoard = class(TCustomControl)
  private
    fInfo: TReversiInfo;
    fSettings: TReversiSettings;
    fInDesignMode: boolean;
    fFileName: string;
    BestMove: array[0..max_depth + 1] of integer;
    Value,
    Value2: array[0..78] of integer;
    Board: array[0..max_depth + 1, 0..BoardSize - 1] of byte;
    fFirstMove: boolean;
    fThinking: boolean;
    fGameOver: boolean;
    fPass: integer;
    fCheated: boolean;
    fPlayer: byte;
    isAutoPlaying: boolean;

    fOnUpdateInfo: TReversiUpdateEvent;
    fOnMove: TReversiMoveEvent;
    fOnGameOver: TReversiGameOverEvent;

    LastMouseMoveFlash: integer;
  protected
    function FinalScore(var B: array of byte; Friendly, Enemy: byte): integer;
    function LegalCheck(var B: array of byte; mv: integer; Friendly, Enemy: byte): boolean;
    procedure MakeMove(var B: array of byte; mv: integer; Friendly, Enemy: byte);
    function Score(var B: array of byte; Friendly, Enemy: byte): integer;
    function MinMax(mv: integer; Friendly, Enemy: byte; ply: integer;
      vmin, vmax: integer): integer;
    function MinMaxEasy(mv: integer; Friendly, Enemy: byte; ply: integer;
      vmin, vmax: integer): integer;
    function MinMaxHard(mv: integer; Friendly, Enemy: byte; ply: integer;
      vmin, vmax: integer): integer;
    function MinMaxAutoPlay(mv: integer; Friendly, Enemy: byte; ply: integer;
      vmin, vmax: integer): integer;
    procedure MessageScan;
    procedure ClearBoard;
    procedure ClearBoardDesignMode;
    procedure CheckGameOver(mv: integer);
    function PointToMoveB(p: TPoint): integer;
    function PointToMoveS(p: TPoint): integer;
    function MoveToRect(mv: integer): TRect;
    function MoveToStr(mv: integer): string;
    procedure FlashMove(mv: integer);
    procedure Paint; override;

    procedure WMEraseBkgnd(var Msg: TMessage); message wm_EraseBkgnd;
    procedure WMLButtonDown(var Msg: TWMLButtonDown); message wm_LButtonDown;
    procedure WMMouseMove(var Msg: TWMMouseMove); message wm_MouseMove;
    procedure WMLButtonDblClk(var Msg: TWMMouse); message wm_LButtonDblClk;

    procedure DesignModeProc(mv: integer);

    procedure SetSettings(Value: TReversiSettings);
    procedure SetInDesignMode(Value: boolean);
    procedure UpdateInfoValue;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure CreateWnd; override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;

    procedure LoadFromStream(s: TStream);
    procedure SaveToStream(s: TStream);
    procedure LoadFromFile(FileName: TFileName);
    procedure SaveToFile(FileName: TFileName);
    procedure LoadFromResource(rsName: string); overload;
    procedure LoadFromResource(Instance: THandle; rsName: string); overload;
    function  OtherPlayer: integer;

    procedure CMPass;
    procedure CMShowHint;
    procedure CMNewGame;
    function  CMSaveGame: boolean;
    function  CMSaveGameAs: boolean;
    function  CMLoadGame: boolean;
    procedure CMAutoPlay(const sleepmsecs: integer);
    procedure CMStop;

    procedure UpdateInfo;

    property FileName: string
      read fFileName write fFileName;
    property Info: TReversiInfo
      read fInfo write fInfo;
    property Player: byte
      read fPlayer write fPlayer;
    property GameOver: boolean
      read fGameOver;
  published
    property OnUpdateInfo: TReversiUpdateEvent
      read fOnUpdateInfo write fOnUpdateInfo;
    property OnMove: TReversiMoveEvent
      read fOnMove write fOnMove;
    property OnGameOver: TReversiGameOverEvent
      read fOnGameOver write fOnGameOver;
    property InDesignMode: boolean
      read fInDesignMode write SetInDesignMode default False;
    property Align;
    property Constraints;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabStop;
    property Visible;
    property Width default 321;
    property Height default 321;
    property Settings: TReversiSettings
      read fSettings write SetSettings;
  end;

  TReversiPanel = class(TCustomControl)
  private
    FAutoSizeDocking: Boolean;
    FBevel: TPanelBevel;
    FBevelWidth: TBevelWidth;
    FBorderWidth: TBorderWidth;
    FBorderStyle: TBorderStyle;
    FLocked: Boolean;
    fBoard: TReversiBoard;
    procedure CMBorderChanged(var Message: TMessage); message CM_BORDERCHANGED;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure CMCtl3DChanged(var Message: TMessage); message CM_CTL3DCHANGED;
    procedure CMIsToolControl(var Message: TMessage); message CM_ISTOOLCONTROL;
    procedure WMWindowPosChanged(var Message: TWMWindowPosChanged); message WM_WINDOWPOSCHANGED;
    procedure SetBevel(Value: TPanelBevel);
    procedure SetBevelWidth(Value: TBevelWidth);
    procedure SetBorderWidth(Value: TBorderWidth);
    procedure SetBorderStyle(Value: TBorderStyle);
    procedure SetBoard(Value: TReversiBoard);
    procedure CMDockClient(var Message: TCMDockClient); message CM_DOCKCLIENT;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure AdjustClientRect(var Rect: TRect); override;
    function CanAutoSize(var NewWidth, NewHeight: Integer): Boolean; override;
    procedure Paint; override;
    procedure WMEraseBkgnd(var Msg: TMessage); message wm_EraseBkgnd;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
    property DockManager;
  published
    property Align;
    property Anchors;
    property AutoSize;
    property Bevel: TPanelBevel read FBevel write SetBevel default bvRaised;
    property BevelWidth: TBevelWidth read FBevelWidth write SetBevelWidth default 1;
    property BorderWidth: TBorderWidth read FBorderWidth write SetBorderWidth default 10;
    property BiDiMode;
    property BorderStyle: TBorderStyle read FBorderStyle write SetBorderStyle default bsNone;
    property Color default clBtnFace;
    property Constraints;
    property Ctl3D;
    property UseDockManager default True;
    property DockSite;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property Locked: Boolean read FLocked write FLocked default False;
    property ParentBiDiMode;
    property ParentColor default False;
    property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    property Height default 352;
    property Width default 352;
    property OnCanResize;
    property OnClick;
    property OnConstrainedResize;
    property OnContextPopup;
    property OnDockDrop;
    property OnDockOver;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnGetSiteInfo;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
    property OnUnDock;
    property Board: TReversiBoard
      read fBoard write SetBoard;
  end;

implementation

{ --- TReversiInfo --- }
constructor TReversiInfo.Create;
begin
  Inherited;
  Reset;
end;

procedure TReversiInfo.Reset;
begin
  Msg := '';
  Score := 0;
  Value := 0;
end;

procedure TReversiInfo.Update(AMsg: string; AScore, AValue: integer);
begin
  Msg := AMsg;
  Score := AScore;
  Value := AValue;
end;

{ --- TReversiSettings --- }

constructor TReversiSettings.Create(AParent: TCustomControl);
begin
  Inherited Create;
  fParent := AParent;
  fDepth := 3;
  fPlayer1Color := clRed;
  fPlayer2Color := clBlue;
  fBoardColor := clBlack;
  fLineColor := clGray;
  fDifficulty := 5;
end;

procedure TReversiSettings.LoadFromStream(s: TStream);
begin
  s.Read(fDepth, SizeOf(fDepth));
  s.Read(fPlayer2Color, SizeOf(fPlayer2Color));
  s.Read(fPlayer1Color, SizeOf(fPlayer1Color));
  s.Read(fBoardColor, SizeOf(fBoardColor));
  s.Read(fLineColor, SizeOf(fLineColor));
  s.Read(fDifficulty, SizeOf(fDifficulty));
  s.Read(fPlayMode, SizeOf(fPlayMode));
  if Assigned(fParent) then
    InvalidateRect(fParent.Handle, nil, False);
end;

procedure TReversiSettings.SaveToStream(s: TStream);
begin
  s.Write(ReversiSignature, SizeOf(ReversiSignature));
  s.Write(fDepth, SizeOf(fDepth));
  s.Write(fPlayer2Color, SizeOf(fPlayer2Color));
  s.Write(fPlayer1Color, SizeOf(fPlayer1Color));
  s.Write(fBoardColor, SizeOf(fBoardColor));
  s.Write(fLineColor, SizeOf(fLineColor));
  s.Write(fDifficulty, SizeOf(fDifficulty));
  s.Write(fPlayMode, SizeOf(fPlayMode));
end;

procedure TReversiSettings.SetDepth(Value: integer);
begin
  if (Value <> fDepth) then
    if Value in [1..max_depth] then
      fDepth := Value;
end;

procedure TReversiSettings.SetPlayer2Color(Value: TColor);
begin
  if Value <> fPlayer2Color then
  begin
    fPlayer2Color := Value;
    if Assigned(fParent) then
      InvalidateRect(fParent.Handle, nil, False);
  end;
end;

procedure TReversiSettings.SetPlayer1Color(Value: TColor);
begin
  if Value <> fPlayer1Color then
  begin
    fPlayer1Color := Value;
    if Assigned(fParent) then
      InvalidateRect(fParent.Handle, nil, False);
  end;
end;

procedure TReversiSettings.SetBoardColor(Value: TColor);
begin
  if Value <> fBoardColor then
  begin
    fBoardColor := Value;
    if Assigned(fParent) then
      InvalidateRect(fParent.Handle, nil, False);
  end;
end;

procedure TReversiSettings.SetLineColor(Value: TColor);
begin
  if Value <> fLineColor then
  begin
    fLineColor := Value;
    if Assigned(fParent) then
      InvalidateRect(fParent.Handle, nil, False);
  end;
end;

procedure TReversiSettings.SetDifficulty(Value: byte);
begin
  if Value <> fDifficulty then
    if Value in [0..10] then
      fDifficulty := Value;
end;

procedure TReversiSettings.SetPlayMode(Value: TReversiPlayMode);
var
  x: integer;
begin
  x := Ord(value);
  if (x < 0) or (x > 2) then
    Exit;

  if Value <> fPlayMode then
    fPlayMode := Value;
end;

procedure TReversiSettings.Assign(Source: TPersistent);
begin
  if Source is TReversiSettings then
  begin
    Depth := (Source as TReversiSettings).Depth;
    Player2Color := (Source as TReversiSettings).Player2Color;
    Player1Color := (Source as TReversiSettings).Player1Color;
    BoardColor := (Source as TReversiSettings).BoardColor;
    LineColor := (Source as TReversiSettings).LineColor;
    Difficulty := (Source as TReversiSettings).Difficulty;
    PlayMode := (Source as TReversiSettings).PlayMode;
    if Assigned(fParent) then InvalidateRect(fParent.Handle, nil, False);
  end;
end;

{ --- TReversiBoard --- }

constructor TReversiBoard.Create(AOwner: TComponent);
var
  i: integer;
begin
  Inherited;
  randomize;
  isAutoPlaying := False;
  fInDesignMode := False;
  fPlayer := Player1;
  fInfo := TReversiInfo.Create;
  fSettings := TReversiSettings.Create(self);
  fFileName := '';
  for i := 0 to 78 do
  begin
    Value[i] := CV1[i];
    Value2[i] := CV2[i];
  end;
  fFirstMove := True;
  fThinking := False;
  fGameOver := False;
  fPass := PASS;
  fCheated := False;
  LastMouseMoveFlash := 0;
  SetBounds(Left, Top, 321, 321);
end;

destructor TReversiBoard.Destroy;
begin
  fSettings.Free;
  fInfo.Free;
  Inherited;
end;

procedure TReversiBoard.CreateWnd;
begin
  Inherited;
  CMNewGame;
end;

procedure TReversiBoard.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  AWidth := (AWidth SHR 3) SHL 3 + 1;
  AHeight := (AHeight SHR 3) SHL 3 + 1;
  Inherited;
end;

//
//  FUNCTION: FinalScore
//
//  PURPOSE:  Calculate final score
//
function TReversiBoard.FinalScore(var B: array of byte; Friendly, Enemy: byte): integer;
var
  i, count: integer;
begin
  count := 0;
  for i := 11  to 88 do
  begin
    if B[i] = Friendly then
      inc(count)
    else
      if B[i] = Enemy then
        dec(count);
  end;

  if count > 0 then
    Result := win + count
  else
  begin
    if count < 0 then
      Result := loss + count
    else
      Result := 0;
  end;
end;

//
//  FUNCTION: LegalCheck
//
//  PURPOSE:  Return True if move legal, else return False
//
function TReversiBoard.LegalCheck(var B: array of byte; mv: integer;
  Friendly, Enemy: byte): boolean;
var
  sq: integer;
  p: integer;
begin
  if B[mv] = empty then
  begin
    p := 0;
    while Direc[p] <> 0 do
    begin
      sq := mv + Direc[p];
      if B[sq] = Enemy then
      begin
        sq := mv + Direc[p];
        while B[sq] = Enemy do inc(sq, Direc[p]);
        if B[sq] = Friendly then
        begin
          Result := True;
          Exit;
        end;
      end;
      inc(p);
    end
  end;
  Result := False;
end;

//
//  PROCEDURE: MakeMove
//
//  PURPOSE:  Capture enemy pieces
//
procedure TReversiBoard.MakeMove(var B: array of byte; mv: integer;
  Friendly, Enemy: byte);
var
  sq: integer;
  p: integer;
begin
  if mv <> PASS then
  begin
    p := 0;
    while Direc[p] <> 0 do
    begin
      sq := mv + Direc[p];
      if B[sq] = Enemy then
      begin
        inc(sq,Direc[p]);
        while B[sq] = Enemy do inc(sq,Direc[p]);
        if B[sq] = Friendly then
        begin
          dec(sq, Direc[p]);
          while B[sq] = Enemy do
          begin
            B[sq] := Friendly;
            dec(sq, Direc[p]);
          end
        end;
      end;
      inc(p);
    end;
    B[mv] := Friendly;
  end;
end;

//
//  FUNCTION: score()
//
//  PURPOSE:  Calculate the value of board
//
function TReversiBoard.Score(var B: array of byte; Friendly, Enemy: byte): integer;
var
  i, ecount: integer;
  pValue: PIntegerArray;
begin
  if ((B[11] <> empty) or (B[18] <> empty) or
      (B[81] <> empty) or (B[88] <> empty)) then
  begin
    pValue := @Value2;
    if B[11] = empty then
    begin
      Value2[12-11] := -8;
      Value2[21-11] := -8;
      Value2[22-11] := -24;
    end
    else
    begin
      Value2[12-11] := 12;
      Value2[21-11] := 12;
      Value2[22-11] := 8;
    end;

    if B[18] = empty then
    begin
      Value2[17-11] := -8;
      Value2[28-11] := -8;
      Value2[27-11] := -24;
    end
    else
    begin
      Value2[17-11] := 12;
      Value2[28-11] := 12;
      Value2[27-11] := 8;
    end;

    if B[81] = empty then
    begin
      Value2[82-11] := -8;
      Value2[71-11] := -8;
      Value2[72-11] := -24;
    end
    else
    begin
      Value2[82-11] := 12;
      Value2[71-11] := 12;
      Value2[72-11] := 8;
    end;

    if B[88] = empty then
    begin
      Value2[87-11] := -8;
      Value2[78-11] := -8;
      Value2[77-11] := -24;
    end
    else
    begin
      Value2[87-11] := 12;
      Value2[78-11] := 12;
      Value2[77-11] := 8;
    end;
  end
  else
    pValue := @Value;

  ecount := 0;
  Result := 0;
  for i := 0 to 78 do
  begin
    if B[11 + i] = friendly then
      inc(Result, pValue[i])
    else if B[11 + i] = enemy then
    begin
      dec(Result, pValue[i]);
      inc(ecount);
    end;
  end;

  if ecount = 0 then    // any enemy pieces on the board?
    Result := win;      // if not, we just won!
  if friendly = Player1 then
    fInfo.Score := Result
  else
    fInfo.Score := -Result;
end;

//
//  FUNCTION: minmax()
//
//  PURPOSE:  Play Player1 move then recursively play Player2 move
//
function TReversiBoard.MinMax(mv: integer; Friendly, Enemy: byte; ply: integer;
  vmin, vmax: integer): integer;
begin
  if fSettings.Difficulty < max_difficulty then
    Result := MinMaxEasy(mv, Friendly, Enemy, ply, vmin, vmax)
  else
    Result := MinMaxHard(mv, Friendly, Enemy, ply, vmin, vmax)
end;

function TReversiBoard.MinMaxEasy(mv: integer;
  Friendly, Enemy: byte; ply: integer; vmin, vmax: integer): integer;
var
  i: integer;
  value, cur_move: integer;
begin
  for i := 11 to 88 do
    Board[ply + 1][i] := Board[ply][i];

  if mv = PASS then
  begin
    if ply = 1{fSettings.Depth} then
    begin
      i := 0;
      while Moves[i] <> 0 do
      begin
        if LegalCheck(Board[ply + 1][0], Moves[i], Enemy, Friendly) then
        begin
          Result := Score(Board[ply + 1][0], Friendly, Enemy);
          Exit;
        end;
        inc(i);
      end;
      Result := FinalScore(Board[ply + 1][0], Friendly, Enemy);
      Exit;
    end;
  end
  else
  begin
    if ply <> 0 then
    begin
      MakeMove(Board[ply + 1][0], mv, Friendly, Enemy);
      if ply = 1 then
      begin
        Result := Score(Board[ply + 1][0], Friendly, Enemy);
        Exit
      end;
    end;
  end;

  cur_move := PASS;
  BestMove[ply] := PASS;
  i := 0;
  while Moves[i] <> 0 do
  begin
    if LegalCheck(Board[ply + 1][0], Moves[i], Enemy, Friendly) then
    begin
      cur_move := Moves[i];
      Value := MinMaxEasy(cur_move, Enemy, Friendly, ply + 1, -vmax, -vmin);
      if max_difficulty <> fSettings.Difficulty then
      begin
        if Value >= vmin - (max_difficulty - fSettings.Difficulty) then
        begin
          if Value < vmin + (max_difficulty - fSettings.Difficulty) then
          begin
            if random >
              (fSettings.Difficulty + fSettings.Depth) /
              (max_difficulty + max_depth) then
              begin
                vmin := Value;
                BestMove[ply] := cur_move;
              end
          end
          else
          begin
            vmin := Value;
            BestMove[ply] := cur_move;
          end;
          if Value >= vmax then
          begin
            Result := -vmin;
            Exit;   // alpha-beta cutoff
          end;
        end
      end
      else
      begin
        if Value >= vmin then
        begin
          // Avoid calculating the same move all the times
          if Value = vmin then
          begin
            if random > 0.5 then
              BestMove[ply] := cur_move
          end
          else
          begin
            vmin := Value;
            BestMove[ply] := cur_move;
          end;
          if Value >= vmax then
          begin
            Result := -vmin;
            Exit;   // alpha-beta cutoff
          end;
        end
      end;
    end;
    inc(i);
  end;

  if cur_move = PASS then
  begin
    if mv = PASS then // two passes in a row mean game is over
    begin
      Result := FinalScore(Board[ply + 1][0], Friendly, Enemy);
      Exit;
    end
    else
    begin
      Value := MinMaxEasy(PASS, Enemy, Friendly, ply + 1, -vmax, -vmin);
      vmin := Max(vmin, Value);
    end;
  end;

  Result := -vmin;
end;

function TReversiBoard.MinMaxHard(mv: integer;
  Friendly, Enemy: byte; ply: integer; vmin, vmax: integer): integer;
var
  i: integer;
  value, cur_move: integer;
begin
  for i := 11 to 88 do Board[ply + 1][i] := Board[ply][i];

  if mv = PASS then
  begin
    if ply = fSettings.Depth then
    begin
      i := 0;
      while Moves[i] <> 0 do
      begin
        if LegalCheck(Board[ply + 1][0], Moves[i], Enemy, Friendly) then
        begin
          Result := Score(Board[ply + 1][0], Friendly, Enemy);
          Exit;
        end;
        inc(i);
      end;
      Result := FinalScore(Board[ply + 1][0], Friendly, Enemy);
      Exit;
    end;
  end
  else
  begin
    if ply <> 0 then
    begin
      MakeMove(Board[ply + 1][0], mv, Friendly, Enemy);
      if ply = fSettings.Depth then
      begin
        Result := Score(Board[ply + 1][0], Friendly, Enemy);
        Exit
      end;
    end;
  end;

  cur_move := PASS;
  BestMove[ply] := PASS;
  i := 0;
  while Moves[i] <> 0 do
  begin
    if LegalCheck(Board[ply + 1][0], Moves[i], Enemy, Friendly) then
    begin
      cur_move := Moves[i];
      Value := MinMaxHard(cur_move, Enemy, Friendly, ply + 1, -vmax, -vmin);
      if Value > vmin then
      begin
        vmin := Value;
        BestMove[ply] := cur_move;
        if Value >= vmax then
        begin
          Result := -vmin;
          Exit;   // alpha-beta cutoff
        end;
      end;
    end;
    inc(i);
  end;

  if cur_move = PASS then
  begin
    if mv = PASS then // two passes in a row mean game is over
    begin
      Result := FinalScore(Board[ply + 1][0], Friendly, Enemy);
      Exit
    end
    else
    begin
      Value := MinMaxHard(PASS, Enemy, Friendly, ply + 1, -vmax, -vmin);
      vmin := Max(vmin, Value);
    end;
  end;

  Result := -vmin;
end;

function TReversiBoard.MinMaxAutoPlay(mv: integer;
  Friendly, Enemy: byte; ply: integer; vmin, vmax: integer): integer;
var
  i: integer;
  value, cur_move: integer;
begin
  for i := 11 to 88 do Board[ply + 1][i] := Board[ply][i];

  if mv = PASS then
  begin
    if ply = fSettings.Depth then
    begin
      i := 0;
      while Moves[i] <> 0 do
      begin
        if LegalCheck(Board[ply + 1][0], Moves[i], Enemy, Friendly) then
        begin
          Result := Score(Board[ply + 1][0], Friendly, Enemy);
          Exit;
        end;
        inc(i);
      end;
      Result := FinalScore(Board[ply + 1][0], Friendly, Enemy);
      Exit;
    end;
  end
  else
  begin
    if ply <> 0 then
    begin
      MakeMove(Board[ply + 1][0], mv, Friendly, Enemy);
      if ply = fSettings.Depth then
      begin
        Result := Score(Board[ply + 1][0], Friendly, Enemy);
        Exit
      end;
    end;
  end;

  cur_move := PASS;
  BestMove[ply] := PASS;
  i := 0;
  while Moves[i] <> 0 do
  begin
    if LegalCheck(Board[ply + 1][0], Moves[i], Enemy, Friendly) then
    begin
      cur_move := Moves[i];
      Value := MinMaxAutoPlay(cur_move, Enemy, Friendly, ply + 1, -vmax, -vmin);
      if Value >= vmin then
      begin
        if Value = vmin then
        begin
          if random > 0.5 then
            BestMove[ply] := cur_move
        end
        else
        begin
          vmin := Value;
          BestMove[ply] := cur_move;
        end;
        if Value >= vmax then
        begin
          Result := -vmin;
          Exit;   // alpha-beta cutoff
        end;
      end;
    end;
    inc(i);
  end;

  if cur_move = PASS then
  begin
    if mv = PASS then         // two passes in a row mean game is over
    begin
      Result := FinalScore(Board[ply + 1][0], Friendly, Enemy);
      Exit
    end
    else
    begin
      Value := MinMaxAutoPlay(PASS, Enemy, Friendly, ply + 1, -vmax, -vmin);
      vmin := Max(vmin, Value);
    end;
  end;

  Result := -vmin;
end;

procedure TReversiBoard.MessageScan;
var
  msg: TMsg;
begin
  if PeekMessage(msg, 0, 0, 0, PM_REMOVE) then
  begin
    if msg.message in [WM_SETCURSOR, WM_PAINT] then
      DispatchMessage(msg)
    else if (msg.message = WM_COMMAND) and (msg.wParam = CM_STOP) then
      isAutoPlaying := False
    else
    begin
      TranslateMessage(msg);
      DispatchMessage(msg);
    end
  end;
end;

//
//  PROCEDURE: ClearBoard
//
//  PURPOSE:  Clear board and set starting pieces
//
procedure TReversiBoard.ClearBoard;
var
  i, j, k: integer;
  p: TPoint;
begin
  for i := 0 to max_depth do
    for j := 0 to BoardSize - 1 do
      Board[i][j] := edge;

  if fSettings.PlayMode = rpmComputerVsHuman then
  begin
    fFirstMove := False;
    // Hardcode the first Computer move.
    p := FirstMoves[random(4)];
    fPlayer := Player1;
    if Assigned(fOnMove) then
      fOnMove(self,MoveToStr(PointToMoveB(p)));
    fPlayer := Player2;
  end;
  for i := 0 to max_depth do
  begin
    for j := 1 to 8 do
      for k := j * 10 + 1 to j * 10 + 8 do
        Board[i][k] := empty;

    Board[i][45] := Player2;
    Board[i][54] := Player2;
    Board[i][44] := Player1;
    Board[i][55] := Player1;
    if fSettings.PlayMode = rpmComputerVsHuman then
    begin
      Board[i][PointToMoveB(p)] := Player1;
      if p.X > p.Y then
        Board[i][PointToMoveB(Point(4, 3))] := Player1
      else if p.X < p.Y then
        Board[i][PointToMoveB(Point(3, 4))] := Player1;
    end;
  end;
end;

procedure TReversiBoard.ClearBoardDesignMode;
var
  i, j: integer;
begin
  for i := 0 to max_depth do
    for j := 0 to BoardSize - 1 do
      Board[i][j] := edge;

  for i := 1 to 8 do
    for j := i * 10 + 1 to i * 10 + 8 do
      Board[0][j] := empty;

  Board[0][45] := Player2;
  Board[0][54] := Player2;
  Board[0][44] := Player1;
  Board[0][55] := Player1;
end;

function TReversiBoard.OtherPlayer: integer;
begin
  if fPlayer = Player1 then
    Result := Player2
  else
    Result := Player1;
end;

// Create Board Coordinates to move
function TReversiBoard.PointToMoveB(p: TPoint): integer;
begin
  Result := p.X * 10 + p.Y + 11;
end;

// Create Mouse Coordinates to move
function TReversiBoard.PointToMoveS(p: TPoint): integer;
begin
  Result := (p.X div (Width div 8)) * 10 + (p.Y div (Height div 8)) + 11
end;

function TReversiBoard.MoveToRect(mv: integer): TRect;
begin
  Result.Left := (Width div 8) * ((mv - 11) div 10);
  Result.Top := (Height div 8) * ((mv - 11) mod 10);
  Result.Right := Result.Left + (Width div 8);
  Result.Bottom := Result.Top + (Height div 8);
end;

function TReversiBoard.MoveToStr(mv: integer): string;
begin
  Result := Chr(((mv - 11) div 10) + Ord('A')) + IntToStr(8 - (mv - 11) mod 10);
end;

procedure TReversiBoard.DesignModeProc(mv: integer);
var
  i: integer;
begin
  for i := 0 to max_depth do
    case Board[i][mv] of
      Player1: Board[i][mv] := Player2;
      Player2: Board[i][mv] := Empty;
    else
      Board[i][mv] := Player1;
    end;
  InvalidateRect(Handle, nil, False);
end;

procedure TReversiBoard.WMEraseBkgnd(var Msg: TMessage);
begin
  Msg.Result := 1;
end;

procedure TReversiBoard.WMLButtonDown(var Msg: TWMLButtonDown);
var
  mv: integer;
begin
  if not isAutoPlaying then
  begin
    mv := PointToMoveS(Point(Msg.XPos, Msg.YPos));
    if fInDesignMode then
      DesignModeProc(mv)
    else if LegalCheck(Board[0], mv, fPlayer, OtherPlayer) then
    begin
      MakeMove(Board[0], mv, fPlayer, OtherPlayer);
      if Assigned(fOnMove) then
        fOnMove(self,MoveToStr(mv));
      fFirstMove := False;
      fPlayer := OtherPlayer;

      InvalidateRect(Handle, nil, False);
      UpdateWindow(Handle);

      if fSettings.PlayMode <> rpmHumanVsHuman then
      begin
        fThinking := True;
        Cursor := crHourGlass;

        MinMax(mv, OtherPlayer, fPlayer, 0, -MAXVALUE, MAXVALUE);
        MakeMove(Board[0], BestMove[0], fPlayer, OtherPlayer);
        if Assigned(fOnMove) then fOnMove(self,MoveToStr(BestMove[0]));
        fPlayer := OtherPlayer;

        InvalidateRect(Handle, nil, False);
        UpdateWindow(Handle);

        Cursor := crDefault;
        fThinking := False;
        CheckGameOver(BestMove[0]);
      end
      else
        CheckGameOver(mv);
    end
    else
      fInfo.Msg := rsIllegalMove;
    UpdateInfo;
  end;
  Inherited;
end;

procedure TReversiBoard.WMLButtonDblClk(var Msg: TWMMouse);
begin
  if fInDesignMode then
    DesignModeProc(PointToMoveS(Point(Msg.XPos, Msg.YPos)));
  Inherited;
end;

procedure TReversiBoard.CheckGameOver(mv: integer);
var
  i: integer;
  cc, hc, reply2: integer;
begin
  fPass := PASS;
  reply2 := PASS;
  i := 0;

  while Moves[i] <> 0 do
  begin
    if LegalCheck(Board[0], Moves[i], fPlayer, OtherPlayer) then
      fPass := Moves[i]
    else if LegalCheck(Board[0], Moves[i], OtherPlayer, fPlayer) then
      reply2 := Moves[i];
    inc(i);
  end;

  if fPass = PASS then
  begin
    if (mv = PASS) or (reply2 = PASS) then
    begin
      hc := 0;
      cc := 0;
      for i := 11 to 88 do
      begin
        if Board[0][i] = Player1 then
          inc(hc)
        else if Board[0][i] = Player2 then
          inc(cc);
      end;
      if hc > cc then
      begin
        fInfo.Msg := rsPlayer1Win;
        UpdateInfo;
        if Assigned(fOnGameOver) then
          fOnGameOver(self,Player1);
      end
      else if hc < cc then
      begin
        fInfo.Msg := rsPlayer2Win;
        UpdateInfo;
        if Assigned(fOnGameOver) then
          fOnGameOver(self,Player2);
      end
      else
      begin
        fInfo.Msg := rsNoPlayerWin;
        UpdateInfo;
        if Assigned(fOnGameOver) then
          fOnGameOver(self,NoPlayer);
      end;
      fGameOver := True;
    end
    else
      fInfo.Msg := rsMustPass
  end
  else
    if mv = PASS then
      fInfo.Msg := rsPass
end;

procedure TReversiBoard.WMMouseMove(var Msg: TWMMouseMove);
var
  mv: integer;
begin
  if not fInDesignMode then
  begin
    if isAutoPlaying then
      Cursor := crHourGlass
    else
    begin
      mv := PointToMoveS(Point(Msg.XPos, Msg.YPos));

      if LegalCheck(Board[0], mv, fPlayer, OtherPlayer) then
      begin
        Cursor := crCross;
        if mv <> LastMouseMoveFlash then
        begin
          FlashMove(mv);
          LastMouseMoveFlash := mv;
        end;
      end
      else
      begin
        LastMouseMoveFlash := 0;
        Cursor := crDefault;
      end;
    end;
  end;
  Inherited;
end;

procedure TReversiBoard.FlashMove(mv: integer);
var
  r: TRect;
begin
  r := MoveToRect(mv);
  InvertRect(Canvas.Handle, r);
  Sleep(200);
  InvertRect(Canvas.Handle, r);
end;

procedure TReversiBoard.Paint;
var
  i, j: integer;
  Cache: TBitmap;
begin
  if csDesigning in ComponentState then
    ClearBoardDesignMode;
  Cache := TBitmap.Create;
  Cache.Width := Width;
  Cache.Height := Height;
  Cache.Canvas.Brush.Color := fSettings.BoardColor;
  Cache.Canvas.Pen.Color := fSettings.LineColor;
  Cache.Canvas.FillRect(Canvas.ClipRect);
  for i := 0 to 8 do
  begin
    Cache.Canvas.MoveTo(i * (Width div 8), 0);
    Cache.Canvas.LineTo(i * (Width div 8), Height);
    Cache.Canvas.MoveTo(0, i * (Height div 8));
    Cache.Canvas.LineTo(Width, i * (Height div 8));
  end;

  for i := 1 to 8 do
    for j := 1 to 8 do
      if Board[0][i * 10 + j]  in [Player1, Player2] then
      begin
        if Board[0][i * 10 + j] = Player2 then
          Cache.Canvas.Brush.Color := fSettings.Player2Color
        else
          Cache.Canvas.Brush.Color := fSettings.Player1Color;
        Cache.Canvas.Ellipse((i - 1) * (Width div 8) + 2, (j - 1) * (Height div 8) + 2,
                              i * (Width div 8) - 2, j * (Height div 8) - 2);
      end;

  Canvas.CopyRect(Canvas.ClipRect, Cache.Canvas, Canvas.ClipRect);
  Cache.Free;
end;

procedure TReversiBoard.SetSettings(Value: TReversiSettings);
begin
  fSettings.Assign(Value);
end;

procedure TReversiBoard.SetInDesignMode(Value: boolean);
begin
  if Value <> fInDesignMode then
  begin
    fInDesignMode := Value;
    if Value then
      Cursor := crDefault
    else
      LastMouseMoveFlash := 0;
  end;
end;

procedure TReversiBoard.CMPass;
begin
  if fSettings.PlayMode <> rpmHumanVsHuman then
  begin
    fThinking := True;
    Cursor := crHourGlass;
    MinMax(PASS, fPlayer, OtherPlayer, 0, -MAXVALUE, MAXVALUE);
    MakeMove(Board[0], BestMove[0], OtherPlayer, fPlayer);
    InvalidateRect(Handle, nil, False);
    UpdateWindow(Handle);
    CheckGameOver(BestMove[0]);
    Cursor := crDefault;
    fThinking := False;
  end
  else
    fPlayer := OtherPlayer;
end;

procedure TReversiBoard.CMShowHint;
var
  p: TPoint;
  bDone: boolean;
  i: integer;
begin
  if (fPass = PASS) and not fFirstMove then
    Exit;

  if not fCheated then
    fInfo.Msg := rsHint
  else
    fCheated := True;
  Cursor := crHourGlass;
  fThinking := True;

  if fFirstMove then
    p := FirstMoves[random(4)] // HACK: Hardcode the first move hint.
  else
  begin
    if fSettings.Depth = 1 then
    begin
      bDone := False;
      i := 0;
      while not bDone do
      begin
        if LegalCheck(Board[0], Moves[i], fPlayer, OtherPlayer) then
          bDone := True
        else
          inc(i);
      end;
      p.X := (Moves[i] - 11) div 10;
      p.Y := (Moves[i] - 11) mod 10;
    end
    else
    begin
      MinMaxHard(BestMove[0], OtherPlayer, fPlayer, 1, -MAXVALUE, MAXVALUE);
      p.X := (BestMove[1] - 11) div 10;
      p.Y := (BestMove[1] - 11) mod 10;
    end;
  end;

  p.X := round((p.X + 0.5) * (Width / 8));
  p.Y := round((p.Y + 0.5) * (Height / 8));
  i := PointToMoveS(p);
  Windows.ClientToScreen(Handle, p);
  SetCursorPos(p.X, p.Y);
  Cursor := crCross;
  FlashMove(i);
  fThinking := False;
end;

procedure TReversiBoard.UpdateInfoValue;
var
  i: integer;
begin
  info.Value := 0;
  for i := 0 to 78 do
  begin
    if Board[0][11 + i] = Player1 then
      inc(info.Value)
    else if Board[0][11 + i] = Player2 then
      dec(info.Value);
  end;
end;

procedure TReversiBoard.UpdateInfo;
begin
  if Assigned(fOnUpdateInfo) then
  begin
    UpdateInfoValue;
    fOnUpdateInfo(self, fInfo);
  end;
end;

procedure TReversiBoard.LoadFromStream(s: TStream);
var
  Test: array [0..SizeOf(ReversiSignature)] of char;
begin
  s.Read(Test, SizeOf(ReversiSignature));
  if StrLComp(ReversiSignature, Test, SizeOf(ReversiSignature)) = 0 then
  begin
    fSettings.LoadFromStream(s);
    s.Read(fPlayer, SizeOf(fPlayer));
    s.Read(Board, SizeOf(Board));
    fFirstMove := False;
    fCheated := False;
    fGameOver := False;
    fPass := PASS;
    fInfo.Update('',0,0);
    UpdateInfo;
    InvalidateRect(Handle, nil, False);
  end
  else
  begin
    fInfo.Msg := rsInvalidSaveGame;
    UpdateInfo;
  end;
end;

procedure TReversiBoard.LoadFromFile(FileName: TFileName);
var
  f: TFileStream;
begin
  f := TFileStream.Create(FileName, fmOpenRead);
  try
    LoadFromStream(f);
  finally
    f.Free;
  end;
end;

procedure TReversiBoard.SaveToFile(FileName: TFileName);
var
  f: TFileStream;
begin
  f := TFileStream.Create(FileName, fmCreate or fmOpenReadWrite);
  try
    SaveToStream(f);
  finally
    f.Free;
  end;
end;

procedure TReversiBoard.LoadFromResource(rsName: string);
begin
  LoadFromResource(HInstance, rsName);
end;

procedure TReversiBoard.LoadFromResource(Instance: THandle; rsName: string);
var
  r: TResourceStream;
  SaveSettings: TReversiSettings;
begin
  r := TResourceStream.Create(Instance, rsName, PChar(rsResourcePrefix));
  SaveSettings := TReversiSettings.Create(self);
  try
    LockWindowUpdate(Handle);
    SaveSettings.Assign(fSettings);
    LoadFromStream(r);
    fSettings.Assign(SaveSettings);
    LockWindowUpdate(0);
  finally
    InvalidateRect(Handle, nil, False);
    SaveSettings.Free;
    r.Free;
  end;
end;

procedure TReversiBoard.SaveToStream(s: TStream);
begin
  fSettings.SaveToStream(s);
  s.Write(fPlayer, SizeOf(fPlayer));
  s.Write(Board, SizeOf(Board));
end;

procedure TReversiBoard.CMNewGame;
begin
  fFirstMove := True;
  fCheated := False;
  fGameOver := False;
  fPass := PASS;
  FileName := '';
  if fSettings.PlayMode = rpmComputerVsHuman then
    fPlayer := Player2
  else
    fPlayer := Player1;
  ClearBoard;
  fInfo.Update('',0,0);
  UpdateInfo;
  InvalidateRect(Handle, nil, False);
end;

function TReversiBoard.CMSaveGame: boolean;
var
  f: TFileStream;
begin
  if fFileName = '' then
    Result := CMSaveGameAs
  else
  begin
    f := TFileStream.Create(fFilename, fmCreate);
    try
      try
        SaveToStream(f);
        Result := True;
      except
        Result := False;
      end;
    finally
      f.Free;
    end;
  end;
end;

function TReversiBoard.CMSaveGameAs: boolean;
var
  SaveDialog1: TSaveDialog;
begin
  Result := False;
  SaveDialog1 := TSaveDialog.Create(nil);
  try
    SaveDialog1.Filter := rsReversiFileFilter;
    SaveDialog1.DefaultExt := rsReversiFileExtention;
    SaveDialog1.Options := SaveDialog1.Options + [ofPathMustExist, ofOverwritePrompt];
    if SaveDialog1.Execute then
    begin
      fFileName := SaveDialog1.FileName;
      Result := CMSaveGame;
    end;
  finally
    SaveDialog1.Free;
  end;
end;

function TReversiBoard.CMLoadGame: boolean;
var
  OpenDialog1: TOpenDialog;
  f: TFileStream;
begin
  Result := False;
  OpenDialog1 := TOpenDialog.Create(nil);
  try
    OpenDialog1.Filter := rsReversiFileFilter;
    OpenDialog1.DefaultExt := rsReversiFileExtention;
    OpenDialog1.Options := OpenDialog1.Options + [ofFileMustExist, ofPathMustExist];
    if OpenDialog1.Execute then
    begin
      f := TFileStream.Create(OpenDialog1.Filename, fmOpenRead);
      try
        LoadFromStream(f);
        Filename := OpenDialog1.FileName;
        Result := True;
      finally
        f.Free;
      end;
    end;
  finally
    OpenDialog1.Free;
  end;
end;

procedure TReversiBoard.CMAutoPlay(const sleepmsecs: integer);
var
  pm: TReversiPlayMode;
begin
  fThinking := True;
  pm := fSettings.PlayMode;
  fSettings.PlayMode := rpmHumanVsComputer;

  if fGameOver then
    CMNewGame;

  isAutoPlaying := True;
  repeat
    Cursor := crHourGlass;
    MinMaxAutoPlay(BestMove[0], OtherPlayer, fPlayer, 0, -MAXVALUE, MAXVALUE);
    MakeMove(Board[0], BestMove[0], fPlayer, OtherPlayer);
    if Assigned(fOnMove) then
      fOnMove(self,MoveToStr(BestMove[0]));
    fPlayer := OtherPlayer;

    InvalidateRect(Handle, nil, False);
    UpdateWindow(Handle);

    MessageScan;
    Sleep(sleepmsecs);
    CheckGameOver(BestMove[0]);
    UpdateInfo;
  until fGameOver or (not isAutoPlaying);
  isAutoPlaying := False;

  fSettings.PlayMode := pm;
  Cursor := crDefault;
  fThinking := False;
end;

procedure TReversiBoard.CMStop;
begin
  PostMessage(Handle, WM_COMMAND, CM_STOP, 0);
end;

{ --- TReversiPanel --- }

constructor TReversiPanel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fBoard := nil;
  ControlStyle := [csAcceptsControls, csCaptureMouse, csClickEvents,
    csSetCaption, csOpaque, csDoubleClicks, csReplicatable];
  Width := 352;
  Height := 352;
  FBevel := bvRaised;
  FBevelWidth := 1;
  FBorderStyle := bsNone;
  Color := clBtnFace;
  UseDockManager := True;
  FBorderWidth := 10;
  Font.Size := 10;
  Font.Style := [fsBold];
end;

procedure TReversiPanel.CreateParams(var Params: TCreateParams);
const
  BorderStyles: array[TBorderStyle] of DWORD = (0, WS_BORDER);
begin
  inherited CreateParams(Params);
  with Params do
  begin
    Style := Style or BorderStyles[FBorderStyle];
    if NewStyleControls and Ctl3D and (FBorderStyle = bsSingle) then
    begin
      Style := Style and not WS_BORDER;
      ExStyle := ExStyle or WS_EX_CLIENTEDGE;
    end;
    WindowClass.style := WindowClass.style and not (CS_HREDRAW or CS_VREDRAW);
  end;
end;

procedure TReversiPanel.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  Inherited;
  if Assigned(fBoard) then
    if fBoard.Parent = self then
      fBoard.Align := alClient;
end;

procedure TReversiPanel.CMBorderChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TReversiPanel.CMTextChanged(var Message: TMessage);
begin
  Invalidate;
end;

procedure TReversiPanel.CMCtl3DChanged(var Message: TMessage);
begin
  if NewStyleControls and (FBorderStyle = bsSingle) then
    RecreateWnd;
  inherited;
end;

procedure TReversiPanel.CMIsToolControl(var Message: TMessage);
begin
  if not FLocked then
    Message.Result := 1;
end;

procedure TReversiPanel.WMWindowPosChanged(var Message: TWMWindowPosChanged);
begin
  Inherited;
  Invalidate;
end;

procedure TReversiPanel.WMEraseBkgnd(var Msg: TMessage);
begin
  Msg.Result := 1;
end;

procedure TReversiPanel.Paint;
var
  Rect: TRect;
  TopColor, BottomColor: TColor;
  Flags: Longint;
  i: integer;
  c: char;
  Step: TPoint;

  procedure AdjustColors(BV: TPanelBevel);
  begin
    if BV = bvLowered then
    begin
      TopColor := clBtnShadow;
      BottomColor := clBtnHighlight;
    end
    else
    begin
      TopColor := clBtnHighlight;
      BottomColor := clBtnShadow;
    end;
  end;

begin
  Rect := GetClientRect;
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := Color;
  Canvas.FillRect(Rect);
  if FBevel <> bvNone then
  begin
    AdjustColors(FBevel);
    Frame3D(Canvas, Rect, TopColor, BottomColor, BevelWidth);
  end;
  SetRect(Rect, Rect.Left + 2 * BorderWidth - 1, Rect.Top + BorderWidth - 1,
                Rect.Right - BorderWidth + 1, Rect.Bottom - 2 * BorderWidth + 1);
  AdjustColors(bvLowered);
  Frame3D(Canvas, Rect, TopColor, BottomColor, 1);
  Canvas.Brush.Style := bsClear;
  Canvas.Font := Font;
  Flags := DT_EXPANDTABS or DT_VCENTER or DT_CENTER;
  Flags := DrawTextBiDiModeFlags(Flags);
  Step.X := (Width - 3 * BorderWidth - 2) div 8;
  Step.Y := (Height - 3 * BorderWidth - 2) div 8;
  for i := 1 to 8 do
  begin
    SetRect(Rect, 1,
                  2 * BorderWidth + (8 - i) * (Height - 3 * BorderWidth) div 8,
                  2 * BorderWidth,
                  2 * BorderWidth + (9 - i) * (Height - 3 * BorderWidth) div 8);
    DrawText(Canvas.Handle, PChar(IntToStr(i)), -1, Rect, Flags);
  end;
  for c := 'A' to 'H' do
  begin
    SetRect(Rect, 2 * BorderWidth + (Ord(c) - Ord('A')) * (Width - 3 * BorderWidth) div 8,
                  Height - 2 * BorderWidth,
                  2 * BorderWidth + (Ord(c) - Ord('A') + 1) * (Width - 3 * BorderWidth) div 8,
                  Height);
    DrawText(Canvas.Handle, PChar(String(c)), -1, Rect, Flags);
  end;
end;

procedure TReversiPanel.SetBevel(Value: TPanelBevel);
begin
  if FBevel <> Value then
  begin
    FBevel := Value;
    Realign;
    Invalidate;
  end;
end;

procedure TReversiPanel.SetBevelWidth(Value: TBevelWidth);
begin
  if FBevelWidth <> Value then
  begin
    FBevelWidth := Value;
    Realign;
    Invalidate;
  end;
end;

procedure TReversiPanel.SetBorderWidth(Value: TBorderWidth);
begin
  if FBorderWidth <> Value then
  begin
    FBorderWidth := Value;
    Realign;
    Invalidate;
  end;
end;

procedure TReversiPanel.SetBorderStyle(Value: TBorderStyle);
begin
  if FBorderStyle <> Value then
  begin
    FBorderStyle := Value;
    RecreateWnd;
  end;
end;

procedure TReversiPanel.SetBoard(Value: TReversiBoard);
begin
  fBoard := Value;
  if Assigned(fBoard) then
    if fBoard.Parent = self then
      fBoard.Align := alClient;
end;

procedure TReversiPanel.AdjustClientRect(var Rect: TRect);
var
  BevelSize: Integer;
begin
  inherited AdjustClientRect(Rect);
  SetRect(Rect, Rect.Left + 2 * BorderWidth, Rect.Top + BorderWidth,
                Rect.Right - BorderWidth, Rect.Bottom - 2 * BorderWidth);
  BevelSize := 0;
  if FBevel <> bvNone then
    Inc(BevelSize, BevelWidth);
  InflateRect(Rect, -BevelSize, -BevelSize);
end;

procedure TReversiPanel.CMDockClient(var Message: TCMDockClient);
var
  R: TRect;
  Dim: Integer;
begin
  if AutoSize then
  begin
    FAutoSizeDocking := True;
    try
      R := Message.DockSource.DockRect;
      case Align of
        alLeft:
          if Width = 0 then
            Width := R.Right - R.Left;
        alRight:
          if Width = 0 then
          begin
            Dim := R.Right - R.Left;
            SetBounds(Left - Dim, Top, Dim, Height);
          end;
        alTop:
          if Height = 0 then
            Height := R.Bottom - R.Top;
        alBottom:
          if Height = 0 then
          begin
            Dim := R.Bottom - R.Top;
            SetBounds(Left, Top - Dim, Width, Dim);
          end;
      end;
      inherited;
      Exit;
    finally
      FAutoSizeDocking := False;
    end;
  end;
  inherited;
end;

function TReversiPanel.CanAutoSize(var NewWidth, NewHeight: Integer): Boolean;
begin
  Result := (not FAutoSizeDocking) and inherited CanAutoSize(NewWidth, NewHeight);
end;

end.
