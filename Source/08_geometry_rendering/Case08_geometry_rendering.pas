unit Case08_geometry_rendering;

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
  libSDL2,
  libSDL2_image;

const
  SCREEN_WIDTH = 640;
  SCREEN_HEIGHT = 480;

var
  // The window we'll be rendering to
  gWindow: PSDL_Window = nil;
  // The window renderer
  gRenderer: PSDL_Renderer = nil;

function Init(): boolean; forward;
// Loads media
function LoadMedia(): boolean; forward;
// Frees media and shuts down SDL
procedure Close(); forward;

procedure Main;
var
  e: TSDL_Event;
  quit: boolean;
  fillRect, outlineRect: TSDL_Rect;
  i: Integer;
begin
  if not Init then
  begin
    WriteLn('Failed to initialize!');
    Exit;
  end;

  if not LoadMedia then
  begin
    WriteLn('Failed to load media!');
    Exit;
  end;

  e := Default(TSDL_Event);
  quit := boolean(false);

  while not quit do
  begin
    while SDL_PollEvent(@e) <> 0 do
    begin
      if e.type_ = SDL_QUIT_EVENT then
        quit := true;
    end;

    //Clear screen
    SDL_SetRenderDrawColor(gRenderer, $FF, $FF, $FF, $FF);
    SDL_RenderClear(gRenderer);

    // Render red filled quad
    fillRect := Default(TSDL_Rect);
    with fillRect do
    begin
      x := SCREEN_WIDTH div 4;
      y := SCREEN_HEIGHT div 4;
      w := SCREEN_WIDTH div 2;
      h := SCREEN_HEIGHT div 2;
    end;
    SDL_SetRenderDrawColor(gRenderer, $FF, $00, $00, $FF);
    SDL_RenderFillRect(gRenderer, @fillRect);

    // Render green outlined quad
    outlineRect := Default(TSDL_Rect);
    with outlineRect do
    begin
      x := SCREEN_WIDTH div 6;
      y := SCREEN_HEIGHT div 6;
      w := trunc(SCREEN_WIDTH * 2 / 3);
      h := trunc(SCREEN_HEIGHT * 2 / 3);
    end;
    SDL_SetRenderDrawColor(gRenderer, $00, $00, $00, $FF);
    SDL_RenderDrawRect(gRenderer, @outlineRect);

    // Draw blue horizontal line
    SDL_SetRenderDrawColor(gRenderer, $00, $00, $FF, $FF);
    SDL_RenderDrawLine(gRenderer, 0, SCREEN_HEIGHT div 2, SCREEN_WIDTH, SCREEN_HEIGHT div 2);

    // Draw vertical line of yellow dots
    SDL_SetRenderDrawColor(gRenderer, $FF, $FF, $00, $FF);
    i := integer(0);
    while i < SCREEN_HEIGHT do
    begin
      SDL_RenderDrawPoint(gRenderer, SCREEN_WIDTH div 2, i);
      i += 4;
    end;

    //Update screen
    SDL_RenderPresent(gRenderer);
  end;

  Close;
end;

function Init(): boolean;
var
  success: boolean;
  imgFlags: integer;
begin
  success := boolean(true);

  if SDL_Init(SDL_INIT_VIDEO) < 0 then
  begin
    WriteLnF('SDL could not initialize! SDL_Error: %s', [SDL_GetError()]);
    Exit(false);
  end;

  // Set texture filtering to linear
  if not SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, '1') then
    WriteLn('Warning: Linear texture filtering not enabled!');

  // Create window
  gWindow := SDL_CreateWindow('SDL Tutorial', SDL_WINDOWPOS_UNDEFINED,
    SDL_WINDOWPOS_UNDEFINED, SCREEN_WIDTH, SCREEN_HEIGHT, SDL_WINDOW_SHOWN);
  if gWindow = nil then
  begin
    WriteLn('Window could not be created! SDL_Error: ', SDL_GetError);
    Exit(false);
  end;

  // Create renderer for window
  gRenderer := SDL_CreateRenderer(gWindow, -1, SDL_RENDERER_ACCELERATED);
  if gRenderer = nil then
  begin
    WriteLn('Renderer could not be created! SDL Error:', SDL_GetError);
    Exit(false);
  end;

  // Initialize renderer color
  SDL_SetRenderDrawColor(gRenderer, $FF, $FF, $FF, $FF);

  //Initialize PNG loading
  imgFlags := integer(0);
  imgFlags := IMG_INIT_PNG;
  if not (IMG_Init(imgFlags) and imgFlags).ToBoolean then
  begin
    WriteLn('SDL_image could not initialize! SDL_image Error.');
    Exit(false);
  end;

  Result := success;
end;

function LoadMedia(): boolean;
var
  success: boolean;
begin
  success := boolean(true);

  Result := success;
end;

procedure Close();
begin
  //Destroy window
  SDL_DestroyRenderer(gRenderer);
  SDL_DestroyWindow(gWindow);
  gWindow := nil;
  gRenderer := nil;

  // Quit SDL subsystems
  IMG_Quit();
  SDL_Quit();
end;

end.
