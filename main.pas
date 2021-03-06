unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,LCLType,
  Menus,Buttons, StdCtrls, Spin, UFigureBase, UScale, UParams, superobject,UFigure;



type

{ TMainForm }

  TMainForm = class(TForm)

    FLoatSpinZoom: TFloatSpinEdit;
    MainMenu: TMainMenu;
    MenuExit: TMenuItem;
    MenuAbout: TMenuItem;
    MenuFile: TMenuItem;
    MenuF1: TMenuItem;
    ExportBtn: TMenuItem;
    MenuItemSave: TMenuItem;
    MenuItemLoad: TMenuItem;
    MenuItemSaveAs: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItemUp: TMenuItem;
    MenuItemDown: TMenuItem;
    OpenD: TOpenDialog;
    SaveD: TSaveDialog;
    ExportD: TSaveDialog;
    ScrollBarHor: TScrollBar;
    ScrollBarVert: TScrollBar;
    ToolsPanel: TPanel;
    Pb: TPaintBox;
    PPanel:TPanel;
    procedure BtnUndoCreate;
    procedure BtnRedoCreate;
    procedure BitUNDOClick(Sender: TObject);
    procedure BitREDOClick(Sender: TObject);
    procedure FLoatSpinZoomChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure MenuAboutClick(Sender: TObject);
    procedure MenuExitClick(Sender: TObject);
    procedure ExportBtnClick(Sender: TObject);
    procedure MenuItemSaveClick(Sender: TObject);
    procedure MenuItemLoadClick(Sender: TObject);
    procedure MenuItemSaveAsClick(Sender: TObject);
    procedure MenuItemUpClick(Sender: TObject);
    procedure MenuItemDownClick(Sender: TObject);
    procedure PanelCreate;
    procedure PanelDelete;
    procedure ScrollBarHorScroll(Sender: TObject; ScrollCode: TScrollCode;
      var ScrollPos: Integer);
    procedure ScrollBarVertScroll(Sender: TObject; ScrollCode: TScrollCode;
      var ScrollPos: Integer);
    procedure ToolsButtonClick(Sender : TObject);
    procedure PbMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PbMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure PbMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PbPaint(Sender: TObject);


  private
     panelchange:boolean;
     isDrawing:boolean;
     FileName:String;
    { private declarations }
  public

    { public declarations }
  end;

var
  MainForm: TMainForm;
  ATool: TTool;

implementation

{$R *.lfm}


{ TMainForm }

procedure TMainForm.PanelCreate;
begin
  PPanel:=TPanel.Create(MainForm);
  PPanel.Parent:=MainForm;
  PPanel.Anchors:=[akTop,akLeft];
  PPanel.Name:='PPanel';
  PPanel.Caption:='';
  PPanel.Width:=100;
  PPanel.Height:=330;
  PPanel.Top:=250;
  PPanel.Left:=0;
  ATool.WritePL:=false;
  ATool.AfterConstruction;
  ATool.ParPanel:=PPanel;
  ATool.PPanelCreate(PPanel);
end;

procedure TMainForm.PanelDelete;
begin
  if FindComponent('PPanel') <> nil then
    FindComponent('PPanel').Free;
end;

procedure TMainForm.MenuExitClick(Sender: TObject);
begin
  close();
end;

procedure TMainForm.ExportBtnClick(Sender: TObject);
var
  Bitmap: TBitmap;
  PNG: TPortableNetworkGraphic;
  JPG: TJPEGImage;
begin
    if ExportD.Execute then begin
      ExportD.Title := 'Export';
      Bitmap := TBitmap.Create;
      Bitmap.LoadFromDevice(PB.Canvas.Handle);
      Bitmap.Width := PB.Width;
      Bitmap.Height := PB.Height;
        case ExportD.FilterIndex of
        1:
          begin
            Bitmap.SaveToFile(ExportD.Filename);
            Bitmap.Free;
          end;
        2:
          begin
            PNG := TPortableNetworkGraphic.Create;
            PNG.Assign(Bitmap);
            PNG.SaveToFile(ExportD.Filename);
            PNG.Free;
          end;
        3:
          begin
            JPG := TJPEGImage.Create;
            JPG.Assign(Bitmap);
            JPG.SaveToFile(ExportD.Filename);
            JPG.Free;
          end
        end;
        ShowMessage('Успешно');
    end;
end;

procedure TMainForm.MenuItemSaveClick(Sender: TObject);
var
 save:TextFile;
begin
  if FileName <> 'Unnamed' then begin
    AssignFile(save,FileName);
    Rewrite(save);
    write(save,SaveFile);
    ShowMessage('Сохранено!');
    closefile(save);
  end
  else
    MenuItemSaveAsClick(Sender);
end;

procedure TMainForm.MenuItemLoadClick(Sender: TObject);
var
  load:TextFile;
  buf,s:string;
begin
  if OpenD.Execute then begin
    AssignFile(load,OpenD.FileName);
    Reset(load);
    while not EOF(load) do begin
      Readln(load,buf);
      S:=S+buf;
    end;
    closefile(load);
    SetLength(Figures,0);
    LoadFile(S);
    MainForm.Caption:=OpenD.FileName;
    ShowMessage('Загружено');
    Changing:=false;
  end;
end;

procedure TMainForm.MenuItemSaveAsClick(Sender: TObject);
var
  save:TextFile;
begin
  if SaveD.Execute then begin
    AssignFile(save,SaveD.FileName);
    Rewrite(save);
    write(save,SaveFile);
    MainForm.Caption:=SaveD.FileName;
    FileName:=SaveD.FileName;
    ShowMessage('Сохранено!');
    closefile(save);
    Changing:=false;
  end;
end;

procedure TMainForm.MenuItemUpClick(Sender: TObject);
begin
  LayerDown;
  pb.Invalidate;
end;

procedure TMainForm.MenuItemDownClick(Sender: TObject);
begin
  LayerUp;
  pb.Invalidate;
end;

procedure TMainForm.ScrollBarHorScroll(Sender: TObject;
  ScrollCode: TScrollCode; var ScrollPos: Integer);
begin
  pb.Invalidate;
end;

procedure TMainForm.ScrollBarVertScroll(Sender: TObject;
  ScrollCode: TScrollCode; var ScrollPos: Integer);
begin
  pb.Invalidate;
end;

procedure TMainForm.MenuAboutClick(Sender: TObject);
begin
  ShowMessage('The vector Editor «RedactoriA» for FEFU hometask'+#10+
  'The development was started in 09.10.17 and finished ____'+ #10+#10+
  'Anton Mikhailenko, 2017, Telegram: @toxaxab');
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key=Ord('Z')) and (ssCtrl in Shift) and (isDrawing=false)then begin
     ATool.WriteUNDOFigures;
     pb.Invalidate;
  end;
  if (key=Ord('Y')) and (ssCtrl in Shift) and (isDrawing=false)then begin
     ATool.WriteREDOFigures;
     pb.Invalidate;
  end;

  if (key=Ord('C')) and (ssCtrl in Shift) and (isDrawing=false)then begin
     CopyFigure;
     pb.Invalidate;
  end;

  if (key=Ord('V')) and (ssCtrl in Shift) and (isDrawing=false)then begin
     PasteFigure;
     pb.Invalidate;
  end;

  if (key=Ord('S')) and (ssCtrl in Shift) and (isDrawing=false)then begin
     MenuItemSaveClick(Sender);
     pb.Invalidate;
  end;

   if (key=Ord('O')) and (ssCtrl in Shift) and (isDrawing=false)then begin
     MenuItemLoadClick(Sender);
     pb.Invalidate;
  end;

  if (key=VK_ADD)      or (key=VK_OEM_PLUS)  then
    FLoatSpinZoom.Value := FLoatSpinZoom.Value + 10;
  if (key=VK_SUBTRACT) or (key=VK_OEM_MINUS) then
    FLoatSpinZoom.Value := FLoatSpinZoom.Value - 1;
  if (key=46) and (isDrawing=false)then begin
     AParam.DeleteFigure(Sender);
     pb.Invalidate;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  AButton: TBitBtn;
  i: integer;
begin
  Forma:=MainForm;
  LastZoom:=Zoom;
  Zoom:= 1.0;
  Offset:= Point(0,0);
  isDrawing:=false;
  UPDpb:=Pb;
  BtnUndoCreate;
  BtnRedoCreate;
  UndoRedoL.Data:=TStringList.Create;
  UndoRedoL.Current:=Push(UndoRedoL,SaveFile);
  FileName:='Unnamed';
  for i:=0 to High(Tools) do
  begin
    AButton := TBitBtn.Create(ToolsPanel);
    AButton.Glyph.LoadFromFile(Tools[i].Pic);
    AButton.Top:=50+(i div 2)*50+10;
    if (i mod 2) = 0 then
      AButton.Left:=10
    else
      AButton.Left:=50;
    AButton.Height:=40;
    AButton.Width:=40;
    AButton.Tag := i;
    AButton.Parent := ToolsPanel;
    AButton.onClick := @ToolsButtonClick;
  end;
  FLoatSpinZoom.MinValue := ZOOM_MIN * 100;
  FLoatSpinZoom.MaxValue := ZOOM_MAX * 100;
end;

procedure TMainForm.BtnUndoCreate;
var
  AButton: TBitBtn;
begin
  AButton:=TBitBtn.Create(Self);
  AButton.Caption:='UNDO';
  AButton.Width := ToolsPanel.Width div 2;
  AButton.Height := 50;
  AButton.Top := 0;
  AButton.Parent := ToolsPanel;
  AButton.onClick := @BitUNDOClick;
end;

procedure TMainForm.BtnRedoCreate;
var
  AButton: TBitBtn;
begin
  AButton:=TBitBtn.Create(Self);
  AButton.Caption:='REDO';
  AButton.Width := ToolsPanel.Width div 2;
  AButton.Left := ToolsPanel.Width div 2;
  AButton.Height := 50;
  AButton.Top := 0;
  AButton.Parent := ToolsPanel;
  AButton.onClick := @BitREDOClick;
end;

procedure TMainForm.BitUNDOClick(Sender: TObject);
begin
    ATool.WriteUNDOFigures;
  pb.Invalidate;
end;

procedure TMainForm.BitREDOClick(Sender: TObject);
begin
    ATool.WriteREDOFigures;
  pb.Invalidate;
end;

procedure TMainForm.FLoatSpinZoomChange(Sender: TObject);
begin
  SetScale(FLoatSpinZoom.Value / 100);
  pb.Invalidate;
end;

procedure TMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if Changing then
    if (Application.MessageBox('Сохранить текущий файл?',  'Сохранение',
           MB_ICONQUESTION + MB_YESNO) = IDYES) then begin
             if FileName <> 'Unnamed' then
               MenuItemSave.Click()
             else
               MenuItemSaveAs.Click();
           end;
end;

procedure TMainform.ToolsButtonClick(Sender : TObject);
begin
  ATool := Tools[(Sender as TBitBtn).tag];
    ATool.ClearSelect;
  PanelDelete;
  PanelCreate;
  Invalidate;
end;

procedure TMainForm.PbMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if ssRight in Shift then
    if ATool.ClassName='TSelectTool' then begin
      Atool.rBtnPressed:= not Atool.rBtnPressed;
      ATool.MouseDown(Point(X,Y));
      isDrawing := true;
      ATool.WritePL:=false;
    end;
  if ssLeft in Shift then begin
    isDrawing := true;
    if not ATool.WritePL then
      ATool.MouseDown(Point(X,Y))
    else
      ATool.MouseMove(Point(X,Y));
    end;
  Invalidate;
end;

procedure TMainForm.PbMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer
  );
begin
  if (isDrawing) and (not ATool.WritePL)then  begin
    ATool.MouseMove(Point(X,Y));
  end;
  Invalidate;
end;

procedure TMainForm.PbMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  ATool.MouseUp();
  Push(UndoRedoL,SaveFile);
  isDrawing:=false;
  panelchange:=false;
  Changing:=true;
  Invalidate;
end;

procedure TMainForm.PbPaint(Sender: TObject);
begin
  if (ATool.ClassName='TSelectTool') and (not panelchange) then begin
    panelchange:=true;
    PanelDelete;
    PanelCreate;
    Invalidate;
  end;
  FLoatSpinZoom.Value := Zoom * 100;
  pb.Canvas.Brush.Color:=clWhite;
  pb.Canvas.FillRect(0,0,Width,Height);
  ATool.FiguresDraw(pb);
  ATool.MinMaxPoints;
  ATool.Scrolling(pb,ScrollBarHor,ScrollBarVert);
end;

initialization
  Atool:=Tools[0];
end.

