unit SDL2_Tutorials.Utils;

{$mode ObjFPC}{$H+}
{$ModeSwitch unicodestrings}{$J-}

interface

uses
  Classes,
  SysUtils,
  libSDL2;

function SDL_Point(aX, aY: integer): TSDL_Point;
function SDL_Rect(aX, aY, aW, aH: integer): TSDL_Rect;
function SDL_Color(r, g, b, a: byte): TSDL_Color;

implementation

function SDL_Rect(aX, aY, aW, aH: integer): TSDL_Rect;
var
  res: TSDL_Rect;
begin
  res := Default(TSDL_Rect);

  with res do
  begin
    x := aX; y := aY; w := aW; h := aH;
  end;

  Result := res;
end;

function SDL_Color(r, g, b, a: byte): TSDL_Color;
var
  res: TSDL_Color;
begin
  res := Default(TSDL_Color);

  res.a := a;
  res.b := b;
  res.g := g;
  res.a := a;

  Result := res;
end;

function SDL_Point(aX, aY: integer): TSDL_Point;
var
  res: TSDL_Point;
begin
  res := Default(TSDL_Point);

  with res do
  begin
    x := aX; y := aY;
  end;

  Result := res;
end;

end.
