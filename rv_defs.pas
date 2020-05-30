unit rv_defs;

interface

uses
  Graphics;

function rv_LoadSettingFromFile(const fn: string): boolean;

procedure rv_SaveSettingsToFile(const fn: string);

const
  MAXHISTORYPATH = 2048;

type
  bigstring_t = array[0..MAXHISTORYPATH - 1] of char;
  bigstring_p = ^bigstring_t;

function bigstringtostring(const bs: bigstring_p): string;

procedure stringtobigstring(const src: string; const bs: bigstring_p);

var
  opt_reversi_depth: integer = 3;
  opt_reversi_difficulty: integer = 10;
  opt_reversi_player1color: LongWord = clRed;
  opt_reversi_player2color: LongWord = clBlue;

  opt_reversi_boardcolor: LongWord = clBlack;
  opt_reversi_linecolor: LongWord = clGray;
  opt_reversi_playmode: integer = 0;
  opt_soundon: boolean = True;

  opt_filemenuhistory1: bigstring_t = '';
  opt_filemenuhistory2: bigstring_t = '';
  opt_filemenuhistory3: bigstring_t = '';
  opt_filemenuhistory4: bigstring_t = '';
  opt_filemenuhistory5: bigstring_t = '';
  opt_filemenuhistory6: bigstring_t = '';
  opt_filemenuhistory7: bigstring_t = '';
  opt_filemenuhistory8: bigstring_t = '';
  opt_filemenuhistory9: bigstring_t = '';
  opt_filemenuhistory10: bigstring_t = '';

implementation

uses
  SysUtils, Classes;

const
  NUMSETTINGS = 21;

type
  TSettingsType = (tstDevider, tstInteger, tstColor, tstBoolean, tstString, tstBigString);

  TSettingItem = record
    desc: string;
    typeof: TSettingsType;
    location: pointer;
  end;

var
  Settings: array[0..NUMSETTINGS - 1] of TSettingItem = (
    (
      desc: '[GAME]';
      typeof: tstDevider;
      location: nil;
    ),
    (
      desc: 'DEPTH';
      typeof: tstInteger;
      location: @opt_reversi_depth;
    ),
    (
      desc: 'DIFFICULTY';
      typeof: tstInteger;
      location: @opt_reversi_difficulty;
    ),
    (
      desc: 'PLAYMODE';
      typeof: tstInteger;
      location: @opt_reversi_playmode;
    ),
    (
      desc: 'SOUND';
      typeof: tstBoolean;
      location: @opt_soundon;
    ),
    (
      desc: '[COLORS]';
      typeof: tstDevider;
      location: nil;
    ),
    (
      desc: 'PLAYER1COLOR';
      typeof: tstColor;
      location: @opt_reversi_player1color;
    ),
    (
      desc: 'PLAYER2COLOR';
      typeof: tstColor;
      location: @opt_reversi_player2color;
    ),
    (
      desc: 'BOARDCOLOR';
      typeof: tstColor;
      location: @opt_reversi_boardcolor;
    ),
    (
      desc: 'LINECOLOR';
      typeof: tstColor;
      location: @opt_reversi_linecolor;
    ),
    (
      desc: '[HISTORY]';
      typeof: tstDevider;
      location: nil;
    ),
    (
      desc: 'FILEMENUHISTORY1';
      typeof: tstBigString;
      location: @opt_filemenuhistory1;
    ),
    (
      desc: 'FILEMENUHISTORY2';
      typeof: tstBigString;
      location: @opt_filemenuhistory2;
    ),
    (
      desc: 'FILEMENUHISTORY3';
      typeof: tstBigString;
      location: @opt_filemenuhistory3;
    ),
    (
      desc: 'FILEMENUHISTORY4';
      typeof: tstBigString;
      location: @opt_filemenuhistory4;
    ),
    (
      desc: 'FILEMENUHISTORY5';
      typeof: tstBigString;
      location: @opt_filemenuhistory5;
    ),
    (
      desc: 'FILEMENUHISTORY6';
      typeof: tstBigString;
      location: @opt_filemenuhistory6;
    ),
    (
      desc: 'FILEMENUHISTORY7';
      typeof: tstBigString;
      location: @opt_filemenuhistory7;
    ),
    (
      desc: 'FILEMENUHISTORY8';
      typeof: tstBigString;
      location: @opt_filemenuhistory8;
    ),
    (
      desc: 'FILEMENUHISTORY9';
      typeof: tstBigString;
      location: @opt_filemenuhistory9;
    ),
    (
      desc: 'FILEMENUHISTORY10';
      typeof: tstBigString;
      location: @opt_filemenuhistory10;
    )
  );


procedure splitstring(const inp: string; var out1, out2: string; const splitter: string = ' ');
var
  p: integer;
begin
  p := Pos(splitter, inp);
  if p = 0 then
  begin
    out1 := inp;
    out2 := '';
  end
  else
  begin
    out1 := Trim(Copy(inp, 1, p - 1));
    out2 := Trim(Copy(inp, p + 1, Length(inp) - p));
  end;
end;

function IntToBool(const x: integer): boolean;
begin
  Result := x <> 0;
end;

function BoolToInt(const b: boolean): integer;
begin
  if b then
    Result := 1
  else
    Result := 0;
end;

function bigstringtostring(const bs: bigstring_p): string;
var
  i: integer;
begin
  Result := '';
  for i := 0 to MAXHISTORYPATH - 1 do
    if bs[i] = #0 then
      Exit
    else
      Result := Result + bs[i];
end;

procedure stringtobigstring(const src: string; const bs: bigstring_p);
var
  i: integer;
begin
  for i := 0 to MAXHISTORYPATH - 1 do
    bs[i] := #0;

  for i := 1 to Length(src) do
  begin
    bs[i - 1] := src[i];
    if i = MAXHISTORYPATH then
      Exit;
  end;
end;

procedure rv_SaveSettingsToFile(const fn: string);
var
  s: TStringList;
  i: integer;
begin
  s := TStringList.Create;
  try
    for i := 0 to NUMSETTINGS - 1 do
    begin
      if Settings[i].typeof = tstInteger then
        s.Add(Format('%s=%d', [Settings[i].desc, PInteger(Settings[i].location)^]))
      else if Settings[i].typeof = tstColor then
        s.Add(Format('%s=%d', [Settings[i].desc, PLongWord(Settings[i].location)^]))
      else if Settings[i].typeof = tstBoolean then
        s.Add(Format('%s=%d', [Settings[i].desc, BoolToInt(PBoolean(Settings[i].location)^)]))
      else if Settings[i].typeof = tstBigString then
        s.Add(Format('%s=%s', [Settings[i].desc, bigstringtostring(bigstring_p(Settings[i].location))]))
      else if Settings[i].typeof = tstString then
        s.Add(Format('%s=%s', [Settings[i].desc, PString(Settings[i].location)^]))
      else if Settings[i].typeof = tstDevider then
      begin
        if s.Count > 0 then
          s.Add('');
        s.Add(Settings[i].desc);
      end;
    end;
    s.SaveToFile(fn);
  finally
    s.Free;
  end;
end;

function rv_LoadSettingFromFile(const fn: string): boolean;
var
  s: TStringList;
  i, j: integer;
  s1, s2: string;
  itmp: integer;
  itmp64: int64;
begin
  if not FileExists(fn) then
  begin
    result := false;
    exit;
  end;
  result := true;

  s := TStringList.Create;
  try
    s.LoadFromFile(fn);
    begin
      for i := 0 to s.Count - 1 do
      begin
        splitstring(s.Strings[i], s1, s2, '=');
        if s2 <> '' then
        begin
          s1 := UpperCase(s1);
          for j := 0 to NUMSETTINGS - 1 do
            if UpperCase(Settings[j].desc) = s1 then
            begin
              if Settings[j].typeof = tstInteger then
              begin
                itmp := StrToIntDef(s2, PInteger(Settings[j].location)^);
                PInteger(Settings[j].location)^ := itmp;
              end
              else if Settings[j].typeof = tstColor then
              begin
                itmp64 := StrToInt64Def(s2, PLongWord(Settings[j].location)^);
                PLongWord(Settings[j].location)^ := itmp64;
              end
              else if Settings[j].typeof = tstBoolean then
              begin
                itmp := StrToIntDef(s2, BoolToInt(PBoolean(Settings[j].location)^));
                PBoolean(Settings[j].location)^ := IntToBool(itmp);
              end
              else if Settings[j].typeof = tstString then
              begin
                PString(Settings[j].location)^ := s2;
              end
              else if Settings[j].typeof = tstBigString then
              begin
                stringtobigstring(s2, bigstring_p(Settings[j].location));
              end;
            end;
        end;
      end;
    end;
  finally
    s.Free;
  end;

end;

end.

