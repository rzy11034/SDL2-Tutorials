unit Case05_optimized_surface_loading_and_soft_stretching;

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
  libSDL2;

const
  SCREEN_WIDTH = 640;
  SCREEN_HEIGHT = 480;

var
  //The window we'll be rendering to
  gWindow: PSDL_Window = nil;
  //The surface contained by the window
  gScreenSurface: PSDL_Surface = nil;
  //Current displayed image
  gStretchedSurface: PSDL_Surface = nil;

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
  quit: Boolean;
  stretchRect: TSDL_Rect;
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

      while not quit do
      begin
        while SDL_PollEvent(@e) <> 0 do
        begin
          if e.type_ = SDL_QUIT_EVENT then
          begin
            quit := true;
          end;
        end;

        stretchRect := Default(TSDL_Rect);
        stretchRect.x := 0;
        stretchRect.y := 0;
        stretchRect.w := SCREEN_WIDTH;
        stretchRect.h := SCREEN_HEIGHT;
        SDL_UpperBlitScaled(gStretchedSurface, nil, gScreenSurface, @stretchRect);

        SDL_UpdateWindowSurface(gWindow);
      end;
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
  imgStretch  = '../Source/05_optimized_surface_loading_and_soft_stretching/stretch.bmp';
var
  success: boolean;
begin
  success := boolean(true);

  // Load stretching surface
  gStretchedSurface := LoadSurface(imgStretch);
  if gStretchedSurface = nil then
  begin
    WriteLn('Failed to load stretching image!');
    Exit(false);
  end;

  Result := success;
end;

procedure Close();
begin
  //Free loaded image
  SDL_FreeSurface(gStretchedSurface);
  gStretchedSurface := nil;

  // Destroy window
  SDL_DestroyWindow(gWindow);
  gWindow := nil;

  // Quit SDL subsystems
  SDL_Quit();
end;

function LoadSurface(path: string): PSDL_Surface;
var
  optimizedSurface, loadedSurface: PSDL_Surface;
begin
  optimizedSurface := PSDL_Surface(nil);

  loadedSurface := SDL_LoadBMP(CrossFixFileName(path).ToPAnsiChar);
  if loadedSurface = nil then
  begin
    WriteLnF('Unable to load image %s! SDL Error: %s', [path, SDL_GetError()]);
  end
  else
  begin
    optimizedSurface := SDL_ConvertSurface(loadedSurface, gScreenSurface^.format, 0);
    if optimizedSurface = nil then
    begin
      WriteLnF('Unable to optimize image %s! SDL Error: %s', [path, SDL_GetError()]);
      SDL_FreeSurface(loadedSurface);
    end;
  end;

  Result := optimizedSurface;
end;

end.

