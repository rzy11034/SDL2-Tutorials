unit Case09_the_viewport;

{$mode ObjFPC}{$H+}
{$ModeSwitch unicodestrings}{$J-}

interface

uses
  Classes, SysUtils;

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
  // Current displayed texture
  gTexture:PSDL_Texture = nil;

// Starts up SDL and creates window
function Init(): boolean; forward;
// Loads media
function LoadMedia(): boolean; forward;
// Frees media and shuts down SDL
procedure Close(); forward;
// Loads individual image as texture
function LoadTexture(path: string): PSDL_Texture; forward;

procedure Main;
var
  topLeftViewport, bottomViewport, topRightViewport: TSDL_Rect;
  e: TSDL_Event;
  quit: Boolean;
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

    // Top left corner viewport
    topLeftViewport := Default(TSDL_Rect);
    with topLeftViewport do
    begin
      x := 0;
      y := 0;
      w := SCREEN_WIDTH div 2;
      h := SCREEN_HEIGHT div 2;
    end;
    SDL_RenderSetViewport(gRenderer, @topLeftViewport);

    //Render texture to screen
		SDL_RenderCopy(gRenderer, gTexture, nil, nil);

    // Top right viewport
    topRightViewport := Default(TSDL_Rect);
    with topRightViewport do
    begin
      x := SCREEN_WIDTH div 2;
      y := 0;
      w := SCREEN_WIDTH div 2;
      h := SCREEN_HEIGHT div 2;
    end;
    SDL_RenderSetViewport(gRenderer, @topRightViewport);

    //Render texture to screen
		SDL_RenderCopy(gRenderer, gTexture, nil, nil);

    // Bottom viewport
    bottomViewport := Default(TSDL_Rect);
    with bottomViewport do
    begin
      x := 0;
      y := SCREEN_HEIGHT div 2;
      w := SCREEN_WIDTH;
      h := SCREEN_HEIGHT div 2;
    end;
    SDL_RenderSetViewport(gRenderer, @bottomViewport);

    // Render texture to screen
		SDL_RenderCopy(gRenderer, gTexture, nil, nil);

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
const
  img = '../Source/09_the_viewport/viewport.png';
var
  success: boolean;
begin
  success := boolean(true);

  // Load PNG texture
  gTexture := LoadTexture(img);
  if gTexture = nil then
  begin
    WriteLn('Failed to load texture image!');
    Exit(false);
  end;

  Result := success;
end;

procedure Close();
begin
  // Free loaded image
  SDL_DestroyTexture(gTexture);
  gTexture := nil;

  //Destroy window
  SDL_DestroyRenderer(gRenderer);
  SDL_DestroyWindow(gWindow);
  gWindow := nil;
  gRenderer := nil;

  // Quit SDL subsystems
  IMG_Quit();
  SDL_Quit();
end;

function LoadTexture(path: string): PSDL_Texture;
var
  loadedSurface: PSDL_Surface;
  newTexture: PSDL_Texture;
begin
	// Load image at specified path
  loadedSurface := PSDL_Surface(nil);
	loadedSurface := IMG_Load(path.ToPAnsiChar);
  if loadedSurface = nil then
  begin
    WriteLnF('Unable to load image %s! SDL_image Error.', [path]);
    Exit(nil);
  end;

  // The final texture
  // Create texture from surface pixels
  try
    newTexture := PSDL_Texture(nil);
    newTexture := SDL_CreateTextureFromSurface(gRenderer, loadedSurface);
    if newTexture = nil then
    begin
      WriteLnF('Unable to create texture from %s! SDL Error: %s', [path, SDL_GetError()]);
      Exit(nil);
    end;
  finally
    // Get rid of old loaded surface
    SDL_FreeSurface(loadedSurface);
  end;

	Result := newTexture;
end;

end.

