unit Case12_color_modulation;

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
    procedure Render(x, y: integer; clip: PSDL_Rect = nil);

    //Set color modulation
    procedure SetColor(red, green, blue: byte);

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

  // Scene texture
  gModulatedTexture: TTexture;

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
  r, g, b: byte;
begin
  // Start up SDL and create window
  if not Init then
  begin
    WriteLn('Failed to initialize!');
  end
  else
  begin
    gModulatedTexture := TTexture.Create;
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

        // Modulation components
        r := byte(255);
        g := byte(255);
        b := byte(255);

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
                //Increase red
                SDLK_q:
                begin
                  if r + 32 >= 255 then
                    r := r + 32 - 255
                  else
                    r := r + 32;
                end;

                //Increase green
                SDLK_w:
                begin
                  if g + 32 >= 255 then
                    g := g + 32 - 255
                  else
                    g := g + 32;
                end;

                //Increase blue
                SDLK_e:
                begin
                  if b + 32 >= 255 then
                    b := b + 32 - 255
                  else
                    b := b + 32;
                end;

                //Decrease red
                SDLK_a:
                begin
                  if r - 32 <= 0 then
                    r := 255 + r - 32
                  else
                    r := r -32;
                end;

                //Decrease green
                SDLK_s:
                begin
                  if g - 32 <= 0 then
                    g := 255 + g - 32
                  else
                    g := g -32;
                end;

                //Decrease blue
                SDLK_d:
                begin
                  if b - 32 <= 0 then
                    b := 255 + b - 32
                  else
                    b := b -32;
                end;

                SDLK_ESCAPE: quit := true;
              end;
            end;
          end;

          // Clear screen
          SDL_SetRenderDrawColor(gRenderer, $FF, $FF, $FF, $FF);
          SDL_RenderClear(gRenderer);

          // Modulate and render texture
          gModulatedTexture.SetColor(r, g, b);
          gModulatedTexture.Render(0, 0);

          //Update screen
          SDL_RenderPresent(gRenderer);
        end;
      end;
    finally
      gModulatedTexture.Free;
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
    gWindow := SDL_CreateWindow('SDL Tutorial', SDL_WINDOWPOS_UNDEFINED,
      SDL_WINDOWPOS_UNDEFINED, SCREEN_WIDTH, SCREEN_HEIGHT, SDL_WINDOW_SHOWN);
    if gWindow = nil then
    begin
      WriteLn('Window could not be created! SDL_Error: ', SDL_GetError);
      success := false;
    end
    else
    begin
      // Create renderer for window
      gRenderer := SDL_CreateRenderer(gWindow, -1, SDL_RENDERER_ACCELERATED);
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
      end;
    end;
  end;

  Result := success;
end;

function LoadMedia(): boolean;
const
  imgcolors = '../Source/12_color_modulation/colors.png';
var
  success: boolean;
begin
  // Loading success flag
  success := boolean(true);

  // Load modulated texture
  if not gModulatedTexture.LoadFromFile(imgcolors) then
  begin
    WriteLn('Failed to load sprite sheet texture!');
    success := false;
  end;

  Result := success;
end;

procedure Close();
begin
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
    SDL_SetColorKey(loadedSurface, Ord(SDL_TRUE), SDL_MapRGB(loadedSurface^.format,
      0, $FF, $FF));

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

procedure TTexture.Render(x, y: integer; clip: PSDL_Rect);
var
  renderQuad: TSDL_Rect;
begin
  // Set rendering space and render to screen
  renderQuad := Default(TSDL_Rect);
  renderQuad.x := x;
  renderQuad.y := y;
  renderQuad.w := _width;
  renderQuad.h := _height;

  // Set clip rendering dimensions
  if clip <> nil then
  begin
    renderQuad.w := clip^.w;
    renderQuad.h := clip^.h;
  end;

  SDL_RenderCopy(gRenderer, _texture, clip, @renderQuad);
end;

procedure TTexture.SetColor(red, green, blue: byte);
begin
  // Modulate texture
  SDL_SetTextureColorMod(_texture, red, green, blue);
end;

end.
