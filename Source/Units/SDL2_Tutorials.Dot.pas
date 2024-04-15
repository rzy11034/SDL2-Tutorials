unit SDL2_Tutorials.Dot;

{$mode ObjFPC}{$H+}

interface

uses
  Classes,
  SysUtils,
  libSDL2,
  SDL2_Tutorials.Texture;

type
  TDot = class(TObject)
  public const
    // The dimensions of the dot
    DOT_WIDTH = 20;
    DOT_HEIGHT = 20;
    //Maximum axis velocity of the dot
    DOT_VEL = 10;

  private
    _Texture: TTexture;

    _ScreenWidth, _ScreenHeight: integer;

    //The X and Y offsets of the dot
    _PosX, _PosY: integer;

    //The velocity of the dot
    _VelX, _VelY: integer;

    // Dot's collision box
    _Collider: TSDL_Rect;

  public
    constructor Create(aWindows: PSDL_Window; aTexture: TTexture);
    destructor Destroy; override;

    // Takes key presses and adjusts the dot's velocity
    procedure HandleEvent(var e: TSDL_Event);

    // Moves the dot
    procedure Move(var wall: TSDL_Rect);

    // Shows the dot on the screen
    procedure Render();

    function CheckCollision(a, b: TSDL_Rect): boolean;
  end;

implementation

{ TDot }

constructor TDot.Create(aWindows: PSDL_Window; aTexture: TTexture);
begin
  _ScreenWidth := aWindows^.w;
  _ScreenHeight := aWindows^.h;
  _Texture := aTexture;

  // Initialize the offsets
  _PosX := 0;
  _PosY := 0;

  // Set collision box dimension
  _Collider.w := DOT_WIDTH;
  _Collider.h := DOT_HEIGHT;

  // Initialize the velocity
  _VelX := 0;
  _VelY := 0;
end;

function TDot.CheckCollision(a, b: TSDL_Rect): boolean;
begin

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

procedure TDot.Move(var wall: TSDL_Rect);
begin
  //Move the dot left or right
  _PosX += _VelX;
  _Collider.x := _PosX;

  //If the dot went too far to the left or right
  if (_PosX < 0) or (_PosX + DOT_WIDTH > _ScreenWidth)
    or CheckCollision(_Collider, wall) then
  begin
    //Move back
    _PosX -= _VelX;
    _Collider.x := _PosX;
  end;

  // Move the dot up or down
  _PosY += _VelY;
  _Collider.y := _PosY;

  // If the dot went too far up or down
  if (_PosY < 0) or (_PosY + DOT_HEIGHT > _ScreenHeight)
    or CheckCollision(_Collider, wall) then
  begin
    //Move back
    _PosY -= _VelY;
    _Collider.y := _PosY
  end;
end;

procedure TDot.Render();
begin
  // Show the dot
  _Texture.render(_PosX, _PosY);
end;

end.
