unit SDL2_Tutorials.Main;

{$mode ObjFPC}{$H+}
{$ModeSwitch unicodestrings}{$J-}

interface

uses
  Classes,
  SysUtils,
  {%H-}DeepStar.Utils,
  {%H-}DeepStar.UString,
  {%H-}libSDL2,
  {%H-}SDL2_Tutorials.Utils;

procedure Run;

implementation

uses
  Case38_particle_engines;

type

  PA = ^TA;
  TA = object
  private
    _X: integer;
  public
    constructor Init;
    constructor Init(ax:integer);
    procedure add;
    destructor Done;
    property X:integer read _X write _X;
  end;

  PB = ^TB;
  TB = object
  private
    _X: integer;
    P : PA;
  public
    constructor Init;
    destructor Done;
    property X:integer read _X write _X;
  end;

procedure Text;
var
  a: PA;
  aa: TA;
  b: PB;
begin
  //a := Default(TT);
  //a.Inits;
  aa._X := 1000;
  aa.add;
  a := PA(nil);
  new(a, Init);

  FreeMemAndNil(a);

  new(b,Init);
  Dispose(b, Done);
  b := nil;
  if Assigned(b) then
    WriteLn('Assigned');



  Exit;
end;

procedure Run;
begin
  Text;
  //Main;
end;

{ TB }

constructor TB.Init;
begin
  new(P, Init);
end;

destructor TB.Done;
begin
  Dispose(P, Done);
end;

{ TT }

constructor TA.Init(ax: integer);
begin
  X := ax;
end;

constructor TA.Init;
begin
  X := 500;
end;

procedure TA.add;
begin
  _x += 500;
end;

destructor TA.Done;
begin
end;

end.
