unit UFigureBase;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,Graphics,UFigure,Dialogs, ExtCtrls, UScale, Controls, Spin, StdCtrls, Buttons,
  UParams, LCLType, FPCanvas, TypInfo, LCL, LCLIntf, Math,
  FileUtil, Forms,
  Menus
  ;
type
  Trans = record
    transporate:boolean;
    index:integer;
    trFigure:TFigure;
  end;

  TTool = class
  public
    FigureClass:TFigureClass;
    Names,Pic:string;
    ParPanel:TPanel;
    Poligon: TDoubleRect;
    PSize: TDoublePoint;
    WTop, WBottom: TDoublePoint;
    delta: integer;
    rBtnPressed:boolean;
    Transp:Trans;
    LastScrollBarHor, LastScrollBarVert: integer;
    procedure Scrolling(pb:TPaintBox;ScrollBarHor: TScrollBar;
    ScrollBarVert: TScrollBar);

    procedure CleanSelect;
    procedure MouseDown(APoint:TPoint);virtual;abstract;
    procedure MouseMove(APoint:TPoint);virtual;abstract;
    procedure MouseUp(APoint:TPoint);virtual;abstract;

    procedure PPanelCreate(APanel:TPanel);virtual;
    procedure MinMaxPoints;
    procedure CleanREDOFigures;
    procedure WriteUNDOFigures;
    procedure WriteREDOFigures;
    procedure FiguresDraw(pb:TPaintBox);
end;


  THandTool = class(TTool)
    FirstP:TPoint;
    procedure MouseDown(APoint:TPoint);override;
    procedure MouseMove(APoint:TPoint);override;
    procedure MouseUp(APoint:TPoint);override;
    procedure PPanelCreate(APanel:TPanel);override;
  end;

  TMagnifierTool = class(TTool)
    FirstP:TPoint;
    procedure MouseDown(APoint:TPoint);override;
    procedure MouseMove(APoint:TPoint);override;
    procedure MouseUp(APoint:TPoint);override;
    procedure PPanelCreate(APanel:TPanel);override;
  end;

  TPolyLineTool = class(TTool)
    ADoublePoint:TDoublePoint;
    procedure MouseDown(APoint:TPoint);override;
    procedure MouseMove(APoint:TPoint);override;
    procedure MouseUp(APoint:TPoint);override;
    procedure PPanelCreate(APanel:TPanel);override;
  end;

  TLineTool = class(TTool)
    ADoublePoint:TDoublePoint;
    procedure MouseDown(APoint:TPoint);override;
    procedure MouseMove(APoint:TPoint);override;
    procedure MouseUp(APoint:TPoint);override;
    procedure PPanelCreate(APanel:TPanel);override;
  end;

  TPenTool = class(TTool)
    ADoublePoint:TDoublePoint;
    procedure MouseDown(APoint:TPoint);override;
    procedure MouseMove(APoint:TPoint);override;
    procedure MouseUp(APoint:TPoint);override;
    procedure PPanelCreate(APanel:TPanel);override;
  end;

  TRectangleTool = class(TTool)
    ADoublePoint:TDoublePoint;
    procedure MouseDown(APoint:TPoint);override;
    procedure MouseMove(APoint:TPoint);override;
    procedure MouseUp(APoint:TPoint);override;
    procedure PPanelCreate(APanel:TPanel);override;
  end;

  TRoundRectTool = class(TTool)
    ADoublePoint:TDoublePoint;
    procedure MouseDown(APoint:TPoint);override;
    procedure MouseMove(APoint:TPoint);override;
    procedure MouseUp(APoint:TPoint);override;
    procedure PPanelCreate(APanel:TPanel);override;
  end;

  TEllipseTool = class(TTool)
    ADoublePoint:TDoublePoint;
    procedure MouseDown(APoint:TPoint);override;
    procedure MouseMove(APoint:TPoint);override;
    procedure MouseUp(APoint:TPoint);override;
    procedure PPanelCreate(APanel:TPanel);override;
  end;

  TSelectTool = class(TTool)
    FirstP:TPoint;
    iFigure:TFigure;
    GPColor:TColor;
    GPStyle:TPenStyle;
    GPWidth:integer;
    GRoundedX:integer;
    GRoundedY:integer;
    GBColor:TColor;
    GBStyle:TBrushStyle;
    bigselected:boolean;
    lineselected:boolean;
    ADoublePoint:TDoublePoint;
    ADPoints:Array of TDoublePoint;
    procedure MouseDown(APoint:TPoint);override;
    procedure MouseMove(APoint:TPoint);override;
    procedure MouseUp(APoint:TPoint);override;
    procedure PPanelCreate(APanel:TPanel);override;
  end;

  procedure DeleteFigure;
  procedure LayerDown;
  procedure LayerUp;

var
  Tools:array of TTool;
  ArrPoints:Array of TDoublePoint;
  AParam: TParam;
  MaxPoint, MinPoint:TDoublePoint;
  writePL:boolean;
implementation

uses Main;

procedure TTool.CleanSelect;
var
  iFigure:TFigure;
begin
  for iFigure in Figures do
    if iFigure.Selected then
      iFigure.Selected:=false;
end;

procedure TTool.PPanelCreate(APanel:TPanel);
begin
  AParam.CreateSpinEdit(APanel, 'Pen Width', PenWidthInt, @AParam.PenWidthChange);
  AParam.CreateComboBox(APanel, 'Pen Style', TypePenStyle.Name, PenStyle.Index, @AParam.PenStyleChange);
  AParam.CreateColorButton(APanel, 'Pen Color', PenColor, @AParam.PenColorButtonChanged);
end;

procedure TTool.Scrolling(pb:TPaintBox;ScrollBarHor: TScrollBar;
    ScrollBarVert: TScrollBar);
begin
  Poligon :=DoubleRect(MinPoint, MaxPoint);
 WTop := Canvas2Wrld(Point(0,0));
  if Poligon.Top.X > WTop.x then
     Poligon.Top.x := WTop.x;
  if Poligon.Top.y > WTop.y then
     Poligon.Top.y := WTop.y;
  WBottom := Canvas2Wrld(Point(pb.Width, pb.Height));
  if Poligon.Bottom.x < WBottom.x then
     Poligon.Bottom.x := WBottom.x;
  if Poligon.Bottom.y < WBottom.y then
     Poligon.Bottom.y := WBottom.y;
  PSize.X := Poligon.Bottom.x - Poligon.Top.x;
  PSize.Y := Poligon.Bottom.y - Poligon.Top.y;
  if PSize.x * PSize.y = 0 then exit;

  delta := ScrollBarHor.Max - ScrollBarHor.Min;
  ScrollBarHor.PageSize := round(pb.Width / (PSize.X * Zoom) * delta);
  ScrollBarHor.Visible := ScrollBarHor.PageSize < delta;
  if ScrollBarHor.PageSize < delta then
  begin
    if (LastScrollBarHor = ScrollBarHor.Position) then
      ScrollBarHor.Position := round(((-1) * (offset.x + Poligon.Top.x)) / PSize.X * delta)
    else
      offset.x := (-1) * round(ScrollBarHor.Position / delta * PSize.x + Poligon.Top.x);
    LastScrollBarHor := ScrollBarHor.Position;
  end;

  delta := ScrollBarVert.Max - ScrollBarVert.Min;
  ScrollBarVert.PageSize := round(pb.Height / (PSize.y * Zoom) * delta);
  ScrollBarVert.Visible := ScrollBarVert.PageSize < delta;
  if ScrollBarVert.PageSize < delta then
  begin
    if (LastScrollBarVert = ScrollBarVert.Position) then
      ScrollBarVert.Position := round(((-1) * (offset.y + Poligon.Top.y)) / PSize.Y * delta)
    else
      offset.y := (-1) * round(ScrollBarVert.Position / delta * PSize.y + Poligon.Top.y);
    LastScrollBarVert := ScrollBarVert.Position;
  end;
end;

procedure TTool.MinMaxPoints;
var
  i:TFigure;
begin
  if Length(Figures)>0 then begin
  MaxPoint.x:=Figures[0].maxPoint.x;
  MinPoint.x:=Figures[0].minPoint.x;
  MaxPoint.y:=Figures[0].maxPoint.y;
  MinPoint.y:=Figures[0].minPoint.y;
  end;
  for i in Figures do begin
    if(i.maxPoint.x > MaxPoint.x) then
      MaxPoint.x:=i.maxPoint.x;
    if(i.minPoint.x < MinPoint.x) then
      MinPoint.x:=i.minPoint.x;
    if(i.maxPoint.y > MaxPoint.y) then
      MaxPoint.y:=i.maxPoint.y;
    if(i.minPoint.y < MinPoint.y) then
      MinPoint.y:=i.minPoint.y;
  end;
end;

procedure THandTool.MouseDown(APoint:TPoint);
begin
  FirstP:=APoint;
end;

procedure THandTool.MouseMove(APoint:TPoint);
begin
  Offset.x += round((APoint.x - FirstP.x)/Zoom);
  Offset.y += round((APoint.y - FirstP.y)/Zoom);
  FirstP:=APoint;
end;

procedure THandTool.MouseUp(APoint:TPoint);
begin

end;

procedure THandTool.PPanelCreate(APanel: TPanel);
begin

end;

procedure TLineTool.MouseDown(APoint:TPoint);
begin
  ADoublePoint:=Canvas2Wrld(APoint);
  SetLength(Figures, Length(Figures) + 1);
  Figures[High(Figures)] := TLine.Create;
  SetLength(Figures[High(Figures)].DPoints, length(Figures[High(Figures)].DPoints)+1);
  Figures[High(Figures)].DPoints[High( Figures[High(Figures)].DPoints)]:=ADoublePoint;
  SetLength(Figures[High(Figures)].DPoints, length(Figures[High(Figures)].DPoints)+1);
  Figures[High(Figures)].DPoints[High( Figures[High(Figures)].DPoints)]:=ADoublePoint;
end;

procedure TLineTool.MouseMove(APoint:TPoint);
begin
  ADoublePoint:=Canvas2Wrld(APoint);
  Figures[High(Figures)].DPoints[High(Figures[High(Figures)].DPoints)]:=ADoublePoint;
end;

procedure TLineTool.MouseUp(APoint:TPoint);
begin

end;

procedure TLineTool.PPanelCreate(APanel: TPanel);
begin
  inherited;
end;

procedure TPolyLineTool.MouseDown(APoint:TPoint);
begin
  ADoublePoint:=Canvas2Wrld(APoint);
  SetLength(Figures, Length(Figures) + 1);
  Figures[High(Figures)] := TPenLine.Create;
  SetLength(Figures[High(Figures)].DPoints, length(Figures[High(Figures)].DPoints)+1);
  Figures[High(Figures)].DPoints[High(Figures[High(Figures)].DPoints)]:=ADoublePoint;
  writePL:=true;
end;

procedure TPolyLineTool.MouseMove(APoint:TPoint);
begin
  ADoublePoint:=Canvas2Wrld(APoint);
  SetLength(Figures[High(Figures)].DPoints, length(Figures[High(Figures)].DPoints)+1);
  Figures[High(Figures)].DPoints[High(Figures[High(Figures)].DPoints)]:=ADoublePoint;
end;

procedure TPolyLineTool.MouseUp(APoint:TPoint);
begin

end;

procedure TPolyLineTool.PPanelCreate(APanel: TPanel);
begin
  inherited;
end;

procedure TPenTool.MouseDown(APoint:TPoint);
begin
  ADoublePoint:=Canvas2Wrld(APoint);
  SetLength(Figures, Length(Figures) + 1);
  Figures[High(Figures)] := TPenLine.Create;
  SetLength(Figures[High(Figures)].APoints,length(Figures[High(Figures)].APoints)+1);
  SetLength(Figures[High(Figures)].DPoints, length(Figures[High(Figures)].DPoints)+1);
  Figures[High(Figures)].DPoints[High(Figures[High(Figures)].DPoints)]:=ADoublePoint;
  Figures[High(Figures)].APoints[High(Figures[High(Figures)].APoints)]:=APoint;
end;

procedure TPenTool.MouseMove(APoint:TPoint);
begin
  ADoublePoint:=Canvas2Wrld(APoint);
  SetLength(Figures[High(Figures)].DPoints, length(Figures[High(Figures)].DPoints)+1);
  Figures[High(Figures)].DPoints[High(Figures[High(Figures)].DPoints)]:=ADoublePoint;
  SetLength(Figures[High(Figures)].APoints,length(Figures[High(Figures)].APoints)+1);
  Figures[High(Figures)].APoints[High(Figures[High(Figures)].APoints)]:=APoint;
end;

procedure TPenTool.MouseUp(APoint:TPoint);
begin

end;

procedure TPenTool.PPanelCreate(APanel:TPanel);
begin
  inherited;
end;

procedure TRectangleTool.MouseDown(APoint:TPoint);
begin
  ADoublePoint:=Canvas2Wrld(APoint);
  SetLength(Figures, Length(Figures) + 1);
  Figures[High(Figures)] := TRectangle.Create;
  SetLength(Figures[High(Figures)].DPoints, length(Figures[High(Figures)].DPoints)+1);
  Figures[High(Figures)].DPoints[High(Figures[High(Figures)].DPoints)]:=ADoublePoint;
  SetLength(Figures[High(Figures)].DPoints, length(Figures[High(Figures)].DPoints)+1);
  Figures[High(Figures)].DPoints[High(Figures[High(Figures)].DPoints)]:=ADoublePoint;
end;

procedure TRectangleTool.MouseMove(APoint:TPoint);
begin
  ADoublePoint:=Canvas2Wrld(APoint);
  Figures[High(Figures)].DPoints[High(Figures[High(Figures)].DPoints)]:=ADoublePoint;
end;

procedure TRectangleTool.MouseUp(APoint:TPoint);
begin

end;

procedure TRectangleTool.PPanelCreate (APanel: TPanel);
begin
  AParam.CreateColorButton(APanel, 'Brush Color', BrushColor, @AParam.BrushColorButtonChanged);
  AParam.CreateComboBox(APanel, 'Brush Style', TypeBrushStyle.Name, BrushStyle.Index, @AParam.BrushStyleChange);
  inherited;
end;

procedure TEllipseTool.MouseDown(APoint:TPoint);
begin
  ADoublePoint:=Canvas2Wrld(APoint);
  SetLength(Figures, Length(Figures) + 1);
  Figures[High(Figures)] := TEllipse.Create;
  SetLength(Figures[High(Figures)].DPoints, length(Figures[High(Figures)].DPoints)+1);
  Figures[High(Figures)].DPoints[High( Figures[High(Figures)].DPoints)]:=ADoublePoint;
  SetLength(Figures[High(Figures)].DPoints, length(Figures[High(Figures)].DPoints)+1);
  Figures[High(Figures)].DPoints[High( Figures[High(Figures)].DPoints)]:=ADoublePoint;
end;

procedure TEllipseTool.MouseMove(APoint:TPoint);
begin
  ADoublePoint:=Canvas2Wrld(APoint);
  Figures[High(Figures)].DPoints[High( Figures[High(Figures)].DPoints)]:=ADoublePoint;
end;

procedure TEllipseTool.MouseUp(APoint:TPoint);
begin

end;

procedure TEllipseTool.PPanelCreate(APanel: TPanel);
begin
  AParam.CreateColorButton(APanel, 'Brush Color', BrushColor, @AParam.BrushColorButtonChanged);
  AParam.CreateComboBox(APanel, 'Brush Style', TypeBrushStyle.Name, BrushStyle.Index, @AParam.BrushStyleChange);
  inherited;
end;

procedure TRoundRectTool.MouseDown(APoint:TPoint);
begin
  ADoublePoint:=Canvas2Wrld(APoint);
  SetLength(Figures, Length(Figures) + 1);
  Figures[High(Figures)] := TRoundRect.Create;
  SetLength(Figures[High(Figures)].DPoints, length(Figures[High(Figures)].DPoints)+1);
  Figures[High(Figures)].DPoints[High( Figures[High(Figures)].DPoints)]:=ADoublePoint;
  SetLength(Figures[High(Figures)].DPoints, length(Figures[High(Figures)].DPoints)+1);
  Figures[High(Figures)].DPoints[High( Figures[High(Figures)].DPoints)]:=ADoublePoint;
end;

procedure TRoundRectTool.MouseMove(APoint:TPoint);
begin
  ADoublePoint:=Canvas2Wrld(APoint);
  Figures[High(Figures)].DPoints[High( Figures[High(Figures)].DPoints)]:=ADoublePoint;
end;

procedure TRoundRectTool.MouseUp(APoint:TPoint);
begin

end;

procedure TRoundRectTool.PPanelCreate(APanel: TPanel);
begin
  AParam.CreateColorButton(APanel, 'Brush Color', BrushColor, @AParam.BrushColorButtonChanged);
  AParam.CreateComboBox(APanel, 'Brush Style', TypeBrushStyle.Name, BrushStyle.Index, @AParam.BrushStyleChange);
  AParam.CreateSpinEdit(APanel, 'Round Y', RoundY, @AParam.RoundYChange);
  AParam.CreateSpinEdit(APanel, 'Round X', RoundX, @AParam.RoundXChange);
  inherited;
end;

procedure TSelectTool.MouseDown(APoint:TPoint);
const
  k=5;
var
  i:integer;
  TL,BR:TPoint;
begin
  if not rBtnPressed then begin
    ADoublePoint:=Canvas2Wrld(APoint);
    SetLength(Figures, Length(Figures) + 1);
    Figures[High(Figures)] := TSelect.Create;

    SetLength(ADPoints,Length(ADPoints)+1);
    ADPoints[high(ADPoints)]:=ADoublePoint;
    SetLength(ADPoints,Length(ADPoints)+1);
    ADPoints[high(ADPoints)]:=ADoublePoint;

    SetLength(Figures[High(Figures)].DPoints, length(Figures[High(Figures)].DPoints)+1);
    Figures[High(Figures)].DPoints[High( Figures[High(Figures)].DPoints)]:=ADoublePoint;
    SetLength(Figures[High(Figures)].DPoints, length(Figures[High(Figures)].DPoints)+1);
    Figures[High(Figures)].DPoints[High( Figures[High(Figures)].DPoints)]:=ADoublePoint;

  end
  else if rBtnPressed  then begin
    FirstP:=APoint;
     for iFigure in Figures do begin
       if iFigure.Selected then
         for i:=0 to Length(iFigure.DPoints)do begin
           TL:=Point(Wrld2Canvas(iFigure.DPoints[i]).x-k-iFigure.PWidth div 2,Wrld2Canvas(iFigure.DPoints[i]).y-k-iFigure.PWidth div 2);
           BR:=Point(Wrld2Canvas(iFigure.DPoints[i]).x+k+iFigure.PWidth div 2,Wrld2Canvas(iFigure.DPoints[i]).y+k+iFigure.PWidth div 2);
           if iFigure.CheckRectangle(TL,BR,APoint) then begin
             Transp.transporate:=true;
             Transp.index:=i;
             Transp.trFigure:=iFigure;
           {end
           else
           TLF1:=Point(Wrld2Canvas(iFigure.DPoints[1]).x-k-iFigure.PWidth div 2,Wrld2Canvas(iFigure.DPoints[0]).y-k-iFigure.PWidth div 2);
           BRF1:=Point(Wrld2Canvas(iFigure.DPoints[1]).x+k+iFigure.PWidth div 2,Wrld2Canvas(iFigure.DPoints[0]).y+k+iFigure.PWidth div 2);
           TLF0:=Point(Wrld2Canvas(iFigure.DPoints[0]).x-k-iFigure.PWidth div 2,Wrld2Canvas(iFigure.DPoints[1]).y-k-iFigure.PWidth div 2);
           BRF0:=Point(Wrld2Canvas(iFigure.DPoints[0]).x+k+iFigure.PWidth div 2,Wrld2Canvas(iFigure.DPoints[1]).y+k+iFigure.PWidth div 2);
           if iFigure.CheckRectangle(TLF1,BRF1,APoint)then begin
             Transp.transporate:=true;
             Transp.index:=1;
             Transp.trFigure:=iFigure;
           end
           else if iFigure.CheckRectangle(TLF0,BRF0,APoint)then begin
             Transp.transporate:=true;
             Transp.index:=0;
             Transp.trFigure:=iFigure;
           end; }
          end;
       end;
    end;
  end;
end;

procedure TSelectTool.MouseMove(APoint:TPoint);
var
  i:integer;
begin
  ADoublePoint:=Canvas2Wrld(APoint);
  if not rBtnPressed then begin
    ADPoints[high(ADPoints)]:=ADoublePoint;
    Figures[High(Figures)].DPoints[High( Figures[High(Figures)].DPoints)]:=ADoublePoint;
  end
  else if not Transp.transporate then begin
    for iFigure in Figures do begin
    if iFigure.Selected then begin
      if iFigure.CheckRectangle(Wrld2Canvas(iFigure.LTop),Wrld2Canvas(iFigure.RBottom),FirstP) then begin
      for i:=0 to Length(iFigure.DPoints)-1 do begin
         iFigure.DPoints[i].x += round((APoint.x - FirstP.x)/Zoom);
         iFigure.DPoints[i].y += round((APoint.y - FirstP.y)/Zoom);
       end;
       FirstP:=APoint;
       end;
      end;
    end;

  end
  else begin
  for iFigure in Figures do begin
    if iFigure.Selected then begin
      Transp.trFigure.DPoints[Transp.index].x += ((APoint.x - FirstP.x)/Zoom);
      Transp.trFigure.DPoints[Transp.index].y += ((APoint.y - FirstP.y)/Zoom);
      FirstP:=APoint;
    end;
   end;
  end;
end;

procedure TSelectTool.MouseUp(APoint:TPoint);
var
  i:integer;
begin

  if (Length(ADPoints)) = 2 then
    if (abs(ADPoints[0].x - ADPoints[1].x) < 2) and
       (abs(ADPoints[0].y - ADPoints[1].y) < 2) then
      SetLength(ADPoints, length(ADPoints) - 1);

  if (length(ADPoints) = 1) then begin
    for iFigure in Figures do begin
      iFigure.CheckPtIn(Wrld2Canvas(ADPoints[0]));
    end;
    SetLength(ADPoints, length(ADPoints)- 1);
  end;

  if (length(ADPoints) = 2) then begin
    for iFigure in Figures do
      iFigure.CheckRect(Wrld2Canvas(ADPoints[0]), Wrld2Canvas(ADPoints[1]));
    SetLength(ADPoints, length(ADPoints) - 2);
    end;

  if Figures[High(Figures)].ClassName = 'TSelect' then
    SetLength(Figures, length(Figures) - 1);
  if rBtnPressed then begin
    rBtnPressed:=false;
    Transp.transporate:=false;
  end;


end;

procedure TSelectTool.PPanelCreate(APanel: TPanel);
begin
   bigselected:=false;
   lineselected:=false;
    for iFigure in Figures do begin
      if (iFigure.Selected) then begin
          GPColor:=iFigure.PColor;
          GPStyle:=iFigure.PStyle;
          GPWidth:=iFigure.PWidth;
          GRoundedX:=iFigure.RoundedX;
          GRoundedY:=iFigure.RoundedY;
          GBColor:=iFigure.BColor;
          GBStyle:=iFigure.BStyle;
          BrushStyle.Index:=iFigure.BStyleInd;
          PenStyle.Index:=iFigure.PStyleInd;
        if iFigure.ClassParent = TFillFigures then
          bigselected:=true
        else
          lineselected:=true;
      end;
    end;

  if lineselected then begin
    AParam.CreateComboBox(APanel, 'Pen Style', TypePenStyle.Name, PenStyle.Index, @AParam.SelectedPenStyleChange);
    AParam.CreateColorButton(APanel, 'Pen Color', GPColor, @AParam.SelectedPenColorButtonChanged);
    AParam.CreateSpinEdit(APanel, 'Pen Width', GPWidth, @AParam.SelectedPenWidthChange);
  end
  else if bigselected then begin
    if (GRoundedY or GRoundedX)<> 0 then begin
      AParam.CreateSpinEdit(APanel, 'Round Y', GRoundedY, @AParam.SelectedRoundYChange);
      AParam.CreateSpinEdit(APanel, 'Round X', GRoundedX, @AParam.SelectedRoundXChange);
    end;
    AParam.CreateColorButton(APanel, 'Brush Color', GBColor, @AParam.SelectedBrushColorButtonChanged);
    AParam.CreateComboBox(APanel, 'Brush Style', TypeBrushStyle.Name, BrushStyle.Index, @AParam.SelectedBrushStyleChange);
    AParam.CreateComboBox(APanel, 'Pen Style', TypePenStyle.Name, PenStyle.Index, @AParam.SelectedPenStyleChange);
    AParam.CreateColorButton(APanel, 'Pen Color', GPColor, @AParam.SelectedPenColorButtonChanged);
    AParam.CreateSpinEdit(APanel, 'Pen Width', GPWidth, @AParam.SelectedPenWidthChange);
  end;
  AParam.CreateDeleteButton(Apanel,@MainForm.ButtonDeleteFigure);

end;

procedure DeleteFigure;
var
  i, j: integer;
begin
  j := 0;

  for i := 0 to high(Figures) do
    if (Figures[i].Selected) then
      FreeAndNil(Figures[i])
    else begin
      Figures[j] := Figures[i];
      inc(j);
    end;

  SetLength(Figures, j);
end;

procedure LayerDown;
var
  i, j: integer;
  Buff: array of TFigure;
begin
  j := high(Figures);
  SetLength(Buff, 0);

  for i := high(Figures) downto 0 do
    if (Figures[i].Selected) then begin
      SetLength(Buff, length(Buff) + 1);
      Buff[high(Buff)] := Figures[i];
    end else begin
      Figures[j] := Figures[i];
      Dec(j);
    end;

  for i := 0 to j do
    Figures[i] := Buff[j - i];
  end;

procedure LayerUp;
var
  i, j: integer;
  Buff: array of TFigure;
begin
  j := 0;
  SetLength(Buff, 0);

  for i := 0 to high(Figures) do
    if (Figures[i].Selected) then begin
      SetLength(Buff, length(Buff) + 1);
      Buff[high(Buff)] := Figures[i];
    end else begin
      Figures[j] := Figures[i];
      inc(j);
    end;

  for i := j to high(Figures) do
    Figures[i] := Buff[i - j];
end;



procedure TMagnifierTool.MouseDown(APoint:TPoint);
begin
  //FirstP:=APoint;
end;

procedure TMagnifierTool.MouseMove(APoint:TPoint);
begin

end;

procedure TMagnifierTool.MouseUp(APoint:TPoint);
const
  ZoomStep=1;
begin
  {if (Button = mbLeft) then begin
    if Zoom=FloatSpinZoom.Value then
      if FloatSpinZoom.Value < ZoomStep then
        FloatSpinZoom.Value:=FloatSpinZoom.Value+(ZoomStep div 10)
      else
        FloatSpinZoom.Value:=FloatSpinZoom.Value+(ZoomStep);
    Zoom:=FloatSpinZoom.Value;
    Offset.x:=round(((Offset.x-x)*Zoom/LastZoom)+x);
    Offset.y:=round(((Offset.y-y)*Zoom/LastZoom)+y);
    LastZoom:=Zoom;
  end else if (Button = mbRight)then begin
    if Zoom=FloatSpinZoom.Value then
      if FloatSpinZoom.Value <= ZoomStep then
        FloatSpinZoom.Value:=FloatSpinZoom.Value-(ZoomStep div 10)
      else
        FloatSpinZoom.Value:=FloatSpinZoom.Value-(ZoomStep);
    Zoom:=FloatSpinZoom.Value;
    Offset.x:=round(((Offset.x-x)*Zoom/LastZoom)+x);
    Offset.y:=round(((Offset.y-y)*Zoom/LastZoom)+y);
    LastZoom:=Zoom;
  end;  }
end;

procedure TMagnifierTool.PPanelCreate(APanel: TPanel);
begin

end;


procedure TTool.CleanREDOFigures;
begin
  SetLength(REDOFigures,0);
end;

procedure TTool.writeUNDOFigures;
begin
  if Length(Figures) > 0 then begin
    SetLength(REDOFigures,Length(REDOFigures)+1);
    REDOFigures[High(REDOFigures)]:=Figures[High(Figures)];
    SetLength(Figures,High(Figures));
  end;
end;

procedure TTool.WriteREDOFigures;
begin
  if Length(REDOFigures)>0 then begin
     SetLength(Figures,Length(Figures)+1);
     Figures[High(Figures)]:=REDOFigures[High(REDOFigures)];
     SetLength(REDOFigures,High(REDOFigures));
  end;
end;

procedure TTool.FiguresDraw(pb:TPaintBox);
var
  i:integer;
  AFigure:TFigure;
begin
  for i:=0 to High(Figures) do begin
    AFigure:=Figures[i];
      AFigure.Draw(pb.Canvas);
  end;
end;

procedure RegisterTool(Tool: TTool; AFigureClass: TFigureClass;AName:String;APicName:String);
begin
  SetLength(Tools, Length(Tools) + 1);
  Tools[High(Tools)] := Tool;
  Tools[High(Tools)].FigureClass := AFigureClass;
  Tools[High(Tools)].Names:=AName;
  Tools[High(Tools)].Pic:=APicName;
end;

procedure RegisterBrushSt(AStyle: TBrushStyle; AName: string);
begin
  SetLength(TypeBrushStyle.Name, Length(TypeBrushStyle.Name)+1);
  SetLength(TypeBrushStyle.Style, Length(TypeBrushStyle.Style)+1);
  TypeBrushStyle.Name[High(TypeBrushStyle.Name)]:=AName;
  TypeBrushStyle.Style[High(TypeBrushStyle.Style)]:=AStyle;
end;

procedure RegisterPenSt(AStyle: TPenStyle; AName: string);
begin
  SetLength(TypePenStyle.Name, Length(TypePenStyle.Name)+1);
  SetLength(TypePenStyle.Style, Length(TypePenStyle.Style)+1);
  TypePenStyle.Name[High(TypePenStyle.Name)]:=AName;
  TypePenStyle.Style[High(TypePenStyle.Style)]:=AStyle;
end;

initialization
  RegisterTool(TLineTool.Create, TLine,'Line','line.bmp');
  RegisterTool(TRectangleTool.Create, TRectangle,'Rectangle','rectangle.bmp');
  RegisterTool(TEllipseTool.Create, TEllipse,'Ellipse','ellipse.bmp');
  RegisterTool(TPolylineTool.Create, TLine,'Polyline','lines.bmp');
  RegisterTool(THandTool.Create, nil ,'Hand', 'hand.bmp');
  RegisterTool(TPenTool.Create, TPenLine,'Pen', 'pencil.bmp');
  RegisterTool(TRoundRectTool.Create, TRoundRect,'RoundRect','roundrect.bmp');
  //RegisterTool(TMagnifierTool.Create, nil ,'Magnifier','pencil.bmp');
  RegisterTool(TSelectTool.Create, nil ,'Select','select.bmp');


  RegisterBrushSt(bsBDiagonal, 'BDiagonal');
  RegisterBrushSt(bsFDiagonal, 'FDiagonal');
  RegisterBrushSt(bsCross, 'Cross');
  RegisterBrushSt(bsDiagCross, 'Diag Cross');
  RegisterBrushSt(bsHorizontal, 'Horizontal');
  RegisterBrushSt(bsVertical, 'Vertical');
  RegisterBrushSt(bsSolid, 'Solid');

  RegisterPenSt(psDash, 'Dash');
  RegisterPenSt(psDashDot, 'Dash-Dot');
  RegisterPenSt(psDashDotDot, 'Dash-Dot-Dot');
  RegisterPenSt(psDot, 'Dot');
  RegisterPenSt(psInsideframe, 'Inside Frame');
  RegisterPenSt(psSolid, 'Solid');
end.

