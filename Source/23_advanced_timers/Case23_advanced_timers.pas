unit Case23_advanced_timers;

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
  SDL2_Tutorials.Utils,
  DeepStar.Utils;

type
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
  gTimeTextTexture, gPausePromptTexture, gStartPromptTexture: TTexture;

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
  timeText: TStringBuilder;
  timer: TTimer;
  textColor: TSDL_Color;
begin
  // Start up SDL and create window
  if not Init then
  begin
    WriteLn('Failed to initialize!');
  end
  else
  begin
    gTimeTextTexture := TTexture.Create;
    gPausePromptTexture := TTexture.Create;
    gStartPromptTexture := TTexture.Create;
    timeText := TStringBuilder.Create;

    // The application timer
    timer := TTimer.Create;
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

        // Set text color as black
        textColor := SDL_Color(0, 0, 0, $FF);

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

                SDLK_s:
                begin
                  if timer.IsStarted then
                  begin
                    timer.Stop;
                  end
                  else
                  begin
                    timer.Start;
                  end;
                end;

                SDLK_p:
                begin
                  if timer.IsPaused then
                  begin
                    timer.Unpause;
                  end
                  else
                  begin
                    timer.Pause;
                  end;
                end;
              end;
            end;
          end;

          //Set text to be rendered
          timeText.Clear;
          timeText.Append('Seconds since start time ');
          timeText.Append(timer.GetTicks / 1000);

          if not gTimeTextTexture.LoadFromRenderedText(timeText.ToString, textColor) then
          begin
            WriteLn('Unable to render time texture!');
          end;

          // Clear screen
          SDL_SetRenderDrawColor(gRenderer, $FF, $FF, $FF, $FF);
          SDL_RenderClear(gRenderer);

          // Render textures
          gStartPromptTexture.Render((SCREEN_HEIGHT - gStartPromptTexture.Width) div 2, 0);
          gPausePromptTexture.Render((SCREEN_WIDTH - gPausePromptTexture.Width) div 2,
            gPausePromptTexture.Height);
          gTimeTextTexture.Render((SCREEN_WIDTH - gStartPromptTexture.Width) div 2,
            (SCREEN_HEIGHT - gTimeTextTexture.Height) div 2);

          // Update screen
          SDL_RenderPresent(gRenderer);
        end;
      end;
    finally
      timer.Free;
      timeText.Free;
      gTimeTextTexture.Free;
      gPausePromptTexture.Free;
      gStartPromptTexture.Free;
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
  ttfLazy = '../Source/23_advanced_timers/lazy.ttf';
var
  success: boolean;
  textColor: TSDL_Colour;
begin
  // Loading success flag
  success := boolean(true);

  // Open the font
  gFont := TTF_OpenFont(CrossFixFileName(ttfLazy).ToPAnsiChar, 28);
  if gFont = nil then
  begin
    WriteLnF('Failed to load lazy font! SDL_ttf Error: %s', [SDL_GetError()]);
    success := false;
  end
  else
  begin
    // Set text color as black
    textColor := Default(TSDL_Colour);
    with textColor do
    begin
      r := 0;
      g := 0;
      b := 0;
      a := 255;
    end;

    // Load stop prompt texture
    if not gStartPromptTexture.LoadFromRenderedText('Press S to Start or Stop the Timer.',
      textColor) then
    begin
      WriteLn('Unable to render start/stop prompt texture!');
      success := false;
    end;

    // Load pause prompt texture
    if not gPausePromptTexture.LoadFromRenderedText('Press P to Pause or Unpause the Timer.',
      textColor) then
    begin
      WriteLn('Unable to render pause/unpause prompt texture!');
      success := false;
    end;
  end;

  Result := success;
end;

procedure Close();
begin
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
