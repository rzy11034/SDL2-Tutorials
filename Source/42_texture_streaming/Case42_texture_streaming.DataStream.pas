unit Case42_texture_streaming.DataStream;

{$mode ObjFPC}{$H+}
{$ModeSwitch unicodestrings}{$J-}
{$WARN 4104 off : Implicit string type conversion from "$1" to "$2"}
interface

uses
  Classes,
  SysUtils,
  DeepStar.Utils,
  DeepStar.UString,
  libSDL2,
  libSDL2_image;

type
  PDataStream = ^TDataStream;
  TDataStream = object
  private
    //Internal data
    _Images: array[0..3] of PSDL_Surface;
    _CurrentImage: integer;
    _DelayFrames: integer;

  public
    constructor Init();
    destructor Done;

    //Loads initial data
    function LoadMedia(): boolean;

    //Deallocator
    procedure Free();

    //Gets current frame data
    function GetBuffer(): Pointer;
  end;


implementation

{ TDataStream }

constructor TDataStream.Init();
begin
  new(_Images[0]);

  //_Images[0] := nil;
  _Images[1] := nil;
  _Images[2] := nil;
  _Images[3] := nil;

  _CurrentImage := 0;
  _DelayFrames := 4;
end;

destructor TDataStream.Done;
begin
  Free();
  inherited;
end;

procedure TDataStream.Free();
var
  i: integer;
begin
  for i := 0 to 3 do
  begin
    SDL_FreeSurface(_Images[i]);
    _Images[i] := nil;
  end;
end;

function TDataStream.GetBuffer(): Pointer;
begin
  _DelayFrames -= 1;

  if _DelayFrames = 0 then
  begin
    _CurrentImage += 1;
    _DelayFrames := 4;
  end;

  if _CurrentImage = 4 then
  begin
    _CurrentImage := 0;
  end;

  Result := _Images[_CurrentImage]^.pixels;
end;

function TDataStream.LoadMedia(): boolean;
var
  success: boolean;
  i: integer;
  path: string;
  loadedSurface: PSDL_Surface;
begin
  success := true;

  for i := 0 to 3 do
  begin
    path := '';
    path := '../Source/42_texture_streaming/foo_walk_' + i.ToString + '.png';

    loadedSurface := PSDL_Surface(nil);
    loadedSurface := IMG_Load(CrossFixFileName(path).ToPAnsiChar);
    if loadedSurface = nil then
    begin
      WriteLnF('Unable to load %s! SDL_image error: %s', [path, SDL_GetError()]);
      success := false;
    end
    else
    begin
      _Images[i] := SDL_ConvertSurfaceFormat(loadedSurface, SDL_PIXELFORMAT_RGBA8888, 0);
    end;

    SDL_FreeSurface(loadedSurface);
  end;

  Result := success;
end;

end.
