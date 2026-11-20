// exitsama.actions.pas — Power and session action commands and executor
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit ExitSama.Actions;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, BaseUnix, ctypes;

type
  TPowerAction = (
    paLock,
    paSwitchUser,
    paSuspend,
    paLogOut,
    paRestart,
    paShutDown,
    paCancel
  );

function ActionToString(AAction: TPowerAction): string;
function StringToAction(const AStr: string): TPowerAction;
function ActionToAccelerator(AAction: TPowerAction): Char;
function ActionToLabel(AAction: TPowerAction): string;
function ActionToDescription(AAction: TPowerAction): string;

function BinaryExistsInPath(const ABinary: string): Boolean;
function ResolveActionCommand(AAction: TPowerAction): string;
function ExecuteAction(AAction: TPowerAction; ADryRun: Boolean = False): Boolean;

implementation

function execl(path: PChar; arg0: PChar; arg1: PChar; arg2: PChar; arg3: PChar): cint; cdecl; external 'c' name 'execl';

function ActionToString(AAction: TPowerAction): string;
begin
  case AAction of
    paLock:       Result := 'lock';
    paSwitchUser: Result := 'switch-user';
    paSuspend:    Result := 'suspend';
    paLogOut:     Result := 'logout';
    paRestart:    Result := 'reboot';
    paShutDown:   Result := 'shutdown';
    paCancel:     Result := 'cancel';
  else
    Result := 'cancel';
  end;
end;

function StringToAction(const AStr: string): TPowerAction;
var
  s: string;
begin
  s := LowerCase(Trim(AStr));
  if (s = 'lock') or (s = '--lock') then
    Result := paLock
  else if (s = 'switch-user') or (s = '--switch-user') or (s = 'switchuser') then
    Result := paSwitchUser
  else if (s = 'suspend') or (s = '--suspend') or (s = 'sleep') then
    Result := paSuspend
  else if (s = 'logout') or (s = '--logout') or (s = 'log-out') then
    Result := paLogOut
  else if (s = 'reboot') or (s = '--reboot') or (s = 'restart') or (s = '--restart') then
    Result := paRestart
  else if (s = 'shutdown') or (s = '--shutdown') or (s = 'poweroff') or (s = '--poweroff') then
    Result := paShutDown
  else
    Result := paCancel;
end;

function ActionToAccelerator(AAction: TPowerAction): Char;
begin
  case AAction of
    paLock:       Result := 'L';
    paSwitchUser: Result := 'U';
    paSuspend:    Result := 'P';
    paLogOut:     Result := 'O';
    paRestart:    Result := 'R';
    paShutDown:   Result := 'S';
    paCancel:     Result := 'C';
  else
    Result := #0;
  end;
end;

function ActionToLabel(AAction: TPowerAction): string;
begin
  case AAction of
    paLock:       Result := 'Lock';
    paSwitchUser: Result := 'Switch User';
    paSuspend:    Result := 'Suspend';
    paLogOut:     Result := 'Log Out';
    paRestart:    Result := 'Restart';
    paShutDown:   Result := 'Shut Down';
    paCancel:     Result := 'Cancel';
  else
    Result := '';
  end;
end;

function ActionToDescription(AAction: TPowerAction): string;
begin
  case AAction of
    paLock:       Result := 'Lock the current screen immediately';
    paSwitchUser: Result := 'Switch to another user or login screen';
    paSuspend:    Result := 'Place the computer into low-power sleep';
    paLogOut:     Result := 'Close all applications and end session';
    paRestart:    Result := 'Restart the computer';
    paShutDown:   Result := 'Turn off the computer completely';
    paCancel:     Result := 'Return to the desktop';
  else
    Result := '';
  end;
end;

function BinaryExistsInPath(const ABinary: string): Boolean;
var
  paths, dir, candidate: string;
  p: Integer;
begin
  if Pos('/', ABinary) > 0 then
    Exit(FileExists(ABinary));

  paths := GetEnvironmentVariable('PATH');
  if paths = '' then
    paths := '/usr/local/bin:/usr/bin:/bin';

  while Length(paths) > 0 do
  begin
    p := Pos(':', paths);
    if p > 0 then
    begin
      dir := Copy(paths, 1, p - 1);
      Delete(paths, 1, p);
    end
    else
    begin
      dir := paths;
      paths := '';
    end;

    if dir <> '' then
    begin
      candidate := IncludeTrailingPathDelimiter(dir) + ABinary;
      if FileExists(candidate) then
        Exit(True);
    end;
  end;

  Result := False;
end;

function ResolveActionCommand(AAction: TPowerAction): string;
begin
  case AAction of
    paLock:
    begin
      if BinaryExistsInPath('shellsama') then
        Result := 'shellsama --lock'
      else if BinaryExistsInPath('loginctl') then
        Result := 'loginctl lock-session'
      else if BinaryExistsInPath('xflock4') then
        Result := 'xflock4'
      else
        Result := 'loginctl lock-session';
    end;

    paSwitchUser:
    begin
      if BinaryExistsInPath('dm-tool') then
        Result := 'dm-tool switch-to-greeter'
      else if BinaryExistsInPath('gdmflexiserver') then
        Result := 'gdmflexiserver'
      else if BinaryExistsInPath('loginctl') then
        Result := 'loginctl lock-session'
      else
        Result := 'dm-tool switch-to-greeter';
    end;

    paSuspend:
    begin
      if BinaryExistsInPath('systemctl') then
        Result := 'systemctl suspend'
      else if BinaryExistsInPath('loginctl') then
        Result := 'loginctl suspend'
      else
        Result := 'systemctl suspend';
    end;

    paLogOut:
    begin
      if BinaryExistsInPath('sessionsama') then
        Result := 'sessionsama --logout'
      else if BinaryExistsInPath('loginctl') then
        Result := 'loginctl terminate-user $USER'
      else
        Result := 'sessionsama --logout';
    end;

    paRestart:
    begin
      if BinaryExistsInPath('systemctl') then
        Result := 'systemctl reboot'
      else if BinaryExistsInPath('loginctl') then
        Result := 'loginctl reboot'
      else
        Result := 'systemctl reboot';
    end;

    paShutDown:
    begin
      if BinaryExistsInPath('systemctl') then
        Result := 'systemctl poweroff'
      else if BinaryExistsInPath('loginctl') then
        Result := 'loginctl poweroff'
      else
        Result := 'systemctl poweroff';
    end;

    paCancel:
      Result := '';
  else
    Result := '';
  end;
end;

function ExecuteAction(AAction: TPowerAction; ADryRun: Boolean = False): Boolean;
var
  cmd: string;
  pid: pid_t;
begin
  if AAction = paCancel then
    Exit(True);

  cmd := ResolveActionCommand(AAction);
  if cmd = '' then
    Exit(False);

  if ADryRun then
    Exit(True);

  // Fork and execute command asynchronously
  pid := fpFork();
  if pid < 0 then
    Exit(False);

  if pid = 0 then
  begin
    // Child process: execute shell command
    execl('/bin/sh', 'sh', '-c', PChar(cmd), nil);
    fpExit(127);
  end;

  Result := True;
end;

end.
