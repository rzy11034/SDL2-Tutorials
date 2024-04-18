unit Case33_file_reading_and_writing;

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
  libSDL2_mixer,
  libSDL2_ttf,
  DeepStar.Utils,
  DeepStar.UString,
  SDL2_Tutorials.Utils;

type
  // A circle stucture
  PCircle = {%H-}^TCircle;
  TCircle = record
    x, y, r: integer;
  end;

  TTexture = class(TObject)
  strict private
    _Renderer: PSDL_Renderer;
    _Font: PTTF_Font;

    _Height: integer;
    _Width: integer;
    _Texture: PSDL_Texture;

  public
    constructor Create(aRenderer: PSDL_Renderer);
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

    function GetHeight: integer;
    function GetWidth: integer;

    property Font: PTTF_Font read _Font write _Font;
  end;

  TDot = class(TObject)
  public const
    // The dimensions of the dot
    DOT_WIDTH = 20;
    DOT_HEIGHT = 20;
    //Maximum axis velocity of the dot
    DOT_VEL = 1;

  strict private
    _Texture: TTexture;

    _ScreenWidth, _ScreenHeight: integer;

    //The X and Y offsets of the dot
    _PosX, _PosY: integer;

    //The velocity of the dot
    _VelX, _VelY: integer;

  public
    constructor Create(aWindows: PSDL_Window; aTexture: TTexture; ax, ay: integer);
    destructor Destroy; override;

    // Takes key presses and adjusts the dot's velocity
    procedure HandleEvent(var e: TSDL_Event);

    // Moves the dot
    procedure Move();

    // Shows the dot on the screen
    procedure Render();
  end;

  TTimer = class(TObject)
  strict private
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
  // The dimensions of the level
  LEVEL_WIDTH = 1280;
  LEVEL_HEIGHT = 960;

  // Screen dimension constants
  SCREEN_WIDTH = 640;
  SCREEN_HEIGHT = 480;

  // Number of data integers
  TOTAL_DATA = 10;

var
  // The window we'll be rendering to
  gWindow: PSDL_Window = nil;

  // The window renderer
  gRenderer: PSDL_Renderer = nil;

  // Globally used font
  gFont: PTTF_Font = nil;

  // Scene texture
  gPromptTextTexture: TTexture;
  gDataTextures: array[0..TOTAL_DATA - 1] of TTexture;

  // Data points
  gData: array[0.. TOTAL_DATA - 1] of Sint32;

// Starts up SDL and creates window
function Init(): boolean; forward;
// Loads media
function LoadMedia(): boolean; forward;
// Frees media and shuts down SDL
procedure Close(); forward;

procedure Main;
var
  quit, renderText: boolean;
  e: TSDL_Event;
  textColor: TSDL_Color;
  inputText: string;
  tempText: PAnsiChar;
  i: integer;
begin
  // Start up SDL and create window
  if not Init then
  begin
    WriteLn('Failed to initialize!');
  end
  else
  begin
    gPromptTextTexture := TTexture.Create(gRenderer);

    for i := 0 to TOTAL_DATA - 1 do
      gDataTextures[i] := TTexture.Create(gRenderer);

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

      // Set text color as black
      textColor := SDL_Color(0, 0, 0, $FF);

      //The current input text.
      inputText := 'Some Text';

      // Enable text input
      SDL_StartTextInput;

      // While application is running
      while not quit do
      begin
        // The rerender text flag
        renderText := false;

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

            // Handle backspace
            if (e.key.keysym.sym = SDLK_BACKSPACE) and (inputText.Length > 0) then
            begin
              //lop off character
              inputText := inputText + Chr(SDLK_BACKSPACE);
              renderText := true;
            end
            // Handle copy
            else if (e.key.keysym.sym = SDLK_c) and (SDL_GetModState() and KMOD_CTRL <> 0) then
            begin
              SDL_SetClipboardText(inputText.ToPAnsiChar);
            end
            // Handle paste
            else if (e.key.keysym.sym = SDLK_v) and (SDL_GetModState() and KMOD_CTRL <> 0) then
            begin
              //Copy text from temporary buffer
              tempText := Default(PAnsiChar);
              tempText := SDL_GetClipboardText();
              inputText := tempText;
              SDL_free(tempText);

              renderText := true;
            end;
          end
          // Special text input event
          else if e.type_ = SDL_TEXTINPUT then
          begin
            //Not copy or pasting
            if not ((SDL_GetModState() and KMOD_CTRL <> 0)
              and (e.Text.Text[0] = 'c')
              or (e.Text.Text[0] = 'C')
              or (e.Text.Text[0] = 'v')
              or (e.Text.Text[0] = 'V')) then
            begin
              //Append character
              inputText += e.Text.Text;
              renderText := true;
            end;
          end;
        end;

        // Clear screen
        SDL_SetRenderDrawColor(gRenderer, $FF, $FF, $FF, $FF);
        SDL_RenderClear(gRenderer);

        //Render text textures
        gPromptTextTexture.Render((SCREEN_WIDTH - gPromptTextTexture.GetWidth()) div 2, 0);

        // Update screen
        SDL_RenderPresent(gRenderer);
      end;

      // Disable text input
      SDL_StopTextInput();
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
  ttfLazy = '../Source/33_file_reading_and_writing/lazy.ttf';
  fileName = '../Source/33_file_reading_and_writing/nums.bin';
var
  success: boolean;
  textColor, highlightColor: TSDL_Color;
  file_: PSDL_RWops;
  i: integer;
begin
  // Text rendering color
  textColor := SDL_Color(0, 0, 0, 0);
  highlightColor := SDL_Color(0, 0, 0, 0);

  // Loading success flag
  success := boolean(true);

  // Open the font
  gFont := TTF_OpenFont(CrossFixFileName(ttfLazy).ToPAnsiChar, 28);
  if gFont = nil then
  begin
    WriteLnF('Failed to load lazy font! SDL_ttf Error: %s\', [SDL_GetError()]);
    success := false;
  end
  else
  begin
    gPromptTextTexture.Font := gFont;
    if not gPromptTextTexture.LoadFromRenderedText('Enter Text:', textColor) then
    begin
      WriteLn('Failed to render prompt text!');
      success := false;
    end;
  end;

  //Open file for reading in binary
  file_ := PSDL_RWops(nil);
  file_ := SDL_RWFromFile(CrossFixFileName(fileName).ToPAnsiChar, 'r+b'.ToPAnsiChar);

  // File does not exist
  if file_ = nil then
  begin
    WriteLnF('Warning: Unable to open file! SDL Error: %s', [SDL_GetError()]);

    // Create file for writing
    file_ := SDL_RWFromFile(CrossFixFileName(fileName).ToPAnsiChar, 'w+b'.ToPAnsiChar);
    if file_ <> nil then
    begin
      WriteLn('New file created!');

      // Initialize data
      for i := 0 to TOTAL_DATA - 1 do
      begin
        gData[i] := 0;
        SDL_RWwrite(file_, &gData[i], sizeof(Sint32), 1);
      end;

      //Close file handler
      SDL_RWclose(file_);
    end
    else
    begin
      WriteLnF('Error: Unable to create file! SDL Error: %s', [SDL_GetError()]);
      success := false;
    end;
  end
  else // File exists
  begin
    //Load data
    WriteLn('Reading file...!');
    for i := 0 to TOTAL_DATA - 1 do
      SDL_RWread(file_, @gData[i], SizeOf(SInt32), 1);

    // Close file handler
    SDL_RWclose(file_);
  end;

  // Initialize data textures
  gDataTextures[0].Font := gFont;
  gDataTextures[0].LoadFromRenderedText(gData[0].ToString, highlightColor);
  for i := 1 to TOTAL_DATA - 1 do
  begin
    gDataTextures[i].Font := gFont;
    gDataTextures[i].LoadFromRenderedText(gData[i].ToString, textColor);
  end;

  Result := success;
end;

procedure Close();
begin


  for i := 0 to TOTAL_DATA - 1 do
    gDataTextures[i].Free;

  gPromptTextTexture.Free;

  // Free global font
  TTF_CloseFont(gFont);
  gFont := nil;

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
end;

destructor TDot.Destroy;
begin
  inherited Destroy;
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

procedure TDot.Move();
begin
  // Move the dot left or right
  _PosX += _VelX;

  // If the dot went too far to the left or right
  if (_PosX < 0) or (_PosX + DOT_WIDTH > LEVEL_WIDTH) then
  begin
    // Move back
    _PosX -= _VelX;
  end;

  // Move the dot up or down
  _PosY += _VelY;

  // If the dot went too far up or down
  if (_PosY < 0) or (_PosY + DOT_HEIGHT > LEVEL_HEIGHT) then
  begin
    // Move back
    _PosY -= _VelY;
  end;
end;

procedure TDot.Render;
begin
  // Show the dot
  _Texture.render(_PosX, _PosY);
end;

{ TTexture }

constructor TTexture.Create(aRenderer: PSDL_Renderer);
begin
  _Renderer := aRenderer;
end;

procedure TTexture.Clean;
begin
  // Free texture if it exists
  if _Texture <> nil then
  begin
    SDL_DestroyTexture(_Texture);
    _Texture := nil;
    _Width := 0;
    _Height := 0;
  end;
end;

destructor TTexture.Destroy;
begin
  Clean;

  inherited Destroy;
end;

function TTexture.GetHeight: integer;
begin
  Result := _Height;
end;

function TTexture.GetWidth: integer;
begin
  Result := _Width;
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
      _Width := loadedSurface^.w;
      _Height := loadedSurface^.h;
    end;

    SDL_FreeSurface(loadedSurface);
  end;

  _Texture := newTexture;
  Result := _Texture <> nil;
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
    _Texture := SDL_CreateTextureFromSurface(_Renderer, textSurface);
    if _Texture = nil then
    begin
      WriteLnF('Unable to create texture from rendered text! SDL Error: %s', [SDL_GetError()]);
    end
    else
    begin
      // Get image dimensions
      _Width := textSurface^.w;
      _Height := textSurface^.h;
    end;
  end;

  // Return success
  Result := _Texture <> nil;
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
  renderQuad.w := _Width;
  renderQuad.h := _Height;

  // Set clip rendering dimensions
  if clip <> nil then
  begin
    renderQuad.w := clip^.w;
    renderQuad.h := clip^.h;
  end;

  SDL_RenderCopyEx(_Renderer, _Texture, clip, @renderQuad, angle, center, flip);
end;

procedure TTexture.SetAlpha(alpha: byte);
begin
  // Modulate texture alpha
  SDL_SetTextureAlphaMod(_Texture, alpha);
end;

procedure TTexture.SetBlendMode(blending: TSDL_BlendMode);
begin
  // Set blending function
  SDL_SetTextureBlendMode(_Texture, blending);
end;

procedure TTexture.SetColor(red, green, blue: byte);
begin
  // Modulate texture
  SDL_SetTextureColorMod(_Texture, red, green, blue);
end;

end.
