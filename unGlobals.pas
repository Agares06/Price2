unit unGlobals;

interface

uses
  Vcl.Graphics,
  unJData;

const
  ExApp = 'Excel.Application';

  DflRequz: string = '�������� � ������������ ���������������� ��������'+
        #13#10+'223021 �. �����, ����������� �����, 14�, ���. 1-16'+#13#10+
        '�/�  BY73BLNB30120000041245000933 BYN  � ��� "���-����", ��� BLNBBY2X,'
        +#13#10+'�. �����, ��. �������������, 87�'+#13#10+
        '��� 691583669'+#13#10+'���. +375 29 132-30-30';
  CStrSetsFN: string = 'setts';

  LogoColor: TColor = 15509777;

type
  TPriceRec = record
    name: string;
    prc: double;
    descr: string;
    link, pict_link: string;
  end;
  TPrice = array of TPriceRec;
  TPrices = array of TPrice;

  TDispPr = record
    ret, dealer: double;
  end;

  TGroupLink = record
    name, link: string;
  end;
  TGroup = array of TGroupLink;

  TSetts = record
    requz: string;
    srs_url: string;
  end;

var
  PricesG, PricesCur: TPrices;
  ExcelG: OleVariant;
  GroupG: TGroup;
  FirstActivate: Boolean = True;
  FirstRefr: Boolean = True;
  SetG: TSetts;
  JDG: TJData;
  SetsFN1G: string;
  RurRateG: double;

implementation

end.
