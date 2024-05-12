unit Case41_bitmap_fonts.Texture;

{$mode ObjFPC}{$H+}
{$ModeSwitch unicodestrings}{$J-}

interface

uses
  Classes,
  SysUtils,
  DeepStar.Utils,
  libSDL2,
  libSDL2_ttf,
  libSDL2_image;

type
  PTexture = ^TTexture;
  TTexture = object
  private
    _Height: integer;
    _Width: integer;
    _Texture: PSDL_Texture;
    _SurfacePixels: PSDL_Surface;

  public
    constructor Init;
    destructor Done;

    // Loads image at specified path
    function LoadFromFile(path: string): boolean;

    //Loads image into pixel buffer
    function loadPixelsFromFile(path: string): boolean;

    //Creates image from preloaded pixels
    function loadFromPixels(): boolean;

    // Creates image from font string
    function LoadFromRenderedText(textureText: string; textColor: TSDL_Color): boolean;

    // Deallocates texture
    procedure Free;

    // Renders texture at given point
    procedure Render(x, y: integer; clip: PSDL_Rect = nil; angle: double = 0;
      center: PSDL_Point = nil; flip: TSDL_RendererFlags = SDL_FLIP_NONE);

    //Set color modulation
    procedure SetColor(red, green, blue: byte);

    //Set blending
    procedure SetBlendMode(blending: TSDL_BlendMode);

    //Set alpha modulation
    procedure SetAlpha(alpha: byte);

    //Gets image dimensions
    function GetHeight: integer;
    function GetWidth: integer;

    //Pixel accessors
    function GetPixel32(x, y: uint32): uint32;
    function GetPixels32(): PUInt32;
    function GetPitch32(): uint32;
    function MapRGBA(r, g, b, a: uint8): uint32;
  end;


implementation

uses
  Case41_bitmap_fonts;

constructor TTexture.Init;
begin
  inherited;
end;

procedure TTexture.Free;
begin
  // Free texture if it exists
  if _Texture <> nil then
  begin
    SDL_DestroyTexture(_Texture);
    _Texture := nil;
    _Width := 0;
    _Height := 0;
  end;

  //Free surface if it exists
  if _SurfacePixels <> nil then
  begin
    SDL_FreeSurface(_SurfacePixels);
    _SurfacePixels := nil;
  end;
end;

destructor TTexture.Done;
begin
  Self.Free;
  inherited;
end;

function TTexture.GetHeight: integer;
begin
  Result := _Height;
end;

function TTexture.GetPitch32(): uint32;
var
  pitch: integer;
begin
  pitch := 0;

  if _SurfacePixels <> nil then
  begin
    pitch := _SurfacePixels^.pitch div 4;
  end;

  Result := pitch;
end;

function TTexture.GetPixel32(x, y: uint32): uint32;
var
  pixels: PUInt32;
begin
  //Convert the pixels to 32 bit
  pixels := PUInt32(_SurfacePixels^.pixels);

  //Get the pixel requested
  Result := pixels[(y * GetPitch32()) + x];
end;

function TTexture.GetPixels32(): PUInt32;
var
  pixels: PUInt32;
begin
  pixels := PUInt32(nil);

  if _SurfacePixels <> nil then
  begin
    pixels := PUInt32(_SurfacePixels^.pixels);
  end;

  Result := pixels;
end;

function TTexture.GetWidth: integer;
begin
  Result := _Width;
end;

function TTexture.LoadFromFile(path: string): boolean;
begin
  //Load pixels
  if not loadPixelsFromFile(path) then
  begin
    WriteLnF('Failed to load pixels for %s!', [path]);
  end
  else
  begin
    //Load texture from pixels
    if not loadFromPixels() then
      WriteLnF('Failed to texture from pixels from %s!', [path]);
  end;

  Result := _Texture <> nil;
end;

function TTexture.loadFromPixels(): boolean;
begin
  //Only load if pixels exist
  if _SurfacePixels = nil then
  begin
    WriteLn('No pixels loaded!');
  end
  else
  begin
    //Color key image
    SDL_SetColorKey(_SurfacePixels, Ord(SDL_TRUE),
      SDL_MapRGB(_SurfacePixels^.format, 0, $FF, $FF));

    //Create texture from surface pixels
    _Texture := SDL_CreateTextureFromSurface(gRenderer, _SurfacePixels);
    if _Texture = nil then
    begin
      WriteLnF('Unable to create texture from loaded pixels! SDL Error: %s', [SDL_GetError()]);
    end
    else
    begin
      //Get image dimensions
      _Width := _SurfacePixels^.w;
      _Height := _SurfacePixels^.h;
    end;

    //Get rid of old loaded surface
    SDL_FreeSurface(_SurfacePixels);
    _SurfacePixels := nil;
  end;

  //Return success
  Result := _Texture <> nil;
end;

function TTexture.LoadFromRenderedText(textureText: string; textColor: TSDL_Color): boolean;
var
  textSurface: PSDL_Surface;
begin
  // Get rid of preexisting texture
  Self.Free();

  // Render text surface
  textSurface := PSDL_Surface(nil);
  textSurface := TTF_RenderUTF8_Solid(gFont, textureText.ToPAnsiChar, textColor);

  if textSurface = nil then
  begin
    WriteLnF('Unable to render text surface! SDL_ttf Error: %s', [SDL_GetError()]);
  end
  else
  begin
    // Create texture from surface pixels
    _Texture := SDL_CreateTextureFromSurface(gRenderer, textSurface);
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

function TTexture.loadPixelsFromFile(path: string): boolean;
var
  loadedSurface: PSDL_Surface;
begin
  //Free preexisting assets
  Free();

  //Load image at specified path
  loadedSurface := PSDL_Surface(nil);
  loadedSurface := IMG_Load(CrossFixFileName(path).ToPAnsiChar);
  if loadedSurface = nil then
  begin
    WriteLnF('Unable to load image %s! SDL_image Error: %s', [path, SDL_GetError()]);
  end
  else
  begin
    //Convert surface to display format
    _SurfacePixels := SDL_ConvertSurfaceFormat(loadedSurface, SDL_GetWindowPixelFormat(gWindow), 0);
    if _SurfacePixels = nil then
    begin
      WriteLnF('Unable to convert loaded surface to display format! SDL Error: %s', [SDL_GetError()]);
    end
    else
    begin
      //Get image dimensions
      _Width := _SurfacePixels^.w;
      _Height := _SurfacePixels^.h;
    end;

    //Get rid of old loaded surface
    SDL_FreeSurface(loadedSurface);
  end;

  Result := _SurfacePixels <> nil;
end;

function TTexture.MapRGBA(r, g, b, a: uint8): uint32;
var
  pixel: uint32;
begin
  pixel := uint32(0);

  if _SurfacePixels <> nil then
  begin
    pixel := SDL_MapRGBA(_SurfacePixels^.format, r, g, b, a);
  end;

  Result := pixel;
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

  SDL_RenderCopyEx(gRenderer, _Texture, clip, @renderQuad, angle, center, flip);
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
