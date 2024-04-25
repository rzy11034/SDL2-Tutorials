unit Case41_bitmap_fonts.BitmapFont;

{$mode ObjFPC}{$H+}
{$ModeSwitch unicodestrings}{$J-}

interface

uses
  Classes,
  SysUtils,
  libSDL2,
  DeepStar.Utils,
  Case41_bitmap_fonts.Texture;

type
  PBitmapFont = ^TBitmapFont;
  TBitmapFont = object
  private
    //The font texture
    _FontTexture: TTexture;

    //The individual characters in the surface
    _Chars: array[0..255] of TSDL_Rect;

    //Spacing Variables
    _NewLine, _Space: integer;

  public
    constructor Init();
    destructor Done;

    //Generates the font
    function BuildFont(path: string): boolean;

    //Deallocates font
    procedure Free();

    //Shows the text
    procedure RenderText(x, y: integer; Text: string);
  end;


implementation

{ TBitmapFont }

constructor TBitmapFont.Init();
begin
  inherited;

  _NewLine := 0;
  _Space := 0;
end;

function TBitmapFont.BuildFont(path: string): boolean;
var
  success: boolean;
  bgColor: uint32;
  cellW, cellH, top, baseA, currentChar, rows, cols: integer;
  pCol, pRow, pX, pY, pColW, pRowW, i: integer;
begin
  //Get rid of preexisting texture
  Self.Free();

  //Load bitmap image
  success := true;

  if not _FontTexture.loadPixelsFromFile(CrossFixFileName(path)) then
  begin
    WriteLn('Unable to load bitmap font surface!\n');
    success := false;
  end
  else
  begin
    //Get the background color
    bgColor := _FontTexture.GetPixel32(0, 0);

    //Set the cell dimensions
    cellW := _FontTexture.GetWidth() div 16;
    cellH := _FontTexture.GetHeight() div 16;

    //New line variables
    top := cellH;
    baseA := cellH;

    //The current character we're setting
    currentChar := 0;

    //Go through the cell rows
    for rows := 0 to 15 do
    begin
      //Go through the cell columns
      for cols := 0 to 15 do
      begin
        //Set the character offset
        _Chars[currentChar].x := cellW * cols;
        _Chars[currentChar].y := cellH * rows;

        //Set the dimensions of the character
        _Chars[currentChar].w := cellW;
        _Chars[currentChar].h := cellH;

        //Find Left Side
        //Go through pixel columns
        for pCol := 0 to cellW - 1 do
        begin
          //Go through pixel rows
          for pRow := 0 to cellH - 1 do
          begin
            //Get the pixel offsets
            pX := (cellW * cols) + pCol;
            pY := (cellH * rows) + pRow;

            //If a non colorkey pixel is found
            if _FontTexture.GetPixel32(pX, pY) <> bgColor then
            begin
              //Set the x offset
              _Chars[currentChar].x := pX;

              //Break the loops
              pCol := cellW;
              pRow := cellH;
            end;
          end;
        end;

        //Find Right Side
        //Go through pixel columns
        for pColW := cellW - 1 downto 0 do
        begin
          //Go through pixel rows
          for pRowW := 0 to cellH - 1 do
          begin
            //Get the pixel offsets
            pX := (cellW * cols) + pColW;
            pY := (cellH * rows) + pRowW;

            //If a non colorkey pixel is found
            if _FontTexture.GetPixel32(pX, pY) <> bgColor then
            begin
              //Set the width
              _Chars[currentChar].w := (pX - _Chars[currentChar].x) + 1;

              //Break the loops
              pColW := -1;
              pRowW := cellH;
            end;
          end;
        end;

        //Find Top
        //Go through pixel rows
        for pRow := 0 to cellH - 1 do
        begin
          //Go through pixel columns
          for pCol := 0 to cellW - 1 do
          begin
            //Get the pixel offsets
            pX := (cellW * cols) + pCol;
            pY := (cellH * rows) + pRow;

            //If a non colorkey pixel is found
            if _FontTexture.getPixel32(pX, pY) <> bgColor then
            begin
              //If new top is found
              if pRow < top then
              begin
                top := pRow;
              end;

              //Break the loops
              pCol := cellW;
              pRow := cellH;
            end;
          end;
        end;

        //Find Bottom of A
        if currentChar = 'A' then
        begin
          //Go through pixel rows
          for pRow := cellH - 1 downto 0 do
          begin
            //Go through pixel columns
            for pCol := 0 to cellW - 1 do
            begin
              //Get the pixel offsets
              pX := (cellW * cols) + pCol;
              pY := (cellH * rows) + pRow;

              //If a non colorkey pixel is found
              if _FontTexture.GetPixel32(pX, pY) <> bgColor then
              begin
                //Bottom of a is found
                baseA := pRow;

                //Break the loops
                pCol := cellW;
                pRow := -1;
              end;
            end;
          end;
        end;

        //Go to the next character
        currentChar += 1;
      end;
    end;

    //Calculate space
    _Space := cellW div 2;

    //Calculate new line
    _NewLine := baseA - top;

    //Lop off excess top pixels
    for i := 0 to 255 do
    begin
      _Chars[i].y += top;
      _Chars[i].h -= top;
    end;

    //Create final texture
    if not _FontTexture.loadFromPixels() then
    begin
      WriteLn('Unable to create font texture!');
      success := false;
    end;
  end;

  Result := success;
end;

destructor TBitmapFont.Done;
begin
  Self.Free;

  inherited;
end;

procedure TBitmapFont.Free();
begin
  _FontTexture.Free;
end;

procedure TBitmapFont.RenderText(x, y: integer; Text: string);
var
  curX, curY, i, ascii: integer;
begin
  //If the font has been built
  if _FontTexture.GetWidth() > 0 then
  begin
    //Temp offsets
    curX := x;
    curY := y;

    //Go through the text
    for i := 0 to Text.Length - 1 do
    begin
      //If the current character is a space
      if Text.Chars[i] = ' ' then
      begin
        //Move over
        curX += _Space;
      end
      //If the current character is a newline
      else if Text.Chars[i] = #$10 then
      begin
        //Move down
        curY += mNewLine;

        //Move back
        curX := x;
      end
      else
      begin
        //Get the ASCII value of the character
        ascii := Ord(Text[i]);

        //Show the character
        _FontTexture.Render(curX, curY, @_Chars[ascii]);

        //Move over the width of the character with one pixel of padding
        curX += _Chars[ascii].w + 1;
      end;
    end;
  end;
end;

end.
