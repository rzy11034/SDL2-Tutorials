unit Case28_per_pixel_collision_detection;

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
  libSDL2_mixer,
  DeepStar.Utils,
  DeepStar.DSA.Interfaces,
  DeepStar.DSA.Linear.ArrayList;

type
  TTexture = class(TObject)
  private
    _Renderer: PSDL_Renderer;
    _Font: PTTF_Font;

    _height: integer;
    _width: integer;
    _texture: PSDL_Texture;

  public
    constructor Create(aRenderer: PSDL_Renderer; aFont: PTTF_Font = nil);
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

  TDot = class(TObject)
  public type
    IList_PSDL_Rect = specialize IList<PSDL_Rect>;
    TList_PSDL_Rect = specialize TArrayList<PSDL_Rect>;

  public const
    // The dimensions of the dot
    DOT_WIDTH = 20;
    DOT_HEIGHT = 20;
    //Maximum axis velocity of the dot
    DOT_VEL = 1;

  private
    _Texture: TTexture;

    _ScreenWidth, _ScreenHeight: integer;

    //The X and Y offsets of the dot
    _PosX, _PosY: integer;

    //The velocity of the dot
    _VelX, _VelY: integer;

    // Dot's collision box
    _Colliders: IList_PSDL_Rect;

    // Moves the collision boxes relative to the dot's offset
    procedure __ShiftColliders();

  public
    constructor Create(aWindows: PSDL_Window; aTexture: TTexture; ax, ay: integer);
    destructor Destroy; override;

    // Takes key presses and adjusts the dot's velocity
    procedure HandleEvent(var e: TSDL_Event);

    // Moves the dot
    procedure Move(otherColliders: IList_PSDL_Rect);

    // Shows the dot on the screen
    procedure Render();

    // Gets the collision boxes
    function GetColliders: IList_PSDL_Rect;

    function CheckCollision(a, b: IList_PSDL_Rect): boolean;
  end;

  TTimer = class(TObject)
  private
    // The clock time when the timer started
    _StartTicks: integer;

    // The ticks stored when the timer was paused
    _PausedTicks: integer;

    // The timer status
    _Paused: boolean;
    _Started: boolean;

  public
    constructor Create;
    destructor Destroy; override;

    // The various clock actions
    procedure Start();
    procedure Stop();
    procedure Pause();
    procedure Unpause();

    // Gets the timer's time
    function GetTicks(): integer;

    //Checks the status of the timer
    function IsStarted(): boolean;
    function IsPaused(): boolean;
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
  gDotTexture: TTexture;

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
  dot, otherDot: TDot;
begin
  // Start up SDL and create window
  if not Init then
  begin
    WriteLn('Failed to initialize!');
  end
  else
  begin
    gDotTexture := TTexture.Create(gRenderer);
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

        dot := TDot.Create(gWindow, gDotTexture, 0, 0);
        otherDot := TDot.Create(gWindow, gDotTexture, SCREEN_WIDTH div 4, SCREEN_HEIGHT div 4);
        try
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

              dot.HandleEvent(e);
            end;

            // Move the dot and check collision
            dot.Move(otherDot.GetColliders);

            // Clear screen
            SDL_SetRenderDrawColor(gRenderer, $FF, $FF, $FF, $FF);
            SDL_RenderClear(gRenderer);

            //Render objects
            dot.Render();
            otherDot.Render();

            // Update screen
            SDL_RenderPresent(gRenderer);
          end;
        finally
          dot.Free;
          otherDot.Free;
        end;
      end;
    finally
      gDotTexture.Free;
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
  if SDL_Init(SDL_INIT_VIDEO or SDL_INIT_AUDIO) < 0 then
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
  imgDot = '../Source/28_per_pixel_collision_detection/dot.bmp';
var
  success: boolean;
begin
  // Loading success flag
  success := boolean(true);

  // Open the font
  if not gDotTexture.LoadFromFile(imgDot) then
  begin
    WriteLn('Failed to load dot texture!');
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
  TTF_Quit();
  IMG_Quit();
  SDL_Quit();
end;

{ TTimer }

constructor TTimer.Create;
begin
  inherited;

  //Initialize the variables
  _StartTicks := 0;
  _PausedTicks := 0;

  _Paused := false;
  _Started := false;
end;

destructor TTimer.Destroy;
begin
  inherited Destroy;
end;

function TTimer.GetTicks: integer;
var
  time_: integer;
begin
  // The actual timer time
  time_ := integer(0);

  // If the timer is running
  if _Started then
  begin
    // If the timer is paused
    if _Paused then
    begin
      // Return the number of ticks when the timer was paused
      time_ := _PausedTicks;
    end
    else
    begin
      // Return the current time minus the start time
      time_ := SDL_GetTicks() - _StartTicks;
    end;
  end;

  Result := time_;
end;

function TTimer.IsPaused(): boolean;
begin
  Result := _Paused;
end;

function TTimer.IsStarted(): boolean;
begin
  Result := _Started;
end;

procedure TTimer.Pause;
begin
  // If the timer is running and isn't already paused
  if _Started and (not _Paused) then
  begin
    //Pause the timer
    _Paused := true;

    //Calculate the paused ticks
    _PausedTicks := SDL_GetTicks() - _StartTicks;
    _StartTicks := 0;
  end;
end;

procedure TTimer.Start;
begin
  //Start the timer
  _Started := true;

  //Unpause the timer
  _Paused := false;

  //Get the current clock time
  _StartTicks := SDL_GetTicks();
  _PausedTicks := 0;
end;

procedure TTimer.Stop;
begin
  //Stop the timer
  _Started := false;

  //Unpause the timer
  _Paused := false;

  //Clear tick variables
  _StartTicks := 0;
  _PausedTicks := 0;
end;

procedure TTimer.Unpause;
begin
  // If the timer is running and paused
  if _Started and _Paused then
  begin
    //Unpause the timer
    _Paused := false;

    //Reset the starting ticks
    _StartTicks := SDL_GetTicks() - _PausedTicks;

    //Reset the paused ticks
    _PausedTicks := 0;
  end;
end;

{ TDot }

constructor TDot.Create(aWindows: PSDL_Window; aTexture: TTexture; ax, ay: integer);
var
  p: PSDL_Rect;
  i: integer;
begin
  _ScreenWidth := aWindows^.w;
  _ScreenHeight := aWindows^.h;
  _Texture := aTexture;

  // Initialize the offsets
  _PosX := ax;
  _PosY := ay;

  // Initialize the velocity
  _VelX := 0;
  _VelY := 0;

  // Create the necessary SDL_Rects
  _Colliders := TList_PSDL_Rect.Create(11);
  for i := 0 to _Colliders.Count - 1 do
  begin
    new(p);
    p^ := Default(TSDL_Rect);
    _Colliders[i] := p;
  end;

  // Initialize the collision boxes' width and height
  _Colliders[0]^.w := 6;
  _Colliders[0]^.h := 1;

  _Colliders[1]^.w := 10;
  _Colliders[1]^.h := 1;

  _Colliders[2]^.w := 14;
  _Colliders[2]^.h := 1;

  _Colliders[3]^.w := 16;
  _Colliders[3]^.h := 2;

  _Colliders[4]^.w := 18;
  _Colliders[4]^.h := 2;

  _Colliders[5]^.w := 20;
  _Colliders[5]^.h := 6;

  _Colliders[6]^.w := 18;
  _Colliders[6]^.h := 2;

  _Colliders[7]^.w := 16;
  _Colliders[7]^.h := 2;

  _Colliders[8]^.w := 14;
  _Colliders[8]^.h := 1;

  _Colliders[9]^.w := 10;
  _Colliders[9]^.h := 1;

  _Colliders[10]^.w := 6;
  _Colliders[10]^.h := 1;

  //Initialize colliders relative to position
  __ShiftColliders();
end;

function TDot.CheckCollision(a, b: IList_PSDL_Rect): boolean;
var
  leftA, leftB, rightA, topA, topB, bottomA, bottomB, rightB, Abox, Bbox: integer;
begin
  leftA := integer(0);
  leftB := integer(0);
  rightA := integer(0);
  rightB := integer(0);
  topA := integer(0);
  topB := integer(0);
  bottomA := integer(0);
  bottomB := integer(0);

  // Go through the A boxes
  for Abox := 0 to a.Count - 1 do
  begin
    // Calculate the sides of rect A
    leftA := a[Abox]^.x;
    rightA := a[Abox]^.x + a[Abox]^.w;
    topA := a[Abox]^.y;
    bottomA := a[Abox]^.y + a[Abox]^.h;

    // Go through the B boxes
    for Bbox := 0 to b.Count - 1 do
    begin
      //Calculate the sides of rect B
      leftB := b[Bbox]^.x;
      rightB := b[Bbox]^.x + b[Bbox]^.w;
      topB := b[Bbox]^.y;
      bottomB := b[Bbox]^.y + b[Bbox]^.h;

      // If no sides from A are outside of B
      if ((bottomA <= topB) or (topA >= bottomB) or (rightA <= leftB)
        or (leftA >= rightB)) = false then
      begin
        // A collision is detected
        Exit(true);
      end;
    end;
  end;

  // If neither set of collision boxes touched
  Result := false;
end;

destructor TDot.Destroy;
var
  i: integer;
begin
  for i := _Colliders.Count - 1 downto 0 do
  begin
    Dispose(_Colliders[i]);
    _Colliders[i] := nil;
  end;

  inherited Destroy;
end;

function TDot.GetColliders: IList_PSDL_Rect;
begin
  Result := _Colliders;
end;

procedure TDot.HandleEvent(var e: TSDL_Event);
begin
  // If a key was pressed
  if (e.type_ = SDL_KEYDOWN) and (e.key._repeat = 0) then
  begin
    // Adjust the velocity
    case e.key.keysym.sym of
      SDLK_UP: _VelY -= DOT_VEL;
      SDLK_DOWN: _VelY += DOT_VEL;
      SDLK_LEFT: _VelX -= DOT_VEL;
      SDLK_RIGHT: _VelX += DOT_VEL;
    end;
  end
  // If a key was released
  else if (e.type_ = SDL_KEYUP) and (e.key._repeat = 0) then
  begin
    case e.key.keysym.sym of
      SDLK_UP: _VelY += DOT_VEL;
      SDLK_DOWN: _VelY -= DOT_VEL;
      SDLK_LEFT: _VelX += DOT_VEL;
      SDLK_RIGHT: _VelX -= DOT_VEL;
    end;
  end;
end;

procedure TDot.Move(otherColliders: IList_PSDL_Rect);
begin
  // Move the dot left or right
  _PosX += _VelX;
  __ShiftColliders;

  // If the dot collided or went too far to the left or right
  if (_PosX < 0) or (_PosX + DOT_WIDTH > _ScreenWidth)
    or CheckCollision(_Colliders, otherColliders) then
  begin
    //Move back
    _PosX -= _VelX;
    __ShiftColliders;
  end;

  // Move the dot up or down
  _PosY += _VelY;
  __ShiftColliders;

  // If the dot went too far up or down
  if (_PosY < 0) or (_PosY + DOT_HEIGHT > _ScreenHeight)
    or CheckCollision(_Colliders, otherColliders) then
  begin
    // Move back
    _PosY -= _VelY;
    __ShiftColliders;
  end;
end;

procedure TDot.Render();
begin
  // Show the dot
  _Texture.render(_PosX, _PosY);
end;

procedure TDot.__ShiftColliders();
var
  r, set_: integer;
begin
  // The row offset
  r := integer(0);

  // Go through the dot's collision boxes
  for set_ := 0 to _Colliders.Count - 1 do
  begin
    // Center the collision box
    _Colliders[set_]^.x := _PosX + (DOT_WIDTH - _Colliders[set_]^.w) div 2;

    //Set_ the collision box at its row offset
    _Colliders[set_]^.y := _PosY + r;

    //Move the row offset down the height of the collision box
    r += _Colliders[set_]^.h;
  end;
end;

{ TTexture }

constructor TTexture.Create(aRenderer: PSDL_Renderer; aFont: PTTF_Font);
begin
  _Renderer := aRenderer;
  _Font := aFont;
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
    SDL_SetColorKey(loadedSurface, Ord(SDL_TRUE), SDL_MapRGB(loadedSurface^.format,
      0, $FF, $FF));

    // Create texture from surface pixels
    newTexture := SDL_CreateTextureFromSurface(_Renderer, loadedSurface);
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
  textSurface := TTF_RenderText_Solid(_Font, textureText.ToPAnsiChar, textColor);
  if textSurface = nil then
  begin
    WriteLnF('Unable to render text surface! SDL_ttf Error: %s', [SDL_GetError()]);
  end
  else
  begin
    // Create texture from surface pixels
    _texture := SDL_CreateTextureFromSurface(_Renderer, textSurface);
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

  SDL_RenderCopyEx(_Renderer, _texture, clip, @renderQuad, angle, center, flip);
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
