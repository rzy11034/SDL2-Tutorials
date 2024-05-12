unit Case10_color_keying;

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
  libSDL2_image,
  DeepStar.Utils;

type
  TTexture = class(TObject)
  private
    _height: integer;
    _texture: PSDL_Texture;
    _width: integer;

  public
    constructor Create;
    destructor Destroy; override;

    // Loads image at specified path
    function LoadFromFile(path: string): boolean;

    // Deallocates texture
    procedure Clean;

    // Renders texture at given point
    procedure render(x, y: integer);

    property Width: integer read _width;
    property Height: integer read _height;
  end;

const
  SCREEN_WIDTH = 640;
  SCREEN_HEIGHT = 480;

var
  // The window we'll be rendering to
  gWindow: PSDL_Window = nil;
  // The window renderer
  gRenderer: PSDL_Renderer = nil;
  // Current displayed texture
  gTexture:PSDL_Texture = nil;
  // Scene textures
  gFooTexture, gBackgroundTexture: TTexture;

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
    gFooTexture := TTexture.Create;
    gBackgroundTexture := TTexture.Create;
    try
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
            end;
          end;

          // Clear screen
          SDL_SetRenderDrawColor(gRenderer, $FF, $FF, $FF, $FF);
          SDL_RenderClear(gRenderer);

          //Render background texture to screen
          gBackgroundTexture.render(0, 0);

          //Render Foo' to the screen
          gFooTexture.render(240, 190);

          //Update screen
          SDL_RenderPresent(gRenderer);
        end;
      end;
    finally
      gFooTexture.Free;
      gBackgroundTexture.Free;
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

  if SDL_Init(SDL_INIT_VIDEO) < 0 then
  begin
    WriteLnF('SDL could not initialize! SDL_Error: %s', [SDL_GetError()]);
    Exit(false);
  end;

  // Set texture filtering to linear
  if not SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, '1') then
    WriteLn('Warning: Linear texture filtering not enabled!');

  // Create window
  gWindow := SDL_CreateWindow('SDL Tutorial', SDL_WINDOWPOS_UNDEFINED,
    SDL_WINDOWPOS_UNDEFINED, SCREEN_WIDTH, SCREEN_HEIGHT, SDL_WINDOW_SHOWN);
  if gWindow = nil then
  begin
    WriteLn('Window could not be created! SDL_Error: ', SDL_GetError);
    Exit(false);
  end;

  // Create renderer for window
  gRenderer := SDL_CreateRenderer(gWindow, -1, SDL_RENDERER_ACCELERATED);
  if gRenderer = nil then
  begin
    WriteLn('Renderer could not be created! SDL Error:', SDL_GetError);
    Exit(false);
  end;

  // Initialize renderer color
  SDL_SetRenderDrawColor(gRenderer, $FF, $FF, $FF, $FF);

  //Initialize PNG loading
  imgFlags := integer(0);
  imgFlags := IMG_INIT_PNG;
  if not (IMG_Init(imgFlags) and imgFlags).ToBoolean then
  begin
    WriteLn('SDL_image could not initialize! SDL_image Error.');
    Exit(false);
  end;

  Result := success;
end;

function LoadMedia(): boolean;
const
  imgFoo = '../Source/10_color_keying/foo.png';
  imgBackground = '../Source/10_color_keying/background.png';
var
  success: boolean;
begin
  success := boolean(true);

  // Load Foo texture
  if not gFooTexture.LoadFromFile(imgFoo) then
  begin
    WriteLn('Failed to load Foo texture image!');
    success := false;
  end;

  // Load background texture
  if not gBackgroundTexture.LoadFromFile(imgBackground) then
  begin
    WriteLn('Failed to load background texture image!');
		success := false;
  end;

  Result := success;
end;

procedure Close();
begin
  // Free loaded image
  SDL_DestroyTexture(gTexture);
  gTexture := nil;

  //Destroy window
  SDL_DestroyRenderer(gRenderer);
  SDL_DestroyWindow(gWindow);
  gWindow := nil;
  gRenderer := nil;

  // Quit SDL subsystems
  IMG_Quit();
  SDL_Quit();
end;

{ TTexture }

constructor TTexture.Create;
begin
  inherited;
end;

procedure TTexture.Clean;
begin
  // Free texture if it exists
	if _texture <> nil then
  begin
    SDL_DestroyTexture(_texture);
    _texture := nil;
    _width := 0;
    _height := 0;
  end;
end;

destructor TTexture.Destroy;
begin
  Clean;
  inherited Destroy;
end;

function TTexture.LoadFromFile(path: string): boolean;
var
  newTexture: PSDL_Texture;
  loadedSurface: PSDL_Surface;
begin
  // Get rid of preexisting texture
  Clean;

  // The final texture
	newTexture := PSDL_Texture(nil);

  // Load image at specified path
  loadedSurface := PSDL_Surface(nil);
  loadedSurface := IMG_Load(path.ToPAnsiChar);
  if loadedSurface = nil then
  begin
    WriteLn('Unable to load image %s! SDL_image Error: ', path);
  end
  else
  begin
    // Color key image
    SDL_SetColorKey(loadedSurface, Ord(SDL_TRUE), SDL_MapRGB(loadedSurface^.format, 0, $FF, $FF));

    // Create texture from surface pixels
    newTexture := SDL_CreateTextureFromSurface(gRenderer, loadedSurface);
    if newTexture = nil then
    begin
      WriteLnF('Unable to create texture from %s! SDL Error: %s', [path, SDL_GetError()]);
    end
    else
    begin
      _width := loadedSurface^.w;
      _height := loadedSurface^.h;
    end;

    SDL_FreeSurface(loadedSurface);
  end;

  _texture := newTexture;
  Result := _texture <> nil;
end;

procedure TTexture.render(x, y: integer);
var
  renderQuad: TSDL_Rect;
begin
  // Set rendering space and render to screen
  renderQuad := Default(TSDL_Rect);
  renderQuad.x := x;
  renderQuad.y := y;
  renderQuad.w := _width;
  renderQuad.h := _height;

  SDL_RenderCopy(gRenderer, _texture, nil, @renderQuad);
end;

end.

