﻿unit Case40_texture_manipulation;

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
  Case40_texture_manipulation.Texture;

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
  gFooTexture: TTexture;

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
  pixels: PUInt32;
  pixelCount, i: integer;
  colorKey, transparent: uint32;
begin
  //Loading success flag
  success := true;

  //Load dot texture
  if not gFooTexture.loadPixelsFromFile('../Source/40_texture_manipulation/foo.png') then
  begin
    WriteLn('Failed to load Foo'' texture!');
    success := false;
  end
  else
  begin
    //Get pixel data
    pixels := gFooTexture.GetPixels32();
    pixelCount := gFooTexture.GetPitch32() * gFooTexture.GetHeight();

    //Map colors
    colorKey := gFooTexture.MapRGBA($FF, $00, $FF, $FF);
    transparent := gFooTexture.MapRGBA($FF, $FF, $FF, $00);

    //Color key pixels
    for i := 0 to pixelCount - 1 do
    begin
      if pixels[i] = colorKey then
        pixels[i] := transparent;
    end;

    //Create texture from manually color keyed pixels
    if not gFooTexture.loadFromPixels() then
    begin
      WriteLn('Unable to load Foo'' texture from surface!');
    end;
  end;

  Result := success;
end;

procedure Close();
begin
  //Free loaded images
  gFooTexture.Free();

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

        //Render stick figure
        gFooTexture.render(
          (SCREEN_WIDTH - gFooTexture.GetWidth()) div 2,
          (SCREEN_HEIGHT - gFooTexture.GetHeight()) div 2);

        //Update screen
        SDL_RenderPresent(gRenderer);
      end;
    end;
  end;

  // Free resources and close SDL
  Close();
end;

end.
