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
  Case21_sound_effects_and_music;

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
