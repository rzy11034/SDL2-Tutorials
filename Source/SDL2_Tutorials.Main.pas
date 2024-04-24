unit SDL2_Tutorials.Main;

{$mode ObjFPC}{$H+}
{$ModeSwitch unicodestrings}{$J-}
{$ModeSwitch advancedrecords}
{$WARN 4104 off : Implicit string type conversion from "$1" to "$2"}
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
  Case39_tiling, Case39_tiling.Tile;

procedure Text;
var
  list: TStringList;
  i, j: Integer;
  str:string;
  s1, s2: TArr_str;
  temp:TArrayList_str;
begin
  list := TStringList.Create;
  temp := TArrayList_str.Create;

  list.LoadFromFile('../Source/39_tiling/lazy.map');

  //SetLength(s1, list.Count);
  for i := 0 to list.Count-1 do
  begin
    str := string(list[i]);
    s1 := str.Split([' ']);

    for j := 0 to 15 do
    begin
      temp.AddLast(s1[j]);
    end;
  end;


  s2 := temp.ToArray;


  temp.Free;
  list.Free;
  Exit;
end;

procedure Run;
begin
  Text;
  //Main;
end;

end.
