CompilerIf Not Defined(MaterialVector,#PB_Module)
	IncludeFile "MaterialVector\MaterialVector.pbi"
CompilerEndIf

CompilerIf Not Defined(CanvasButton,#PB_Module)
	IncludeFile "CanvasButton\CanvasButton.pbi"
CompilerEndIf

DeclareModule PureTL
	; Public variables, structures, constants...
	EnumerationBinary ;Flags
		#Default = 0
	EndEnumeration
	
	EnumerationBinary 1 ; Items flags
		#Item_ShowChildrenPoints
		#Item_ShowParentBlocks
		#Item_InheritColor
	EndEnumeration
	
	Enumeration ;Content Type
		#Content_Media
		#Content_DataPoints
	EndEnumeration
	
	; Public procedures declaration
	Declare Gadget(Gadget, X, Y, Width, Height, Flags = #Default)
	Declare Resize(Gadget, X, Y, Width, Height)
	Declare Freeze(Gadget, State)
	
	Declare AddLine(Gadget, Position, Text.s, ParentID = 0, Flags = #Default)
	Declare DeleteLine(Gadget, LineID)
	Declare GetLineID(Gadget, Position, ParentID = 0)
	
	Declare AddDataPoint(Gadget, LineID, Position, Identifier = 0)
	
	Declare AddMediaBlock(Gadget, LineID, Start, Finish, Identifier = 0, Icon = -1)
	Declare ResizeMediaBlock(Gadget, MediablockID, Start, Finish)
EndDeclareModule

Module PureTL
	EnableExplicit
	
	; Macro
	CompilerIf #PB_Compiler_OS = #PB_OS_Windows ; Fix color
		Macro FixColor(Color)
			RGB(Blue(Color), Green(Color), Red(Color))
		EndMacro
	CompilerElse
		Macro FixColor(Color)
			Color
		EndMacro
	CompilerEndIf
	CompilerIf #PB_Compiler_OS = #PB_OS_Windows ; Set Alpha
		Macro SetAlpha(Alpha, Color)
			Alpha << 24 + Color
		EndMacro
	CompilerElse
		Macro SetAlpha(Alpha, Color) ; You might want to check that...
			Color << 8 + Alpha
		EndMacro
	CompilerEndIf
	
	;{ Private variables, structures, constants...
	
	Enumeration
		#State_Cold
		#State_Warm
		#State_Hot
		#State_Drag
		#State_Resize
	EndEnumeration
	
	Enumeration ; Drag
		#Drag_None
		#Drag_Init
		#Drag_Movement
	EndEnumeration
	
	Enumeration ; Resize Mediablock
		#Resize_None
		#Resize_Hover
		#Resize_Movement
		#Resize_Start
		#Resize_End
	EndEnumeration
	
	Enumeration ; Folds
		#NoFold
		
		#Folded
		#Unfolded
	EndEnumeration
	
	Enumeration ;MediaBlock type
		#MediaBlock_Video
		#MediaBlock_Sound
		#MediaBlock_Effect
	EndEnumeration
	
	Enumeration ;Player state
		#Player_None
		#Player_Hover
		#Player_Drag
	EndEnumeration
	
	; Functionality
	#Func_LineSelection = #False
	#Func_DefaultDuration = 360
	
	; Style
	#Style_Header_Height = 60
	#Style_Header_ButtonSize = 30
	#Style_Header_ButtonSpace = 20
	
	#Style_Player_Width = 2
	#Style_Player_TopHeight = 24
	#Style_Player_TopWidth = 18
	#Style_Player_TopOffset = (#Style_Player_TopWidth - #Style_Player_Width) / 2
	#Style_Player_TopSquare = #Style_Player_TopHeight - #Style_Player_TopOffset - 1
	
	#Style_List_Width = 240
	#Style_List_LineHeight = 58
	#Style_List_FontSize = 24
	#Style_List_TextVOffset = (#Style_List_LineHeight - #Style_List_FontSize) / 2
	#Style_List_TextHOffset = 38
	#Style_List_LineMargin = 24
	#Style_List_FoldSize = 14
	#Style_List_FoldMargin = 10
	#Style_List_FoldVOffset = (#Style_List_LineHeight - #Style_List_FoldSize) / 2 + 2 ; +2 to get the right alignment with the text...
	
	#Style_Body_DefaultColumnWidth = 12
	#Style_Body_MaximumColumnWidth = 17
	#Style_Body_ColumnMargin = 2
	
	#Style_DataPoint_SizeBig = 5
	#Style_DataPoint_SizeMedium = 3
	#Style_DataPoint_SizeSmall = 1
	#Style_DataPoint_OffsetY = #Style_List_LineHeight / 2
	
	#Style_MediaBlock_Margin = 3
	#Style_MediaBlock_Height = #Style_List_LineHeight - 2 * #Style_MediaBlock_Margin
	#Style_MediaBlock_IconYOffset = 15
	#Style_MediaBlock_IconXOffset = 10
	#Style_MediaBlock_IconSize = #Style_List_LineHeight - 2 * #Style_MediaBlock_IconYOffset
	#Style_MediaBlock_IconMinimumWidth = #Style_MediaBlock_IconSize + #Style_MediaBlock_IconXOffset + 10
	
	; Colors
	#Color_ListBack		= $2F3136
	#Color_ListFront 	= $FFFFFF
	
	#Color_HeaderBack	= $2F3136
	
	#Color_BodyBack		= $323539
	#Color_BodyAltBack	= $36393F
	
	#Color_Blending_Front_Hot = 255
	#Color_Blending_Front_Warm = 210
	#Color_Blending_Front_Cold = 120
	
	#Color_Blending_Back_Hot = 16
	#Color_Blending_Back_Warm = 8
	#Color_Blending_Back_Cold = 0
	
	#Color_Body_Objects00 = $0094FF
	#Color_Body_Objects01 = $FF3232
	#Color_Body_Objects02 = $FF6A00
	#Color_Body_Objects03 = $FFDB37
	#Color_Body_Objects04 = $00D721
	#Color_Body_Objects05 = $C03AFF
	#Color_Body_Count = 6
	
	#Color_Player = $FF6654
	
	Structure MediaBlock
		BlockType.b
		FirstBlock.i
		LastBlock.i
		Identifier.i
		Icon.i
		State.b
; 		Test.s		; Could be added?
		*Line.Line
		*StateListElement
	EndStructure
	
	Structure DataPoint
		Position.i
		State.b
		Identifier.i
		*Line.Line
	EndStructure
	
	Structure LineAdress
		*Object.Line
	EndStructure
	
	Structure Line
		Text.s
		Fold.b
		HOffset.b
		Color.i
		
		*DisplayListAdress
		*Parent.Line
		*ParentListAdress
		
		List Content_Lines.LineAdress()
		Array *DataPoints.DataPoint(1)
		Array *MediaBlocks.MediaBlock(1)
	EndStructure
	
	Structure Item
		Text.s
	EndStructure
	
	Structure ItemAdress
		*Object.Item
	EndStructure
	
	Structure GadgetData
		; Content
		List Content_Lines.LineAdress()
		List Content_DisplayedLines.LineAdress()
		
		Content_Duration.i
		
		; Components
		Comp_VScrollBar.i
		Comp_HScrollbar.i
		Comp_PlayButton.i
		Comp_StartButton.i
		Comp_EndButton.i
		
		; Colors
		Colors_HeaderBack.l
		Colors_HeaderFront.l
		Colors_ListBack.l
		Colors_ListFront.l
		Colors_BodyBack.l
		Colors_BodyFront.l
		Colors_BodyAltBack.l
		Colors_BodyAltFront.l
		
		; Measurements
		Meas_Body_HOffset.i
		Meas_Body_VOffset.i
		Meas_Body_Width.i
		Meas_Body_Height.i
		
		Meas_List_Width.i
		Meas_List_Height.i
		Meas_List_HOffset.i
		Meas_List_VOffset.i
		
		Meas_Header_Width.i
		Meas_Header_Height.i
		
		Meas_VisibleLines.i
		Meas_VisibleColumns.i
		
		Meas_VScrollPosition.i
		Meas_VScrollBarWidth.i
		Meas_VScrollBarVisible.b
		
		Meas_HScrollPosition.i
		Meas_HScrollbarHeight.i
		Meas_HScrollBarVisible.b
		
		Meas_Body_ColumnWidth.i
		
		; State
		State_HotLine.i
		State_WarmLine.i
		State_WarmToggleButton.i
		*State_WarmDataPoint.DataPoint
		*State_WarmMediaBlock.Mediablock
		List *State_HotMediaBlocks.Mediablock()
		
		; Player
		Player_Enabled.b
		Player_Position.i
		Player_State.b
		Player_OriginX.i
		Player_Step.b
		
		; Drag
		Drag_MediaBlock.i
		Drag_DataPoint.i
		Drag_OriginX.i
		Drag_OriginY.i
		Drag_OffsetX.i
		Drag_OffsetY.i
		*Drag_MediaBlock_Unselect.Mediablock
		*Drag_MediaBlock_Keep.Mediablock
		
		; Resize MB
		Resize_State.b
		Resize_Direction.b
		Resize_OriginX.i
		Resize_Offset.i
		
		; Drawing informations
		Draw_Font.i
		Draw_FontSize.i
		Draw_ColorIndex.i
		Draw_Freeze.i
	EndStructure
	
	Global DefaultFont = LoadFont(#PB_Any, "Bebas Neue", #Style_List_FontSize, #PB_Font_HighQuality)
	
	Global Dim DefaultColors(#Color_Body_Count - 1)
	DefaultColors(0) = FixColor(#Color_Body_Objects00)
	DefaultColors(1) = FixColor(#Color_Body_Objects01)
	DefaultColors(2) = FixColor(#Color_Body_Objects02)
	DefaultColors(3) = FixColor(#Color_Body_Objects03)
	DefaultColors(4) = FixColor(#Color_Body_Objects04)
	DefaultColors(5) = FixColor(#Color_Body_Objects05)
	;}
	; Private procedures declaration
	Macro CoolDown ; Removes any warm element.
		If *Data\State_WarmLine > -1
			*Data\State_WarmLine = -1
			Redraw = #True
		EndIf
		
		If *Data\State_WarmToggleButton > -1
			*Data\State_WarmToggleButton = -1
			Redraw = #True
		EndIf
		
		If *Data\State_WarmMediaBlock
			If *Data\State_WarmMediaBlock\State = #State_Warm
				*Data\State_WarmMediaBlock\State = #State_Cold
				Redraw = #True
			EndIf
			*Data\State_WarmMediaBlock = 0
		EndIf
			
		If *Data\State_WarmDataPoint
			*Data\State_WarmDataPoint\State = #State_Cold
			*Data\State_WarmDataPoint = 0
			Redraw = #True
		EndIf
		
		If *Data\Resize_State = #Resize_Hover
			*Data\Resize_State = #Resize_None
			SetGadgetAttribute(Gadget, #PB_Canvas_Cursor, #PB_Cursor_Default)
		EndIf
		
		If *Data\Player_State = #Player_Hover
			*Data\Player_State = #Player_None
; 			SetGadgetAttribute(Gadget, #PB_Canvas_Cursor, #PB_Cursor_Default)
		EndIf
		
	EndMacro
	Macro MouseMove
		MouseX - *Data\Meas_Body_HOffset
		Column = Round(MouseX / *Data\Meas_Body_ColumnWidth, #PB_Round_Down) + *Data\Meas_HScrollPosition
		If Column > *Data\Content_Duration
			CoolDown
		Else
			SelectElement(*Data\Content_DisplayedLines(), Line)
			If (MouseY > #Style_MediaBlock_Margin And MouseY < #Style_List_LineHeight - #Style_MediaBlock_Margin)
				If *Data\Content_DisplayedLines()\Object\Mediablocks(Column) 
					If *Data\State_WarmMediaBlock <> *Data\Content_DisplayedLines()\Object\Mediablocks(Column)
						CoolDown
						*Data\State_WarmMediaBlock = *Data\Content_DisplayedLines()\Object\Mediablocks(Column)
						If *Data\State_WarmMediaBlock\State = #State_Cold
							*Data\State_WarmMediaBlock\State = #State_Warm
							Redraw = #True
						EndIf
					EndIf
					
					If *Data\State_WarmMediaBlock\State = #State_Hot
						If Abs(MouseX - ((*Data\State_WarmMediaBlock\FirstBlock - *Data\Meas_HScrollPosition) * *Data\Meas_Body_ColumnWidth)) <= 3
							*Data\Resize_State = #Resize_Hover
							*Data\Resize_Direction = #Resize_Start
							SetGadgetAttribute(Gadget, #PB_Canvas_Cursor, #PB_Cursor_LeftRight)
						ElseIf Abs(MouseX - ((*Data\State_WarmMediaBlock\LastBlock - *Data\Meas_HScrollPosition + 1) * *Data\Meas_Body_ColumnWidth)) <= 3
							*Data\Resize_State = #Resize_Hover
							SetGadgetAttribute(Gadget, #PB_Canvas_Cursor, #PB_Cursor_LeftRight)
							*Data\Resize_Direction = #Resize_End
						ElseIf *Data\Resize_State = #Resize_Hover
							*Data\Resize_State = #Resize_None
							SetGadgetAttribute(Gadget, #PB_Canvas_Cursor, #PB_Cursor_Default)
						EndIf
					EndIf
					
				Else
					If Column > 0 And *Data\Content_DisplayedLines()\Object\Mediablocks(Column - 1) And *Data\Content_DisplayedLines()\Object\Mediablocks(Column - 1)\State = #State_Hot
						If Abs(MouseX - (Column - *Data\Meas_HScrollPosition) * *Data\Meas_Body_ColumnWidth) <= 3
							*Data\Resize_State = #Resize_Hover
							*Data\Resize_Direction = #Resize_End
							SetGadgetAttribute(Gadget, #PB_Canvas_Cursor, #PB_Cursor_LeftRight)
						Else
							CoolDown
						EndIf
					ElseIf Column < *Data\Content_Duration And *Data\Content_DisplayedLines()\Object\Mediablocks(Column + 1) And *Data\Content_DisplayedLines()\Object\Mediablocks(Column + 1)\State = #State_Hot
						If Abs(MouseX - ((Column + 1 - *Data\Meas_HScrollPosition)  * *Data\Meas_Body_ColumnWidth)) <= 4
							*Data\Resize_State = #Resize_Hover
							*Data\Resize_Direction = #Resize_Start
							SetGadgetAttribute(Gadget, #PB_Canvas_Cursor, #PB_Cursor_LeftRight)
						Else
							CoolDown
						EndIf
					Else
						CoolDown
					EndIf
				EndIf
			Else
				CoolDown
			EndIf
		EndIf
	EndMacro
	Macro VerticalFocus
		If *Data\State_HotLine < *Data\Meas_VScrollPosition
			*Data\Meas_VScrollPosition = *Data\State_HotLine
			SetGadgetState(*Data\Comp_VScrollBar, *Data\Meas_VScrollPosition)
		ElseIf *Data\State_HotLine >= *Data\Meas_VScrollPosition + *Data\Meas_VisibleLines - 1
			*Data\Meas_VScrollPosition = *Data\State_HotLine - *Data\Meas_VisibleLines + 1
			SetGadgetState(*Data\Comp_VScrollBar, *Data\Meas_VScrollPosition)
		EndIf
	EndMacro
	Macro HorizontalFocus
		If *Data\Meas_HScrollPosition > *Data\Player_Position
			SetGadgetState(*Data\Comp_HScrollbar, *Data\Player_Position - *Data\Meas_VisibleColumns * 0.5)
			*Data\Meas_HScrollPosition = GetGadgetState(*Data\Comp_HScrollbar)
			Redraw(Gadget)
		ElseIf *Data\Meas_HScrollPosition + *Data\Meas_VisibleColumns < *Data\Player_Position
			SetGadgetState(*Data\Comp_HScrollbar, *Data\Player_Position - *Data\Meas_VisibleColumns * 0.5)
			*Data\Meas_HScrollPosition = GetGadgetState(*Data\Comp_HScrollbar)
			Redraw(Gadget)
		EndIf
	EndMacro
	Macro MakeSpace(Block1, Block2, Direction) ; Recurcively move any blocs on the way /!\Marked for cleanup/!\ This macro was a mistake and makes everything harder to read and understand. 
		For loop = New#Block2#Block To New#Block1#Block Step Direction
			If *Block\Line\MediaBlocks(Loop)
				TargetOffset = New#Block2#Block - *Block\Line\MediaBlocks(Loop)\Block1#Block - Direction
				ResultOffset = MoveMediaBlock(*Block\Line\MediaBlocks(Loop), TargetOffset)
				
				If Not ResultOffset = TargetOffset
					Offset = Offset - (TargetOffset - ResultOffset)
					Success = #False
					Break
				EndIf
				
			EndIf
		Next
	EndMacro
	
	Procedure Min(a, b)
		If b < a
			ProcedureReturn b
		EndIf
		ProcedureReturn a
	EndProcedure
	Procedure Max(a, b)
		If b > a
			ProcedureReturn b
		EndIf
		ProcedureReturn a
	EndProcedure
	
	Declare HandlerCanvas()
	Declare HandlerHScrollbar()
	Declare HandlerVScrollbar()
	Declare HandlerPlayButton(Gadget)
	Declare HandlerStartButton(Gadget)
	Declare HandlerEndButton(Gadget)
	Declare HandlerPlayer()
	Declare ScrollVertical(Gadget)
	Declare ScrollHorizontal(Gadget)
	Declare Redraw(Gadget)
	Declare DrawLine(*Data, YPos, ListIndex, AltBackground)
	Declare Refit(Gadget)
	Declare RecurciveDelete(*Data.GadgetData, *Line.Line)
	Declare RecurciveFold(*Data.GadgetData, *Line.Line)
	Declare RecurciveUnFold(*Data.GadgetData, *Line.Line)
	Declare ResizeMB(*Block.MediaBlock, Start, Finish)
	Declare ToggleFold(Gadget, Item)
	Declare MoveMediaBlock(*Block.MediaBlock, Offset)
	
	; Public procedures
	Procedure Gadget(Gadget, X, Y, Width, Height, Flags = #Default)
		Protected Result.i, *Data.GadgetData, Theme
		Result = CanvasGadget(Gadget, X, Y, Width, Height, #PB_Canvas_Container | #PB_Canvas_Keyboard)
		
		If Result
			If Gadget = #PB_Any
				Gadget = Result
			EndIf
			
			*Data = AllocateStructure(GadgetData)
			
			With *Data
				; Colors
				\Colors_HeaderBack = FixColor(#Color_HeaderBack)
				
				\Colors_ListBack = FixColor(#Color_ListBack)
				\Colors_ListFront = FixColor(#Color_ListFront)
				
				\Colors_BodyBack = FixColor(#Color_BodyBack)
				\Colors_BodyAltBack = FixColor(#Color_BodyAltBack)
				
				; Measurements
				\Meas_List_Width = #Style_List_Width
				\Meas_Header_Height = #Style_Header_Height
				\Meas_Body_ColumnWidth = #Style_Body_DefaultColumnWidth
				
				; Drawing informations
				\Draw_Font = DefaultFont
				\Draw_FontSize = #Style_List_FontSize
				
				; State
				\State_HotLine = -1
				\State_WarmLine = -1
				\State_WarmToggleButton = -1
				
				\Content_Duration = #Func_DefaultDuration + #Style_Body_ColumnMargin * 2
				
				; Components
				\Comp_VScrollBar = ScrollBarGadget(#PB_Any, 0, 0, 10, 10, 0, 10, 10, #PB_ScrollBar_Vertical)
				\Meas_VScrollBarWidth = GadgetWidth(\Comp_VScrollBar, #PB_Gadget_RequiredSize)
				HideGadget(\Comp_VScrollBar, #True)
				BindGadgetEvent(\Comp_VScrollBar, @HandlerVScrollbar())
				SetGadgetData(\Comp_VScrollBar, Gadget)
				
				\Comp_HScrollbar = ScrollBarGadget(#PB_Any, 0, 0, 10, 10, 0, *Data\Content_Duration - 1, 10)
				\Meas_HScrollbarHeight = GadgetHeight(\Comp_HScrollbar, #PB_Gadget_RequiredSize)
				HideGadget(\Comp_HScrollbar, #True)
				BindGadgetEvent(\Comp_HScrollBar, @HandlerHScrollbar())
				SetGadgetData(\Comp_HScrollBar, Gadget)
				
				\Comp_StartButton = CanvasButton::GadgetImage(#PB_Any,
				                                              (#Style_List_Width - 3 * #Style_Header_ButtonSize - 2 * #Style_Header_ButtonSpace) * 0.5,
				                                              (#Style_Header_Height - #Style_Header_ButtonSize) * 0.5, #Style_Header_ButtonSize, 
				                                              #Style_Header_ButtonSize, MaterialVector::#Skip,
				                                              CanvasButton::#MaterialVectorIcon | CanvasButton::#DarkTheme | MaterialVector::#style_rotate_180)
				CanvasButton::SetColor(\Comp_StartButton, CanvasButton::#ColorType_BackWarm, SetAlpha($FF, \Colors_BodyBack))
				CanvasButton::SetColor(\Comp_StartButton, CanvasButton::#ColorType_BackHot, SetAlpha($FF, \Colors_BodyBack))
				CanvasButton::SetData(\Comp_StartButton, Gadget)
				CanvasButton::BindEventHandler(\Comp_StartButton, @HandlerStartButton())
				
				\Comp_PlayButton = CanvasButton::GadgetImage(#PB_Any,
				                                              (#Style_List_Width - 3 * #Style_Header_ButtonSize - 2 * #Style_Header_ButtonSpace) * 0.5 + #Style_Header_ButtonSize + #Style_Header_ButtonSpace,
				                                              (#Style_Header_Height - #Style_Header_ButtonSize) * 0.5, #Style_Header_ButtonSize, 
				                                              #Style_Header_ButtonSize, MaterialVector::#Play,
				                                              CanvasButton::#MaterialVectorIcon | CanvasButton::#DarkTheme)
				CanvasButton::SetColor(\Comp_PlayButton, CanvasButton::#ColorType_BackWarm, SetAlpha($FF, \Colors_BodyBack))
				CanvasButton::SetColor(\Comp_PlayButton, CanvasButton::#ColorType_BackHot, SetAlpha($FF, \Colors_BodyBack))
				CanvasButton::SetData(\Comp_PlayButton, Gadget)
				CanvasButton::BindEventHandler(\Comp_PlayButton, @HandlerPlayButton())
				
				\Comp_EndButton = CanvasButton::GadgetImage(#PB_Any,
				                                              (#Style_List_Width - 3 * #Style_Header_ButtonSize - 2 * #Style_Header_ButtonSpace) * 0.5 + #Style_Header_ButtonSize * 2 + #Style_Header_ButtonSpace * 2,
				                                              (#Style_Header_Height - #Style_Header_ButtonSize) * 0.5, #Style_Header_ButtonSize, 
				                                              #Style_Header_ButtonSize, MaterialVector::#Skip,
				                                              CanvasButton::#MaterialVectorIcon | CanvasButton::#DarkTheme)
				CanvasButton::SetColor(\Comp_EndButton, CanvasButton::#ColorType_BackWarm, SetAlpha($FF, \Colors_BodyBack))
				CanvasButton::SetColor(\Comp_EndButton, CanvasButton::#ColorType_BackHot, SetAlpha($FF, \Colors_BodyBack))
				CanvasButton::SetData(\Comp_EndButton, Gadget)
				CanvasButton::BindEventHandler(\Comp_EndButton, @HandlerEndButton())
				
				; Player
				\Player_Position = #Style_Body_ColumnMargin
				\Player_State = #False
			EndWith
			
			CloseGadgetList()
			SetGadgetData(Gadget, *Data)
			Refit(Gadget)
			Redraw(Gadget)
			BindGadgetEvent(Gadget, @HandlerCanvas())
		EndIf
		
		ProcedureReturn Result
	EndProcedure
	
	Procedure Resize(Gadget, X, Y, Width, Height)
		ResizeGadget(Gadget, X, Y, Width, Height)
		Refit(Gadget)
		Redraw(Gadget)
	EndProcedure
	
	Procedure Freeze(Gadget, State)
		Protected *Data.GadgetData = GetGadgetData(Gadget)
		*Data\Draw_Freeze = State
		
		Redraw(Gadget)
	EndProcedure
	
	Procedure AddLine(Gadget, Position, Text.s, *ParentID.Line = 0, Flags = #Default)
		Protected *Data.GadgetData = GetGadgetData(Gadget)
		Protected *NewLine.Line = AllocateStructure(Line), *PreviousLine.Line
		
		If *ParentID
			If Position = -1 Or Position >= ListSize(*ParentID\Content_Lines())
				LastElement(*ParentID\Content_Lines())
				
				If ListSize(*ParentID\Content_Lines()) = 0
					*PreviousLine = *ParentID
				Else
					*PreviousLine = *ParentID\Content_Lines()\Object
				EndIf
			Else
				If Position = 0
					ResetList(*ParentID\Content_Lines())
					*PreviousLine = *ParentID
				Else
					SelectElement(*ParentID\Content_Lines(), Position - 1)
					*PreviousLine = *ParentID\Content_Lines()\Object
				EndIf
			EndIf
			
			AddElement(*ParentID\Content_Lines())
			*ParentID\Content_Lines()\Object = *NewLine
			
			*NewLine\HOffset = *ParentID\HOffset + #Style_List_TextHOffset
			
			If *ParentID\Fold = #Unfolded 
				If *ParentID\DisplayListAdress
					ChangeCurrentElement(*Data\Content_DisplayedLines(), *PreviousLine)
					AddElement(*Data\Content_DisplayedLines())
					*Data\Content_DisplayedLines()\Object = *NewLine
					*NewLine\DisplayListAdress = @*Data\Content_DisplayedLines()
				EndIf
			ElseIf *ParentID\Fold = #NoFold
				*ParentID\Fold = #Folded
			EndIf
			
			*NewLine\Parent = *ParentID
			*NewLine\ParentListAdress = @*ParentID\Content_Lines()
			*NewLine\Color = *ParentID\Color
		Else
			If Position = -1 Or Position >= ListSize(*Data\Content_Lines())
				LastElement(*Data\Content_DisplayedLines())
				AddElement(*Data\Content_DisplayedLines())
				
				LastElement(*Data\Content_Lines())
				AddElement(*Data\Content_Lines())
			Else
				SelectElement(*Data\Content_Lines(), Position)
				ChangeCurrentElement(*Data\Content_DisplayedLines(), *Data\Content_Lines()\Object\DisplayListAdress)
				InsertElement(*Data\Content_DisplayedLines())
				InsertElement(*Data\Content_Lines())
			EndIf
			
			*Data\Content_DisplayedLines()\Object = *NewLine
			*Data\Content_Lines()\Object = *NewLine
			
			*NewLine\HOffset = #Style_List_LineMargin
			*NewLine\ParentListAdress = @*Data\Content_Lines()
			*NewLine\DisplayListAdress = @*Data\Content_DisplayedLines()
			*NewLine\Color = DefaultColors(*Data\Draw_ColorIndex)
			*Data\Draw_ColorIndex = (*Data\Draw_ColorIndex + 1) % #Color_Body_Count
		EndIf
		
		ReDim *NewLine\DataPoints(*Data\Content_Duration)
		ReDim *NewLine\Mediablocks(*Data\Content_Duration)
		*NewLine\Text = Text
		
		Refit(Gadget)
		Redraw(Gadget)
		
		ProcedureReturn *NewLine
	EndProcedure
	
	Procedure DeleteLine(Gadget, *Line.Line)
		Protected *Data.GadgetData = GetGadgetData(Gadget)
		
		RecurciveDelete(*Data.GadgetData, *Line.Line)
		
		Refit(Gadget)
		Redraw(Gadget)
	EndProcedure
	
	Procedure GetLineID(Gadget, Position, *ParentID.Line = 0)
		If *ParentID
			If SelectElement(*ParentID\Content_Lines(), Position)
				ProcedureReturn *ParentID\Content_Lines()\Object
			EndIf
		Else
			Protected *Data.GadgetData = GetGadgetData(Gadget)
			If SelectElement(*Data\Content_Lines(), Position)
				ProcedureReturn *Data\Content_Lines()\Object
			EndIf
		EndIf
	EndProcedure
	
	Procedure AddDataPoint(Gadget, *Line.Line, Position, Identifier = 0)
		Protected *Data.GadgetData = GetGadgetData(Gadget), *Point.DataPoint = AllocateMemory(SizeOf(DataPoint))
		
		Position + #Style_Body_ColumnMargin
		
		*Point\Position = Position
		*Point\State = #False
		*Point\Identifier = Identifier
		*Point\Line = *Line
		
		*Line\DataPoints(Position) = *Point
		
		Redraw(Gadget)
	EndProcedure
	
	Procedure AddMediaBlock(Gadget, *Line.Line, Start, Finish, Identifier = 0, Icon = -1)
		Protected *Data.GadgetData = GetGadgetData(Gadget), *Block.Mediablock = AllocateMemory(SizeOf(Mediablock)), Loop
		
		Start + #Style_Body_ColumnMargin
		Finish + #Style_Body_ColumnMargin
		
		*Block\FirstBlock = Start
		*Block\LastBlock = Finish
		*Block\Line = *Line
		*Block\Identifier = Identifier
		
		*Block\Icon = Icon
		
		For loop = Start To Finish
			*Line\Mediablocks(Loop) = *Block
		Next
		
		Redraw(Gadget)
	EndProcedure
	
	Procedure ResizeMediaBlock(Gadget, MediablockID, Start, Finish)
		
	EndProcedure
	
	; Private procedures
	Procedure MoveMediaBlock(*Block.MediaBlock, Offset)
		Protected BlockDuration = *Block\LastBlock - *Block\FirstBlock + 1, loop
		Protected NewFirstBlock, NewLastBlock, Success, TargetOffset, ResultOffset
		
		For loop = *Block\FirstBlock To *Block\LastBlock
			*Block\Line\MediaBlocks(Loop) = 0
		Next
		
		If *Block\FirstBlock + Offset < #Style_Body_ColumnMargin
			Offset = #Style_Body_ColumnMargin - *Block\FirstBlock 
		EndIf
		
		If *Block\LastBlock + Offset > ArraySize(*Block\Line\MediaBlocks()) - 2
			Offset = ArraySize(*Block\Line\MediaBlocks()) - *Block\LastBlock - 2
		EndIf
		
		Repeat
			Success = #True
			NewFirstBlock =  *Block\FirstBlock + Offset
			NewLastBlock = *Block\LastBlock + Offset
			
			If Offset > 0
				MakeSpace(First, Last, -1)
			Else
				MakeSpace(Last, First, 1)
			EndIf
		Until Success = #True
		
		*Block\FirstBlock = NewFirstBlock
		*Block\LastBlock =  NewLastBlock
		
		For loop = *Block\FirstBlock To *Block\LastBlock
			*Block\Line\MediaBlocks(Loop) = *Block
		Next
		
		ProcedureReturn Offset
	EndProcedure
	
	Procedure HandlerCanvas()
		Protected Gadget = EventGadget(), *Data.GadgetData = GetGadgetData(Gadget)
		Protected MouseX = GetGadgetAttribute(Gadget, #PB_Canvas_MouseX)
		Protected MouseY = GetGadgetAttribute(Gadget, #PB_Canvas_MouseY)
		Protected Line, Column, Redraw, OffsetX
		
		Select EventType()
			Case #PB_EventType_MouseMove ;{
				If *Data\Resize_State = #Resize_Movement ;{
					OffsetX = Round((MouseX - *Data\Resize_OriginX) / *Data\Meas_Body_ColumnWidth, #PB_Round_Down)
					
					If OffsetX <> *Data\Resize_Offset
						*Data\Resize_Offset = OffsetX
						Redraw = #True
					EndIf
					
					;}
				ElseIf *Data\Drag_MediaBlock
					If *Data\Drag_MediaBlock = #Drag_Movement ;{ Draginig media blocks
						OffsetX = (MouseX - *Data\Drag_OriginX) / *Data\Meas_Body_ColumnWidth
						If Not *Data\Drag_OffsetX = OffsetX
							*Data\Drag_OffsetX = OffsetX
							Redraw = #True
						EndIf
						;}
					Else ;{ Drag init
						If Abs(MouseX - *Data\Drag_OriginX) + Abs(MouseX - *Data\Drag_OriginX) > 4
							*Data\Drag_MediaBlock = #Drag_Movement
							SetGadgetAttribute(Gadget, #PB_Canvas_Cursor, #PB_Cursor_Arrows)
							
							ForEach *Data\State_HotMediaBlocks()
								*Data\State_HotMediaBlocks()\State = #State_Drag
							Next
							
							Redraw = #True
							
						EndIf
					EndIf ;}
				Else
					If MouseY <= *Data\Meas_Header_Height ;{ Header
						MouseX - *Data\Meas_Body_HOffset
						
						CoolDown
						If MouseX >= (*Data\Player_Position - *Data\Meas_HScrollPosition) * *Data\Meas_Body_ColumnWidth - #Style_Player_TopOffset And MouseX <= (*Data\Player_Position - *Data\Meas_HScrollPosition) * *Data\Meas_Body_ColumnWidth + #Style_Player_TopOffset
							*Data\Player_State = #Player_Hover
; 							SetGadgetAttribute(Gadget, #PB_Canvas_Cursor, #PB_Cursor_LeftRight)
						EndIf
						
						;}
					Else 
						;{ Get active line
						MouseY - *Data\Meas_Header_Height
						Line = Round(MouseY / #Style_List_LineHeight, #PB_Round_Down)
						MouseY - (Line * #Style_List_LineHeight)
						Line + *Data\Meas_VScrollPosition
						
						If Line => ListSize(*Data\Content_DisplayedLines())
							If *Data\State_WarmToggleButton > -1 Or *Data\State_WarmLine > -1
								CoolDown
								Redraw(Gadget)
							EndIf
							ProcedureReturn
						EndIf
						;}
						
						If MouseX <= *Data\Meas_List_Width ;{ List
							If MouseY >= #Style_List_FoldVOffset - 4 And MouseY <= #Style_List_FoldVOffset + #Style_List_FoldSize + 4
								SelectElement(*Data\Content_DisplayedLines(), Line)
								If *Data\Content_DisplayedLines()\Object\Fold
									If MouseX >= *Data\Content_DisplayedLines()\Object\HOffset - 4 And MouseX <= *Data\Content_DisplayedLines()\Object\HOffset + #Style_List_FoldSize + 4
										If Not Line = *Data\State_WarmToggleButton
											CoolDown
											*Data\State_WarmToggleButton = line
											Redraw(Gadget)
										EndIf
										ProcedureReturn
									EndIf
								EndIf
							EndIf
							
							If *Data\State_WarmToggleButton > -1
								*Data\State_WarmToggleButton = -1
								Redraw = #True
							EndIf
							
							CompilerIf #Func_LineSelection
								If Not line = *Data\State_WarmLine
									CoolDown
									*Data\State_WarmLine = line
									Redraw = #True
								EndIf
							CompilerEndIf
							;}
						Else ;{ body
							MouseMove
						EndIf ;}
					EndIf
				EndIf;}
			Case #PB_EventType_MouseLeave ;{
				CoolDown
				;}
			Case #PB_EventType_LeftButtonUp ;{
				If *Data\Resize_State = #Resize_Movement ;{
					*Data\Resize_State = #Resize_None
					ForEach *Data\State_HotMediaBlocks()
						If *Data\Resize_Direction = #Resize_Start
							ResizeMB(*Data\State_HotMediaBlocks(), Min(max(*Data\State_HotMediaBlocks()\FirstBlock + *Data\Resize_Offset, #Style_Body_ColumnMargin), *Data\State_HotMediaBlocks()\LastBlock - 1), *Data\State_HotMediaBlocks()\LastBlock)
						Else
							ResizeMB(*Data\State_HotMediaBlocks(), *Data\State_HotMediaBlocks()\FirstBlock, max(Min(*Data\State_HotMediaBlocks()\LastBlock + *Data\Resize_Offset, *Data\Content_Duration - 2 * #Style_Body_ColumnMargin), *Data\State_HotMediaBlocks()\FirstBlock + 1))
						EndIf
						*Data\State_HotMediaBlocks()\State = #State_Hot
					Next
					SetGadgetAttribute(Gadget, #PB_Canvas_Cursor, #PB_Cursor_Default)
					Redraw = #True
				;}
				ElseIf *Data\Drag_MediaBlock = #Drag_Init ;{
					If *Data\Drag_MediaBlock_Unselect
						ChangeCurrentElement(*Data\State_HotMediaBlocks(), *Data\Drag_MediaBlock_Unselect\StateListElement)
						DeleteElement(*Data\State_HotMediaBlocks())
						*Data\Drag_MediaBlock_Unselect\State = #State_Warm
						Redraw = #True
					ElseIf *Data\Drag_MediaBlock_Keep
						ForEach *Data\State_HotMediaBlocks()
							*Data\State_HotMediaBlocks()\State = #State_Cold
							DeleteElement(*Data\State_HotMediaBlocks())
						Next
						
						*Data\Drag_MediaBlock_Keep\State = #State_Hot
						AddElement(*Data\State_HotMediaBlocks())
						*Data\State_HotMediaBlocks() = *Data\Drag_MediaBlock_Keep
						*Data\Drag_MediaBlock_Keep\StateListElement = @*Data\State_HotMediaBlocks()
						Redraw = #True
					EndIf
					
					*Data\Drag_MediaBlock = #Drag_None ;}
				ElseIf *Data\Drag_MediaBlock = #Drag_Movement ;{
					ForEach *Data\State_HotMediaBlocks()
						MoveMediaBlock(*Data\State_HotMediaBlocks(), *Data\Drag_OffsetX)
						*Data\State_HotMediaBlocks()\State = #State_Hot
					Next
					SetGadgetAttribute(Gadget, #PB_Canvas_Cursor, #PB_Cursor_Default)
					*Data\Drag_MediaBlock = #Drag_None
					*Data\Drag_OffsetX = 0
					Redraw = #True
				EndIf 
				;}
				*Data\Drag_MediaBlock_Unselect = 0
				*Data\Drag_MediaBlock_Keep = 0
				;}
			Case #PB_EventType_LeftButtonDown ;{
				If MouseY <= *Data\Meas_Header_Height ;{ Header
					If *Data\Player_State = #Player_Hover
						
					EndIf
				Else ;}
					If MouseX <= *Data\Meas_List_Width ;{ List
						If *Data\State_WarmLine > -1 And Not *Data\State_HotLine = *Data\State_WarmLine
							*Data\State_HotLine = *Data\State_WarmLine
							*Data\State_WarmLine = -1
							Redraw = #True
						ElseIf *Data\State_WarmToggleButton > -1
							ToggleFold(Gadget, *Data\State_WarmToggleButton)
						EndIf
						;}
					Else;{ body
						If *Data\Resize_State = #Resize_Hover
							*Data\Resize_State = #Resize_Movement
; 							*Data\Resize_MediaBlock\State = #State_Resize
							
							ForEach *Data\State_HotMediaBlocks()
								*Data\State_HotMediaBlocks()\State = #State_Resize
							Next
							
							*Data\Resize_OriginX = MouseX
							*Data\Resize_Offset = 0
							
							Redraw = #True
						ElseIf *Data\State_WarmMediaBlock
							If Not *Data\State_WarmMediaBlock\State = #State_Hot
								If Not (GetGadgetAttribute(Gadget, #PB_Canvas_Modifiers) & #PB_Canvas_Control)
									ForEach *Data\State_HotMediaBlocks()
										*Data\State_HotMediaBlocks()\State = #State_Cold
										DeleteElement(*Data\State_HotMediaBlocks())
									Next
								EndIf
								
								*Data\State_WarmMediaBlock\State = #State_Hot
								AddElement(*Data\State_HotMediaBlocks())
								*Data\State_HotMediaBlocks() = *Data\State_WarmMediaBlock
								*Data\State_WarmMediaBlock\StateListElement = @*Data\State_HotMediaBlocks()
								
								Redraw = #True
							Else
								If GetGadgetAttribute(Gadget, #PB_Canvas_Modifiers) & #PB_Canvas_Control
									
									*Data\Drag_MediaBlock_Unselect = *Data\State_WarmMediaBlock
									
								ElseIf ListSize(*Data\State_HotMediaBlocks()) > 1
									*Data\Drag_MediaBlock_Keep = *Data\State_WarmMediaBlock
								EndIf
							EndIf
							
							*Data\Drag_MediaBlock = #Drag_Init
							*Data\Drag_OriginX = MouseX
							*Data\Drag_OriginY = MouseY
							
						ElseIf *Data\State_WarmDataPoint
							
						Else
							If Not (GetGadgetAttribute(Gadget, #PB_Canvas_Modifiers) & #PB_Canvas_Control)
								ForEach *Data\State_HotMediaBlocks()
									*Data\State_HotMediaBlocks()\State = #State_Cold
									DeleteElement(*Data\State_HotMediaBlocks())
									Redraw = #True
								Next
							EndIf
						EndIf
					EndIf ;}
				EndIf
				;}
			Case #PB_EventType_LeftDoubleClick ;{
				If MouseY <= *Data\Meas_Header_Height ;{ Header
					
				Else ;}
					If MouseX <= *Data\Meas_List_Width ;{ List
						If *Data\State_WarmToggleButton = -1 
							Line = Round((MouseY - *Data\Meas_Header_Height) / #Style_List_LineHeight, #PB_Round_Down) + *Data\Meas_VScrollPosition
							If Line < ListSize(*Data\Content_DisplayedLines())
								SelectElement(*Data\Content_DisplayedLines(), Line)
								If *Data\Content_DisplayedLines()\Object\Fold
									ToggleFold(Gadget, Line)
								EndIf
							EndIf
						EndIf
						;}
					Else;{ body
						
					EndIf ;}
				EndIf
				;}
			Case #PB_EventType_MouseWheel ;{
				If (GetGadgetAttribute(Gadget, #PB_Canvas_Modifiers) & #PB_Canvas_Control)
					If GetGadgetAttribute(Gadget, #PB_Canvas_WheelDelta) = 1
						If *Data\Meas_Body_ColumnWidth < #Style_Body_MaximumColumnWidth
							*Data\Meas_Body_ColumnWidth = *Data\Meas_Body_ColumnWidth + 1
						EndIf
					Else
						If *Data\Meas_Body_ColumnWidth > 1
							*Data\Meas_Body_ColumnWidth = *Data\Meas_Body_ColumnWidth - 1
						EndIf
					EndIf
					
					Refit(Gadget)
					MouseMove
					Redraw = #True
				Else
					SetGadgetState(*Data\Comp_VScrollBar, GetGadgetState(*Data\Comp_VScrollBar) - GetGadgetAttribute(Gadget, #PB_Canvas_WheelDelta))
					If ScrollVertical(Gadget)
						MouseMove
						Redraw = #True
					EndIf
				EndIf
				;}
			Case #PB_EventType_KeyDown ;{
				Select GetGadgetAttribute(Gadget, #PB_Canvas_Key)
					CompilerIf #Func_LineSelection
					Case #PB_Shortcut_Up
						If *Data\State_HotLine > 0
							*Data\State_HotLine - 1
							VerticalFocus
							Redraw = #True
						EndIf
					Case #PB_Shortcut_Down		
						If *Data\State_HotLine < ListSize(*Data\Content_DisplayedLines()) - 1
							*Data\State_HotLine + 1
							VerticalFocus
							Redraw = #True
						EndIf
					Case #PB_Shortcut_Space
						If *Data\State_HotLine > -1
							SelectElement(*Data\Content_DisplayedLines(), *Data\State_HotLine)
							If *Data\Content_DisplayedLines()\Object\Fold
								ToggleFold(Gadget, *Data\State_HotLine)
							EndIf
						EndIf
					CompilerElse	
					Case #PB_Shortcut_Up
						SetGadgetState(*Data\Comp_VScrollBar, GetGadgetState(*Data\Comp_VScrollBar) - 1)
						If ScrollVertical(Gadget)
							MouseMove
							Redraw = #True
						EndIf
					Case #PB_Shortcut_Down		
						SetGadgetState(*Data\Comp_VScrollBar, GetGadgetState(*Data\Comp_VScrollBar) + 1)
						If ScrollVertical(Gadget)
							MouseMove
							Redraw = #True
						EndIf
					CompilerEndIf
					Case #PB_Shortcut_Left ;{
						If *Data\Player_Position > #Style_Body_ColumnMargin
							*Data\Player_Position = max(*Data\Player_Position - (1 + Bool(GetGadgetAttribute(Gadget, #PB_Canvas_Modifiers) & #PB_Canvas_Control) * 9), #Style_Body_ColumnMargin)
							HorizontalFocus
							Redraw = #True
						EndIf
						;}
					Case #PB_Shortcut_Right;{
						If *Data\Player_Position < *Data\Content_Duration - #Style_Body_ColumnMargin
							*Data\Player_Position = Min(*Data\Player_Position + (1 + Bool(GetGadgetAttribute(Gadget, #PB_Canvas_Modifiers) & #PB_Canvas_Control) * 9), *Data\Content_Duration - #Style_Body_ColumnMargin)
							HorizontalFocus
							Redraw = #True
						EndIf
						;}
				EndSelect
				;}
		EndSelect
		
		If Redraw = #True
			Redraw(Gadget)
		EndIf
	EndProcedure
	
	Procedure HandlerHScrollbar()
		Protected Gadget = GetGadgetData(EventGadget())
		If ScrollHorizontal(Gadget)
			Redraw(Gadget)
		EndIf
	EndProcedure
	
	Procedure HandlerVScrollbar()
		Protected Gadget = GetGadgetData(EventGadget())
		If ScrollVertical(Gadget)
			Redraw(Gadget)
		EndIf
	EndProcedure
	
	Procedure HandlerPlayButton(Button)
		Protected Gadget = CanvasButton::GetData(Button), *Data.GadgetData = GetGadgetData(Gadget)
		
		If *Data\Player_Enabled
			*Data\Player_Enabled = #False
			CanvasButton::SetImage(Button, MaterialVector::#Play)
		Else
			*Data\Player_Enabled = #True
			CanvasButton::SetImage(Button, MaterialVector::#Pause)
		EndIf
		
		SetActiveGadget(Gadget)
	EndProcedure
	
	Procedure HandlerStartButton(Button)
		Protected Gadget = CanvasButton::GetData(Button), *Data.GadgetData = GetGadgetData(Gadget)
		
		*Data\Player_Position = #Style_Body_ColumnMargin
		SetGadgetState(*Data\Comp_HScrollbar, 0)
		If ScrollHorizontal(Gadget)
			Redraw(Gadget)
		EndIf
		
		SetActiveGadget(Gadget)
	EndProcedure
	
	Procedure HandlerEndButton(Button)
		Protected Gadget = CanvasButton::GetData(Button), *Data.GadgetData = GetGadgetData(Gadget)
		
		*Data\Player_Position = *Data\Content_Duration - #Style_Body_ColumnMargin
		SetGadgetState(*Data\Comp_HScrollbar, *Data\Content_Duration)
		If ScrollHorizontal(Gadget)
			Redraw(Gadget)
		EndIf
		
		If *Data\Player_Enabled
			*Data\Player_Enabled = #False
			CanvasButton::SetImage(*Data\Comp_PlayButton, MaterialVector::#Play)
		EndIf
		
		SetActiveGadget(Gadget)
	EndProcedure
	
	Procedure HandlerPlayer()
		Protected Player = EventGadget(), Gadget = GetGadgetData(Player),*Data.GadgetData = GetGadgetData(Gadget), MouseX, GadgetX
		
		Select EventType()
			Case #PB_EventType_MouseMove
				If *Data\Player_State = #Player_Drag
					MouseX = GetGadgetAttribute(Player, #PB_Canvas_MouseX) 
					GadgetX = GadgetX(Player)
					
					If (MouseX + GadgetX) < *Data\Meas_Body_HOffset
						If *Data\Meas_HScrollPosition > 0
							SetGadgetState(*Data\Comp_HScrollbar, *Data\Meas_HScrollPosition - 1)
							*Data\Player_Position = Max(*Data\Meas_HScrollPosition - 1, #Style_Body_ColumnMargin)
							If ScrollHorizontal(Gadget)
								Redraw(Gadget)
							EndIf
						EndIf
					ElseIf (MouseX + GadgetX) > GadgetWidth(Gadget) - *Data\Meas_VScrollBarWidth * *Data\Meas_VScrollBarVisible
						If *Data\Meas_HScrollPosition + *Data\Meas_VisibleColumns < *Data\Content_Duration
							SetGadgetState(*Data\Comp_HScrollbar, *Data\Meas_HScrollPosition + 1)
							*Data\Player_Position = Min(*Data\Meas_HScrollPosition + *Data\Meas_VisibleColumns + 1, *Data\Content_Duration - #Style_Body_ColumnMargin)
							If ScrollHorizontal(Gadget)
								Redraw(Gadget)
							EndIf
						EndIf
					Else
						*Data\Player_Position = Min(Max(Round((MouseX + GadgetX - *Data\Meas_Body_HOffset) / *Data\Meas_Body_ColumnWidth, #PB_Round_Down) + *Data\Meas_HScrollPosition, #Style_Body_ColumnMargin), *Data\Content_Duration - #Style_Body_ColumnMargin)
					EndIf
				EndIf
			Case #PB_EventType_LeftButtonDown
				*Data\Player_State = #Player_Drag
			Case #PB_EventType_LeftButtonUp
				*Data\Player_State = #Player_None
		EndSelect
	EndProcedure
	
	Procedure ScrollVertical(Gadget)
		Protected *Data.GadgetData = GetGadgetData(Gadget)
		Protected Position = GetGadgetState(*Data\Comp_VScrollBar)
		
		If Position <> *Data\Meas_VScrollPosition
			*Data\Meas_VScrollPosition = Position
			ProcedureReturn #True
		EndIf
		
		ProcedureReturn #False
	EndProcedure
	
	Procedure ScrollHorizontal(Gadget)
		Protected *Data.GadgetData = GetGadgetData(Gadget)
		Protected Position = GetGadgetState(*Data\Comp_HScrollBar)
		
		If Position <> *Data\Meas_HScrollPosition
			*Data\Meas_HScrollPosition = Position
			ProcedureReturn #True
		EndIf
		
		ProcedureReturn #False
	EndProcedure
	
	Procedure Redraw(Gadget)
		Protected *Data.GadgetData = GetGadgetData(Gadget), Loop, LoopCount, YPos, ListIndex
		
		If Not *Data\Draw_Freeze
			StartVectorDrawing(CanvasVectorOutput(Gadget))
			VectorFont(FontID(*Data\Draw_Font), *Data\Draw_FontSize)
			
			;{ Header
			AddPathBox(*Data\Meas_Body_HOffset,0 , *Data\Meas_Body_Width + *Data\Meas_VScrollBarWidth, *Data\Meas_Header_Height)
			VectorSourceColor(SetAlpha(255, *Data\Colors_HeaderBack))
			FillPath()
			;}
			
			;{ Content
			
			;{ Back color
			AddPathBox(*Data\Meas_List_HOffset, *Data\Meas_List_VOffset, *Data\Meas_List_Width, *Data\Meas_List_Height)
			VectorSourceColor(SetAlpha(255, *Data\Colors_ListBack))
			FillPath()
			
			AddPathBox(*Data\Meas_Body_HOffset, *Data\Meas_Body_VOffset, *Data\Meas_Body_Width, *Data\Meas_Body_Height)
			VectorSourceColor(SetAlpha(255, *Data\Colors_BodyBack))
			FillPath()
			;}
			
			LoopCount = Min((ListSize(*Data\Content_DisplayedLines()) - 1), *Data\Meas_VisibleLines)
			
			SelectElement(*Data\Content_DisplayedLines(), *Data\Meas_VScrollPosition)
			ListIndex = ListIndex(*Data\Content_DisplayedLines())
			
			For Loop = 0 To LoopCount
				
				YPos = *Data\Meas_Body_VOffset + Loop * #Style_List_LineHeight
				
				DrawLine(*Data, *Data\Meas_Body_VOffset + Loop * #Style_List_LineHeight, ListIndex, (*Data\Meas_VScrollPosition + Loop) % 2)
				
				If Not NextElement(*Data\Content_DisplayedLines())
					Break
				EndIf
				ListIndex + 1
			Next
			
			If (-#Style_Player_TopOffset < (*Data\Player_Position - *Data\Meas_HScrollPosition) * *Data\Meas_Body_ColumnWidth) And (*Data\Player_Position * *Data\Meas_Body_ColumnWidth - #Style_Player_TopOffset <= (*Data\Meas_HScrollPosition + *Data\Meas_VisibleColumns) * *Data\Meas_Body_ColumnWidth + *Data\Meas_VScrollBarWidth)
				MovePathCursor((*Data\Player_Position - *Data\Meas_HScrollPosition) * *Data\Meas_Body_ColumnWidth + *Data\Meas_Body_HOffset - #Style_Player_TopOffset - 0.5, 0)
				AddPathLine(0, #Style_Player_TopSquare, #PB_Path_Relative)
				AddPathLine(#Style_Player_TopOffset - 0.5, #Style_Player_TopHeight - #Style_Player_TopSquare, #PB_Path_Relative)
				AddPathLine(#Style_Player_Width, 0, #PB_Path_Relative)
				AddPathLine(#Style_Player_TopOffset - 0.5, - (#Style_Player_TopHeight - #Style_Player_TopSquare), #PB_Path_Relative)
				AddPathLine(0, - #Style_Player_TopSquare, #PB_Path_Relative)
				ClosePath()
				If *Data\Player_Position >= *Data\Meas_HScrollPosition
					MovePathCursor(#Style_Player_TopOffset - 0.5, #Style_Player_TopHeight, #PB_Path_Relative)
					AddPathBox(0,0, #Style_Player_Width, VectorOutputHeight(), #PB_Path_Relative)
				EndIf
				VectorSourceColor(SetAlpha($FF, FixColor(#Color_Player)))
				FillPath()
			EndIf
			
			AddPathBox(0, 0, *Data\Meas_Body_HOffset, *Data\Meas_Header_Height)
			VectorSourceColor(SetAlpha(255, *Data\Colors_HeaderBack))
			FillPath()
			
			MovePathCursor(*Data\Meas_Body_HOffset - 0.5, *Data\Meas_Body_VOffset)
			AddPathLine(0, *Data\Meas_Body_Height, #PB_Path_Relative)
			VectorSourceColor($FF000000)
			StrokePath(1)
			
			;}
			StopVectorDrawing()
		EndIf
	EndProcedure
	
	Procedure DrawDataPoint(*Data.GadgetData, x, y)
		If *Data\Meas_Body_ColumnWidth < 10
			If *Data\Meas_Body_ColumnWidth > 5
				AddPathCircle(x + (*Data\Meas_Body_ColumnWidth - 2 * #Style_DataPoint_SizeMedium) * 0.5, y, #Style_DataPoint_SizeMedium)
			EndIf
		Else
			MovePathCursor(x + (*Data\Meas_Body_ColumnWidth - 2 * #Style_DataPoint_SizeBig) * 0.5, y - #Style_DataPoint_SizeBig)
			AddPathLine(- #Style_DataPoint_SizeBig, #Style_DataPoint_SizeBig, #PB_Relative)
			AddPathLine(#Style_DataPoint_SizeBig, #Style_DataPoint_SizeBig, #PB_Relative)
			AddPathLine(#Style_DataPoint_SizeBig, - #Style_DataPoint_SizeBig, #PB_Relative)
			ClosePath()
		EndIf
	EndProcedure
	
	Procedure AddPathMediaBlock(x, y, Width, Height, Radius)
		MovePathCursor(x + Width, y)
		AddPathArc(x, y, x,y + Height, Radius)
		AddPathLine(x, y + Height)
		AddPathLine(x + Width, y + Height)
		ClosePath()
	EndProcedure
	
	Procedure DrawMediaBlock(*Data.GadgetData, YPos, Index, *Block.Mediablock)
		Protected LastBlock = Min(*Block\LastBlock, *Data\Meas_HScrollPosition + *Data\Meas_VisibleColumns)
		Protected Duration = LastBlock - *Block\FirstBlock + min(*Block\FirstBlock - *Data\Meas_HScrollPosition, 0) + 1
		Protected Loop, x
		
		If *Block\State = #State_Drag
			AddPathMediaBlock((Max((*Block\FirstBlock + *Data\Drag_OffsetX), #Style_Body_ColumnMargin) - *Data\Meas_HScrollPosition) * *Data\Meas_Body_ColumnWidth + *Data\Meas_Body_HOffset - 1,
			                  YPos + #Style_MediaBlock_Margin - 1,
			                  (*Block\LastBlock - *Block\FirstBlock + 1) * *Data\Meas_Body_ColumnWidth + 2,
			                  #Style_MediaBlock_Height + 2, #Style_Body_DefaultColumnWidth)
			VectorSourceColor( SetAlpha($FF, $F0F0F0))
			StrokePath(2)
		ElseIf*Block\State = #State_Resize
			Protected Resize_FirstBlock, Resize_LastBlock
			
			If *Data\Resize_Direction = #Resize_Start
				Resize_FirstBlock = Max(Min(*Block\FirstBlock + *Data\Resize_Offset, *Block\LastBlock - 1), #Style_Body_ColumnMargin)
				Resize_LastBlock = *Block\LastBlock
			Else
				Resize_FirstBlock = *Block\FirstBlock
				Resize_LastBlock = min(Max(*Block\LastBlock + *Data\Resize_Offset, *Block\FirstBlock +1), *Data\Content_Duration - #Style_Body_ColumnMargin * 2)
			EndIf
			
			AddPathMediaBlock((Max(Resize_FirstBlock, 0) - *Data\Meas_HScrollPosition) * *Data\Meas_Body_ColumnWidth + *Data\Meas_Body_HOffset - 1,
			                  YPos + #Style_MediaBlock_Margin - 1,
			                  (Resize_LastBlock - Resize_FirstBlock + 1) * *Data\Meas_Body_ColumnWidth + 2,
			                  #Style_MediaBlock_Height + 2, #Style_Body_DefaultColumnWidth)
			VectorSourceColor( SetAlpha($FF, $F0F0F0))
			StrokePath(2)
		EndIf
		
		If *Block\FirstBlock >= Index + *Data\Meas_HScrollPosition
			x = (*Block\FirstBlock - *Data\Meas_HScrollPosition) * *Data\Meas_Body_ColumnWidth + *Data\Meas_Body_HOffset
			If *Block\State = #State_Hot
				AddPathMediaBlock(x - 1,YPos + #Style_MediaBlock_Margin - 1, Duration * *Data\Meas_Body_ColumnWidth + 2, #Style_MediaBlock_Height + 2, #Style_Body_DefaultColumnWidth)
				VectorSourceColor( SetAlpha($FF, $F0F0F0))
				StrokePath(3)
			EndIf
			
			AddPathMediaBlock(x, YPos + #Style_MediaBlock_Margin, Duration * *Data\Meas_Body_ColumnWidth, #Style_MediaBlock_Height, #Style_Body_DefaultColumnWidth)
		Else
			Index = *Data\Meas_HScrollPosition
			x = *Data\Meas_Body_HOffset
			
			If *Block\State = #State_Hot
				AddPathBox(x - 2,YPos + #Style_MediaBlock_Margin - 1, Duration * *Data\Meas_Body_ColumnWidth + 3, #Style_MediaBlock_Height + 2)
				VectorSourceColor( SetAlpha($FF, $F0F0F0))
				StrokePath(3)
			EndIf
			
			AddPathBox(*Data\Meas_Body_HOffset - 1, YPos + #Style_MediaBlock_Margin, Duration * *Data\Meas_Body_ColumnWidth + 1, #Style_MediaBlock_Height)
		EndIf
		
		Select *Block\State
			Case #State_Cold, #State_Drag, #State_Resize
				VectorSourceColor( SetAlpha($20, *Data\Content_DisplayedLines()\Object\Color))
			Case #State_Warm
				VectorSourceColor( SetAlpha($40, *Data\Content_DisplayedLines()\Object\Color))
			Default
				VectorSourceColor( SetAlpha($60, *Data\Content_DisplayedLines()\Object\Color))
		EndSelect
		
		FillPath(#PB_Path_Preserve)
		
		If *Block\State = #State_Drag Or *Block\State = #State_Resize
			VectorSourceColor( SetAlpha($70, *Data\Content_DisplayedLines()\Object\Color))
		Else
			VectorSourceColor( SetAlpha($FF, *Data\Content_DisplayedLines()\Object\Color))
		EndIf
		StrokePath(2)
		
		If *Block\Icon > -1 And (*Block\LastBlock - *Block\FirstBlock + 1) * *Data\Meas_Body_ColumnWidth >= #Style_MediaBlock_IconMinimumWidth
			If Duration * *Data\Meas_Body_ColumnWidth < #Style_MediaBlock_IconMinimumWidth And *Block\FirstBlock < *Data\Meas_HScrollPosition
				x = *Data\Meas_Body_HOffset + Duration * *Data\Meas_Body_ColumnWidth - #Style_MediaBlock_IconMinimumWidth
			EndIf
			
			MaterialVector::Draw(*Block\Icon, x + #Style_MediaBlock_IconXOffset, YPos + #Style_MediaBlock_IconYOffset, #Style_MediaBlock_IconSize, SetAlpha($40, $F0F0F0), 0)
		EndIf
		
		For Loop = Index To LastBlock
			If *Data\Content_DisplayedLines()\Object\DataPoints(Loop)
				DrawDataPoint(*Data, *Data\Meas_Body_HOffset + (Loop - *Data\Meas_HScrollPosition) * *Data\Meas_Body_ColumnWidth, YPos + #Style_DataPoint_OffsetY)
			EndIf
		Next
		
		; I don't understand why this is necessary...
		VectorSourceColor($FFF0F0F0)
		FillPath(#PB_Path_Preserve)
		VectorSourceColor($FF000000)
		StrokePath(1.5)
		ProcedureReturn Duration - 1
	EndProcedure
	
	Procedure DrawLine(*Data.GadgetData, YPos, ListIndex, AltBackground)
		Protected ListFrontColor, ToggleColor, Loop, NewLastBlock = *Data\Meas_VisibleColumns
		
		; Body
		;{ Background
		If AltBackground
			AddPathBox(*Data\Meas_Body_HOffset, YPos, *Data\Meas_Body_Width, #Style_List_LineHeight)
			VectorSourceColor(SetAlpha(255,*Data\Colors_BodyAltBack))
			FillPath()
		EndIf
		;}
		
		For Loop = 0 To NewLastBlock
			If *Data\Content_DisplayedLines()\Object\Mediablocks(Loop + *Data\Meas_HScrollPosition)
				VectorSourceColor( $FFF0F0F0)
				FillPath(#PB_Path_Preserve)
				VectorSourceColor( $FF000000)
				StrokePath(1.5)
				Loop + DrawMediaBlock(*Data, YPos, Loop, *Data\Content_DisplayedLines()\Object\Mediablocks(Loop + *Data\Meas_HScrollPosition))
			ElseIf *Data\Content_DisplayedLines()\Object\DataPoints(Loop + *Data\Meas_HScrollPosition)
				DrawDataPoint(*Data, *Data\Meas_Body_HOffset + Loop * *Data\Meas_Body_ColumnWidth, YPos + #Style_DataPoint_OffsetY)
			EndIf
		Next
		
		VectorSourceColor($FFF0F0F0)
		FillPath(#PB_Path_Preserve)
		VectorSourceColor($FF000000)
		StrokePath(1.5)
		
		; List
		;{ Background
		AddPathBox(*Data\Meas_List_HOffset, YPos, *Data\Meas_List_Width, #Style_List_LineHeight)
		VectorSourceColor(SetAlpha($FF ,*Data\Colors_ListBack))
		FillPath()
		
		If ListIndex = *Data\State_HotLine
			AddPathBox(*Data\Meas_List_HOffset, YPos, *Data\Meas_List_Width, #Style_List_LineHeight)
			VectorSourceColor(SetAlpha(#Color_Blending_Back_Hot ,*Data\Colors_ListFront))
			FillPath()
			ListFrontColor = SetAlpha(#Color_Blending_Front_Hot ,*Data\Colors_ListFront)
		ElseIf ListIndex = *Data\State_WarmLine
			AddPathBox(*Data\Meas_List_HOffset, YPos, *Data\Meas_List_Width, #Style_List_LineHeight)
			VectorSourceColor(SetAlpha(#Color_Blending_Back_Warm ,*Data\Colors_ListFront))
			FillPath()
			ListFrontColor = SetAlpha(#Color_Blending_Front_Warm ,*Data\Colors_ListFront)
		Else
			CompilerIf #Func_LineSelection
				ListFrontColor = SetAlpha(#Color_Blending_Front_Cold ,*Data\Colors_ListFront)
			CompilerElse
				ListFrontColor = SetAlpha(#Color_Blending_Front_Warm ,*Data\Colors_ListFront)
			CompilerEndIf
		EndIf
		;}
		
		;{ Fold icon
		If *Data\Content_DisplayedLines()\Object\Fold
			If ListIndex = *Data\State_WarmToggleButton
				
				MaterialVector::AddPathRoundedBox(*Data\Content_DisplayedLines()\Object\HOffset - 5, YPos + #Style_List_FoldVOffset - 5, #Style_List_FoldSize + 10, #Style_List_FoldSize + 10, 4)
				
				If ListIndex = *Data\State_HotLine
					VectorSourceColor(SetAlpha(255, *Data\Colors_ListBack))
					ToggleColor = SetAlpha(#Color_Blending_Front_Warm ,*Data\Colors_ListFront)
				Else
					VectorSourceColor(SetAlpha(#Color_Blending_Back_Hot ,*Data\Colors_ListFront))
					ToggleColor = SetAlpha(#Color_Blending_Front_Hot ,*Data\Colors_ListFront)
				EndIf
				
				FillPath()
				VectorSourceColor(ListFrontColor)
			Else
				ToggleColor = ListFrontColor
			EndIf
			
			If *Data\Content_DisplayedLines()\Object\Fold = #Folded
				MaterialVector::Draw(MaterialVector::#Chevron, *Data\Meas_List_HOffset + *Data\Content_DisplayedLines()\Object\HOffset, YPos + #Style_List_FoldVOffset, #Style_List_FoldSize, ToggleColor, 0, MaterialVector::#style_rotate_90)
			Else
				MaterialVector::Draw(MaterialVector::#Chevron, *Data\Meas_List_HOffset + *Data\Content_DisplayedLines()\Object\HOffset, YPos + #Style_List_FoldVOffset, #Style_List_FoldSize, ToggleColor, 0, MaterialVector::#style_rotate_180)
			EndIf
			
			VectorSourceColor(ListFrontColor)
			
			MovePathCursor(*Data\Meas_List_HOffset + *Data\Content_DisplayedLines()\Object\HOffset + #Style_List_FoldSize + #Style_List_FoldMargin, YPos + #Style_List_TextVOffset)
		Else
			VectorSourceColor(ListFrontColor)
			MovePathCursor(*Data\Meas_List_HOffset + *Data\Content_DisplayedLines()\Object\HOffset, YPos + #Style_List_TextVOffset)
		EndIf
		;}
		
		DrawVectorText(*Data\Content_DisplayedLines()\Object\Text)
		
	EndProcedure
	
	Procedure Refit(Gadget)
		Protected *Data.GadgetData = GetGadgetData(Gadget)
		Protected Width = GadgetWidth(Gadget), Height = GadgetHeight(Gadget)
		*Data\Meas_Header_Width = Width
		
		*Data\Meas_List_Height = Height - *Data\Meas_Header_Height
		*Data\Meas_List_VOffset = *Data\Meas_Header_Height
		
		*Data\Meas_Body_HOffset = *Data\Meas_List_Width
		*Data\Meas_Body_VOffset = *Data\Meas_Header_Height
		*Data\Meas_Body_Height = Height - *Data\Meas_Header_Height
		*Data\Meas_Body_Width = Width - *Data\Meas_List_Width
		
		*Data\Meas_VisibleLines = *Data\Meas_List_Height / #Style_List_LineHeight
		
		If ListSize(*Data\Content_DisplayedLines()) > *Data\Meas_VisibleLines
			*Data\Meas_VScrollBarVisible = #True
			*Data\Meas_Body_Width - *Data\Meas_VScrollBarWidth
		Else
			SetGadgetAttribute(*Data\Comp_VScrollBar, #PB_ScrollBar_Maximum, 1)
			SetGadgetState(*Data\Comp_VScrollBar, 0)
			*Data\Meas_VScrollPosition = 0
			*Data\Meas_VScrollBarVisible = #False
		EndIf
		
		*Data\Meas_VisibleColumns = *Data\Meas_Body_Width / *Data\Meas_Body_ColumnWidth
		
		If *Data\Content_Duration > *Data\Meas_VisibleColumns
			*Data\Meas_HScrollBarVisible = #True
		Else
			*Data\Meas_VisibleColumns = *Data\Content_Duration
			SetGadgetState(*Data\Comp_HScrollBar, 0)
			*Data\Meas_HScrollPosition = 0
			*Data\Meas_HScrollBarVisible = #False
		EndIf
		
		If *Data\Meas_VScrollBarVisible
			SetGadgetAttribute(*Data\Comp_VScrollBar, #PB_ScrollBar_Maximum, ListSize(*Data\Content_DisplayedLines()) - 1)
			SetGadgetAttribute(*Data\Comp_VScrollBar, #PB_ScrollBar_PageLength, *Data\Meas_VisibleLines)
			ResizeGadget(*Data\Comp_VScrollBar, Width - *Data\Meas_VScrollBarWidth, *Data\Meas_Body_VOffset, *Data\Meas_VScrollBarWidth, *Data\Meas_Body_Height - *Data\Meas_HScrollBarVisible * *Data\Meas_HScrollbarHeight)
		EndIf
		
		If *Data\Meas_HScrollBarVisible
			SetGadgetAttribute(*Data\Comp_HScrollBar, #PB_ScrollBar_PageLength, *Data\Meas_VisibleColumns)
			ResizeGadget(*Data\Comp_HScrollBar, *Data\Meas_Body_HOffset, Height - *Data\Meas_HScrollbarHeight, *Data\Meas_Body_Width, *Data\Meas_HScrollbarHeight)
		EndIf
		
		HideGadget(*Data\Comp_VScrollBar, Bool( Not *Data\Meas_VScrollBarVisible))
		HideGadget(*Data\Comp_HScrollBar, Bool( Not *Data\Meas_HScrollBarVisible))
		
	EndProcedure
	
	Procedure RecurciveDelete(*Data.GadgetData, *Line.Line)
		If *Line\DisplayListAdress
			ChangeCurrentElement(*Data\Content_DisplayedLines(), *Line\DisplayListAdress)
			DeleteElement(*Data\Content_DisplayedLines())
		EndIf
		
		ForEach *Line\Content_Lines()
			RecurciveDelete(*Data.GadgetData, *Line\Content_Lines()\Object)
		Next
		
		If *Line\Parent
			ChangeCurrentElement(*Line\Parent\Content_Lines(), *Line\ParentListAdress)
			DeleteElement(*Line\Parent\Content_Lines())
		Else
			ChangeCurrentElement(*Data\Content_Lines(), *Line\ParentListAdress)
			DeleteElement(*Data\Content_Lines())
		EndIf
		
		FreeStructure(*Line)
		
	EndProcedure
	
	Procedure RecurciveFold(*Data.GadgetData, *Line.Line)
		Protected Result
		
		ForEach *Line\Content_Lines()
			NextElement(*Data\Content_DisplayedLines())
			
			If *Line\Content_Lines()\Object\Fold = #Unfolded
				Result + RecurciveFold(*Data.GadgetData, *Line\Content_Lines()\Object)
			EndIf
			
			DeleteElement(*Data\Content_DisplayedLines())
			*Line\Content_Lines()\Object\DisplayListAdress = 0
			Result + 1
		Next
		
		ProcedureReturn Result
	EndProcedure
	
	Procedure RecurciveUnFold(*Data.GadgetData, *Line.Line)
		Protected Result
		
		ForEach *Line\Content_Lines()
			AddElement(*Data\Content_DisplayedLines())
			*Data\Content_DisplayedLines()\Object = *Line\Content_Lines()\Object
			*Line\Content_Lines()\Object\DisplayListAdress= @*Data\Content_DisplayedLines()
			
			If *Line\Content_Lines()\Object\Fold = #Unfolded
				Result + RecurciveUnFold(*Data.GadgetData, *Line\Content_Lines()\Object)
			EndIf
			Result + 1
		Next
		
		ProcedureReturn Result
	EndProcedure
	
	Procedure ResizeMB(*Block.MediaBlock, Start, Finish)
		Protected Loop, NewFirstBlock, NewLastBlock, ResultOffset, Success, TargetOffset
		Protected Offset
		
		For loop = *Block\FirstBlock To *Block\LastBlock
			*Block\Line\MediaBlocks(Loop) = 0
		Next
		
		;Make place on the left
		If Start < *Block\FirstBlock
			Offset = Start - *Block\FirstBlock
			NewLastBlock = *Block\FirstBlock
			Repeat
				Success = #True
				NewFirstBlock = NewLastBlock + Offset
				MakeSpace(Last, First, 1)
			Until Success = #True
			Start = *Block\FirstBlock + Offset
		EndIf
		
		If Finish > *Block\LastBlock
			Offset = Finish - *Block\LastBlock
			NewFirstBlock = *Block\LastBlock
			Repeat
				Success = #True
				NewLastBlock = NewFirstBlock + Offset
				MakeSpace(First, Last, -1)
			Until Success = #True
			Finish = *Block\LastBlock + Offset
		EndIf
		
		*Block\FirstBlock = Start
		*Block\LastBlock = Finish
		
		For loop = *Block\FirstBlock To *Block\LastBlock
			*Block\Line\MediaBlocks(Loop) = *Block
		Next
	EndProcedure
	
	Procedure ToggleFold(Gadget, Item)
		Protected *Data.GadgetData = GetGadgetData(Gadget), *Line.Line, Index, Offset
		
		SelectElement(*Data\Content_DisplayedLines(), Item)
		Index = ListIndex(*Data\Content_DisplayedLines())
		
		*Line.Line = *Data\Content_DisplayedLines()\Object
		
		If *Data\Content_DisplayedLines()\Object\Fold = #Folded
			*Data\Content_DisplayedLines()\Object\Fold = #Unfolded
			Offset = RecurciveUnFold(*Data.GadgetData, *Data\Content_DisplayedLines()\Object)
			
			If *Data\State_HotLine > Index
				*Data\State_HotLine + Offset
			EndIf
			
		Else
			*Data\Content_DisplayedLines()\Object\Fold = #Folded
			Offset = RecurciveFold(*Data.GadgetData, *Data\Content_DisplayedLines()\Object)
			
			If *Data\State_HotLine > Index + Offset
				*Data\State_HotLine - Offset
			ElseIf *Data\State_HotLine > Index
				*Data\State_HotLine = -1
			EndIf
			
		EndIf
		
		Refit(Gadget)
		Redraw(Gadget)
	EndProcedure
EndModule













































; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 921
; FirstLine = 356
; Folding = v0AAwIDGGDgBHw
; EnableXP