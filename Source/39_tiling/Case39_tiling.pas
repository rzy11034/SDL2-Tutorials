unit Case39_tiling;

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
  Case39_tiling.Texture,
  Case39_tiling.Tile;

type
  TArr_Tile = array of TTile;

const
  //Screen dimension constants
  SCREEN_WIDTH = 640;
  SCREEN_HEIGHT = 480;

  //The dimensions of the level
  LEVEL_WIDTH = 1280;
  LEVEL_HEIGHT = 960;

  //Tile constants
  TILE_WIDTH = 80;
  TILE_HEIGHT = 80;
  TOTAL_TILES = 192;
  TOTAL_TILE_SPRITES = 12;

  //The different tile sprites
  TILE_RED = 0;
  TILE_GREEN = 1;
  TILE_BLUE = 2;
  TILE_CENTER = 3;
  TILE_TOP = 4;
  TILE_TOPRIGHT = 5;
  TILE_RIGHT = 6;
  TILE_BOTTOMRIGHT = 7;
  TILE_BOTTOM = 8;
  TILE_BOTTOMLEFT = 9;
  TILE_LEFT = 10;
  TILE_TOPLEFT = 11;

var
  //The window we'll be rendering to
  gWindow: PSDL_Window;

  //The window renderer
  gRenderer: PSDL_Renderer;

  // Font
  gFont: PTTF_Font;

  //Scene textures
  gDotTexture: TTexture;
  gTileTexture: TTexture;
  gTileClips: array[0.. TOTAL_TILE_SPRITES - 1] of TSDL_Rect;

procedure Main;
// Starts up SDL and creates window
function Init(): boolean;
//Loads media
function LoadMedia(tiles: TArr_Tile): boolean;
// Frees media and shuts down SDL
procedure Close(tiles: TArr_Tile);
//Box collision detector
function CheckCollision(a, b: TSDL_Rect): boolean;
//Checks collision box against set of tiles
function TouchesWall(box: TSDL_Rect; tiles: TArr_Tile): boolean;
//Sets tiles from tile map
function SetTiles(tiles: TArr_Tile): boolean;

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

function LoadMedia(tiles: TArr_Tile): boolean;
var
  success: boolean;
begin
  //Loading success flag
  success := true;

  //Load dot texture
  if not gDotTexture.LoadFromFile('../Source/9_tiling/dot.bmp') then
  begin
    WriteLn('Failed to load dot texture!');
    success := false;
  end;

  //Load tile texture
  if not gTileTexture.LoadFromFile('../Source/39_tiling/tiles.png') then
  begin
    WriteLn('Failed to load tile set texture!');
    success := false;
  end;

  //Load tile map
  if not SetTiles(tiles) then
  begin
    WriteLn('Failed to load tile set!');
    success := false;
  end;

  Result := success;
end;

procedure Close(tiles: TArr_Tile);
begin
  //Free loaded images


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

function CheckCollision(a, b: TSDL_Rect): boolean;
begin

end;

function TouchesWall(box: TSDL_Rect; tiles: TArr_Tile): boolean;
begin

end;

function SetTiles(tiles: TArr_Tile): boolean;
begin

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

          //Handle input for the dot
        end;

        //Move the dot

        //Clear screen
        SDL_SetRenderDrawColor(gRenderer, $FF, $FF, $FF, $FF);
        SDL_RenderClear(gRenderer);

        //Render objects

        //Update screen
        SDL_RenderPresent(gRenderer);
      end;
    end;
  end;

  // Free resources and close SDL
  Close();
end;

end.
