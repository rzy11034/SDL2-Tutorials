unit Case34_audio_recording;

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
  DeepStar.UString;

type
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

type
  //The various recording actions we can take
  TRecordingState = (
    SELECTING_DEVICE,
    STOPPED,
    RECORDING,
    RECORDED,
    PLAYBACK,
    ERROR);

const
  // Screen dimension constants
  SCREEN_WIDTH = 640;
  SCREEN_HEIGHT = 480;

  //Maximum number of supported recording devices
  MAX_RECORDING_DEVICES = 10;

  //Maximum recording time
  MAX_RECORDING_SECONDS = 5;

  //Maximum recording time plus padding
  RECORDING_BUFFER_SECONDS = MAX_RECORDING_SECONDS + 1;

var
  // The window we'll be rendering to
  gWindow: PSDL_Window = nil;

  // The window renderer
  gRenderer: PSDL_Renderer = nil;

  // Globally used font
  gFont: PTTF_Font = nil;
  gTextColor: TSDL_Color = (r: 0; g: 0; b: 0; a: $FF);

  // Scene texture
  gPromptTexture: TTexture;

  //The text textures that specify recording device names
  gDeviceTextures: array[0.. MAX_RECORDING_DEVICES - 1] of TTexture;

  //Number of available devices
  gRecordingDeviceCount: integer = 0;

  //Received audio spec
  gReceivedRecordingSpec: TSDL_AudioSpec;
  gReceivedPlaybackSpec: TSDL_AudioSpec;

  //Recording data buffer
  gRecordingBuffer: array of byte = nil;

  //Size of data buffer
  gBufferByteSize: uint32 = 0;

  //Position in data buffer
  gBufferBytePosition: uint32 = 0;

  //Maximum position in data buffer for recording
  gBufferByteMaxPosition: uint32 = 0;

// Starts up SDL and creates window
function Init(): boolean; forward;
// Loads media
function LoadMedia(): boolean; forward;
// Frees media and shuts down SDL
procedure Close(); forward;

//Recording/playback callbacks
procedure AudioRecordingCallback(userdata: Pointer; stream: PUInt8; len: integer); cdecl; forward;
procedure AudioPlaybackCallback(userdata: Pointer; stream: PUInt8; len: integer); cdecl; forward;


procedure Main;
var
  quit: boolean;
  e: TSDL_Event;
  i, index, bytesPerSample, bytesPerSecond, yOffset: integer;
  currentState: TRecordingState;
  recordingDeviceId, playbackDeviceId: TSDL_AudioDeviceID;
  desiredRecordingSpec, desiredPlaybackSpec: TSDL_AudioSpec;
begin
  // Start up SDL and create window
  if not Init then
  begin
    WriteLn('Failed to initialize!');
  end
  else
  begin
    gPromptTexture := TTexture.Create(gRenderer);

    for i := 0 to High(gDeviceTextures) do
      gDeviceTextures[i] := TTexture.Create(gRenderer);

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

      //Set the default recording state
      currentState := TRecordingState.SELECTING_DEVICE;

      //Audio device IDs
      recordingDeviceId := TSDL_AudioDeviceID(0);
      playbackDeviceId := TSDL_AudioDeviceID(0);

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

          //Do current state event handling
          case currentState of
            //User is selecting recording device
            SELECTING_DEVICE:
            begin
              //On key press
              if e.type_ = SDL_KEYDOWN then
              begin
                // Handle key press from 0 to 9
                if (e.key.keysym.sym >= SDLK_0) and (e.key.keysym.sym <= SDLK_9) then
                begin
                  // Get selection index
                  index := integer(0);
                  index := e.key.keysym.sym - SDLK_0;

                  // Index is valid
                  if index < gRecordingDeviceCount then
                  begin
                    // Default audio spec
                    desiredRecordingSpec := Default(TSDL_AudioSpec);
                    desiredRecordingSpec.freq := 44100;
                    desiredRecordingSpec.format := AUDIO_F32;
                    desiredRecordingSpec.channels := 2;
                    desiredRecordingSpec.samples := 4096;
                    desiredRecordingSpec.callback := @AudioRecordingCallback;

                    //Open recording device
                    recordingDeviceId := SDL_OpenAudioDevice(
                      SDL_GetAudioDeviceName(index, Ord(SDL_TRUE)), Ord(SDL_TRUE), @desiredRecordingSpec,
                      @gReceivedRecordingSpec, SDL_AUDIO_ALLOW_FORMAT_CHANGE);

                    //Device failed to open
                    if recordingDeviceId = 0 then
                    begin
                      //Report error
                      WriteF('Failed to open recording device! SDL Error: %s', [SDL_GetError()]);
                      gPromptTexture.LoadFromRenderedText('Failed to open recording device!', gTextColor);
                      currentState := ERROR;
                    end
                    //Device opened successfully
                    else
                    begin
                      // Default audio spec
                      desiredPlaybackSpec := Default(TSDL_AudioSpec);
                      desiredPlaybackSpec.freq := 44100;
                      desiredPlaybackSpec.format := AUDIO_F32;
                      desiredPlaybackSpec.channels := 2;
                      desiredPlaybackSpec.samples := 4096;
                      desiredPlaybackSpec.callback := @AudioPlaybackCallback;

                      //Open playback device
                      playbackDeviceId := SDL_OpenAudioDevice(nil, Ord(SDL_FALSE),
                        @desiredPlaybackSpec, @gReceivedPlaybackSpec, SDL_AUDIO_ALLOW_FORMAT_CHANGE);

                      //Device failed to open
                      if playbackDeviceId = 0 then
                      begin
                        //Report error
                        WriteLnF('Failed to open playback device! SDL Error: %s', [SDL_GetError()]);
                        gPromptTexture.LoadFromRenderedText('Failed to open playback device!', gTextColor);
                        currentState := ERROR;
                      end
                      //Device opened successfully
                      else
                      begin
                        //Calculate per sample bytes
                        bytesPerSample := integer(0);
                        bytesPerSample := gReceivedRecordingSpec.channels *
                          (SDL_AUDIO_BITSIZE(gReceivedRecordingSpec.format) div 8);

                        //Calculate bytes per second
                        bytesPerSecond := integer(0);
                        bytesPerSecond := gReceivedRecordingSpec.freq * bytesPerSample;

                        //Calculate buffer size
                        gBufferByteSize := RECORDING_BUFFER_SECONDS * bytesPerSecond;

                        //Calculate max buffer use
                        gBufferByteMaxPosition := MAX_RECORDING_SECONDS * bytesPerSecond;

                        //Allocate and initialize byte buffer
                        SetLength(gRecordingBuffer, gBufferByteSize);

                        //Go on to next state
                        gPromptTexture.LoadFromRenderedText('Press 1 to record for 5 seconds.', gTextColor);
                        currentState := STOPPED;
                      end;
                    end;
                  end;
                end;
              end;
            end;

            //User getting ready to record
            STOPPED:
            begin
              //On key press
              if e.type_ = SDL_KEYDOWN then
              begin
                //Start recording
                if e.key.keysym.sym = SDLK_1 then
                begin
                  //Go back to beginning of buffer
                  gBufferBytePosition := 0;

                  //Start recording
                  SDL_PauseAudioDevice(recordingDeviceId, Ord(SDL_FALSE));

                  //Go on to next state
                  gPromptTexture.LoadFromRenderedText('Recording...', gTextColor);
                  currentState := RECORDING;
                end;
              end;
            end;


            //User has finished recording
            RECORDED:
            begin
              //On key press
              if e.type_ = SDL_KEYDOWN then
              begin
                //Start playback
                if e.key.keysym.sym = SDLK_1 then
                begin
                  //Go back to beginning of buffer
                  gBufferBytePosition := 0;

                  //Start playback
                  SDL_PauseAudioDevice(playbackDeviceId, Ord(SDL_FALSE));

                  //Go on to next state
                  gPromptTexture.LoadFromRenderedText('Playing...', gTextColor);
                  currentState := PLAYBACK;
                end;

                //Record again
                if e.key.keysym.sym = SDLK_2 then
                begin
                  //Reset the buffer
                  gBufferBytePosition := 0;
                  SetLength(gRecordingBuffer, gBufferByteSize);

                  //Start recording
                  SDL_PauseAudioDevice(recordingDeviceId, Ord(SDL_FALSE));

                  //Go on to next state
                  gPromptTexture.loadFromRenderedText('Recording...', gTextColor);
                  currentState := RECORDING;
                end;
              end;
            end;

            else
          end;
        end;

        //Updating recording
        if currentState = RECORDING then
        begin
          //Lock callback
          SDL_LockAudioDevice(recordingDeviceId);

          //Finished recording
          if gBufferBytePosition > gBufferByteMaxPosition then
          begin
            //Stop recording audio
            SDL_PauseAudioDevice(recordingDeviceId, Ord(SDL_TRUE));

            //Go on to next state
            gPromptTexture.LoadFromRenderedText('Press 1 to play back. Press 2 to record again.', gTextColor);
            currentState := RECORDED;
          end;

          //Unlock callback
          SDL_UnlockAudioDevice(recordingDeviceId);
        end
        //Updating playback
        else if currentState = PLAYBACK then
        begin
          //Lock callback
          SDL_LockAudioDevice(playbackDeviceId);

          //Finished playback
          if gBufferBytePosition > gBufferByteMaxPosition then
          begin
            //Stop playing audio
            SDL_PauseAudioDevice(playbackDeviceId, ord(SDL_TRUE));

            //Go on to next state
            gPromptTexture.loadFromRenderedText(
              'Press 1 to play back. Press 2 to record again.', gTextColor);
            currentState := RECORDED;
          end;

          //Unlock callback
          SDL_UnlockAudioDevice(playbackDeviceId);
        end;

        // Clear screen
        SDL_SetRenderDrawColor(gRenderer, $FF, $FF, $FF, $FF);
        SDL_RenderClear(gRenderer);

        //Render prompt centered at the top of the screen
        gPromptTexture.render((SCREEN_WIDTH - gPromptTexture.GetWidth) div 2, 0);

        //User is selecting
        if currentState = SELECTING_DEVICE then
        begin
          //Render device names
          yOffset := integer(0);
          yOffset := gPromptTexture.GetHeight * 2;
          for i := 0 to gRecordingDeviceCount - 1 do
          begin
            gDeviceTextures[i].Render(0, yOffset);
            yOffset += gDeviceTextures[i].GetHeight + 1;
          end;
        end;

        // Update screen
        SDL_RenderPresent(gRenderer);
      end;
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
  ttfLazy = '../Source/34_audio_recording/lazy.ttf';
var
  success: boolean;
  promptText: TStringBuilder;
  i: integer;
begin
  // Loading success flag
  success := boolean(true);

  // Open the font
  gFont := TTF_OpenFont(CrossFixFileName(ttfLazy).ToPAnsiChar, 24);
  if gFont = nil then
  begin
    WriteLnF('Failed to load lazy font! SDL_ttf Error: %s', [SDL_GetError()]);
    success := false;
  end
  else
  begin
    gPromptTexture.Font := gFont;

    //Set starting prompt
    gPromptTexture.LoadFromRenderedText('Select your recording device:', gTextColor);

    //Get capture device count
    gRecordingDeviceCount := SDL_GetNumAudioDevices(Ord(SDL_TRUE));

    //No recording devices
    if gRecordingDeviceCount < 1 then
    begin
      WriteLnF('Unable to get audio capture device! SDL Error: %s', [SDL_GetError()]);
      success := false;
    end
    //At least one device connected
    else
    begin
      //Cap recording device count
      if gRecordingDeviceCount > MAX_RECORDING_DEVICES then
        gRecordingDeviceCount := MAX_RECORDING_DEVICES;

      //Render device names
      promptText := TStringBuilder.Create;
      try
        for i := 0 to gRecordingDeviceCount - 1 do
        begin
          //Get capture device name
          promptText.Clear;

          promptText.Append(i).Append(': ');
          promptText.Append(SDL_GetAudioDeviceName(i, Ord(SDL_TRUE)));

          //Set texture from name
          gDeviceTextures[i].Font := gFont;
          gDeviceTextures[i].LoadFromRenderedText(promptText.ToString, gTextColor);
        end;
      finally
        FreeAndNil(promptText);
      end;
    end;
  end;

  Result := success;
end;

procedure Close();
var
  i: Integer;
begin
  gPromptTexture.Free;

  for i := 0 to High(gDeviceTextures) do
    gDeviceTextures[i].Free;

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

procedure AudioRecordingCallback(userdata: Pointer; stream: PUInt8; len: integer); cdecl;
begin
  // Copy audio from stream
  Move(gRecordingBuffer[gBufferBytePosition], stream^, len);

  // Move along buffer
  gBufferBytePosition += len;
end;

procedure AudioPlaybackCallback(userdata: Pointer; stream: PUInt8; len: integer); cdecl;
begin
  //Copy audio to stream
  Move(stream^, gRecordingBuffer[gBufferBytePosition], len);

  //Move along buffer
  gBufferBytePosition += len;
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
  textSurface := TTF_RenderUTF8_Solid(_Font, textureText.ToPAnsiChar, textColor);

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
