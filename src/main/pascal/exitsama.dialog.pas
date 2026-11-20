// exitsama.dialog.pas — Centered modal power and session exit dialog
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit ExitSama.Dialog;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  ftpas, ftpas.api, ftpas.app, ftpas.types, ftpas.window, ftpas.controls,
  ExitSama.Actions, ExitSama.Timer;

type
  TExitActionSelectedEvent = procedure(Sender: TObject; AAction: TPowerAction) of object;

  TExitDialog = class(TFtWindow)
  private
    FTracker          : TCountdownTracker;
    FSelectedAction   : TPowerAction;
    FIsDark           : Boolean;
    FAutoClose        : Boolean;

    FTitleLabel       : TFtLabel;
    FSubtitleLabel    : TFtLabel;
    FCloseBtn         : TFtWindowButton;
    FCountdownLabel   : TFtLabel;
    FCancelButton     : TFtButton;

    FBtnLock          : TFtButton;
    FBtnSwitch        : TFtButton;
    FBtnSuspend       : TFtButton;
    FBtnLogOut        : TFtButton;
    FBtnRestart       : TFtButton;
    FBtnShutDown      : TFtButton;

    FOnActionSelected : TExitActionSelectedEvent;

    procedure BuildUI();
    procedure SyncTheme();
    procedure CenterOnScreen();
    procedure UpdateCountdownDisplay();

    procedure HandleActionClick(Sender: TFtButton);
    procedure HandleCancelClick(Sender: TFtButton);
    procedure HandleWindowCloseClick(Sender: TFtWindowButton);
  protected
    procedure DoKey(AKey: LongWord; AIsDown: Boolean); override;
    procedure DoMouseMove(AX, AY: Integer); override;
    function  DoClose(): Boolean; override;
  public
    constructor Create(ATimeoutSeconds: Integer = 60; ADefaultAction: TPowerAction = paShutDown); reintroduce;
    destructor Destroy(); override;

    procedure Tick(AElapsedMs: Integer);
    procedure TriggerAction(AAction: TPowerAction);

    property Tracker: TCountdownTracker read FTracker;
    property SelectedAction: TPowerAction read FSelectedAction write FSelectedAction;
    property OnActionSelected: TExitActionSelectedEvent read FOnActionSelected write FOnActionSelected;
  end;

implementation

constructor TExitDialog.Create(ATimeoutSeconds: Integer; ADefaultAction: TPowerAction);
begin
  FIsDark := FtApp().DarkMode;
  FSelectedAction := ADefaultAction;
  FAutoClose := True;

  FTracker := TCountdownTracker.Create(ATimeoutSeconds, ADefaultAction);

  // 560px width, 290px height dialog
  inherited Create(560, 290, 'End Session');

  WindowType := ftwtDialog;
  SkipTaskbar := True;
  Borderless := False;

  BuildUI();
  CenterOnScreen();
  SyncTheme();
end;

destructor TExitDialog.Destroy();
begin
  if FTracker <> nil then
  begin
    FTracker.Free();
    FTracker := nil;
  end;
  inherited Destroy();
end;

procedure TExitDialog.CenterOnScreen();
var
  sw, sh: Integer;
  posX, posY: Integer;
begin
  sw := 0;
  sh := 0;
  if Assigned(ft_screen_get_width) then
    sw := ft_screen_get_width();
  if Assigned(ft_screen_get_height) then
    sh := ft_screen_get_height();

  if sw <= 0 then sw := 1920;
  if sh <= 0 then sh := 1080;

  posX := (sw - 560) div 2;
  posY := (sh - 290) div 2;
  if posX < 0 then posX := 0;
  if posY < 0 then posY := 0;

  SetPosition(posX, posY);
end;

procedure TExitDialog.BuildUI();
var
  curY: Integer;
  btnW, btnH, gap, btnX: Integer;
  userStr: string;
begin
  userStr := GetEnvironmentVariable('USER');
  if userStr = '' then userStr := 'Session';

  curY := 16;

  // 1. Header: Title and Subtitle
  FTitleLabel := TFtLabel.Create(Self, 24, curY, 470, 26, 'Log out ' + userStr + '?');
  FTitleLabel.Font := 'sans-serif,15,bold';

  FCloseBtn := TFtWindowButton.Create(Self, 524, curY + 2, 16, 16, ftwbClose, ftwsCircle);
  FCloseBtn.Hint := 'cancel';
  FCloseBtn.ShowHint := True;
  FCloseBtn.OnClick := @HandleWindowCloseClick;

  curY := curY + 26;

  FSubtitleLabel := TFtLabel.Create(Self, 24, curY, 500, 18, 'Select an action or press Esc to cancel.');
  FSubtitleLabel.Font := 'sans-serif,10';

  curY := curY + 36;

  // 2. Power Actions Grid: 6 actions across two rows or 5 primary actions in a clean row
  // Row 1: Lock (L), Switch (U), Suspend (P), Log Out (O)
  // Row 2: Restart (R), Shut Down (S)
  // Let us make a balanced 6-button grid (2 rows of 3 buttons)
  // Each button: width = 160, height = 44, gapX = 16, gapY = 12
  // Total width: 160*3 + 16*2 = 480 + 32 = 512, centered with marginX = 24
  btnW := 160;
  btnH := 44;
  gap := 16;

  // Row 1: Lock, Switch User, Suspend
  btnX := 24;
  FBtnLock := TFtButton.Create(Self, btnX, curY, btnW, btnH, 'Lock  (L)');
  FBtnLock.OnClick := @HandleActionClick;
  FBtnLock.Hint := ActionToDescription(paLock);
  FBtnLock.ShowHint := True;

  btnX := btnX + btnW + gap;
  FBtnSwitch := TFtButton.Create(Self, btnX, curY, btnW, btnH, 'Switch User  (U)');
  FBtnSwitch.OnClick := @HandleActionClick;
  FBtnSwitch.Hint := ActionToDescription(paSwitchUser);
  FBtnSwitch.ShowHint := True;

  btnX := btnX + btnW + gap;
  FBtnSuspend := TFtButton.Create(Self, btnX, curY, btnW, btnH, 'Suspend  (P)');
  FBtnSuspend.OnClick := @HandleActionClick;
  FBtnSuspend.Hint := ActionToDescription(paSuspend);
  FBtnSuspend.ShowHint := True;

  curY := curY + btnH + 12;

  // Row 2: Log Out, Restart, Shut Down
  btnX := 24;
  FBtnLogOut := TFtButton.Create(Self, btnX, curY, btnW, btnH, 'Log Out  (O)');
  FBtnLogOut.OnClick := @HandleActionClick;
  FBtnLogOut.Hint := ActionToDescription(paLogOut);
  FBtnLogOut.ShowHint := True;

  btnX := btnX + btnW + gap;
  FBtnRestart := TFtButton.Create(Self, btnX, curY, btnW, btnH, 'Restart  (R)');
  FBtnRestart.OnClick := @HandleActionClick;
  FBtnRestart.Hint := ActionToDescription(paRestart);
  FBtnRestart.ShowHint := True;

  btnX := btnX + btnW + gap;
  FBtnShutDown := TFtButton.Create(Self, btnX, curY, btnW, btnH, 'Shut Down  (S)');
  FBtnShutDown.OnClick := @HandleActionClick;
  FBtnShutDown.Hint := ActionToDescription(paShutDown);
  FBtnShutDown.ShowHint := True;

  curY := curY + btnH + 18;

  // 3. Footer: Countdown Label and Cancel Button
  FCountdownLabel := TFtLabel.Create(Self, 24, curY + 6, 380, 20, FTracker.GetStatusText());
  FCountdownLabel.Font := 'sans-serif,9';

  FCancelButton := TFtButton.Create(Self, 424, curY, 112, 30, 'Cancel');
  FCancelButton.OnClick := @HandleCancelClick;
  FCancelButton.Hint := 'Return to the desktop (Esc)';
  FCancelButton.ShowHint := True;
end;

procedure TExitDialog.SyncTheme();
begin
  FIsDark := FtApp().DarkMode;
  if FTitleLabel <> nil then
  begin
    if FIsDark then
      FTitleLabel.SetColor(0.95, 0.95, 0.96)
    else
      FTitleLabel.SetColor(0.12, 0.14, 0.18);
  end;

  if FSubtitleLabel <> nil then
  begin
    if FIsDark then
      FSubtitleLabel.SetColor(0.68, 0.70, 0.74)
    else
      FSubtitleLabel.SetColor(0.40, 0.42, 0.46);
  end;

  if FCountdownLabel <> nil then
  begin
    if FIsDark then
      FCountdownLabel.SetColor(0.55, 0.58, 0.64)
    else
      FCountdownLabel.SetColor(0.45, 0.48, 0.52);
  end;
end;

procedure TExitDialog.UpdateCountdownDisplay();
begin
  if FCountdownLabel <> nil then
    FCountdownLabel.Text := FTracker.GetStatusText();
end;

procedure TExitDialog.Tick(AElapsedMs: Integer);
begin
  if FTracker.Tick(AElapsedMs) then
  begin
    UpdateCountdownDisplay();
    TriggerAction(FTracker.DefaultAction);
  end
  else
  begin
    UpdateCountdownDisplay();
  end;
end;

procedure TExitDialog.TriggerAction(AAction: TPowerAction);
begin
  FTracker.Pause();
  if Assigned(FOnActionSelected) then
    FOnActionSelected(Self, AAction);

  if AAction = paCancel then
  begin
    Close();
    FtApp().Terminate();
  end
  else
  begin
    ExecuteAction(AAction, False);
    Close();
    FtApp().Terminate();
  end;
end;

procedure TExitDialog.HandleActionClick(Sender: TFtButton);
var
  act: TPowerAction;
begin
  FTracker.Pause();
  UpdateCountdownDisplay();

  if Sender = FBtnLock then
    act := paLock
  else if Sender = FBtnSwitch then
    act := paSwitchUser
  else if Sender = FBtnSuspend then
    act := paSuspend
  else if Sender = FBtnLogOut then
    act := paLogOut
  else if Sender = FBtnRestart then
    act := paRestart
  else if Sender = FBtnShutDown then
    act := paShutDown
  else
    act := paCancel;

  TriggerAction(act);
end;

procedure TExitDialog.HandleCancelClick(Sender: TFtButton);
begin
  TriggerAction(paCancel);
end;

procedure TExitDialog.HandleWindowCloseClick(Sender: TFtWindowButton);
begin
  TriggerAction(paCancel);
end;

procedure TExitDialog.DoKey(AKey: LongWord; AIsDown: Boolean);
begin
  inherited DoKey(AKey, AIsDown);

  if not AIsDown then Exit;

  // Any key press pauses countdown
  if not FTracker.IsPaused then
  begin
    FTracker.Pause();
    UpdateCountdownDisplay();
  end;

  // Escape ($FF1B or 27) or 'c' / 'C'
  if (AKey = $FF1B) or (AKey = 27) or (AKey = Ord('c')) or (AKey = Ord('C')) then
  begin
    TriggerAction(paCancel);
    Exit;
  end;

  // Return / Enter ($FF0D or 13 or $FF8D)
  if (AKey = $FF0D) or (AKey = 13) or (AKey = $FF8D) then
  begin
    TriggerAction(FSelectedAction);
    Exit;
  end;

  // Accelerators
  case AKey of
    Ord('l'), Ord('L'): TriggerAction(paLock);
    Ord('u'), Ord('U'): TriggerAction(paSwitchUser);
    Ord('p'), Ord('P'): TriggerAction(paSuspend);
    Ord('o'), Ord('O'): TriggerAction(paLogOut);
    Ord('r'), Ord('R'): TriggerAction(paRestart);
    Ord('s'), Ord('S'): TriggerAction(paShutDown);
  end;
end;

procedure TExitDialog.DoMouseMove(AX, AY: Integer);
begin
  inherited DoMouseMove(AX, AY);

  // Pointer movement pauses countdown
  if not FTracker.IsPaused then
  begin
    FTracker.Pause();
    UpdateCountdownDisplay();
  end;
end;

function TExitDialog.DoClose(): Boolean;
begin
  TriggerAction(paCancel);
  Result := True;
end;

end.
