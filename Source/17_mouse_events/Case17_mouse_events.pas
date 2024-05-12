unit Case17_mouse_events;

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
  libSDL2_ttf,
  DeepStar.Utils;

type
  TButtonSprite =
    (
    BUTTON_SPRITE_MOUSE_OUT = 0,
    BUTTON_SPRITE_MOUSE_OVER_MOTION = 1,
    BUTTON_SPRITE_MOUSE_DOWN = 2,
    BUTTON_SPRITE_MOUSE_UP = 3,
    BUTTON_SPRITE_TOTAL = 4
    );

  TTexture = class(TObject)
  private
    _height: integer;
    _width: integer;
    _texture: PSDL_Texture;

  public
    constructor Create;
    destructor Destroy; override;

    // Loads image at specified path
    function LoadFromFile(path: string): boolean;

    // Creates image from font string
    function LoadFromRenderedText(textureText: string; textColor: TSDL_Color): boolean;

    // Deallocates texture
    procedure Clean;

    // Renders texture at given point
    procedure Render(x, y: integer; clip: PSDL_Rect = nil; angle: double = 0;
      center: PSDL_Point = nil; flip: TSDL_RendererFlags = SDL_FLIP_NONE);

    //Set color modulation
    procedure SetColor(red, green, blue: byte);

    //Set blending
    procedure SetBlendMode(blending: TSDL_BlendMode);

    //Set alpha modulation
    procedure SetAlpha(alpha: byte);

    property Width: integer read _width;
    property Height: integer read _height;
  end;

  TButton = class(TObject)
  private
    //Top left position
		_Position: TSDL_Point;
		//Currently used global sprite
		_CurrentSprite: TButtonSprite;

  public
    constructor Create;
    destructor Destroy; override;

    // Sets top left position
    procedure SetPosition(x, y: integer);

    // Handles mouse event
    procedure HandleEvent(e: PSDL_Event);

    // Shows button sprite
    procedure Render();
  end;

const
  SCREEN_WIDTH = 640;
  SCREEN_HEIGHT = 480;

  // Button constants
  BUTTON_WIDTH = 300;
  BUTTON_HEIGHT = 200;
  TOTAL_BUTTONS = 4;

var
  // The window we'll be rendering to
  gWindow: PSDL_Window = nil;

  // The window renderer
  gRenderer: PSDL_Renderer = nil;

  // Mouse button sprites
  gSpriteClips: array[0..pred(Ord(BUTTON_SPRITE_TOTAL))] of TSDL_Rect;
  gButtonSpriteSheetTexture: TTexture;

  // Buttons objects
  gButtons: array[0.. pred(TOTAL_BUTTONS)] of TButton;

  // Globally used font
  gFont: PTTF_Font = nil;

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
  i: Integer;
begin
  // Start up SDL and create window
  if not Init then
  begin
    WriteLn('Failed to initialize!');
  end
  else
  begin
    gButtonSpriteSheetTexture := TTexture.Create;

    for i := 0 to High(gButtons) do
      gButtons[i] := TButton.Create;

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
            end
            else if e.type_ = SDL_KEYDOWN then
            begin
              case e.key.keysym.sym of
                SDLK_ESCAPE: quit := true;
              end;
            end;

            // Handle button events
            for i := 0 to TOTAL_BUTTONS - 1 do
            begin
              gButtons[i].HandleEvent(@e);
            end;
          end;

          // Clear screen
          SDL_SetRenderDrawColor(gRenderer, $FF, $FF, $FF, $FF);
          SDL_RenderClear(gRenderer);

          // Render buttons
          for i := 0 to TOTAL_BUTTONS - 1 do
          begin
            gButtons[i].Render;
          end;

          //Update screen
          SDL_RenderPresent(gRenderer);
        end;
      end;
    finally
      for i := 0 to High(gButtons) do
        FreeAndNil(gButtons[i]);

      gButtonSpriteSheetTexture.Free;
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
      gRenderer := SDL_CreateRenderer(gWindow, -1, SDL_RENDERER_ACCELERATED or SDL_RENDERER_PRESENTVSYNC);
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
  imgButton = '../Source/17_mouse_events/button.png';
var
  success: boolean;
  i: Integer;
begin
  // Loading success flag
  success := boolean(true);

  // Load sprites
  if not gButtonSpriteSheetTexture.LoadFromFile(imgButton) then
  begin
    WriteLn('Failed to load button sprite texture!');
    success := false;
  end
  else
  begin
    // Set sprites
    for i := 0 to Ord(BUTTON_SPRITE_TOTAL) - 1 do
    begin
      gSpriteClips[i].x := 0;
      gSpriteClips[i].y := i * 200;
      gSpriteClips[i].w := BUTTON_WIDTH;
      gSpriteClips[i].h := BUTTON_HEIGHT;
    end;
  end;

  // Set buttons in corners
  gButtons[0].setPosition(0, 0);
  gButtons[1].setPosition(SCREEN_WIDTH - BUTTON_WIDTH, 0);
  gButtons[2].setPosition(0, SCREEN_HEIGHT - BUTTON_HEIGHT);
  gButtons[3].setPosition(SCREEN_WIDTH - BUTTON_WIDTH, SCREEN_HEIGHT - BUTTON_HEIGHT);

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

{ TButton }

constructor TButton.Create;
begin
  _Position := Default(TSDL_Point);
  _CurrentSprite := TButtonSprite.BUTTON_SPRITE_MOUSE_OUT;
end;

destructor TButton.Destroy;
begin
  inherited Destroy;
end;

procedure TButton.HandleEvent(e: PSDL_Event);
var
  x, y: Integer;
  inside: Boolean;
begin
  // If mouse event happened
  if (e^.type_ = SDL_MOUSEMOTION)
    or (e^.type_ = SDL_MOUSEBUTTONDOWN)
    or (e^.type_ = SDL_MOUSEBUTTONUP) then
  begin
    // Get mouse position
    x := integer(0);
    y := integer(0);
    SDL_GetMouseState(@x, @y);

    // Check if mouse is in button
    inside := boolean(true);

    // Mouse is left of the button
    if x < _Position.x then
    begin
      inside := false;
    end
    // Mouse is right of the button
    else if x > _Position.x + BUTTON_WIDTH then
    begin
      inside := false;
    end
    // Mouse above the button
    else if y < _Position.y then
    begin
      inside := false;
    end
    // Mouse below the button
    else if y > _Position.y + BUTTON_HEIGHT then
    begin
      inside := false;
    end;

    // Mouse is outside button
    if not inside then
    begin
      _CurrentSprite := BUTTON_SPRITE_MOUSE_OUT;
    end
    else // Mouse is inside button
    begin
      // Set mouse over sprite
      case e^.type_ of
        SDL_MOUSEMOTION: _CurrentSprite := BUTTON_SPRITE_MOUSE_OVER_MOTION;
        SDL_MOUSEBUTTONDOWN: _CurrentSprite := BUTTON_SPRITE_MOUSE_DOWN;
        SDL_MOUSEBUTTONUP: _CurrentSprite := BUTTON_SPRITE_MOUSE_UP;
      end;
    end;
  end;
end;

procedure TButton.Render();
begin
  //Show current button sprite
  gButtonSpriteSheetTexture.Render(_Position.x, _Position.y, @gSpriteClips[Ord(_CurrentSprite)]);
end;

procedure TButton.SetPosition(x, y: integer);
begin
  _Position.x := x;
  _Position.y := y;
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

function TTexture.LoadFromRenderedText(textureText: string; textColor: TSDL_Color): boolean;
var
  textSurface: PSDL_Surface;
begin
  // Get rid of preexisting texture
  Clean;

  // Render text surface
  textSurface := PSDL_Surface(nil);
  textSurface := TTF_RenderText_Solid(gFont, textureText.ToPAnsiChar, textColor);
  if textSurface = nil then
  begin
    WriteLnF('Unable to render text surface! SDL_ttf Error: %s', [SDL_GetError()]);
  end
  else
  begin
    // Create texture from surface pixels
    _texture := SDL_CreateTextureFromSurface(gRenderer, textSurface);
    if _texture = nil then
    begin
      WriteLnF('Unable to create texture from rendered text! SDL Error: %s', [SDL_GetError()]);
    end
    else
    begin
      // Get image dimensions
      _width := textSurface^.w;
      _height := textSurface^.h;
    end;
  end;

  // Return success
  Result := _texture <> nil;
end;

procedure TTexture.Render(x, y: integer; clip: PSDL_Rect; angle: double;
  center: PSDL_Point; flip: TSDL_RendererFlags);
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

  SDL_RenderCopyEx(gRenderer, _texture, clip, @renderQuad, angle, center, flip);
end;

procedure TTexture.SetAlpha(alpha: byte);
begin
  // Modulate texture alpha
  SDL_SetTextureAlphaMod(_texture, alpha);
end;

procedure TTexture.SetBlendMode(blending: TSDL_BlendMode);
begin
  // Set blending function
  SDL_SetTextureBlendMode(_texture, blending);
end;

procedure TTexture.SetColor(red, green, blue: byte);
begin
  // Modulate texture
  SDL_SetTextureColorMod(_texture, red, green, blue);
end;

end.
