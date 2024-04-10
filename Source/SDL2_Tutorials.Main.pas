unit SDL2_Tutorials.Main;

{$mode ObjFPC}{$H+}
{$ModeSwitch unicodestrings}{$J-}

interface

uses
  Classes,
  SysUtils,
  {%H-}DeepStar.Utils,
  {%H-}DeepStar.UString,
  {%H-}libSDL2;

procedure Run;

implementation

uses
  Case16_true_type_fonts;

procedure Text;
begin
  Exit;
end;

procedure Run;
begin
  Text;
  Main;
end;

end.
