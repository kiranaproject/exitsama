// exitsama.timer.pas — Countdown timer tracker with automatic pause handling
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit ExitSama.Timer;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes,
  ExitSama.Actions;

type
  TCountdownTracker = class
  private
    FInitialSeconds   : Integer;
    FRemainingSeconds : Integer;
    FElapsedMs        : Integer;
    FIsPaused         : Boolean;
    FIsExpired        : Boolean;
    FDefaultAction    : TPowerAction;

    function ActionToVerb(AAction: TPowerAction): string;
  public
    constructor Create(ASeconds: Integer = 60; ADefaultAction: TPowerAction = paShutDown);

    procedure Pause();
    procedure Resume();
    procedure Reset(ASeconds: Integer = -1);

    function  Tick(AElapsedMs: Integer): Boolean;
    function  GetStatusText(): string;

    property RemainingSeconds: Integer read FRemainingSeconds;
    property InitialSeconds: Integer read FInitialSeconds;
    property IsPaused: Boolean read FIsPaused;
    property IsExpired: Boolean read FIsExpired;
    property DefaultAction: TPowerAction read FDefaultAction write FDefaultAction;
  end;

implementation

constructor TCountdownTracker.Create(ASeconds: Integer; ADefaultAction: TPowerAction);
begin
  inherited Create();
  if ASeconds <= 0 then
    ASeconds := 60;

  FInitialSeconds := ASeconds;
  FRemainingSeconds := ASeconds;
  FElapsedMs := 0;
  FIsPaused := False;
  FIsExpired := False;
  FDefaultAction := ADefaultAction;
end;

procedure TCountdownTracker.Pause();
begin
  FIsPaused := True;
end;

procedure TCountdownTracker.Resume();
begin
  if not FIsExpired then
    FIsPaused := False;
end;

procedure TCountdownTracker.Reset(ASeconds: Integer);
begin
  if ASeconds > 0 then
    FInitialSeconds := ASeconds;

  FRemainingSeconds := FInitialSeconds;
  FElapsedMs := 0;
  FIsPaused := False;
  FIsExpired := False;
end;

function TCountdownTracker.Tick(AElapsedMs: Integer): Boolean;
begin
  Result := False;
  if FIsPaused or FIsExpired then Exit;

  FElapsedMs := FElapsedMs + AElapsedMs;
  while FElapsedMs >= 1000 do
  begin
    FElapsedMs := FElapsedMs - 1000;
    if FRemainingSeconds > 0 then
    begin
      Dec(FRemainingSeconds);
      if FRemainingSeconds = 0 then
      begin
        FIsExpired := True;
        Result := True;
        Break;
      end;
    end;
  end;
end;

function TCountdownTracker.ActionToVerb(AAction: TPowerAction): string;
begin
  case AAction of
    paLock:       Result := 'locking screen';
    paSwitchUser: Result := 'switching user';
    paSuspend:    Result := 'suspending';
    paLogOut:     Result := 'logging out';
    paRestart:    Result := 'restarting';
    paShutDown:   Result := 'shutting down';
  else
    Result := 'closing';
  end;
end;

function TCountdownTracker.GetStatusText(): string;
begin
  if FIsExpired then
    Result := 'Executing ' + ActionToLabel(FDefaultAction) + '...'
  else if FIsPaused then
    Result := 'Automatic action paused'
  else
    Result := 'Automatically ' + ActionToVerb(FDefaultAction) + ' in ' + IntToStr(FRemainingSeconds) + 's';
end;

end.
