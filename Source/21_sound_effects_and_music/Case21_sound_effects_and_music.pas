unit Case21_sound_effects_and_music;

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

const
  SCREEN_WIDTH = 640;
  SCREEN_HEIGHT = 480;

var
  // The window we'll be rendering to
  gWindow: PSDL_Window = nil;

  // The window renderer
  gRenderer: PSDL_Renderer = nil;

  // Scene texture
  gSplashTexture: TTexture;

  // Globally used font
  gFont: PTTF_Font = nil;

  // The music that will be played
  gMusic: PMix_Music;

  // The sound effects that will be used
  gScratch, gHigh, gMedium, gLow: PMix_Chunk;

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
    gSplashTexture := TTexture.Create;
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

                //Play high sound effect
                SDLK_1: Mix_PlayChannel(-1, gHigh, 0);

                //Play medium sound effect
                SDLK_2: Mix_PlayChannel(-1, gMedium, 0);

                //Play low sound effect
                SDLK_3: Mix_PlayChannel(-1, gLow, 0);

                //Play scratch sound effect
                SDLK_4: Mix_PlayChannel(-1, gScratch, 0);

                SDLK_9:
                begin
                  if Mix_PlayingMusic() = 0 then
                  begin
                    // Play the music
                    Mix_PlayMusic(gMusic, -1);
                  end
                  else // If music is being played
                  begin
                    // If the music is paused
                    if Mix_PausedMusic() = 1 then
                    begin
                      //Resume the music
                      Mix_ResumeMusic();
                    end
                    else //If the music is playing
                    begin
                      //Pause the music
                      Mix_PauseMusic();
                    end;
                  end;
                end;

                //Stop the music
                SDLK_0: Mix_HaltMusic;
              end;
            end;
          end;

          // Clear screen
          SDL_SetRenderDrawColor(gRenderer, $FF, $FF, $FF, $FF);
          SDL_RenderClear(gRenderer);

          // Render splash image
          gSplashTexture.render(0, 0);

          //Update screen
          SDL_RenderPresent(gRenderer);
        end;
      end;
    finally
      gSplashTexture.Free;
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

        if Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 2048) < 0 then
        begin
          WriteLnF('SDL_mixer could not initialize! SDL_mixer Error: %s',
            [SDL_GetError()]);
          success := false;
        end;
      end;
    end;
  end;

  Result := success;
end;

function LoadMedia(): boolean;
const
  imgPrompt = '../Source/21_sound_effects_and_music/prompt.png';
  wavBeat = '../Source/21_sound_effects_and_music/beat.wav';
  wavScratch = '../Source/21_sound_effects_and_music/scratch.wav';
  wavHigh = '../Source/21_sound_effects_and_music/high.wav';
  wavMedium = '../Source/21_sound_effects_and_music/medium.wav';
  wavLow = '../Source/21_sound_effects_and_music/Low.wav';
var
  success: boolean;
begin
  // Loading success flag
  success := boolean(true);

  // Load arrow texture
  if not gSplashTexture.loadFromFile(imgPrompt) then
  begin
    WriteLn('Failed to load prompt texture!');
    success := false;
  end;

  // Load music
  gMusic := Mix_LoadMUS(CrossFixFileName(wavBeat).ToPAnsiChar);
  if gMusic = nil then
  begin
    WriteLnF('Failed to load beat music! SDL_mixer Error: %s', [SDL_GetError()]);
		success := false;
  end;

  // Load sound effects
  gScratch := Mix_LoadWAV(CrossFixFileName(wavScratch).ToPAnsiChar);
  if gScratch = nil then
  begin
    WriteLnF('Failed to load Scratch music! SDL_mixer Error: %s', [SDL_GetError()]);
		success := false;
  end;

  gHigh := Mix_LoadWAV(CrossFixFileName(wavHigh).ToPAnsiChar);
  if gScratch = nil then
  begin
    WriteLnF('Failed to load High music! SDL_mixer Error: %s', [SDL_GetError()]);
		success := false;
  end;

  gMedium := Mix_LoadWAV(CrossFixFileName(wavMedium).ToPAnsiChar);
  if gScratch = nil then
  begin
    WriteLnF('Failed to load Medium music! SDL_mixer Error: %s', [SDL_GetError()]);
		success := false;
  end;

  gLow := Mix_LoadWAV(CrossFixFileName(wavLow).ToPAnsiChar);
  if gScratch = nil then
  begin
    WriteLnF('Failed to load Low music! SDL_mixer Error: %s', [SDL_GetError()]);
		success := false;
  end;

  Result := success;
end;

procedure Close();
begin
  // Free the sound effects
  Mix_FreeChunk(gScratch);
  Mix_FreeChunk(gHigh);
  Mix_FreeChunk(gMedium);
  Mix_FreeChunk(gLow);
  gScratch := nil;
  gHigh := nil;
  gMedium := nil;
  gLow := nil;

  // Free the music
  Mix_FreeMusic(gMusic);
  gMusic := nil;

  //Destroy window
  SDL_DestroyRenderer(gRenderer);
  SDL_DestroyWindow(gWindow);
  gWindow := nil;
  gRenderer := nil;

  // Quit SDL subsystems
  Mix_Quit();
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
