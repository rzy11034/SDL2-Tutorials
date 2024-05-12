unit Case38_particle_engines.Texture;

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

  public
    constructor Init;
    destructor Done;

    // Loads image at specified path
    function LoadFromFile(path: string): boolean;

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

    function GetHeight: integer;
    function GetWidth: integer;
  end;


implementation

uses
  Case38_particle_engines;

constructor TTexture.Init;
begin
  inherited;
end;

destructor TTexture.Done;
begin
  Free;
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
  Free;

  // The final texture
  newTexture := PSDL_Texture(nil);

  // Load image at specified path
  loadedSurface := PSDL_Surface(nil);
  loadedSurface := IMG_Load(CrossFixFileName(path).ToPAnsiChar);
  if loadedSurface = nil then
  begin
    WriteLn('Unable to load image %s! SDL_image Error: ', path);
  end
  else
  begin
    // Color key image
    SDL_SetColorKey(loadedSurface, Ord(SDL_TRUE),
      SDL_MapRGB(loadedSurface^.format, 0, $FF, $FF));

    // Create texture from surface pixels
    newTexture := SDL_CreateTextureFromSurface(gRenderer, loadedSurface);
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
  Free;

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
