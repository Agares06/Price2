unit unMain;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ActiveX,
  System.SysUtils, System.Variants, System.Classes, System.Math,
  System.Win.ComObj,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Clipbrd,
  Vcl.CheckLst, Vcl.ComCtrls, Vcl.ExtCtrls,
  Vcl.Imaging.pngimage, Vcl.Imaging.jpeg,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  unGlobals, unParsIvid, unMiscF,
  unSetts, unJData;

type
  TfmMain = class(TForm)
    clbPosits: TCheckListBox;
    pnManag: TPanel;
    clbCateg: TCheckListBox;
    lbCateg: TLabel;
    lbUnits: TLabel;
    btRefr: TButton;
    btCrtExc: TButton;
    IdHTTP1: TIdHTTP;
    ProgressBar1: TProgressBar;
    btSett: TButton;
    cbSett: TCheckBox;
    Button2: TButton;
    Edit1: TEdit;
    Label1: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure clbCategClickCheck(Sender: TObject);
    procedure clbPositsClickCheck(Sender: TObject);
    procedure btRefrClick(Sender: TObject);
    procedure btCrtExcClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure cbSettClick(Sender: TObject);
    procedure btSettClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
  private
    procedure upd_categories;
    procedure upd_prices(AFstTime: boolean = False);
    procedure show_price(ACateg: integer);
    procedure add_rem_cur(cat, ind: integer; _add: boolean = True);
    procedure refresh_all;
    procedure place_logo(sht, celr, celc: integer);
    procedure place_pict(sht, pgrp, pind, ph, pw: integer);
    procedure get_descr;
    procedure AlignCenterHV(sht: integer; rang: string);
    procedure load_sets;
    procedure upd_rate;
  public
  end;

var
  fmMain: TfmMain;
  LColor: TColor;

implementation

{$R *.dfm}

procedure TfmMain.add_rem_cur(cat, ind: integer; _add: boolean = True);
  var
    pip1: integer;
  begin
    pip1 := PosInPrice(PricesG[cat][ind], PricesCur[cat]);

    if _add then
    begin
      if pip1 = -1 then
        Insert(PricesG[cat][ind], PricesCur[cat], Length(PricesCur[cat]));
    end
    else
      if pip1 <> -1 then
        Delete(PricesCur[cat], pip1, 1);
  end;

procedure TfmMain.btRefrClick(Sender: TObject);
  begin
    if FirstRefr then
    begin
      btRefr.Caption := 'Обновить списки';
      btCrtExc.Enabled := True;
      FirstRefr := False;
    end;

    refresh_all;
  end;

procedure TfmMain.btSettClick(Sender: TObject);
  begin
    Application.CreateForm(TfmSetts, fmSetts);
    fmSetts.ShowModal;
  end;

procedure TfmMain.Button2Click(Sender: TObject);
  begin
    upd_rate;
  end;

procedure TfmMain.AlignCenterHV(sht: integer; rang: string);
  begin
    ExcelG.WorkBooks[1].WorkSheets[sht].Range[rang].HorizontalAlignment :=
      -4108;
    ExcelG.WorkBooks[1].WorkSheets[sht].Range[rang].VerticalAlignment :=
      -4108;
  end;

procedure TfmMain.btCrtExcClick(Sender: TObject);
  var
    i1, i2, sind1, tabh1: integer;
    rng1: string;
    dp1: TDispPr;
  begin
    i2 := 0;
    for i1 := 0 to Length(PricesG)-1 do
      if clbCateg.Checked[i1] then
        i2 := i2+1;

    if i2 > 0 then
    begin
      get_descr;

      ExcelG := CreateOLEObject(ExApp);

      ExcelG.DisplayAlerts := False;
      ExcelG.WorkBooks.Add;

      while ExcelG.WorkBooks[1].WorkSheets.Count > 1 do
        ExcelG.WorkBooks[1].WorkSheets[ExcelG.WorkBooks[1].WorkSheets.Count].Delete;
      ExcelG.WorkBooks[1].WorkSheets[1].Name := 'Категории';

      sind1 := 1;
      for i1 := 0 to Length(GroupG)-1 do
        if clbCateg.Checked[i1] then
        begin
          ExcelG.WorkBooks[1].WorkSheets.Add(After :=
            ExcelG.WorkBooks[1].WorkSheets[ExcelG.WorkBooks[1].WorkSheets.Count]);
          sind1 := sind1+1;
          ExcelG.WorkBooks[1].WorkSheets[sind1].Name := ExcShName(GroupG[i1].name);
          ExcelG.WorkBooks[1].WorkSheets[sind1].PageSetup.TopMargin := 40;
          ExcelG.WorkBooks[1].WorkSheets[sind1].PageSetup.BottomMargin := 40;
          ExcelG.WorkBooks[1].WorkSheets[sind1].PageSetup.LeftMargin := 15;
          ExcelG.WorkBooks[1].WorkSheets[sind1].PageSetup.RightMargin := 15;

          ExcelG.WorkBooks[1].WorkSheets[1].Hyperlinks.Add(
            Anchor := ExcelG.WorkBooks[1].WorkSheets[1].Cells[sind1+3, 2],
            Address :=  '',
            SubAddress := QuoteSpacedStr(ExcelG.WorkBooks[1].WorkSheets[sind1].Name)+'!R1C1',
            TextToDisplay := GroupG[i1].name);

          ExcelG.WorkBooks[1].WorkSheets[sind1].Cells[2, 2] := '№';
          ExcelG.WorkBooks[1].WorkSheets[sind1].Cells[2, 3] := 'Наименование';
          ExcelG.WorkBooks[1].WorkSheets[sind1].Cells[2, 4] := 'Вид';
          ExcelG.WorkBooks[1].WorkSheets[sind1].Cells[2, 5] := 'Описание';
          ExcelG.WorkBooks[1].WorkSheets[sind1].Cells[2, 6] := 'Цена, р.';

          tabh1 := Length(PricesCur[i1]);

          for i2 := 0 to Length(PricesCur[i1])-1 do
            begin
              ExcelG.WorkBooks[1].WorkSheets[sind1].Cells[i2+3, 2] :=
                    IntToStr(i2+1);
              ExcelG.WorkBooks[1].WorkSheets[sind1].Cells[i2+3, 3] :=
                    PricesCur[i1][i2].name;
              try
                place_pict(sind1, i1, i2, 123, 123);
              except
                ExcelG.WorkBooks[1].WorkSheets[sind1].Cells[i2+3, 4] :=
                    'No image.';
                rng1 := 'D'+IntToStr(i2+3);
                AlignCenterHV(sind1, rng1);
              end;
              ExcelG.WorkBooks[1].WorkSheets[sind1].Cells[i2+3, 5] :=
                PricesCur[i1][i2].descr;
              dp1 := PriceByRate(RurRateG, PricesCur[i1][i2].prc, 15);
              ExcelG.WorkBooks[1].WorkSheets[sind1].Cells[i2+3, 6] := dp1.ret;
{              ExcelG.WorkBooks[1].WorkSheets[sind1].Hyperlinks.Add(
                Anchor := ExcelG.WorkBooks[1].WorkSheets[sind1].Cells[i2+3, 6],
                Address := PricesCur[i1][i2].link,
                ScreenTip := PricesCur[i1][i2].link,
                TextToDisplay := 'Ссылка');   }

              ExcelG.WorkBooks[1].WorkSheets[sind1].Rows[i2+3].RowHeight := 119;
            end;

          for i2 := 1 to ExcelG.WorkBooks[1].WorkSheets[sind1].Shapes.Count do
          begin
            ExcelG.WorkBooks[1].WorkSheets[sind1].Shapes[i2].IncrementLeft(10);
            ExcelG.WorkBooks[1].WorkSheets[sind1].Shapes[i2].IncrementTop(10);
          end;
//FORMATTING PRICE PAGES
          ExcelG.WorkBooks[1].WorkSheets[sind1].Columns[1].ColumnWidth := 1;
          ExcelG.WorkBooks[1].WorkSheets[sind1].Rows[1].RowHeight := 25;
//Group name at the top of page
          rng1 := 'B1:F1';
          ExcelG.WorkBooks[1].WorkSheets[sind1].Cells[1, 2] := GroupG[i1].name;
          ExcelG.WorkBooks[1].WorkSheets[sind1].Range[rng1].Font.FontStyle := 'Bold';
          ExcelG.WorkBooks[1].WorkSheets[sind1].Range[rng1].Font.Size := 18;
          ExcelG.WorkBooks[1].WorkSheets[sind1].Range[rng1].Font.Color := LogoColor;
          ExcelG.WorkBooks[1].WorkSheets[sind1].Range[rng1].WrapText := True;
          ExcelG.WorkBooks[1].WorkSheets[sind1].Range[rng1].Merge;
          AlignCenterHV(sind1, rng1);
//Table common formats
          rng1 := 'B2:F'+IntToStr(tabh1+2);
          ExcelG.WorkBooks[1].WorkSheets[sind1].Range[rng1].Borders.LineStyle := 1;
          for i2 := 11 to 12 do
            ExcelG.WorkBooks[1].WorkSheets[sind1].Range[rng1].Borders.Item[i2].Weight := 2;
          for i2 := 7 to 10 do
            ExcelG.WorkBooks[1].WorkSheets[sind1].Range[rng1].Borders.Item[i2].Weight := 4;
          ExcelG.WorkBooks[1].WorkSheets[sind1].Range[rng1].Font.Size := 10;
          AlignCenterHV(sind1, rng1);
//Description column format
          rng1 := 'E3:E'+IntToStr(tabh1+2);
          ExcelG.WorkBooks[1].WorkSheets[sind1].Range[rng1].Font.Size := 8;
//Table head format
          rng1 := 'B2:F2';
          ExcelG.WorkBooks[1].WorkSheets[sind1].Range[rng1].Borders.Item[9].Weight := 4;
          ExcelG.WorkBooks[1].WorkSheets[sind1].Range[rng1].Font.FontStyle := 'Bold';
          ExcelG.WorkBooks[1].WorkSheets[sind1].Range[rng1].Font.Size := 12;
          AlignCenterHV(sind1, rng1);
//Columns details
          ExcelG.WorkBooks[1].WorkSheets[sind1].Columns[2].AutoFit;
          ExcelG.WorkBooks[1].WorkSheets[sind1].Columns[3].ColumnWidth := 20;
          ExcelG.WorkBooks[1].WorkSheets[sind1].Columns[3].WrapText := True;
          ExcelG.WorkBooks[1].WorkSheets[sind1].Columns[4].ColumnWidth := 20;
          ExcelG.WorkBooks[1].WorkSheets[sind1].Columns[5].ColumnWidth := 42;
          ExcelG.WorkBooks[1].WorkSheets[sind1].Columns[5].WrapText := True;
          ExcelG.WorkBooks[1].WorkSheets[sind1].Columns[6].NumberFormat := '0.00';
          ExcelG.WorkBooks[1].WorkSheets[sind1].Columns[6].AutoFit;
        end;

      ExcelG.WorkBooks[1].WorkSheets[1].Activate;

      place_logo(1, 2, 2);
      ExcelG.WorkBooks[1].WorkSheets[1].Columns[3].ColumnWidth := 53;
      ExcelG.WorkBooks[1].WorkSheets[1].Cells[2, 3] := SetG.requz;
      ExcelG.WorkBooks[1].WorkSheets[1].Cells[2, 3].HorizontalAlignment :=
        -4152;
      ExcelG.WorkBooks[1].WorkSheets[1].Cells[2, 3].VerticalAlignment :=
        -4160;
      ExcelG.WorkBooks[1].WorkSheets[1].Cells[2, 3].Font.Size := 12;


      ExcelG.WorkBooks[1].WorkSheets[1].Cells[3, 2] := 'РАЗДЕЛЫ';
      ExcelG.WorkBooks[1].WorkSheets[1].Cells[3, 2].Font.Color := LogoColor;
      ExcelG.WorkBooks[1].WorkSheets[1].Cells[3, 2].Font.FontStyle := 'Bold';
      ExcelG.WorkBooks[1].WorkSheets[1].Cells[3, 2].Font.Size := 14;
      ExcelG.WorkBooks[1].WorkSheets[1].Columns[2].AutoFit;

      ExcelG.WorkBooks[1].WorkSheets[1].Columns[1].ColumnWidth := 1;
      ExcelG.WorkBooks[1].WorkSheets[1].PageSetup.TopMargin := 40;
      ExcelG.WorkBooks[1].WorkSheets[1].PageSetup.BottomMargin := 40;
      ExcelG.WorkBooks[1].WorkSheets[1].PageSetup.LeftMargin := 12;
      ExcelG.WorkBooks[1].WorkSheets[1].PageSetup.RightMargin := 12;


      ExcelG.Visible := True;
    end
    else
      ShowMessage('Не выбрано ни одной позиции!');
  end;

procedure TfmMain.cbSettClick(Sender: TObject);
  begin
    if cbSett.Checked then
      btSett.Enabled := True
    else
      btSett.Enabled := False;
  end;

procedure TfmMain.clbCategClickCheck(Sender: TObject);
  begin
    show_price(clbCateg.ItemIndex);
  end;

procedure TfmMain.clbPositsClickCheck(Sender: TObject);
  var
    ctg1, ind1: integer;
    add1: boolean;
  begin
    ctg1 := clbCateg.ItemIndex;
    ind1 := clbPosits.ItemIndex;

    add1 := True;
    if not clbPosits.Checked[ind1] then
      add1 := False;

    add_rem_cur(ctg1, ind1, add1);

    show_price(ctg1);
  end;

procedure TfmMain.Edit1Change(Sender: TObject);
  var
    hs1: string;
  begin
    try
      RurRateG := StrToFloat(Edit1.Text);
    except
      on E: EConvertError do
        begin
          ShowMessage(E.Message);
          Edit1.Text := '0';
          RurRateG := 0;
        end;
    end;
  end;

procedure TfmMain.FormActivate(Sender: TObject);
  begin
    if FirstActivate then
    begin
      upd_rate;

      FirstActivate := False;
    end;
  end;

procedure TfmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  var
    i1, i2: integer;
  begin
    if not VarIsEmpty(ExcelG) then
      ExcelG.Quit;

    for i1 := 0 to Length(PricesG)-1 do
      for i2 := 0 to Length(PricesG[i1])-1 do
        SetLength(PricesG[i1], 0);
    SetLength(PricesG, 0);

    for i1 := 0 to Length(PricesCur)-1 do
      for i2 := 0 to Length(PricesCur[i1])-1 do
        SetLength(PricesCur[i1], 0);
    SetLength(PricesCur, 0);

    SetLength(GroupG, 0);
  end;

procedure TfmMain.FormCreate(Sender: TObject);
  begin
    clbCateg.ItemEnabled[0] := False;
    clbPosits.ItemEnabled[0] := False;

    SetsFN1G := ExtractFilePath(Application.ExeName)+CStrSetsFN;
    SetLength(JDG, 0);

    load_sets;
  end;

procedure TfmMain.get_descr;
  var
    i1, i2, pos1: integer;
    rsp1, hs1, hs2, errst: string;
    add_brk: boolean;
  begin
    for i1 := 0 to Length(PricesCur)-1 do
      for i2 := 0 to Length(PricesCur[i1])-1 do
      begin
        hs1 := '';
        add_brk := False;
        try
          errst := '1';
          rsp1 := IdHTTP1.Get(PricesCur[i1][i2].link);
          errst := '2';
          repeat
            pos1 := Pos('feature-description__text">', rsp1);
            if pos1 > 0 then
            begin
              Delete(rsp1, 1, pos1+26);
              hs2 := Copy(rsp1, 1, Pos('<', rsp1)-1);
              if add_brk then
                hs2 := ', '+hs2
              else
                add_brk := True;
              hs1 := hs1+hs2;
            end;
          until pos1 = 0;
          PricesCur[i1][i2].descr := hs1;
          errst := '';
        except
          PricesCur[i1][i2].descr := errst;
        end;
      end;
  end;

procedure TfmMain.load_sets;
  var
    jstr: string;
  begin
    if FileExists(SetsFN1G) then
    begin
      ReadJDFile(SetsFN1G, JDG);
      SetG.requz := JValByName('requz', JDG);
    end
    else
    begin
      SetG.requz := DflRequz;

      jstr := JDR('requz', SetG.requz);
      WriteJDFile(jstr, SetsFN1G, True);
    end;
  end;

procedure TfmMain.place_logo(sht, celr, celc: integer);
  var
    bmp1, bmp2: TBitmap;
  begin
    bmp1 := TBitmap.Create;
    bmp2 := TBitmap.Create;

    bmp1.LoadFromResourceName(HInstance, 'WFBLogo');
    bmp2.Width := 200;
    bmp2.Height := 200;
    bmp2.Canvas.StretchDraw(Rect(0, 0, 200, 200), bmp1);
    ClipBoard.Assign(bmp2);

    ExcelG.WorkBooks[1].WorkSheets[sht].Activate;
    ExcelG.WorkBooks[1].WorkSheets[sht].Rows[celr].RowHeight := Round(0.8*200);
    ExcelG.WorkBooks[1].WorkSheets[sht].Cells[celr, celc].Select;
    ExcelG.WorkBooks[1].WorkSheets[sht].Paste;

    bmp2.Free;
    bmp1.Free;
    ClipBoard.Clear;
  end;

procedure TfmMain.place_pict(sht, pgrp, pind, ph, pw: integer);
  var
    bmp1, bmp2: TBitmap;
    ms1: TMemoryStream;
    lnk1: string;
    png1: TPNGImage;
    jpg1: TJPEGImage;
    img_code: integer;
  begin
    img_code := 0;

    lnk1 := PricesCur[pgrp][pind].pict_link;
    ms1 := TMemoryStream.Create;
    IdHTTP1.Get(lnk1, ms1);
    png1 := TPNGImage.Create;
    jpg1 := TJPEGImage.Create;
    try
      try
        ms1.Seek(0, soBeginning);
        png1.LoadFromStream(ms1);
        img_code := 1;
      except
        try
          ms1.Seek(0, soBeginning);
          jpg1.LoadFromStream(ms1);
          img_code := 2;
        except

        end;
      end;
    finally
      ms1.Free;
    end;


    bmp1 := TBitmap.Create;
    bmp2 := TBitmap.Create;
    if img_code = 1 then
      bmp1.Assign(png1)
    else
      if img_code = 2 then
        bmp1.Assign(jpg1);
    png1.Free;
    jpg1.Free;

    if img_code <> 0 then
    begin
      bmp2.Width := pw;
      bmp2.Height := ph;
      bmp2.Canvas.StretchDraw(Rect(0, 0, ph, pw), bmp1);
      ClipBoard.Assign(bmp2);

      ExcelG.WorkBooks[1].WorkSheets[sht].Activate;
      ExcelG.WorkBooks[1].WorkSheets[sht].Cells[pind+3, 4].Select;
      ExcelG.WorkBooks[1].WorkSheets[sht].Paste;

      ClipBoard.Clear;
    end;

    bmp2.Free;
    bmp1.Free;
  end;

procedure TfmMain.refresh_all;
  begin
    upd_categories;
    upd_prices(True);

    clbCateg.ItemIndex := 0;
    show_price(clbCateg.ItemIndex);
  end;

procedure TfmMain.show_price(ACateg: integer);
  var
    i1: integer;
  begin
    clbPosits.Items.Clear;
    for i1 := 0 to Length(PricesG[ACateg])-1 do
    begin
      clbPosits.Items.Add(PricesG[ACateg][i1].name);
      if PosInPrice(PricesG[ACateg][i1], PricesCur[ACateg]) > -1 then
        clbPosits.Checked[i1] := True
      else
        clbPosits.Checked[i1] := False;

      if clbCateg.Checked[ACateg] then
        clbPosits.ItemEnabled[i1] := True
      else
        clbPosits.ItemEnabled[i1] := False;
    end;

    clbPosits.ItemIndex := -1;
  end;

procedure TfmMain.upd_categories;
  var
    rs1: string;
    i1: integer;
  begin
    rs1 := IdHTTP1.Get('https://ru.ivideon.com/shop/');

//    rs1 := CutStr('Каталог<span class="hidden-xs"> товаров', '</a></div>', rs1);
    ParsGrpListIv(rs1, GroupG);

    clbCateg.Items.Clear;
    for i1 := 0 to Length(GroupG)-1 do
    begin
      clbCateg.Items.Add(GroupG[i1].name);
      clbCateg.Checked[i1] := True;
    end;
  end;

procedure TfmMain.upd_rate;
  var
    rsp1: string;
    pos1: integer;
  begin
    rsp1 := IdHTTP1.Get('https://myfin.by/bank/kursy_valjut_nbrb/rub');
    pos1 := Pos('div class="cur-rate__cell"', rsp1);
    if pos1 > 0 then
    begin
      Delete(rsp1, 1, pos1);
      Delete(rsp1, 1, Pos('class="h1"', rsp1)+10);
      Edit1.Text := Copy(rsp1, 1, Pos('<', rsp1)-1);
    end
    else
      Edit1.Text := 'Ошибка';
    Sleep(1);
  end;

procedure TfmMain.upd_prices(AFstTime: boolean = False);
  var
    i1, i2: integer;
    rs1: string;
    prc1: TPrice;
  begin
    for i1 := 0 to Length(PricesG)-1 do
      for i2 := 0 to Length(PricesG[i1])-1 do
        SetLength(PricesG[i1], 0);
    SetLength(PricesG, 0);

    if AFstTime then
    begin
      for i1 := 0 to Length(PricesCur)-1 do
        for i2 := 0 to Length(PricesCur[i1])-1 do
          SetLength(PricesCur[i1], 0);
      SetLength(PricesCur, 0);
    end;

    ProgressBar1.Position := 0;
    for i1 := 0 to Length(GroupG)-1 do
    begin
      rs1 := IdHTTP1.Get(GroupG[i1].link);
      ParsPriceIv(rs1, prc1);
      Insert(prc1, PricesG, Length(PricesG));

      if AFstTime then
        Insert(prc1, PricesCur, Length(PricesCur));
    end;
//    ProgressBar1.Position := 0;
  end;

end.
