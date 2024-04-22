unit Case37_multiple_displays;

{$mode ObjFPC}{$H+}
{$ModeSwitch unicodestrings}{$J-}

interface

uses
  Classes,
  SysUtils;

procedure Main;

implementation

uses
  libSDL2,
  DeepStar.Utils,
  Case37_multiple_displays.Windows;

var
  //Our custom window
  gWindow: TWindows;

  //Display data
  gTotalDisplays: integer;
  gDisplayBounds: TWindows.TArr_TSDL_Rect;

// Starts up SDL and creates window
function Init(): boolean; forward;
// Frees media and shuts down SDL
procedure Close(); forward;

procedure Main;
var
  quit: boolean;
  e: TSDL_Event;
begin
  // Start up SDL and create window
  if not Init then
  begin
    WriteLn('Failed to initialize!');
  end
  else
  begin
    // Main loop flag
    quit := boolean(false);

    // Event handler
    e := Default(TSDL_Event);

    // While application is running
    while not quit do
    begin
      while SDL_PollEvent(@e) <> 0 do
      begin
        if e.type_ = SDL_QUIT_EVENT then
        begin
          quit := true;
        end
        else if e.type_ = SDL_KEYDOWN then
        begin
          case e.key.keysym.sym of
            SDLK_ESCAPE: quit := true;
          end;
        end;

        //Handle window events
        gWindow.HandleEvent(e);

        //Update window
        gWindow.Render();
      end;
    end;
  end;

  // Free resources and close SDL
  Close();
end;

function Init(): boolean;
var
  success: boolean;
  i: integer;
begin
  success := boolean(true);

  // Initialize SDL
  if SDL_Init(SDL_INIT_VIDEO) < 0 then
  begin
    WriteLnF('SDL could not initialize! SDL_Error: %s', [SDL_GetError()]);
    success := false;
  end
  else
  begin
    // Set texture filtering to linear
    if not SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, '1') then
    begin
      WriteLn('Warning: Linear texture filtering not enabled!');
    end;

    //Get number of displays
    gTotalDisplays := SDL_GetNumVideoDisplays();
    if gTotalDisplays < 2 then
      WriteLn('Warning: Only one display connected!');

    //Get bounds of each display
    SetLength(gDisplayBounds, gTotalDisplays);
    for i := 0 to gTotalDisplays - 1 do
      SDL_GetDisplayBounds(i, @gDisplayBounds[i]);

    //Create window
    gWindow := TWindows.Create;
    if not gWindow.Init then
    begin
      WriteLn('Window could not be created!');
      success := false;
    end;
  end;

  Result := success;
end;

procedure Close();
begin
  gWindow.Free;

  // Quit SDL subsystems
  SDL_Quit();
end;

end.
