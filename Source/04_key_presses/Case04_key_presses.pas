unit Case04_key_presses;

{$mode ObjFPC}{$H+}
{$ModeSwitch unicodestrings}{$J-}

interface

uses
  Classes,
  SysUtils;

procedure Main;

implementation

uses
  DeepStar.Utils,
  DeepStar.UString,
  libSDL2;

const
  SCREEN_WIDTH = 640;
  SCREEN_HEIGHT = 480;

type
  KeyPressSurfaces = (
    KEY_PRESS_SURFACE_DEFAULT,
    KEY_PRESS_SURFACE_UP,
    KEY_PRESS_SURFACE_DOWN,
    KEY_PRESS_SURFACE_LEFT,
    KEY_PRESS_SURFACE_RIGHT,
    KEY_PRESS_SURFACE_TOTAL);

var
  //The window we'll be rendering to
  gWindow: PSDL_Window = nil;
  //The surface contained by the window
  gScreenSurface: PSDL_Surface = nil;
  //Current displayed image
  gCurrentSurface: PSDL_Surface = nil;

  gKeyPressSurfaces: array [KeyPressSurfaces] of PSDL_Surface = (nil, nil, nil, nil, nil, nil);

// Starts up SDL and creates window
function Init(): boolean; forward;
// Loads media
function LoadMedia(): boolean; forward;
// Frees media and shuts down SDL
procedure Close(); forward;
// Loads individual image
function LoadSurface(path: string): PSDL_Surface; forward;

procedure Main;
var
  e: TSDL_Event;
  quit: boolean;
begin
  if not Init then
  begin
    WriteLn('Failed to initialize!');
  end
  else
  begin
    if not LoadMedia then
    begin
      WriteLn('Failed to load media!');
    end
    else
    begin
      e := Default(TSDL_Event);
      quit := boolean(false);

      repeat
        while SDL_PollEvent(@e) <> 0 do
        begin
          if e.type_ = SDL_QUIT_EVENT then
          begin
            quit := true;
          end
          else if e.type_ = SDL_KEYDOWN then
          begin
            case e.key.keysym.sym of
              SDLK_UP: gCurrentSurface := gKeyPressSurfaces[KEY_PRESS_SURFACE_UP];
              SDLK_DOWN: gCurrentSurface := gKeyPressSurfaces[KEY_PRESS_SURFACE_DOWN];
              SDLK_LEFT: gCurrentSurface := gKeyPressSurfaces[KEY_PRESS_SURFACE_LEFT];
              SDLK_RIGHT: gCurrentSurface := gKeyPressSurfaces[KEY_PRESS_SURFACE_RIGHT];
              else
                gCurrentSurface := gKeyPressSurfaces[KEY_PRESS_SURFACE_DEFAULT]
            end;
          end;
        end;

        SDL_UpperBlit(gCurrentSurface, nil, gScreenSurface, nil);
        SDL_UpdateWindowSurface(gWindow);

      until quit = true;
    end;
  end;

  Close;
end;

function Init: boolean;
var
  success: boolean;
begin
  success := boolean(true);

  //Initialize SDL
  if SDL_Init(SDL_INIT_VIDEO) < 0 then
  begin
    WriteLnF('SDL could not initialize! SDL_Error: %s', [SDL_GetError()]);
    Exit(false);
  end
  else
  begin
    // Create window
    gWindow := SDL_CreateWindow('SDL Tutorial', SDL_WINDOWPOS_UNDEFINED,
      SDL_WINDOWPOS_UNDEFINED, SCREEN_WIDTH, SCREEN_HEIGHT, SDL_WINDOW_SHOWN);

    if gWindow = nil then
    begin
      WriteLnF('Window could not be created! SDL_Error: %s', [SDL_GetError()]);
      Exit(false);
    end
    else
      gScreenSurface := SDL_GetWindowSurface(gWindow);
  end;

  Result := success;
end;

function LoadMedia: boolean;
const
  imgDefault  = '../Source/04_Key_Presses/press.bmp';
  imgUp       = '../Source/04_Key_Presses/up.bmp';
  imgDown     = '../Source/04_Key_Presses/down.bmp';
  imgLeft     = '../Source/04_Key_Presses/left.bmp';
  imgRight    = '../Source/04_Key_Presses/right.bmp';
var
  success: boolean;
begin
  success := boolean(true);

  // Load default surface
  gKeyPressSurfaces[KEY_PRESS_SURFACE_DEFAULT] := LoadSurface(imgDefault);
  if gKeyPressSurfaces[KEY_PRESS_SURFACE_DEFAULT] = nil then
  begin
    WriteLn('Failed to load default image!');
    Exit(false);
  end;

  // Load down surface
  gKeyPressSurfaces[KEY_PRESS_SURFACE_DOWN] := LoadSurface(imgDown);
  if gKeyPressSurfaces[KEY_PRESS_SURFACE_DOWN] = nil then
  begin
    WriteLn('Failed to load down image!');
    Exit(false);
  end;

  // Load left surface
  gKeyPressSurfaces[KEY_PRESS_SURFACE_LEFT] := LoadSurface(imgLeft);
  if gKeyPressSurfaces[KEY_PRESS_SURFACE_LEFT] = nil then
  begin
    WriteLn('Failed to load left image!');
    Exit(false);
  end;

  // Load up surface
  gKeyPressSurfaces[KEY_PRESS_SURFACE_UP] := LoadSurface(imgUp);
  if gKeyPressSurfaces[KEY_PRESS_SURFACE_UP] = nil then
  begin
    WriteLn('Failed to load up image!');
    Exit(false);
  end;

  // Load right surface
  gKeyPressSurfaces[KEY_PRESS_SURFACE_RIGHT] := LoadSurface(imgRight);
  if gKeyPressSurfaces[KEY_PRESS_SURFACE_RIGHT] = nil then
  begin
    WriteLn('Failed to load right image!');
    Exit(false);
  end;

  Result := success;
end;

procedure Close();
var
  i: integer;
begin
  for i := 0 to Length(gKeyPressSurfaces) - 1 do
  begin
    if gKeyPressSurfaces[KeyPressSurfaces(i)] <> nil then
    begin
      SDL_FreeSurface(gKeyPressSurfaces[KeyPressSurfaces(i)]);
      gKeyPressSurfaces[KeyPressSurfaces(i)] := nil;
    end;
  end;

  // Destroy window
  SDL_DestroyWindow(gWindow);
  gWindow := nil;

  // Quit SDL subsystems
  SDL_Quit();
end;

function LoadSurface(path: string): PSDL_Surface;
var
  res: PSDL_Surface;
begin
  res := PSDL_Surface(nil);

  res := SDL_LoadBMP(CrossFixFileName(path).ToPAnsiChar);
  if res = nil then
  begin
    WriteLnF('Unable to load image %s! SDL Error: %s', [path, SDL_GetError()]);
    Exit(nil);
  end;

  Result := res;
end;

end.
