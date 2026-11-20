// exitsama.actions.test.pas — Unit test for power actions and resolvers
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit exitsama.actions.test;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  ExitSama.Actions;

type
  TActionsTest = class(TTestCase)
  published
    procedure TestActionStringConversions();
    procedure TestActionAccelerators();
    procedure TestActionDescriptions();
    procedure TestCommandResolvers();
    procedure TestDryRunExecution();
  end;

implementation

procedure TActionsTest.TestActionStringConversions();
begin
  AssertEquals('StringToAction shutdown', Ord(paShutDown), Ord(StringToAction('shutdown')));
  AssertEquals('StringToAction --shutdown', Ord(paShutDown), Ord(StringToAction('--shutdown')));
  AssertEquals('StringToAction reboot', Ord(paRestart), Ord(StringToAction('reboot')));
  AssertEquals('StringToAction restart', Ord(paRestart), Ord(StringToAction('restart')));
  AssertEquals('StringToAction logout', Ord(paLogOut), Ord(StringToAction('logout')));
  AssertEquals('StringToAction suspend', Ord(paSuspend), Ord(StringToAction('suspend')));
  AssertEquals('StringToAction lock', Ord(paLock), Ord(StringToAction('lock')));
  AssertEquals('StringToAction switch-user', Ord(paSwitchUser), Ord(StringToAction('switch-user')));
  AssertEquals('StringToAction unknown returns cancel', Ord(paCancel), Ord(StringToAction('invalid-action')));

  AssertEquals('ActionToString paShutDown', 'shutdown', ActionToString(paShutDown));
  AssertEquals('ActionToString paRestart', 'reboot', ActionToString(paRestart));
  AssertEquals('ActionToString paLogOut', 'logout', ActionToString(paLogOut));
  AssertEquals('ActionToString paSuspend', 'suspend', ActionToString(paSuspend));
  AssertEquals('ActionToString paLock', 'lock', ActionToString(paLock));
  AssertEquals('ActionToString paSwitchUser', 'switch-user', ActionToString(paSwitchUser));
  AssertEquals('ActionToString paCancel', 'cancel', ActionToString(paCancel));
end;

procedure TActionsTest.TestActionAccelerators();
begin
  AssertEquals('Accelerator for Shut Down', 'S', ActionToAccelerator(paShutDown));
  AssertEquals('Accelerator for Restart', 'R', ActionToAccelerator(paRestart));
  AssertEquals('Accelerator for Log Out', 'O', ActionToAccelerator(paLogOut));
  AssertEquals('Accelerator for Lock', 'L', ActionToAccelerator(paLock));
  AssertEquals('Accelerator for Switch User', 'U', ActionToAccelerator(paSwitchUser));
  AssertEquals('Accelerator for Suspend', 'P', ActionToAccelerator(paSuspend));
  AssertEquals('Accelerator for Cancel', 'C', ActionToAccelerator(paCancel));
end;

procedure TActionsTest.TestActionDescriptions();
var
  act: TPowerAction;
begin
  for act in [paLock, paSwitchUser, paSuspend, paLogOut, paRestart, paShutDown] do
  begin
    AssertTrue('Description should not be empty for ' + ActionToString(act), Length(ActionToDescription(act)) > 0);
    AssertTrue('Label should not be empty for ' + ActionToString(act), Length(ActionToLabel(act)) > 0);
  end;
end;

procedure TActionsTest.TestCommandResolvers();
var
  cmd: string;
begin
  cmd := ResolveActionCommand(paShutDown);
  AssertTrue('ShutDown command should resolve', Length(cmd) > 0);

  cmd := ResolveActionCommand(paRestart);
  AssertTrue('Restart command should resolve', Length(cmd) > 0);

  cmd := ResolveActionCommand(paCancel);
  AssertEquals('Cancel command is empty', '', cmd);
end;

procedure TActionsTest.TestDryRunExecution();
begin
  AssertTrue('Dry run shutdown succeeds', ExecuteAction(paShutDown, True));
  AssertTrue('Dry run restart succeeds', ExecuteAction(paRestart, True));
  AssertTrue('Dry run logout succeeds', ExecuteAction(paLogOut, True));
  AssertTrue('Dry run cancel succeeds', ExecuteAction(paCancel, True));
end;

initialization
  RegisterTest(TActionsTest);

end.
