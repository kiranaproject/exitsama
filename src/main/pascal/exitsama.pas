// exitsama.pas — Samarinda Session Termination and Power Management Dialog
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

program exitsama;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, BaseUnix, ctypes,
  ftpas, ftpas.api, ftpas.app, ftpas.types, ftpas.window,
  ExitSama.Actions, ExitSama.Timer, ExitSama.Dialog;

const
  EXITSAMA_VERSION = '0.0.1-SNAPSHOT';

function setenv(name: PChar; value: PChar; overwrite: cint): cint; cdecl; external 'c' name 'setenv';

var
  GDialog: TExitDialog = nil;

procedure ExitSamaSignalHandler(sig: cint); cdecl;
begin
  case sig of
    SIGINT, SIGTERM, SIGHUP:
    begin
      FtApp().Terminate();
    end;
  end;
end;

procedure ExitSamaTimerDispatcher(user_data: Pointer); cdecl;
var
  dialog: TExitDialog;
begin
  dialog := TExitDialog(user_data);
  if dialog <> nil then
    dialog.Tick(100);
end;

procedure PrintUsage();
begin
  WriteLn('Usage: exitsama [options]');
  WriteLn('Samarinda Desktop Session Termination Dialog');
  WriteLn('');
  WriteLn('Options:');
  WriteLn('  -h, --help             Display this help message and exit');
  WriteLn('  -v, --version          Display version information and exit');
  WriteLn('  --shutdown             Open dialog with Shut Down as default action');
  WriteLn('  --reboot               Open dialog with Restart as default action');
  WriteLn('  --logout               Open dialog with Log Out as default action');
  WriteLn('  --suspend              Open dialog with Suspend as default action');
  WriteLn('  --lock                 Lock screen immediately and exit');
  WriteLn('  --timeout=<seconds>    Specify countdown duration (default: 60)');
  WriteLn('  --immediate            Execute selected action immediately without prompt');
end;

procedure PrintVersion();
begin
  WriteLn('exitsama ' + EXITSAMA_VERSION + ' (Samarinda Session Termination Dialog)');
  WriteLn('Copyright (c) 2026 Dio Affriza. Licensed under MPL-2.0.');
end;

var
  i: Integer;
  arg, valStr: string;
  defaultAction: TPowerAction;
  timeoutSeconds: Integer;
  immediate: Boolean;
begin
  defaultAction := paShutDown;
  timeoutSeconds := 60;
  immediate := False;

  for i := 1 to ParamCount() do
  begin
    arg := ParamStr(i);
    if (arg = '-v') or (arg = '--version') then
    begin
      PrintVersion();
      Exit;
    end
    else if (arg = '-h') or (arg = '--help') then
    begin
      PrintUsage();
      Exit;
    end
    else if arg = '--lock' then
    begin
      ExecuteAction(paLock, False);
      Exit;
    end
    else if (arg = '--shutdown') or (arg = '--poweroff') then
      defaultAction := paShutDown
    else if (arg = '--reboot') or (arg = '--restart') then
      defaultAction := paRestart
    else if arg = '--logout' then
      defaultAction := paLogOut
    else if (arg = '--suspend') or (arg = '--sleep') then
      defaultAction := paSuspend
    else if arg = '--immediate' then
      immediate := True
    else if Pos('--timeout=', arg) = 1 then
    begin
      valStr := Copy(arg, 11, Length(arg));
      timeoutSeconds := StrToIntDef(valStr, 60);
    end;
  end;

  if immediate then
  begin
    ExecuteAction(defaultAction, False);
    Exit;
  end;

  fpsignal(SIGTERM, SignalHandler(@ExitSamaSignalHandler));
  fpsignal(SIGINT,  SignalHandler(@ExitSamaSignalHandler));
  fpsignal(SIGHUP,  SignalHandler(@ExitSamaSignalHandler));

  if GetEnvironmentVariable('DISPLAY') = '' then
    setenv('DISPLAY', ':0', 1);

  FtApp().Initialize();

  GDialog := TExitDialog.Create(timeoutSeconds, defaultAction);

  if Assigned(ft_set_timer) then
    ft_set_timer(100, @ExitSamaTimerDispatcher, Pointer(GDialog))
  else if Assigned(ft_set_tick_callback) then
    ft_set_tick_callback(@ExitSamaTimerDispatcher, Pointer(GDialog));

  GDialog.Show();

  try
    FtApp().Run();
  finally
    if GDialog <> nil then
    begin
      GDialog.Free();
      GDialog := nil;
    end;
  end;
end.
