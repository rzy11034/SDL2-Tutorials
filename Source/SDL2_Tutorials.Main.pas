unit SDL2_Tutorials.Main;

{$mode ObjFPC}{$H+}
{$ModeSwitch unicodestrings}{$J-}

interface

uses
  Classes,
  SysUtils,
  {%H-}DeepStar.Utils,
  {%H-}libSDL2,
  {%H-}SDL2_Tutorials.Utils;


procedure Run;

implementation

uses
  Case26_motion;

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
