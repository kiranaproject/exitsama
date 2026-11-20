// exitsama.timer.test.pas — Unit test for countdown tracker
// Copyright (c) 2026 Dio Affriza — SPDX-License-Identifier: MPL-2.0

unit exitsama.timer.test;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  ExitSama.Actions, ExitSama.Timer;

type
  TTimerTest = class(TTestCase)
  published
    procedure TestTimerInitialization();
    procedure TestTimerTickCountdown();
    procedure TestTimerPauseResume();
    procedure TestTimerReset();
    procedure TestStatusText();
  end;

implementation

procedure TTimerTest.TestTimerInitialization();
var
  tracker: TCountdownTracker;
begin
  tracker := TCountdownTracker.Create(30, paShutDown);
  AssertEquals('Initial seconds should be 30', 30, tracker.InitialSeconds);
  AssertEquals('Remaining seconds should be 30', 30, tracker.RemainingSeconds);
  AssertFalse('Timer should not be paused initially', tracker.IsPaused);
  AssertFalse('Timer should not be expired initially', tracker.IsExpired);
  AssertEquals('Default action matches', Ord(paShutDown), Ord(tracker.DefaultAction));
  tracker.Free();
end;

procedure TTimerTest.TestTimerTickCountdown();
var
  tracker: TCountdownTracker;
  expired: Boolean;
begin
  tracker := TCountdownTracker.Create(3, paRestart);

  // Tick 500ms -> remaining still 3
  expired := tracker.Tick(500);
  AssertFalse('Not expired at 500ms', expired);
  AssertEquals('Remaining is 3 at 500ms', 3, tracker.RemainingSeconds);

  // Tick another 500ms (total 1000ms) -> remaining becomes 2
  expired := tracker.Tick(500);
  AssertFalse('Not expired at 1000ms', expired);
  AssertEquals('Remaining is 2 at 1000ms', 2, tracker.RemainingSeconds);

  // Tick 1000ms -> remaining becomes 1
  expired := tracker.Tick(1000);
  AssertFalse('Not expired at 2000ms', expired);
  AssertEquals('Remaining is 1 at 2000ms', 1, tracker.RemainingSeconds);

  // Tick 1000ms -> remaining becomes 0, triggers expiry
  expired := tracker.Tick(1000);
  AssertTrue('Expired at 3000ms', expired);
  AssertTrue('Tracker is expired', tracker.IsExpired);
  AssertEquals('Remaining is 0', 0, tracker.RemainingSeconds);

  tracker.Free();
end;

procedure TTimerTest.TestTimerPauseResume();
var
  tracker: TCountdownTracker;
begin
  tracker := TCountdownTracker.Create(10, paLogOut);

  tracker.Tick(1000);
  AssertEquals('Remaining is 9', 9, tracker.RemainingSeconds);

  tracker.Pause();
  AssertTrue('Tracker is paused', tracker.IsPaused);

  // Ticks while paused should not decrement remaining seconds
  tracker.Tick(2000);
  AssertEquals('Remaining is still 9 while paused', 9, tracker.RemainingSeconds);

  tracker.Resume();
  AssertFalse('Tracker is resumed', tracker.IsPaused);

  tracker.Tick(1000);
  AssertEquals('Remaining is 8 after resume', 8, tracker.RemainingSeconds);

  tracker.Free();
end;

procedure TTimerTest.TestTimerReset();
var
  tracker: TCountdownTracker;
begin
  tracker := TCountdownTracker.Create(15, paShutDown);

  tracker.Tick(5000);
  AssertEquals('Remaining is 10', 10, tracker.RemainingSeconds);

  tracker.Reset();
  AssertEquals('Reset restores initial 15 seconds', 15, tracker.RemainingSeconds);
  AssertFalse('Not paused after reset', tracker.IsPaused);

  tracker.Reset(45);
  AssertEquals('Reset with new value restores 45 seconds', 45, tracker.RemainingSeconds);
  AssertEquals('Initial seconds updated to 45', 45, tracker.InitialSeconds);

  tracker.Free();
end;

procedure TTimerTest.TestStatusText();
var
  tracker: TCountdownTracker;
  txt: string;
begin
  tracker := TCountdownTracker.Create(60, paShutDown);

  txt := tracker.GetStatusText();
  AssertTrue('Status contains remaining seconds', Pos('60s', txt) > 0);
  AssertTrue('Status contains shutting down', Pos('shutting down', txt) > 0);

  tracker.Pause();
  txt := tracker.GetStatusText();
  AssertEquals('Status shows paused', 'Automatic action paused', txt);

  tracker.Resume();
  tracker.Tick(60000);
  txt := tracker.GetStatusText();
  AssertTrue('Status shows executing on expiration', Pos('Executing', txt) > 0);

  tracker.Free();
end;

initialization
  RegisterTest(TTimerTest);

end.
