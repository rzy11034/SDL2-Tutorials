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
function LoadMedia(var tiles: TArr_PTile): boolean;
// Frees media and shuts down SDL
procedure Close(var tiles: TArr_PTile);
//Box collision detector
function CheckCollision(a, b: TSDL_Rect): boolean;
//Checks collision box against set of tiles
function TouchesWall(box: TSDL_Rect; var tiles: TArr_PTile): boolean;
//Sets tiles from tile map
function SetTiles(var tiles: TArr_PTile): boolean;

implementation

uses
  Case39_tiling.Dot,
  SDL2_Tutorials.Utils;

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

function LoadMedia(var tiles: TArr_PTile): boolean;
var
  success: boolean;
begin
  //Loading success flag
  success := true;

  //Load dot texture
  if not gDotTexture.LoadFromFile('../Source/39_tiling/dot.bmp') then
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

procedure Close(var tiles: TArr_PTile);
var
  i: integer;
begin
  //Deallocate tiles
  for i := 0 to TOTAL_TILES - 1 do
  begin
    if tiles[i] <> nil then
    begin
      Dispose(tiles[i], Done);
      tiles[i] := nil;
    end;
  end;

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
var
  bottomB, leftA, leftB, rightA, rightB, topA, topB, bottomA: integer;
begin
  //The sides of the rectangles
  leftA := integer(0);
  leftB := integer(0);
  rightA := integer(0);
  rightB := integer(0);
  topA := integer(0);
  topB := integer(0);
  bottomA := integer(0);
  bottomB := integer(0);

  //Calculate the sides of rect A
  leftA := a.x;
  rightA := a.x + a.w;
  topA := a.y;
  bottomA := a.y + a.h;

  //Calculate the sides of rect B
  leftB := b.x;
  rightB := b.x + b.w;
  topB := b.y;
  bottomB := b.y + b.h;

  //If any of the sides from A are outside of B
  if bottomA <= topB then
    Exit(false);

  if topA >= bottomB then
    Exit(false);

  if rightA <= leftB then
    Exit(false);

  if leftA >= rightB then
    Exit(false);

  //If none of the sides from A are outside B
  Result := true;
end;

function TouchesWall(box: TSDL_Rect; var tiles: TArr_PTile): boolean;
var
  i: integer;
begin
  //Go through the tiles
  for i := 0 to TOTAL_TILES - 1 do
  begin
    //If the tile is a wall type tile
    if (tiles[i]^.GetType >= TILE_CENTER) and (tiles[i]^.GetType <= TILE_TOPLEFT) then
    begin
      //If the collision box touches the wall tile
      if checkCollision(box, tiles[i]^.GetBox) then
        Exit(true);
    end;
  end;

  //If no wall tiles were touched
  Result := false;
end;

function SetTiles(var tiles: TArr_PTile): boolean;
var
  tilesLoaded: boolean;
  list: TStringList;
  x, y, i, tileType: integer;
  map: IList_str;
  tempS: TArr_str;
begin
  //Success flag
  tilesLoaded := true;

  //The tile offsets
  x := 0;
  y := 0;

  map := TArrayList_str.Create;

  list := TStringList.Create();
  try
    list.LoadFromFile('../Source/39_tiling/lazy.map');

    for i := 0 to list.Count - 1 do
    begin
      tempS := string(list[i]).Split([' ']);
      map.AddRange(tempS, 0, 16);
    end;
  finally
    list.Free;
  end;

  //If the map couldn't be loaded
  if map.IsEmpty then
  begin
    WriteLn('Unable to load map file!');
    tilesLoaded := false;
  end
  else
  begin
    //Initialize the tiles
    for i := 0 to TOTAL_TILES - 1 do
    begin
      //Determines what kind of tile will be made
      tileType := -1;

      //Read tile from map file
      tileType := map[i].ToInteger;

      //If the number is a valid tile number
      if (tileType >= 0) and (tileType < TOTAL_TILE_SPRITES) then
      begin
        new(tiles[i], Init(x, y, tileType));
      end
      //If we don't recognize the tile type
      else
      begin
        //Stop loading map
        WriteLn('Error loading map: Invalid tile type at %d!', i);
        tilesLoaded := false;
        Break;
      end;

      //Move to next tile spot
      x += TILE_WIDTH;

      //If we've gone too far
      if x >= LEVEL_WIDTH then
      begin
        //Move back
        x := 0;

        //Move to the next row
        y += TILE_HEIGHT;
      end;
    end;

    //Clip the sprite sheet
    if tilesLoaded then
    begin
      gTileClips[TILE_RED].x := 0;
      gTileClips[TILE_RED].y := 0;
      gTileClips[TILE_RED].w := TILE_WIDTH;
      gTileClips[TILE_RED].h := TILE_HEIGHT;

      gTileClips[TILE_GREEN].x := 0;
      gTileClips[TILE_GREEN].y := 80;
      gTileClips[TILE_GREEN].w := TILE_WIDTH;
      gTileClips[TILE_GREEN].h := TILE_HEIGHT;

      gTileClips[TILE_BLUE].x := 0;
      gTileClips[TILE_BLUE].y := 160;
      gTileClips[TILE_BLUE].w := TILE_WIDTH;
      gTileClips[TILE_BLUE].h := TILE_HEIGHT;

      gTileClips[TILE_TOPLEFT].x := 80;
      gTileClips[TILE_TOPLEFT].y := 0;
      gTileClips[TILE_TOPLEFT].w := TILE_WIDTH;
      gTileClips[TILE_TOPLEFT].h := TILE_HEIGHT;

      gTileClips[TILE_LEFT].x := 80;
      gTileClips[TILE_LEFT].y := 80;
      gTileClips[TILE_LEFT].w := TILE_WIDTH;
      gTileClips[TILE_LEFT].h := TILE_HEIGHT;

      gTileClips[TILE_BOTTOMLEFT].x := 80;
      gTileClips[TILE_BOTTOMLEFT].y := 160;
      gTileClips[TILE_BOTTOMLEFT].w := TILE_WIDTH;
      gTileClips[TILE_BOTTOMLEFT].h := TILE_HEIGHT;

      gTileClips[TILE_TOP].x := 160;
      gTileClips[TILE_TOP].y := 0;
      gTileClips[TILE_TOP].w := TILE_WIDTH;
      gTileClips[TILE_TOP].h := TILE_HEIGHT;

      gTileClips[TILE_CENTER].x := 160;
      gTileClips[TILE_CENTER].y := 80;
      gTileClips[TILE_CENTER].w := TILE_WIDTH;
      gTileClips[TILE_CENTER].h := TILE_HEIGHT;

      gTileClips[TILE_BOTTOM].x := 160;
      gTileClips[TILE_BOTTOM].y := 160;
      gTileClips[TILE_BOTTOM].w := TILE_WIDTH;
      gTileClips[TILE_BOTTOM].h := TILE_HEIGHT;

      gTileClips[TILE_TOPRIGHT].x := 240;
      gTileClips[TILE_TOPRIGHT].y := 0;
      gTileClips[TILE_TOPRIGHT].w := TILE_WIDTH;
      gTileClips[TILE_TOPRIGHT].h := TILE_HEIGHT;

      gTileClips[TILE_RIGHT].x := 240;
      gTileClips[TILE_RIGHT].y := 80;
      gTileClips[TILE_RIGHT].w := TILE_WIDTH;
      gTileClips[TILE_RIGHT].h := TILE_HEIGHT;

      gTileClips[TILE_BOTTOMRIGHT].x := 240;
      gTileClips[TILE_BOTTOMRIGHT].y := 160;
      gTileClips[TILE_BOTTOMRIGHT].w := TILE_WIDTH;
      gTileClips[TILE_BOTTOMRIGHT].h := TILE_HEIGHT;
    end;
  end;

  //If the map was loaded fine
  Result := tilesLoaded;
end;

procedure Main;
var
  quit: boolean;
  e: TSDL_Event;
  tileSet: TArr_PTile;
  dot: TDot;
  camera: TSDL_Rect;
  i: Integer;
begin
  // Start up SDL and create window
  if not Init then
  begin
    WriteLn('Failed to initialize!');
  end
  else
  begin
    tileSet := TArr_PTile(nil);
    SetLength(tileSet, TOTAL_TILES);

    //Load media
    if not loadMedia(tileSet) then
    begin
      WriteLn('Failed to load media!');
    end
    else
    begin
      // Main loop flag
      quit := boolean(false);

      // Event handler
      e := Default(TSDL_Event);

      //The dot that will be moving around on the screen
      dot := Default(TDot);
      dot.Init;

      //Level camera
      camera := SDL_Rect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);

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
          dot.HandleEvent(e);
        end;

        //Move the dot
        dot.Move(tileSet);
        dot.SetCamera(camera);

        //Clear screen
        SDL_SetRenderDrawColor(gRenderer, $FF, $FF, $FF, $FF);
        SDL_RenderClear(gRenderer);

        //Render level
        for i := 0 to TOTAL_TILES - 1 do
          tileSet[i]^.Render(camera);

        //Render dot
        dot.Render(camera);

        //Update screen
        SDL_RenderPresent(gRenderer);
      end;
    end;
  end;

  // Free resources and close SDL
  Close(tileSet);
end;

end.
