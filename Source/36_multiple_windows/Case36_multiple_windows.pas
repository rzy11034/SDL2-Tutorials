unit Case36_multiple_windows;

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
  DeepStar.UString,
  Case36_multiple_windows.Windows;

const
  TOTAL_WINDOWS = 3;

var
  //Our custom windows
  gWindows: array[0..TOTAL_WINDOWS - 1] of TWindows;

// Starts up SDL and creates window
function Init(): boolean; forward;
// Frees media and shuts down SDL
procedure Close(); forward;

procedure Main;
var
  quit, allWindowsClosed: boolean;
  e: TSDL_Event;
  i: integer;
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
        for i := 0 to TOTAL_WINDOWS - 1 do
          gWindows[i].HandleEvent(e);

        //Pull up window
        if e.type_ = SDL_KEYDOWN then
        begin
          case e.key.keysym.sym of
            SDLK_1: gWindows[0].Focus();
            SDLK_2: gWindows[1].Focus();
            SDLK_3: gWindows[2].Focus();
          end;
        end;
      end;

      //Update all windows
      for i := 0 to TOTAL_WINDOWS - 1 do
        gWindows[i].Render();

      //Check all windows
      allWindowsClosed := true;
      for i := 0 to TOTAL_WINDOWS - 1 do
      begin
        if gWindows[i].IsShown() then
        begin
          allWindowsClosed := false;
          Break;
        end;
      end;

      //Application closed all windows
      if allWindowsClosed then
        quit := true;
    end;
  end;

  // Free resources and close SDL
  Close();
end;

function Init(): boolean;
var
  success, flag: boolean;
  imgFlags, i: integer;
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

    // Create window
    for i := 0 to High(gWindows) do
    begin
      gWindows[i] := TWindows.Create;
      flag := gWindows[i].Init;

      if not flag then
      begin
        WriteLn('Window 0 could not be created!');
        success := false;
        Break;
      end;
    end;
  end;

  Result := success;
end;

procedure Close();
var
  i: Integer;
begin
  for i := 0 to TOTAL_WINDOWS - 1 do
  begin
    gWindows[i].Free;
  end;

  // Quit SDL subsystems
  SDL_Quit();
end;

end.
