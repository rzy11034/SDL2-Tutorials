unit Case01_hello_SDL;

{$mode ObjFPC}{$H+}

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

procedure Main;
var
  window: PSDL_Window;
  screenSurface: PSDL_Surface;
  e: TSDL_Event;
  quit: Boolean;
begin
  //The window we'll be rendering to
  window := PSDL_Window(nil);

  //The surface contained by the window
  screenSurface := PSDL_Surface(nil);

  //Initialize SDL
  if SDL_Init(SDL_INIT_VIDEO) < 0 then
    WriteLnF('SDL could not initialize! SDL_Error: %s', [SDL_GetError()])
  else
  begin
    // Create window
    window := SDL_CreateWindow('SDL Tutorial', SDL_WINDOWPOS_UNDEFINED,
      SDL_WINDOWPOS_UNDEFINED, SCREEN_WIDTH, SCREEN_HEIGHT, SDL_WINDOW_SHOWN);

    if window = nil then
      WriteLnF('Window could not be created! SDL_Error: %s', [SDL_GetError()])
    else
    begin
      // Get window surface
      screenSurface := SDL_GetWindowSurface(window);

      // Fill the surface white
      SDL_FillRect(screenSurface, nil, SDL_MapRGB(screenSurface^.format,
        $FF, $FF, $FF));

      // Update the surface
      SDL_UpdateWindowSurface(window);

      // Hack to get window to stay up
      e := Default(TSDL_Event);
      quit := Boolean(false);

      while quit = false do
      begin
        while SDL_PollEvent(@e) <> 0 do
        begin
          if e.type_ = SDL_QUIT_EVENT then quit := true;
        end;
      end;
    end;
  end;

  //Destroy window
  SDL_DestroyWindow(window);

  //Quit SDL subsystems
  SDL_Quit;
end;

end.
