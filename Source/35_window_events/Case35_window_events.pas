unit Case35_window_events;

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
  libSDL2_ttf,
  libSDL2_image,
  libSDL2_mixer,
  DeepStar.Utils,
  DeepStar.UString,
  Case35_window_events.Windows,
  Case35_window_events.Texture;

var
  // The window we'll be rendering to
  gWindow: TWindows = nil;

  // The window renderer
  gRenderer: PSDL_Renderer = nil;

  // Scene texture
  gSceneTexture: TTexture = nil;

// Starts up SDL and creates window
function Init(): boolean; forward;
// Loads media
function LoadMedia(): boolean; forward;
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
    gSceneTexture := TTexture.Create(gRenderer);

    // Load media
    if not loadMedia then
    begin
      WriteLn('Failed to load media!');
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
        end;

        //Only draw when not minimized
        if not gWindow.IsMinimized then
        begin
          // Clear screen
          SDL_SetRenderDrawColor(gRenderer, $FF, $FF, $FF, $FF);
          SDL_RenderClear(gRenderer);

          //Render prompt centered at the top of the screen
          gSceneTexture.render((SCREEN_WIDTH - gSceneTexture.GetWidth) div 2, 0);

          // Update screen
          SDL_RenderPresent(gRenderer);
        end;
      end;
    end;
  end;

  // Free resources and close SDL
  Close();
end;

function Init(): boolean;
var
  success: boolean;
  imgFlags: integer;
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
    gWindow := TWindows.Create;

    if not gWindow.Init then
    begin
      WriteLn('Window could not be created! SDL_Error: ', SDL_GetError);
      success := false;
    end
    else
    begin
      // Create renderer for window
      gRenderer := gWindow.createRenderer;
      if gRenderer = nil then
      begin
        WriteLn('Renderer could not be created! SDL Error:', SDL_GetError);
        success := false;
      end
      else
      begin
        // Initialize renderer color
        SDL_SetRenderDrawColor(gRenderer, $FF, $FF, $FF, $FF);

        //Initialize PNG loading
        imgFlags := integer(0);
        imgFlags := IMG_INIT_PNG;
        if not (IMG_Init(imgFlags) and imgFlags).ToBoolean then
        begin
          WriteLn('SDL_image could not initialize! SDL_image Error.');
          success := false;
        end;

        // Initialize SDL_ttf
        if TTF_Init() = -1 then
        begin
          WriteLnF('SDL_ttf could not initialize! SDL_ttf Error: %s', [SDL_GetError()]);
          success := false;
        end;
      end;
    end;
  end;

  Result := success;
end;

function LoadMedia(): boolean;
const
  imgWindow = '../Source/35_window_events/window.png';
var
  success: boolean;
begin
  // Loading success flag
  success := boolean(true);

  //Load scene texture
  if not gSceneTexture.LoadFromFile(CrossFixFileName(imgWindow).ToPAnsiChar) then
  begin
    WriteLn('Failed to load window texture!');
    success := false;
  end;

  Result := success;
end;

procedure Close();
begin
  gSceneTexture.Free;

  //Destroy window
  SDL_DestroyRenderer(gRenderer);
  gRenderer := nil;

  gWindow.Free;

  // Quit SDL subsystems
  TTF_Quit();
  IMG_Quit();
  SDL_Quit();
end;

end.
