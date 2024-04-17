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
  Case32_text_input_and_clipboard_handling;

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
