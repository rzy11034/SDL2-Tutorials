unit Case10_color_keying.LTexture;

{$mode ObjFPC}{$H+}
{$ModeSwitch unicodestrings}{$J-}

interface

uses
  Classes,
  SysUtils,
  libSDL2;

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
    procedure render(x, y: integer);

    property Width: integer read _width;
    property Height: integer read _height;
  end;

implementation

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
  Clean;
  inherited Destroy;
end;

function TTexture.LoadFromFile(path: string): boolean;
begin

end;

procedure TTexture.render(x, y: integer);
begin

end;

end.
