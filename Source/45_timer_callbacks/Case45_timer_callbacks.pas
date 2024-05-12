unit Case45_timer_callbacks;

{$mode ObjFPC}{$H+}
{$ModeSwitch unicodestrings}{$J-}

interface

uses
  Classes,
  SysUtils,
  libSDL2,
  libSDL2_ttf,
  libSDL2_image,
  DeepStar.Utils,
  Case45_timer_callbacks.Texture;

const
  //Screen dimension constants
  SCREEN_WIDTH = 640;
  SCREEN_HEIGHT = 480;

var
  //The window we'll be rendering to
  gWindow: PSDL_Window;

  //The window renderer
  gRenderer: PSDL_Renderer;

  // Font
  gFont: PTTF_Font;

  //Scene textures
  gSplashTexture: TTexture;

procedure Main;
// Starts up SDL and creates window
function Init(): boolean;
//Loads media
function LoadMedia(): boolean;
// Frees media and shuts down SDL
procedure Close();

implementation

function Init(): boolean;
var
  success: boolean;
  imgFlags: integer;
begin
  success := boolean(true);

  // Initialize SDL
  if SDL_Init(SDL_INIT_VIDEO or SDL_INIT_TIMER) < 0 then
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

    //Create window
    gWindow := SDL_CreateWindow(
      'SDL Tutorial',
      SDL_WINDOWPOS_UNDEFINED,
      SDL_WINDOWPOS_UNDEFINED,
      SCREEN_WIDTH, SCREEN_HEIGHT,
      SDL_WINDOW_SHOWN);

    if gWindow = nil then
    begin
      WriteLn('Window could not be created! SDL Error: %s', SDL_GetError());
      success := false;
    end
    else
    begin
      //Create renderer for window
      gRenderer := SDL_CreateRenderer(gWindow, -1, SDL_RENDERER_ACCELERATED or SDL_RENDERER_PRESENTVSYNC);

      if gRenderer = nil then
      begin
        WriteLn('Renderer could not be created! SDL Error: %s', SDL_GetError());
        success := false;
      end
      else
      begin
        //Initialize renderer color
        SDL_SetRenderDrawColor(gRenderer, $FF, $FF, $FF, $FF);

        //Initialize PNG loading
        imgFlags := IMG_INIT_PNG;
        if not (IMG_Init(imgFlags) or imgFlags).ToBoolean then
        begin
          WriteLn('SDL_image could not initialize! SDL_image Error: %s', SDL_GetError());
          success := false;
        end;
      end;
    end;
  end;

  Result := success;
end;

function LoadMedia: boolean;
var
  success: boolean;
begin
  //Loading success flag
  success := true;

  //Load blank texture
  if not gSplashTexture.LoadFromFile('../Source/45_timer_callbacks/splash.png') then
  begin
    WriteLn('Failed to load dot texture!');
    success := false;
  end;

  Result := success;
end;

procedure Close();
begin
  //Free loaded images
  gSplashTexture.Free();

  //Destroy window
  SDL_DestroyRenderer(gRenderer);
  SDL_DestroyWindow(gWindow);
  gWindow := nil;
  gRenderer := nil;

  // Quit SDL subsystems
  TTF_Quit();
  IMG_Quit();
  SDL_Quit();
end;

function Callback(interval: UInt32; param: Pointer): UInt32; cdecl;
begin
  //Print callback message
  WriteLnF('Callback called back with message: %s', [PString(param)^]);

  Result := 0;
end;

procedure Main;
var
  quit: boolean;
  e: TSDL_Event;
  timerID: TSDL_TimerID;
  str: String;
begin
  // Start up SDL and create window
  if not Init then
  begin
    WriteLn('Failed to initialize!');
  end
  else
  begin
    //Load media
    if not loadMedia() then
    begin
      WriteLn('Failed to load media!');
    end
    else
    begin
      // Main loop flag
      quit := false;
      //Event handler
      e := Default(TSDL_Event);

      str := '3 seconds waited!';
      timerID := Default(TSDL_TimerID);
      timerID := SDL_AddTimer(3 * 1000, @Callback, Pointer(@str));

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
        end;

        //Clear screen
        SDL_SetRenderDrawColor(gRenderer, $FF, $FF, $FF, $FF);
        SDL_RenderClear(gRenderer);

        //Render splash
        gSplashTexture.render(0, 0);

        //Update screen
        SDL_RenderPresent(gRenderer);
      end;

      //Remove timer in case the call back was not called
      SDL_RemoveTimer(timerID);
    end;
  end;

  // Free resources and close SDL
  Close();
end;

end.
