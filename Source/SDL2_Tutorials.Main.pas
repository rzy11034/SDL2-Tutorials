unit SDL2_Tutorials.Main;

{$mode ObjFPC}{$H+}
{$ModeSwitch unicodestrings}{$J-}

interface

uses
  Classes,
  SysUtils,
  {%H-}DeepStar.Utils,
  DeepStar.DSA.Interfaces,
  DeepStar.DSA.Linear.ArrayList,
  {%H-}DeepStar.UString,
  {%H-}libSDL2, SDL2_Tutorials.Utils;

procedure Run;

implementation

uses
  Case27_collision_detection;

type
  tr = record
    x, y: integer;
    w, h: integer;
  end;

  IList_SDL_Rect = specialize IList<TSDL_Rect>;
  TList_SDL_Rect = specialize TArrayList<TSDL_Rect>;


procedure Text;
var
  c: TList_SDL_Rect;
  t: tr;
begin
  c := TList_SDL_Rect.Create(11);

  c[0] := SDL_Rect(0, 0, 10, 10);

  Exit;
end;

procedure Run;
begin
  Text;
  Main;
end;

end.
