unit Case39_tiling.Tile;

{$mode ObjFPC}{$H+}

interface

uses
  Classes,
  SysUtils,
  libSDL2;

type
  PTile = ^TTile;
  TTile = object
  private
    //The attributes of the tile
    _Box: TSDL_Rect;

    //The tile type
    _Type: integer;

  public
    constructor Init(x, y, tileType: integer);
    destructor Done;

    //Shows the tile
		procedure Render( var camera: TSDL_Rect );

		//Get the tile type
    function GetType(): Integer;

		//Get the collision box
		function GetBox(): TSDL_Rect;
  end;


implementation

uses Case39_tiling;

{ TTile }

constructor TTile.Init(x, y, tileType: integer);
begin
  inherited;

  //Get the offsets
    _Box.x := x;
    _Box.y := y;

    //Set the collision box
    _Box.w := TILE_WIDTH;
    _Box.h := TILE_HEIGHT;

    //Get the tile type
    _Type := tileType;
end;

destructor TTile.Done;
begin
  inherited;
end;

function TTile.GetBox(): TSDL_Rect;
begin
  Result := _Box;
end;

function TTile.GetType(): Integer;
begin
  Result := _Type;
end;

procedure TTile.Render(var camera: TSDL_Rect);
begin
  //If the tile is on screen
  if CheckCollision(camera, _Box) then
  begin
    //Show the tile
    gTileTexture.Render(_Box.x - camera.x, _Box.y - camera.y, @gTileClips[_Type]);
  end;
end;

end.
