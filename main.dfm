object Form1: TForm1
  Left = 249
  Top = 121
  Width = 802
  Height = 600
  Caption = 'RMP Creator'
  Color = clBtnFace
  Constraints.MinHeight = 600
  Constraints.MinWidth = 800
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  OnResize = FormResize
  DesignSize = (
    794
    573)
  PixelsPerInch = 96
  TextHeight = 13
  object lLoading: TLabel
    Left = 672
    Top = 200
    Width = 38
    Height = 13
    Caption = 'Loading'
  end
  object pbConvert: TProgressBar
    Left = 0
    Top = 546
    Width = 794
    Height = 25
    Anchors = [akLeft, akRight, akBottom]
    TabOrder = 0
  end
  object btnOpenTiffs: TButton
    Left = 1
    Top = 8
    Width = 75
    Height = 35
    Caption = 'Open maps'
    TabOrder = 1
    OnClick = btnOpenTiffsClick
  end
  object sgStatus: TStringGrid
    Left = 1
    Top = 119
    Width = 792
    Height = 396
    Anchors = [akLeft, akTop, akBottom]
    ColCount = 6
    Ctl3D = False
    FixedColor = clWindow
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goEditing]
    ParentCtl3D = False
    TabOrder = 7
    OnDrawCell = sgStatusDrawCell
    ColWidths = (
      64
      64
      64
      64
      64
      64)
    RowHeights = (
      24
      24
      24
      24
      24)
  end
  object memoLog: TMemo
    Left = 386
    Top = 246
    Width = 393
    Height = 256
    Anchors = [akRight, akBottom]
    Lines.Strings = (
      'memoLog')
    TabOrder = 12
  end
  object inProv: TLabeledEdit
    Left = 1
    Top = 64
    Width = 130
    Height = 21
    EditLabel.Width = 63
    EditLabel.Height = 13
    EditLabel.Caption = 'Map Provider'
    TabOrder = 3
  end
  object inGroup: TLabeledEdit
    Left = 137
    Top = 64
    Width = 130
    Height = 21
    EditLabel.Width = 53
    EditLabel.Height = 13
    EditLabel.Caption = 'Map Group'
    TabOrder = 4
  end
  object rbAtlas: TRadioButton
    Left = 1
    Top = 96
    Width = 129
    Height = 17
    Caption = 'All files to one RMP'
    TabOrder = 5
    OnClick = rbAtlasClick
  end
  object rbSingle: TRadioButton
    Left = 137
    Top = 96
    Width = 135
    Height = 17
    Caption = 'Every file to single RMP'
    TabOrder = 6
    OnClick = rbSingleClick
  end
  object btnHelp: TButton
    Left = 728
    Top = 7
    Width = 65
    Height = 35
    Anchors = [akTop, akRight]
    Caption = 'Help'
    TabOrder = 11
    OnClick = btnHelpClick
  end
  object btnCreateRMP: TButton
    Left = 80
    Top = 8
    Width = 75
    Height = 35
    Caption = 'Create RMP'
    TabOrder = 2
    OnClick = btnCreateRMPClick
  end
  object btnDeleteTiff: TButton
    Left = 0
    Top = 518
    Width = 49
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Remove'
    TabOrder = 8
    OnClick = btnDeleteTiffClick
  end
  object btnClearTiffs: TButton
    Left = 55
    Top = 518
    Width = 49
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Clear'
    TabOrder = 9
    OnClick = btnClearTiffsClick
  end
  object btnVisualize: TButton
    Left = 718
    Top = 518
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Visualize'
    TabOrder = 10
    OnClick = btnVisualizeClick
  end
  object GroupBox1: TGroupBox
    Left = 272
    Top = 2
    Width = 273
    Height = 113
    Anchors = [akTop, akRight]
    Caption = 'geoTIFF export Scale'
    TabOrder = 13
    object Label1: TLabel
      Left = 8
      Top = 18
      Width = 65
      Height = 13
      Caption = 'Device model'
    end
    object cbModel: TComboBox
      Left = 8
      Top = 34
      Width = 110
      Height = 21
      Style = csDropDownList
      ItemHeight = 13
      TabOrder = 0
      OnChange = cbModelChange
      Items.Strings = (
        'Triton 300/400/500'
        'Triton 1500/2000'
        'eXp 110/GC/310'
        'eXp 510/610'
        'eXp 710')
    end
    object inExportScale: TLabeledEdit
      Left = 123
      Top = 34
      Width = 145
      Height = 21
      EditLabel.Width = 72
      EditLabel.Height = 13
      EditLabel.Caption = 'Scale in meters'
      TabOrder = 1
      OnChange = inExportScaleChange
    end
    object btnSetScale: TButton
      Left = 211
      Top = 60
      Width = 57
      Height = 25
      Caption = 'Set'
      TabOrder = 2
      OnClick = btnSetScaleClick
    end
    object memoScale: TMemo
      Left = 7
      Top = 60
      Width = 150
      Height = 45
      TabOrder = 3
    end
  end
  object GroupBox2: TGroupBox
    Left = 550
    Top = 2
    Width = 175
    Height = 113
    Anchors = [akTop, akRight]
    Caption = 'Use gdal_translate for tiling'
    TabOrder = 14
    object inUseExternalX: TLabeledEdit
      Left = 8
      Top = 31
      Width = 121
      Height = 21
      EditLabel.Width = 103
      EditLabel.Height = 13
      EditLabel.Caption = 'If image width > pixels'
      TabOrder = 0
      OnChange = inUseExternalXChange
    end
    object inUseExternalY: TLabeledEdit
      Left = 8
      Top = 69
      Width = 121
      Height = 21
      EditLabel.Width = 107
      EditLabel.Height = 13
      EditLabel.Caption = 'If image height > pixels'
      TabOrder = 1
      OnChange = inUseExternalYChange
    end
    object cbUseExternal: TCheckBox
      Left = 9
      Top = 93
      Width = 97
      Height = 17
      Caption = 'always'
      TabOrder = 2
      OnClick = cbUseExternalClick
    end
  end
  object Button1: TButton
    Left = 736
    Top = 88
    Width = 57
    Height = 25
    Caption = 'Button1'
    TabOrder = 15
    Visible = False
    OnClick = Button1Click
  end
  object inJpegQual: TLabeledEdit
    Left = 187
    Top = 20
    Width = 80
    Height = 21
    EditLabel.Width = 60
    EditLabel.Height = 13
    EditLabel.Caption = 'JPEG quality'
    TabOrder = 16
  end
  object openTiff: TOpenDialog
    Filter = 
      'All Supported types|*.tif; *.tiff; *.map|OziExplorer .MAP|*.map|' +
      'geoTIFF|*.tiff; *.tif'
    Left = 136
    Top = 520
  end
  object SaveDialog1: TSaveDialog
    FileName = '*.rmp'
    Filter = 'RMP File'
    Left = 176
    Top = 520
  end
end
