VERSION 5.00
Begin VB.UserControl ListGrid 
   AutoRedraw      =   -1  'True
   ClientHeight    =   2430
   ClientLeft      =   0
   ClientTop       =   0
   ClientWidth     =   3615
   ScaleHeight     =   2430
   ScaleWidth      =   3615
   Begin VB.ListBox List1 
      Height          =   1980
      IntegralHeight  =   0   'False
      Left            =   0
      TabIndex        =   0
      Top             =   315
      Width           =   3525
   End
End
Attribute VB_Name = "ListGrid"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit


Private Declare Function DrawEdge Lib "user32" (ByVal hdc As Long, qrc As rect, ByVal edge As Long, ByVal grfFlags As Long) As Long

Private Declare Function DrawText Lib "user32" Alias "DrawTextA" (ByVal hdc As Long, ByVal lpStr As String, ByVal nCount As Long, lpRect As rect, ByVal wFormat As Long) As Long
Private Declare Function GetCursorPos Lib "user32" (lpPoint As pointapi) As Long

Private Declare Function InflateRect Lib "user32" (lpRect As rect, ByVal X As Long, ByVal Y As Long) As Long
Private Declare Function LBItemFromPt Lib "comctl32" (ByVal hLB As Long, ByVal X As Long, ByVal Y As Long, ByVal bAutoScroll As Boolean) As Long

Private Declare Function MoveWindow Lib "user32" (ByVal hwnd As Long, ByVal X As Long, ByVal Y As Long, ByVal nWidth As Long, ByVal nHeight As Long, ByVal bRepaint As Long) As Long

Private Declare Function OffsetRect Lib "user32" (lpRect As rect, ByVal X As Long, ByVal Y As Long) As Long
Private Declare Function PtInRect Lib "user32" (lpRect As rect, ByVal X As Long, ByVal Y As Long) As Long
Private Declare Function ScreenToClient Lib "user32" (ByVal hwnd As Long, ByRef lpPoint As pointapi) As Integer
 

Private Declare Function SetTextColor Lib "gdi32" (ByVal hdc As Long, ByVal crColor As Long) As Long
Private Declare Function SetRect Lib "user32" (lpRect As rect, ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long) As Long
Private Declare Function SendMessageArray Lib "user32" Alias "SendMessageA" (ByVal hwnd As Long, ByVal wMsg As Long, ByVal wParam As Long, lParam As Any) As Long
Private Declare Function SendMessage Lib "user32" Alias "SendMessageA" (ByVal hwnd As Long, ByVal wMsg As Long, ByVal wParam As Long, lParam As Any) As Long
 
Private Type pointapi
  X As Long
  Y As Long
End Type
 
 

Enum enListBorderStyle
   lbsFlat = 0
   lbs3D = 1
End Enum

Enum enDrawType
    drRAISED = 0
    drETCHED = 1
    drSUNKEN = 2
End Enum

Private Type rect
   Left As Long
   Top As Long
   Right As Long
   Bottom As Long
End Type

Dim r()  As rect
 
'Default Property Values:
Const m_def_horizontal_scrollbar = 0
Const m_def_selected_row = 0
Const m_def_cell_text = "0"
Const m_def_header_text_color = 0
Const m_def_header_style = 4
Const m_def_Header = " string1 | string2 | string3 "

'Property Variables:
Dim m_horizontal_scrollbar As Boolean
Dim m_selected_row As Long
Dim m_cell_text As String
Dim m_header_text_color As OLE_COLOR
Dim m_header_style As enDrawType
Dim m_Header As String
 

'======================================
' RETURN: a long value the will be the width
'         of the usercontrol
'======================================
Private Function draw_header()
 '
 'variable declarations
 Dim sParts()      As String
 Dim upper&, left_point, left_edge&, top_point&, lcnt&
 'constants for drawing text
 Const DT_CALCRECT As Long = &H400
 Const DT_LEFT As Long = &H0
 Const DT_CENTER As Long = &H1
 Const DT_SINGLELINE As Long = &H20
 Const DT_CALC = (DT_CENTER Or DT_SINGLELINE Or DT_CALCRECT)
 Const DT_DRAW = (DT_CENTER Or DT_SINGLELINE)
 'constants for the header edge type
 Const BDR_RAISED As Long = &H5
 Const BDR_RAISEDINNER As Long = &H4
 Const BDR_SUNKENOUTER As Long = &H2
 Const BF_BOTTOM = &H8
 Const BF_LEFT = &H1
 Const BF_RIGHT = &H4
 Const BF_TOP = &H2
 Const BF_RECT = (BF_LEFT Or BF_TOP Or BF_RIGHT Or BF_BOTTOM)
 
 '
 ' user supplies the header in the format
 '  "string | string |  string"
 ' we will set the column width based upon
 ' the width of each of the string parts
  sParts = Split(m_Header, "|")
  '
  left_point = 0
  upper = UBound(sParts)

  If upper = -1 Then Exit Function
  
  ReDim r(upper)
  '
  'clear the old drawing
  Cls
  '
  For lcnt = 0 To upper
      '
      'set preliminary rect that will be adjusted
      'based upon the text val of this part
      SetRect r(lcnt), 0, 0, 0, 0
      '
      'the rect gets recalculated here
      DrawText hdc, sParts(lcnt), Len(sParts(lcnt)), r(lcnt), DT_CALC
      '
      'offset the rect so the rects lefts line up one after the other
      OffsetRect r(lcnt), left_point, 0
      '
      'add a little padding
      InflateRect r(lcnt), 1, 1
      '
      'draw the border for the rect
      DrawEdge hdc, r(lcnt), func_SelectStyle(), BF_RECT
      '
      'the color of the header text
      SetTextColor hdc, m_header_text_color
      '
      'now draw the caption
      DrawText hdc, sParts(lcnt), Len(sParts(lcnt)), r(lcnt), DT_DRAW
      '
      'keep track of where the next rects left should be
      left_point = (left_point + (r(lcnt).Right - r(lcnt).Left))

   Next lcnt
  '
  ' width of the header after all the formatting.
  ' set listbox to the same width
  Width = (left_point * Screen.TwipsPerPixelX) - _
                    (left_edge * Screen.TwipsPerPixelX)
  '
  'reposition/resize the listbox to fit
  MoveWindow List1.hwnd, 0, r(lcnt - 1).Bottom, _
             (Width / Screen.TwipsPerPixelX), _
             (Height / Screen.TwipsPerPixelY) - r(lcnt - 1).Bottom, _
             True
End Function
'
'this sets the tabpoints for the listbox
'
Sub tab_points(ParamArray TBpoints())
 
 Dim upper&, lcnt&
 Dim LBtabs() As Long
 'constant for listbox tabstops
 Const LB_SETTABSTOPS = &H192
 
 upper = UBound(TBpoints)
 ReDim LBtabs(upper)
 
 For lcnt = 0 To upper
    LBtabs(lcnt) = CLng(TBpoints(lcnt))
 Next lcnt
 '
 'set the tabstops
 SendMessageArray List1.hwnd, LB_SETTABSTOPS, (upper + 1), LBtabs(0)
 
End Sub
Private Function func_SelectStyle() As Long
 
  Const BDR_RAISED As Long = &H5
  Const BDR_RAISEDINNER As Long = &H4
  Const BDR_SUNKENOUTER As Long = &H2
  Const BDR_SUNKEN As Long = &HA
  
  If m_header_style = drETCHED Then
     func_SelectStyle = (BDR_RAISEDINNER Or BDR_SUNKENOUTER)
  ElseIf m_header_style = drRAISED Then
     func_SelectStyle = BDR_RAISED
  ElseIf m_header_style = drSUNKEN Then
     func_SelectStyle = (BDR_SUNKENOUTER)
  End If
  
End Function

Private Sub List1_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
'
'implement the tooltip for the listitem under the mouse
'
  Dim ret, pt As pointapi
  GetCursorPos pt
  
  With List1
    ret = LBItemFromPt(.hwnd, pt.X, pt.Y, True)
    .ToolTipText = .List(ret)
  End With
  
End Sub

Private Sub UserControl_MouseDown(Button As Integer, Shift As Integer, X As Single, Y As Single)

  Dim lcnt&
  Dim pt As pointapi
  '
  'we need to know which "panel" in the header the mouse
  'pressed down on so we can visually depress it as well
  '
  GetCursorPos pt
  '
  'convert the cood, which is 0,0 for the upper left of
  'screen by default, to 0,0 being the upper left of this control
  '
  ScreenToClient hwnd, pt
  '
  For lcnt = 0 To UBound(r)
    If PtInRect(r(lcnt), pt.X, pt.Y) Then
       MsgBox lcnt
       '
       'code to visually press the header panel down
    End If
  Next lcnt

End Sub

Private Sub UserControl_MouseUp(Button As Integer, Shift As Integer, X As Single, Y As Single)
'
'visually raise the header panel back to the up position
'and alphabetically sort the list


End Sub

Private Sub UserControl_Resize(): Call draw_header: End Sub

Private Sub UserControl_Terminate()
  '
  'erase the rect array
  Erase r

End Sub


'
'this takes the string [str_with_tabs] which should
'have pipe character embedded in it that represents tabs
'so instead of  "string" & vbtab & "string" & vbtab
' its "string|string|string"
Public Sub add_row(str_with_tabs As String)

 str_with_tabs = Replace(str_with_tabs, "|", vbTab)
 List1.AddItem str_with_tabs
 
 'are we adding horizontal scrollbars ?
 If m_horizontal_scrollbar Then
   Const LB_SETHORIZONTALEXTENT As Long = &H194
   Dim i%                 'integer
   Dim new_len&, max_len&, scroll_width& 'long
  
   With List1
    '
    'if user supplies a scroll width then he wants to supply the
    'value and we wont attempt to calculate
    If scroll_width <= 0 Then
       For i = 0 To (.ListCount - 1)
           new_len = (UserControl.ScaleX( _
                    UserControl.TextWidth(.List(i)), _
                    UserControl.ScaleMode, vbPixels) * 1.1)
   
           If scroll_width < new_len Then scroll_width = new_len
       Next i
     End If
     
    SendMessage .hwnd, LB_SETHORIZONTALEXTENT, scroll_width, 0
    
  End With
 
 End If
 
End Sub


'cell_text
Public Property Get cell_text(row As Long, column As Long) As String
    
    On Local Error GoTo local_error:
    cell_text = Split(List1.List(row), vbTab)(column)
    
local_error:
    If Err.Number = 9 Then
       Err.Raise 3444, "ListGridControl", "You referenced an invalid " & _
                       "row or column.  A valid row is between 0 and " & _
                       (List1.ListCount - 1)
    End If
    
End Property
Public Property Let cell_text(row As Long, column As Long, ByVal New_cell_text As String)
    
    Dim sRow$, sParts()  As String
    
    'place the listitem (row) and place in string holder
    sRow$ = List1.List(row)
    'break it up by the tabs
    sParts = Split(sRow, vbTab)
    'replace the "cell_index" specified
    sParts(column) = New_cell_text
    'reassemble
    List1.List(row) = Join(sParts, vbTab)
    
    PropertyChanged "cell_text"
End Property
'Header
Public Property Get Header() As String
    Header = m_Header
End Property
Public Property Let Header(ByVal New_Header As String)
    m_Header = New_Header
    PropertyChanged "Header"
    Call draw_header
End Property
'header_backcolor
Public Property Get header_backcolor() As OLE_COLOR
    header_backcolor = UserControl.BackColor
End Property
Public Property Let header_backcolor(ByVal New_header_backcolor As OLE_COLOR)
    UserControl.BackColor() = New_header_backcolor
    PropertyChanged "header_backcolor"
    Call draw_header
End Property
'border_style
Public Property Get border_style() As enListBorderStyle
    border_style = UserControl.BorderStyle
End Property
Public Property Let border_style(ByVal New_border_style As enListBorderStyle)
    UserControl.BorderStyle() = New_border_style
    PropertyChanged "border_style"
End Property
'header_font
Public Property Get header_font() As Font
    Set header_font = UserControl.Font
End Property
Public Property Set header_font(ByVal New_header_font As Font)
    Set UserControl.Font = New_header_font
    PropertyChanged "header_font"
    Call draw_header
End Property
'header_style
Public Property Get header_style() As enDrawType
    header_style = m_header_style
End Property
Public Property Let header_style(ByVal New_header_style As enDrawType)
    m_header_style = New_header_style
    PropertyChanged "header_style"
    Call draw_header
End Property
'header_text_color
Public Property Get header_text_color() As OLE_COLOR
    header_text_color = m_header_text_color
End Property
Public Property Let header_text_color(ByVal New_header_text_color As OLE_COLOR)
    m_header_text_color = New_header_text_color
    PropertyChanged "header_text_color"
    Call draw_header
End Property
'horizontal_scrollbar
Public Property Get horizontal_scrollbar() As Boolean
    horizontal_scrollbar = m_horizontal_scrollbar
End Property
Public Property Let horizontal_scrollbar(ByVal New_horizontal_scrollbar As Boolean)
    m_horizontal_scrollbar = New_horizontal_scrollbar
    PropertyChanged "horizontal_scrollbar"
End Property
'list_backcolor
Public Property Get list_backcolor() As OLE_COLOR
    list_backcolor = List1.BackColor
End Property
Public Property Let list_backcolor(ByVal New_list_backcolor As OLE_COLOR)
    List1.BackColor() = New_list_backcolor
    PropertyChanged "list_backcolor"
End Property
'list_borderstyle
Public Property Get list_borderstyle() As enListBorderStyle
    list_borderstyle = List1.Appearance
End Property
Public Property Let list_borderstyle(ByVal New_list_borderstyle As enListBorderStyle)
    List1.Appearance() = New_list_borderstyle
    PropertyChanged "list_borderstyle"
End Property
'list_font
Public Property Get list_font() As Font
    Set list_font = List1.Font
End Property
Public Property Set list_font(ByVal New_list_font As Font)
    Set List1.Font = New_list_font
    PropertyChanged "list_font"
End Property
'list_forecolor
Public Property Get list_forecolor() As OLE_COLOR
    list_forecolor = List1.ForeColor
End Property
Public Property Let list_forecolor(ByVal New_list_forecolor As OLE_COLOR)
    List1.ForeColor() = New_list_forecolor
    PropertyChanged "list_forecolor"
End Property
'selected_row
Public Property Get selected_row() As Long
    selected_row = List1.ListIndex
End Property
Public Property Let selected_row(ByVal New_selected_row As Long)
    If New_selected_row >= 0 And New_selected_row <= (List1.ListCount - 1) Then
        List1.ListIndex = New_selected_row
    End If
    PropertyChanged "selected_row"
End Property

'Initialize Properties for User Control
Private Sub UserControl_InitProperties()
    m_Header = m_def_Header
    m_header_style = m_def_header_style
    m_header_text_color = m_def_header_text_color
    Set UserControl.Font = Ambient.Font
    m_cell_text = m_def_cell_text
    m_selected_row = m_def_selected_row
   
    m_horizontal_scrollbar = m_def_horizontal_scrollbar
End Sub
'Load property values from storage
Private Sub UserControl_ReadProperties(PropBag As PropertyBag)
    m_Header = PropBag.ReadProperty("Header", m_def_Header)
    m_header_style = PropBag.ReadProperty("header_style", m_def_header_style)
    m_header_text_color = PropBag.ReadProperty("header_text_color", m_def_header_text_color)
    Set UserControl.Font = PropBag.ReadProperty("header_font", Ambient.Font)
    Set List1.Font = PropBag.ReadProperty("list_font", Ambient.Font)
    m_cell_text = PropBag.ReadProperty("cell_text", m_def_cell_text)
    List1.ForeColor = PropBag.ReadProperty("list_forecolor", &H80000008)
    UserControl.BackColor = PropBag.ReadProperty("header_backcolor", &H8000000F)
    List1.BackColor = PropBag.ReadProperty("list_backcolor", &H80000005)
    List1.Appearance = PropBag.ReadProperty("list_borderstyle", 1)
    UserControl.BorderStyle = PropBag.ReadProperty("border_style", 0)
    m_selected_row = PropBag.ReadProperty("selected_row", m_def_selected_row)
 
   Call draw_header
    m_horizontal_scrollbar = PropBag.ReadProperty("horizontal_scrollbar", m_def_horizontal_scrollbar)
End Sub
'Write property values to storage
Private Sub UserControl_WriteProperties(PropBag As PropertyBag)
    Call PropBag.WriteProperty("Header", m_Header, m_def_Header)
    Call PropBag.WriteProperty("header_style", m_header_style, m_def_header_style)
    Call PropBag.WriteProperty("header_text_color", m_header_text_color, m_def_header_text_color)
    Call PropBag.WriteProperty("header_font", UserControl.Font, Ambient.Font)
    Call PropBag.WriteProperty("list_font", List1.Font, Ambient.Font)
    Call PropBag.WriteProperty("cell_text", m_cell_text, m_def_cell_text)
    Call PropBag.WriteProperty("list_forecolor", List1.ForeColor, &H80000008)
    Call PropBag.WriteProperty("header_backcolor", UserControl.BackColor, &H8000000F)
    Call PropBag.WriteProperty("list_backcolor", List1.BackColor, &H80000005)
    Call PropBag.WriteProperty("list_borderstyle", List1.Appearance, 1)
    Call PropBag.WriteProperty("border_style", UserControl.BorderStyle, 0)
    Call PropBag.WriteProperty("selected_row", m_selected_row, m_def_selected_row)
    Call PropBag.WriteProperty("horizontal_scrollbar", m_horizontal_scrollbar, m_def_horizontal_scrollbar)
 End Sub
  
 

 

 

