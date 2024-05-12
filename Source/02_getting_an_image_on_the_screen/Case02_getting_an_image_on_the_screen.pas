unit Case02_getting_an_image_on_the_screen;

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
  //The image we will load and show on the screen
  gHelloWorld: PSDL_Surface = nil;

//Starts up SDL and creates window
function Init(): boolean; forward;
//Loads media
function LoadMedia(): boolean; forward;
//Frees media and shuts down SDL
procedure Close(); forward;

procedure Main;
var
  e: TSDL_Event;
  quit: boolean;
begin
  //Start up SDL and create window
  if not Init then
    WriteLn('Failed to initialize!')
  else
  if not LoadMedia then
    WriteLn('Failed to load media!')
  else
  begin
    // Apply the image
    SDL_UpperBlit(gHelloWorld, nil, gScreenSurface, nil);

    // Update the surface
    SDL_UpdateWindowSurface(gWindow);

    // Hack to get window to stay up
    e := Default(TSDL_Event);
    quit := boolean(false);

    while quit = false do
      while SDL_PollEvent(@e) <> 0 do
        if e.type_ = SDL_QUIT_EVENT then
          quit := true;
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
  filename = '../Source/02_getting_an_image_on_the_screen/hello_world.bmp';
var
  success: boolean;
begin
  success := boolean(true);
  gHelloWorld := SDL_LoadBMP(CrossFixFileName(filename).ToPAnsiChar);

  if gHelloWorld = nil then
  begin
    WriteLnF('Unable to load image %s! SDL Error: %s', [SDL_GetError(), SDL_GetError()]);
    WriteLn(filename);
    Exit(false);
  end;

  Result := success;
end;

procedure Close();
begin
  //Deallocate surface
  SDL_FreeSurface(gHelloWorld);
  gHelloWorld := nil;

  //Destroy window
  SDL_DestroyWindow(gWindow);
  gWindow := nil;

  //Quit SDL subsystems
  SDL_Quit();
end;

end.
