object Form3: TForm3
  Left = 528
  Top = 185
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Form3'
  ClientHeight = 262
  ClientWidth = 177
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 8
    Top = 232
    Width = 57
    Height = 25
    Caption = 'Calibrate'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 112
    Top = 232
    Width = 57
    Height = 25
    Caption = 'Cancel'
    TabOrder = 1
    OnClick = Button2Click
  end
  object GroupBox1: TGroupBox
    Left = 8
    Top = 7
    Width = 161
    Height = 105
    Caption = 'Top Left'
    TabOrder = 2
    object tly1: TLabeledEdit
      Left = 45
      Top = 32
      Width = 49
      Height = 21
      EditLabel.Width = 38
      EditLabel.Height = 13
      EditLabel.Caption = 'Lat Deg'
      TabOrder = 0
    end
    object tly2: TLabeledEdit
      Left = 102
      Top = 32
      Width = 49
      Height = 21
      EditLabel.Width = 40
      EditLabel.Height = 13
      EditLabel.Caption = 'Lat Mins'
      TabOrder = 1
    end
    object tlyType: TComboBox
      Left = 8
      Top = 32
      Width = 33
      Height = 21
      ItemHeight = 13
      TabOrder = 2
      Text = 'N'
      Items.Strings = (
        'N'
        'S')
    end
    object tlxType: TComboBox
      Left = 8
      Top = 72
      Width = 33
      Height = 21
      ItemHeight = 13
      TabOrder = 3
      Text = 'E'
      Items.Strings = (
        'E'
        'W')
    end
    object tlx1: TLabeledEdit
      Left = 45
      Top = 72
      Width = 49
      Height = 21
      EditLabel.Width = 41
      EditLabel.Height = 13
      EditLabel.Caption = 'Lon Deg'
      TabOrder = 4
    end
    object tlx2: TLabeledEdit
      Left = 102
      Top = 72
      Width = 49
      Height = 21
      EditLabel.Width = 43
      EditLabel.Height = 13
      EditLabel.Caption = 'Lon Mins'
      TabOrder = 5
    end
  end
  object GroupBox2: TGroupBox
    Left = 8
    Top = 119
    Width = 161
    Height = 105
    Caption = 'Bottom Right'
    TabOrder = 3
    object bry1: TLabeledEdit
      Left = 45
      Top = 32
      Width = 49
      Height = 21
      EditLabel.Width = 38
      EditLabel.Height = 13
      EditLabel.Caption = 'Lat Deg'
      TabOrder = 0
    end
    object bry2: TLabeledEdit
      Left = 102
      Top = 32
      Width = 49
      Height = 21
      EditLabel.Width = 40
      EditLabel.Height = 13
      EditLabel.Caption = 'Lat Mins'
      TabOrder = 1
    end
    object bryType: TComboBox
      Left = 8
      Top = 32
      Width = 33
      Height = 21
      ItemHeight = 13
      TabOrder = 2
      Text = 'N'
      Items.Strings = (
        'N'
        'S')
    end
    object brxType: TComboBox
      Left = 8
      Top = 72
      Width = 33
      Height = 21
      ItemHeight = 13
      TabOrder = 3
      Text = 'E'
      Items.Strings = (
        'E'
        'W')
    end
    object brx1: TLabeledEdit
      Left = 45
      Top = 72
      Width = 49
      Height = 21
      EditLabel.Width = 41
      EditLabel.Height = 13
      EditLabel.Caption = 'Lon Deg'
      TabOrder = 4
    end
    object brx2: TLabeledEdit
      Left = 102
      Top = 72
      Width = 49
      Height = 21
      EditLabel.Width = 43
      EditLabel.Height = 13
      EditLabel.Caption = 'Lon Mins'
      TabOrder = 5
    end
  end
end
