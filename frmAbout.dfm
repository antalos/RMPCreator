object Form2: TForm2
  Left = 515
  Top = 252
  Width = 240
  Height = 163
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSizeToolWin
  Caption = 'About RMP Creator'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 10
    Width = 165
    Height = 12
    Caption = 'Created by Alexander Savchenkov'
  end
  object lVer: TLabel
    Left = 8
    Top = 26
    Width = 15
    Height = 12
    Caption = 'ver'
  end
  object Label2: TLabel
    Left = 8
    Top = 55
    Width = 25
    Height = 12
    Caption = 'Help:'
  end
  object lUrl: TLabel
    Left = 8
    Top = 69
    Width = 115
    Height = 12
    Cursor = crHandPoint
    Caption = 'http://antalos.com/gps/'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    OnClick = lUrlClick
  end
  object Label4: TLabel
    Left = 8
    Top = 98
    Width = 45
    Height = 12
    Caption = 'Email me:'
  end
  object lMail: TLabel
    Left = 8
    Top = 112
    Width = 92
    Height = 12
    Cursor = crHandPoint
    Caption = 'antalos@gmail.com'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    OnClick = lMailClick
  end
end
