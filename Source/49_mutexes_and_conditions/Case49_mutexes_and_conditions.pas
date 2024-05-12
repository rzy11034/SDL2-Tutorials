unit Case49_mutexes_and_conditions;

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
  SDL2_Tutorials.Header_file_supplement,
  Case49_mutexes_and_conditions.Texture;

const
  //Screen dimension constants
  SCREEN_WIDTH = 640;
  SCREEN_HEIGHT = 480;
  SCREEN_FPS = 60;

var
  //The window we'll be rendering to
  gWindow: PSDL_Window;

  //The window renderer
  gRenderer: PSDL_Renderer;

  // Font
  gFont: PTTF_Font;

  //Scene textures
  gSplashTexture: TTexture;

  //The protective mutex
  gBufferLock: PSDL_Mutex = nil;

  //The conditions
  gCanProduce: PSDL_Cond = nil;
  gCanConsume: PSDL_Cond = nil;

  //The "data buffer"
  gData: integer = -1;

procedure Main;
// Starts up SDL and creates window
function Init(): boolean;
//Loads media
function LoadMedia(): boolean;
// Frees media and shuts down SDL
procedure Close();

//Our worker functions
function producer(Data: Pointer): integer; cdecl;
function consumer(Data: Pointer): integer; cdecl;
procedure produce();
procedure consume();

implementation

function Init(): boolean;
var
  success: boolean;
  imgFlags: integer;
begin
  success := boolean(true);

  // Initialize SDL
  if SDL_Init(SDL_INIT_VIDEO or SDL_INIT_TIMER) < 0 then
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

function LoadMedia: boolean;
var
  success: boolean;
begin
  //Create the mutex
  gBufferLock := SDL_CreateMutex();

  //Create conditions
  gCanProduce := SDL_CreateCond();
  gCanConsume := SDL_CreateCond();

  //Loading success flag
  success := true;

  //Load blank texture
  if not gSplashTexture.LoadFromFile('../Source/49_mutexes_and_conditions/splash.png') then
  begin
    WriteLn('Failed to load dot texture!');
    success := false;
  end;

  Result := success;
end;

procedure Close();
begin
  //Free loaded images
  gSplashTexture.Free();

  //Destroy the mutex
  SDL_DestroyMutex(gBufferLock);
  gBufferLock := nil;

  //Destroy conditions
  SDL_DestroyCond(gCanProduce);
  SDL_DestroyCond(gCanConsume);
  gCanProduce := nil;
  gCanConsume := nil;

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

function producer(Data: Pointer): integer; cdecl;
var
  i: integer;
begin
  WriteLn;
  WriteLn('Producer started...');

  RandSeed := SDL_GetTicks();

  //Produce
  for i := 0 to 4 do
  begin
    //Wait
    SDL_Delay(Random(MaxInt) mod 1000);

    //Produce
    produce();
  end;

  WriteLn;
  WriteLn('Producer finished!');

  Result := 0;
end;

function consumer(Data: Pointer): integer; cdecl;
var
  i: integer;
begin
  WriteLn;
  WriteLn('Consumer started...');

  //Seed thread random
  RandSeed := SDL_GetTicks();

  for i := 0 to 4 do
  begin
    //Wait
    SDL_Delay(Random(MaxInt) mod 1000);

    //Consume
    consume;
  end;

  WriteLn;
  WriteLn('Consumer finished!');

  Result := 0;
end;

procedure produce();
begin
  //Lock
  SDL_LockMutex(gBufferLock);

  //If the buffer is full
  if gData <> -1 then
  begin
    //Wait for buffer to be cleared
    Write(LineEnding);
    WriteLn('Producer encountered full buffer, waiting for consumer to empty buffer...');
    SDL_CondWait(gCanProduce, gBufferLock);
  end;

  //Fill and show buffer
  gData := Random(MaxInt) mod 255;
  Write(LineEnding);
  WriteLnF('Produced %d', [gData]);

  //Unlock
  SDL_UnlockMutex(gBufferLock);

  //Signal consumer
  SDL_CondSignal(gCanConsume);
end;

procedure consume();
begin
  //Lock
  SDL_LockMutex(gBufferLock);

  //If the buffer is empty
  if gData = -1 then
  begin
    //Wait for buffer to be filled
    Write(LineEnding);
    WriteLn('Consumer encountered empty buffer, waiting for producer to fill buffer...');
    SDL_CondWait(gCanConsume, gBufferLock);
  end;

  //Show and empty buffer
  Write(LineEnding);
  WriteLnF('Consumed %d', [gData]);
  gData := -1;

  //Unlock
  SDL_UnlockMutex(gBufferLock);

  //Signal producer
  SDL_CondSignal(gCanProduce);
end;

procedure Main;
var
  quit: boolean;
  e: TSDL_Event;
  producerThread, consumerThread: PSDL_Thread;
  strA, strB: string;
begin
  // Start up SDL and create window
  if not Init then
  begin
    WriteLn('Failed to initialize!');
  end
  else
  begin
    //Load media
    if not loadMedia() then
    begin
      WriteLn('Failed to load media!');
    end
    else
    begin
      // Main loop flag
      quit := false;
      //Event handler
      e := Default(TSDL_Event);

      RandSeed := SDL_GetTicks();

      producerThread := PSDL_Thread(nil);
      strA := 'Producer';
      producerThread := SDL_CreateThread(@producer, strA.ToPAnsiChar, nil);

      consumerThread := PSDL_Thread(nil);
      strB := 'Consumer';
      consumerThread := SDL_CreateThread(@consumer, strB.ToPAnsiChar, nil);

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
        end;

        //Clear screen
        SDL_SetRenderDrawColor(gRenderer, $FF, $FF, $FF, $FF);
        SDL_RenderClear(gRenderer);

        //Render splash
        gSplashTexture.render(0, 0);

        //Update screen
        SDL_RenderPresent(gRenderer);
      end;

      //Wait for threads to finish
      SDL_WaitThread(consumerThread, nil);
      SDL_WaitThread(producerThread, nil);
    end;
  end;

  // Free resources and close SDL
  Close();
end;

end.
