unit Case43_render_to_texture;

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
  SDL2_Tutorials.Utils,
  Case43_render_to_texture.Texture;

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
  gTargetTexture: TTexture;

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
  if not gTargetTexture.CreateBlank(SCREEN_WIDTH, SCREEN_HEIGHT, SDL_TEXTUREACCESS_TARGET) then
  begin
    WriteLn('Failed to create target texture!');
    success := false;
  end;

  Result := success;
end;

procedure Close();
begin
  //Free loaded images
	gTargetTexture.Free();

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

procedure Main;
var
  quit: boolean;
  e: TSDL_Event;
  angle: double;
  screenCenter: TSDL_Point;
  fillRect, outlineRect: TSDL_Rect;
  i: Integer;
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
      quit := boolean(false);

      // Event handler
      e := Default(TSDL_Event);

      //Rotation variables
      angle := double(0);
      screenCenter := SDL_Point(SCREEN_WIDTH div 2, SCREEN_HEIGHT div 2);

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

        angle += 2;
        if angle > 360 then
          angle -= 360;

        //Set self as render target
        gTargetTexture.setAsRenderTarget();

        //Clear screen
        SDL_SetRenderDrawColor(gRenderer, $FF, $FF, $FF, $FF);
        SDL_RenderClear(gRenderer);

        //Render red filled quad
        fillRect := SDL_Rect(
          SCREEN_WIDTH div 4,
          SCREEN_HEIGHT div 4,
          SCREEN_WIDTH div 2,
          SCREEN_HEIGHT div 2);
        SDL_SetRenderDrawColor(gRenderer, $FF, $00, $00, $FF);
        SDL_RenderFillRect(gRenderer, @fillRect);

        //Render green outlined quad
        outlineRect := SDL_Rect(
          SCREEN_WIDTH div 6,
          SCREEN_HEIGHT div 6,
          SCREEN_WIDTH * 2 div 3,
          SCREEN_HEIGHT * 2 div 3);
        SDL_SetRenderDrawColor(gRenderer, $00, $FF, $00, $FF);
        SDL_RenderDrawRect(gRenderer, @outlineRect);

        //Draw blue horizontal line
        SDL_SetRenderDrawColor(gRenderer, $00, $00, $FF, $FF);
        SDL_RenderDrawLine(gRenderer, 0, SCREEN_HEIGHT div 2,
          SCREEN_WIDTH, SCREEN_HEIGHT div 2);

        //Draw vertical line of yellow dots
        SDL_SetRenderDrawColor(gRenderer, $FF, $FF, $00, $FF);

        i := 0; while i < SCREEN_HEIGHT do
        begin
          SDL_RenderDrawPoint(gRenderer, SCREEN_WIDTH div 2, i);
          i += 4;
        end;

        //Reset render target
        SDL_SetRenderTarget(gRenderer, nil);

        //Show rendered to texture
        gTargetTexture.render(0, 0, nil, angle, @screenCenter);

        //Update screen
        SDL_RenderPresent(gRenderer);
      end;
    end;
  end;

  // Free resources and close SDL
  Close();
end;

end.
