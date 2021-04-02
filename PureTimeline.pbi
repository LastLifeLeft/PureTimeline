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
	
	Declare AddDataPoint(Gadget, LineID, Position)
	
	Declare AddMediaBlock(Gadget, LineID, Start, Finish, Icon = -1)
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
	
	Enumeration ; Resize Mediablock
		#Resize_Start
		#Resize_End
	EndEnumeration
	
	Enumeration ; Folds
		#NoFold
		
		#Folded
		#Unfolded
	EndEnumeration
	
	Enumeration ; UserAction
		#Action_Hover
		#Action_Resizing
		#Action_ResizingInit
		#Action_MBDrag
		#Action_MBDragInit
		#Action_DPDrag
		#Action_DPDragInit
	EndEnumeration
	
	; Functionality
	#Func_LineSelection = #False
	#Func_DefaultDuration = 360
	#Func_DragScrollStep = 2
	
	; Style
	#Style_Header_Height = 60
	#Style_Header_ButtonSize = 30
	#Style_Header_ButtonSpace = 20
	
	#Style_Player_Width = 2
	#Style_Player_TopHeight = 24
	#Style_Player_TopWidth = 18
	#Style_Player_TopOffset = (#Style_Player_TopWidth - #Style_Player_Width) / 2
	#Style_Player_TopSquare = #Style_Player_TopHeight - #Style_Player_TopOffset - 1
	
	#Style_Line_Height = 58
	
	#Style_List_Width = 240
	#Style_List_FontSize = 24
	#Style_List_TextVOffset = (#Style_Line_Height - #Style_List_FontSize) / 2
	#Style_List_TextHOffset = 38
	#Style_List_LineMargin = 24
	#Style_List_FoldSize = 14
	#Style_List_FoldMargin = 10
	#Style_List_FoldOffset = (#Style_Line_Height - #Style_List_FoldSize) / 2 + 2 ; +2 to get the right alignment with the text...
	#Style_List_FoldIconOffset =#Style_List_FoldSize + #Style_List_FoldMargin
	
	#Style_Body_DefaultColumnWidth = 12
	#Style_Body_MaximumColumnWidth = 17
	#Style_Body_MinimumColumnWidth = 1
	#Style_Column_MinimumDisplaySize = 5
	#Style_Body_ColumnMargin = 2
	
	#Style_DataPoint_SizeBig = 5
	#Style_DataPoint_SizeMedium = 3
	#Style_DataPoint_OffsetY = #Style_Line_Height / 2
	
	#Style_MediaBlock_Margin = 3
	#Style_MediaBlock_Height = #Style_Line_Height - 2 * #Style_MediaBlock_Margin
	#Style_MediaBlock_IconYOffset = 15
	#Style_MediaBlock_IconXOffset = 10
	#Style_MediaBlock_IconSize = #Style_Line_Height - 2 * #Style_MediaBlock_IconYOffset
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
	
	#Color_Content_00 = $0094FF
	#Color_Content_01 = $FF3232
	#Color_Content_02 = $FF6A00
	#Color_Content_03 = $FFDB37
	#Color_Content_04 = $00D721
	#Color_Content_05 = $C03AFF
	#Color_Content_Count = 6
	
	#Color_Player = $FF6654
	
	Structure MediaBlock
		BlockType.b
		FirstBlock.i
		LastBlock.i
		Icon.i
		State.b
; 		Test.s		; Could be added?
		*Line.Line
		*StateListElement
	EndStructure
	
	Structure DataPoint
		Position.i
		State.b
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
		State.b
		
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
		Comp_ButtonContainer.i
		Comp_LitSplitter.i
		Comp_CornerCover.i
		
		; Colors
		Colors_Header_Back.l
		Colors_Header_Front.l
		Colors_List_Back.l
		Colors_List_Front.l
		Array Colors_List_FillBlending.l(3)
		Colors_Body_Back.l
		Colors_Body_AltBack.l
		Colors_Index.b
		Array Colors_Body_StrokeBlending.l(5)
		Array Colors_Body_FillBlending.l(5)
		
		; Measurements
		Meas_Body_Width.i
		
		Meas_Content_Height.i
		
		Meas_List_Width.i
		
		Meas_Header_Height.i
		
		Meas_Line_Visible.i
		Meas_Line_Total.i
		
		Meas_VScrollBar_Width.i
		Meas_VScrollBar_Visible.b
		
		Meas_HScrollbar_Height.i
		Meas_HScrollBar_Visible.b
		
		Meas_Column_Width.i
		Meas_Column_Visible.i
		
		Meas_Gadget_Width.i
		Meas_Gadget_Height.i
		
		; State
		State_SelectedLine.i
		List *State_SelectedMediaBlocks.Mediablock()
		List *State_SelectedDataPoints.DataPoint()
		State_UserAction.i
		State_VerticalScroll.i
		State_HorizontalScroll.i
		
		; Player
		Player_Enabled.b
		Player_Position.i
		Player_OriginX.i
		Player_Step.b
		
		; Drawing informations
		Draw_WarmToggle.i
		Draw_WarmLine.i
		*Draw_WarmDataPoint.DataPoint
		*Draw_WarmMediaBlock.Mediablock
		
		Draw_Font.i
		Draw_FontSize.i
		
		Draw_Freeze.i
	EndStructure
	
	Global DefaultFont = LoadFont(#PB_Any, "Bebas Neue", #Style_List_FontSize, #PB_Font_HighQuality)
	
	Global Dim DefaultColors(#Color_Content_Count - 1)
	DefaultColors(0) = FixColor(#Color_Content_00)
	DefaultColors(1) = FixColor(#Color_Content_01)
	DefaultColors(2) = FixColor(#Color_Content_02)
	DefaultColors(3) = FixColor(#Color_Content_03)
	DefaultColors(4) = FixColor(#Color_Content_04)
	DefaultColors(5) = FixColor(#Color_Content_05)
	;}
	
	;{ Private procedures declaration
	; Non specific
	Declare Min(a, b)
	Declare Max(a, b)
	
	; Handlers
	Declare HandlerCanvas()
	Declare HandlerHScrollbar()
	Declare HandlerVScrollbar()
	Declare HandlerPlayButton(Button)
	Declare HandlerStartButton(Button)
	Declare HandlerEndButton(Button)
	
	; Drawing
	Declare Redraw(Gadget)
	Declare DrawLine(*Data.GadgetData)
	Declare DrawMediaBlock(*Data.GadgetData, YPos, *Block.Mediablock)
	Declare DrawDataPoint(*Data.GadgetData, x, y)
	Declare AddPathMediaBlock(x, y, Width, Height, Radius)
	
	; Misc
	Declare ScrollVertical(Gadget)
	Declare ScrollHorizontal(Gadget)
	Declare Refit(Gadget)
	Declare RecurciveDelete(*Data.GadgetData, *Line.Line)
	Declare ResizeMB(*Block.MediaBlock, Start, Finish)
	Declare MoveMB(*Block.MediaBlock, Offset)
	Declare RecurciveFold(*Data.GadgetData, *Line.Line)
	Declare RecurciveUnFold(*Data.GadgetData, *Line.Line)
	Declare ToggleFold(Gadget, Item)
	;}
	
	;{ Public procedures
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
				\Colors_Header_Back = FixColor(#Color_HeaderBack)
				
				\Colors_List_Back = FixColor(#Color_ListBack)
				\Colors_List_Front = FixColor(#Color_ListFront)
				\Colors_List_FillBlending(#State_Cold) = #Color_Blending_Back_Cold
				\Colors_List_FillBlending(#State_Warm) = #Color_Blending_Back_Warm
				\Colors_List_FillBlending(#State_Hot) = #Color_Blending_Back_Hot
				
				\Colors_Body_Back = FixColor(#Color_BodyBack)
				\Colors_Body_AltBack = FixColor(#Color_BodyAltBack)
				\Colors_Body_StrokeBlending(#State_Cold) = $FF
				\Colors_Body_StrokeBlending(#State_Warm) = $FF
				\Colors_Body_StrokeBlending(#State_Hot) = $FF
				\Colors_Body_StrokeBlending(#State_Drag) = $70
				\Colors_Body_StrokeBlending(#State_Resize) = $70
				\Colors_Body_FillBlending(#State_Cold) = $20
				\Colors_Body_FillBlending(#State_Warm) = $40
				\Colors_Body_FillBlending(#State_Hot) = $60
				\Colors_Body_FillBlending(#State_Drag) = $20
				\Colors_Body_FillBlending(#State_Resize) = $20
				
				; Measurements
				\Meas_List_Width = #Style_List_Width
				\Meas_Header_Height = #Style_Header_Height
				\Meas_Column_Width = #Style_Body_DefaultColumnWidth
				\Meas_Line_Total = -1
				
				; Drawing informations
				\Draw_Font = DefaultFont
				\Draw_FontSize = #Style_List_FontSize
				
				; State
				\State_SelectedLine = -1
				
				; Draw
				\Draw_WarmLine = -1
				\Draw_WarmToggle = -1
				
				\Content_Duration = #Func_DefaultDuration + #Style_Body_ColumnMargin * 2
				
				; Components
				\Comp_VScrollBar = ScrollBarGadget(#PB_Any, 0, \Meas_Header_Height, 10, 10, 0, 10, 10, #PB_ScrollBar_Vertical)
				\Meas_VScrollBar_Width = GadgetWidth(\Comp_VScrollBar, #PB_Gadget_RequiredSize)
				ResizeGadget(\Comp_VScrollBar, #PB_Ignore, #PB_Ignore, \Meas_VScrollBar_Width, #PB_Ignore)
				HideGadget(\Comp_VScrollBar, #True)
				BindGadgetEvent(\Comp_VScrollBar, @HandlerVScrollbar())
				SetGadgetData(\Comp_VScrollBar, Gadget)
				
				\Comp_HScrollbar = ScrollBarGadget(#PB_Any, 0, 0, 10, 10, 0, *Data\Content_Duration - 1, 10)
				\Meas_HScrollbar_Height = GadgetHeight(\Comp_HScrollbar, #PB_Gadget_RequiredSize)
				HideGadget(\Comp_HScrollbar, #True)
				BindGadgetEvent(\Comp_HScrollBar, @HandlerHScrollbar())
				SetGadgetData(\Comp_HScrollBar, Gadget)
				
				\Comp_ButtonContainer = ContainerGadget(#PB_Any, 0, 0, #Style_List_Width, #Style_Header_Height, #PB_Container_BorderLess)
				SetGadgetColor(\Comp_ButtonContainer, #PB_Gadget_BackColor, \Colors_Header_Back)
				
				\Comp_StartButton = CanvasButton::GadgetImage(#PB_Any,
				                                              (#Style_List_Width - 3 * #Style_Header_ButtonSize - 2 * #Style_Header_ButtonSpace) * 0.5,
				                                              (#Style_Header_Height - #Style_Header_ButtonSize) * 0.5, #Style_Header_ButtonSize, 
				                                              #Style_Header_ButtonSize, MaterialVector::#Skip,
				                                              CanvasButton::#MaterialVectorIcon | CanvasButton::#DarkTheme | MaterialVector::#style_rotate_180)
				CanvasButton::SetColor(\Comp_StartButton, CanvasButton::#ColorType_BackWarm, SetAlpha($FF, \Colors_Body_Back))
				CanvasButton::SetColor(\Comp_StartButton, CanvasButton::#ColorType_BackHot, SetAlpha($FF, \Colors_Body_Back))
				CanvasButton::SetData(\Comp_StartButton, Gadget)
				CanvasButton::BindEventHandler(\Comp_StartButton, @HandlerStartButton())
				
				\Comp_PlayButton = CanvasButton::GadgetImage(#PB_Any,
				                                              (#Style_List_Width - 3 * #Style_Header_ButtonSize - 2 * #Style_Header_ButtonSpace) * 0.5 + #Style_Header_ButtonSize + #Style_Header_ButtonSpace,
				                                              (#Style_Header_Height - #Style_Header_ButtonSize) * 0.5, #Style_Header_ButtonSize, 
				                                              #Style_Header_ButtonSize, MaterialVector::#Play,
				                                              CanvasButton::#MaterialVectorIcon | CanvasButton::#DarkTheme)
				CanvasButton::SetColor(\Comp_PlayButton, CanvasButton::#ColorType_BackWarm, SetAlpha($FF, \Colors_Body_Back))
				CanvasButton::SetColor(\Comp_PlayButton, CanvasButton::#ColorType_BackHot, SetAlpha($FF, \Colors_Body_Back))
				CanvasButton::SetData(\Comp_PlayButton, Gadget)
				CanvasButton::BindEventHandler(\Comp_PlayButton, @HandlerPlayButton())
				
				\Comp_EndButton = CanvasButton::GadgetImage(#PB_Any,
				                                              (#Style_List_Width - 3 * #Style_Header_ButtonSize - 2 * #Style_Header_ButtonSpace) * 0.5 + #Style_Header_ButtonSize * 2 + #Style_Header_ButtonSpace * 2,
				                                              (#Style_Header_Height - #Style_Header_ButtonSize) * 0.5, #Style_Header_ButtonSize, 
				                                              #Style_Header_ButtonSize, MaterialVector::#Skip,
				                                              CanvasButton::#MaterialVectorIcon | CanvasButton::#DarkTheme)
				CanvasButton::SetColor(\Comp_EndButton, CanvasButton::#ColorType_BackWarm, SetAlpha($FF, \Colors_Body_Back))
				CanvasButton::SetColor(\Comp_EndButton, CanvasButton::#ColorType_BackHot, SetAlpha($FF, \Colors_Body_Back))
				CanvasButton::SetData(\Comp_EndButton, Gadget)
				CanvasButton::BindEventHandler(\Comp_EndButton, @HandlerEndButton())
				CloseGadgetList()
				
				\Comp_LitSplitter = ContainerGadget(#PB_Any, *Data\Meas_List_Width - 1, \Meas_Header_Height, 1, Height - *Data\Meas_Header_Height, #PB_Container_BorderLess)
				SetGadgetColor(\Comp_LitSplitter, #PB_Gadget_BackColor, $000000)
				CloseGadgetList()
				
				\Comp_CornerCover = ContainerGadget(#PB_Any, *Data\Meas_List_Width - 1, \Meas_Header_Height, \Meas_VScrollBar_Width, \Meas_HScrollbar_Height, #PB_Container_BorderLess)
				SetGadgetColor(\Comp_CornerCover, #PB_Gadget_BackColor, \Colors_Body_Back)
				HideGadget(\Comp_CornerCover, #True)
				
				; Player
				\Player_Position = #Style_Body_ColumnMargin
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
		Protected *Data.GadgetData = GetGadgetData(Gadget)
		ResizeGadget(Gadget, X, Y, Width, Height)
		ResizeGadget(*Data\Comp_LitSplitter, #PB_Ignore, #PB_Ignore, #PB_Ignore, Height - *Data\Meas_Header_Height)
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
			*NewLine\Color = DefaultColors(*Data\Colors_Index)
			*Data\Colors_Index = (*Data\Colors_Index + 1) % #Color_Content_Count
		EndIf
		
		ReDim *NewLine\DataPoints(*Data\Content_Duration)
		ReDim *NewLine\Mediablocks(*Data\Content_Duration)
		*NewLine\Text = Text
		
		*Data\Meas_Line_Total = ListSize(*Data\Content_DisplayedLines()) -1
		
		Refit(Gadget)
		Redraw(Gadget)
		
		ProcedureReturn *NewLine
	EndProcedure
	
	Procedure DeleteLine(Gadget, *Line.Line)
		Protected *Data.GadgetData = GetGadgetData(Gadget)
		
		RecurciveDelete(*Data.GadgetData, *Line.Line)
		
		*Data\Meas_Line_Total = ListSize(*Data\Content_DisplayedLines()) -1
		
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
	
	Procedure AddDataPoint(Gadget, *Line.Line, Position)
		Protected *Data.GadgetData = GetGadgetData(Gadget), *Point.DataPoint = AllocateMemory(SizeOf(DataPoint))
		
		Position + #Style_Body_ColumnMargin
		
		*Point\Position = Position
		*Point\State = #False
		*Point\Line = *Line
		
		*Line\DataPoints(Position) = *Point
		
		Redraw(Gadget)
	EndProcedure
	
	Procedure AddMediaBlock(Gadget, *Line.Line, Start, Finish, Icon = -1)
		Protected *Data.GadgetData = GetGadgetData(Gadget), *Block.Mediablock = AllocateMemory(SizeOf(Mediablock)), Loop
		
		Start + #Style_Body_ColumnMargin
		Finish + #Style_Body_ColumnMargin
		
		*Block\FirstBlock = Start
		*Block\LastBlock = Finish
		*Block\Line = *Line
		
		*Block\Icon = Icon
		
		For loop = Start To Finish
			*Line\Mediablocks(Loop) = *Block
		Next
		
		Redraw(Gadget)
	EndProcedure
	
	Procedure ResizeMediaBlock(Gadget, MediablockID, Start, Finish)
		
	EndProcedure
	;}
	
	;{ Private procedures
	; Non specific
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
	
	; Handlers
	Macro StartLocalRedrawing
		If Not Redraw
			Redraw = #True
			StartVectorDrawing(CanvasVectorOutput(Gadget))
			VectorFont(FontID(*Data\Draw_Font), *Data\Draw_FontSize)
		EndIf
	EndMacro
	
	Procedure HandlerCanvas()
		Protected Gadget= EventGadget(), *Data.GadgetData = GetGadgetData(Gadget)
		Protected MouseX = GetGadgetAttribute(Gadget, #PB_Canvas_MouseX), MouseY = GetGadgetAttribute(Gadget, #PB_Canvas_MouseY)
		Protected Line, Column
		Protected WarmLine = -1, WarmToggle = -1, *WarmMediaBlock.MediaBlock, *WarmDataPoint.DataPoint, Redraw
		
		Select EventType()
			Case #PB_EventType_MouseMove ;{
				Select *Data\State_UserAction
					Case #Action_Hover ;{
						If MouseY < *Data\Meas_Header_Height ;{ Hovering over the header
							;}
						ElseIf MouseX < *Data\Meas_List_Width ;{ Hovering over the list
							MouseY - *Data\Meas_Header_Height
							Line = MouseY / #Style_Line_Height + *Data\State_VerticalScroll
							If Line <= *Data\Meas_Line_Total
								MouseY % #Style_Line_Height
								;Check if the mouse is hovering above the fold
								SelectElement(*Data\Content_DisplayedLines(), Line)
								If (*Data\Content_DisplayedLines()\Object\Fold And
								    MouseX > *Data\Content_DisplayedLines()\Object\HOffset -4 And
								    MouseX < *Data\Content_DisplayedLines()\Object\HOffset + #Style_List_FoldSize + 4 And
								    MouseY > #Style_List_FoldOffset -4 And
								    MouseY < #Style_List_FoldOffset + #Style_List_FoldSize + 4 )
									WarmToggle = Line
								CompilerIf #Func_LineSelection
								Else
									If Line <> *Data\State_SelectedLine
										WarmLine = Line
									EndIf
								CompilerEndIf
								EndIf
							EndIf
							;}
						Else ;{ Hovering over the content
							
						EndIf ;}
						
						If *Data\Draw_WarmLine <> WarmLine
							StartLocalRedrawing
							If *Data\Draw_WarmLine > - 1
								SelectElement(*Data\Content_DisplayedLines(), *Data\Draw_WarmLine)
								*Data\Content_DisplayedLines()\Object\State = #State_Cold
								*Data\Draw_WarmLine = -1
								DrawLine(*Data)
							EndIf
							
							If WarmLine > -1
								*Data\Draw_WarmLine = WarmLine
								SelectElement(*Data\Content_DisplayedLines(), *Data\Draw_WarmLine)
								*Data\Content_DisplayedLines()\Object\State = #State_Warm
								DrawLine(*Data)
							EndIf
						EndIf
						
						If *Data\Draw_WarmToggle <> WarmToggle
							StartLocalRedrawing
							If *Data\Draw_WarmToggle > - 1
								SelectElement(*Data\Content_DisplayedLines(), *Data\Draw_WarmToggle)
								*Data\Draw_WarmToggle = -1
								DrawLine(*Data)
							EndIf
							
							If WarmToggle > -1
								*Data\Draw_WarmToggle = WarmToggle
								SelectElement(*Data\Content_DisplayedLines(), *Data\Draw_WarmToggle)
								DrawLine(*Data)
							EndIf
						EndIf
						
						If *Data\Draw_WarmDataPoint <> *WarmDataPoint
							StartLocalRedrawing
						EndIf
						
						If *Data\Draw_WarmMediaBlock <> *WarmMediaBlock
							StartLocalRedrawing
						EndIf
						
						If Redraw
							; REDRAW THE PLAYER LINE ONCE IMPLEMENTED!
							StopVectorDrawing()
						EndIf
						;}
					Case #Action_Resizing ;{
						;}
					Case #Action_ResizingInit ;{
						;}
					Case #Action_MBDrag ;{
						;}
					Case #Action_MBDragInit ;{
						;}
					Case #Action_DPDrag ;{
						;}
					Case #Action_DPDragInit ;{
						;}
				EndSelect

				;}
			Case #PB_EventType_MouseLeave ;{
				If *Data\State_UserAction = #Action_Hover
					If *Data\Draw_WarmLine <> WarmLine
						StartLocalRedrawing
						If *Data\Draw_WarmLine > - 1
							SelectElement(*Data\Content_DisplayedLines(), *Data\Draw_WarmLine)
							*Data\Content_DisplayedLines()\Object\State = #State_Cold
							*Data\Draw_WarmLine = -1
							DrawLine(*Data)
						EndIf
						
						If WarmLine > 1
							*Data\Draw_WarmLine = WarmLine
							SelectElement(*Data\Content_DisplayedLines(), *Data\Draw_WarmLine)
							*Data\Content_DisplayedLines()\Object\State = #State_Warm
							DrawLine(*Data)
						EndIf
					EndIf
					
					If *Data\Draw_WarmToggle <> WarmToggle
						StartLocalRedrawing
						
					EndIf
					
					If *Data\Draw_WarmDataPoint <> *WarmDataPoint
						StartLocalRedrawing
					EndIf
					
					If *Data\Draw_WarmMediaBlock <> *WarmMediaBlock
						StartLocalRedrawing
					EndIf
					
					If Redraw
						; REDRAW THE PLAYER LINE ONCE IMPLEMENTED!
						StopVectorDrawing()
					EndIf
				EndIf
				;}
			Case #PB_EventType_LeftButtonDown ;{
				Select *Data\State_UserAction
					Case #Action_Hover ;{
						If *Data\Draw_WarmLine > -1
							StartLocalRedrawing
							If *Data\State_SelectedLine > -1
								SelectElement(*Data\Content_DisplayedLines(), *Data\State_SelectedLine)
								*Data\Content_DisplayedLines()\Object\State = #State_Cold
								DrawLine(*Data)
							EndIf
							
							*Data\State_SelectedLine = *Data\Draw_WarmLine
							*Data\Draw_WarmLine = - 1
							
							SelectElement(*Data\Content_DisplayedLines(), *Data\State_SelectedLine)
							*Data\Content_DisplayedLines()\Object\State = #State_Hot
							DrawLine(*Data)
							StopVectorDrawing()
						ElseIf *Data\Draw_WarmToggle > -1
							ToggleFold(Gadget, *Data\Draw_WarmToggle)
						EndIf
						;}
					Case #Action_ResizingInit ;{
						
						;}
					Case #Action_DPDragInit ;{
						
						;}
					EndSelect
				;}
				Case #PB_EventType_LeftButtonUp ;{
					Select *Data\State_UserAction
						Case #Action_Hover ;{
							
							;}
						Case #Action_Resizing ;{
							
							;}
						Case #Action_ResizingInit ;{
							
							;}
						Case #Action_MBDrag ;{
							
							;}
						Case #Action_MBDragInit ;{
							
							;}
						Case #Action_DPDrag ;{
							
							;}
						Case #Action_DPDragInit ;{
							
							;}
					EndSelect
 					;}
		EndSelect
		
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
		
	EndProcedure
	
	Procedure HandlerStartButton(Button)
		
	EndProcedure
	
	Procedure HandlerEndButton(Button)
		
	EndProcedure
	
	; Drawing

	Procedure Redraw(Gadget)
		Protected *Data.GadgetData = GetGadgetData(Gadget)
		Protected LineLoop, LineLoopEnd, YPos, Height
		Protected ContentLoop, ContentLoopEnd
		
		If Not *Data\Draw_Freeze
			StartVectorDrawing(CanvasVectorOutput(Gadget))
			VectorFont(FontID(*Data\Draw_Font), *Data\Draw_FontSize)
			
			; Header
			AddPathBox(*Data\Meas_List_Width,0 , *Data\Meas_Body_Width + *Data\Meas_VScrollBar_Width, *Data\Meas_Header_Height)
			VectorSourceColor(SetAlpha($FF, *Data\Colors_Header_Back))
			FillPath()
			
			; Content
			LineLoopEnd = min(*Data\Meas_Line_Visible, *Data\Meas_Line_Total - *Data\State_VerticalScroll)
			SelectElement(*Data\Content_DisplayedLines(), *Data\State_VerticalScroll)
			
			For LineLoop = 0 To LineLoopEnd
				DrawLine(*Data)
				NextElement(*Data\Content_DisplayedLines())
			Next
			
			; Fill the empty bottom of the gadget if needed
			If LineLoop < *Data\Meas_Line_Visible + 1
				YPos = *Data\Meas_Header_Height + LineLoop * #Style_Line_Height
				Height = *Data\Meas_Gadget_Height - YPos
				AddPathBox(0, YPos , *Data\Meas_List_Width, Height)
				VectorSourceColor(SetAlpha($FF, *Data\Colors_List_Back))
				FillPath()
				
				AddPathBox(*Data\Meas_List_Width, YPos , *Data\Meas_Body_Width, Height)
				VectorSourceColor(SetAlpha($FF, *Data\Colors_Body_Back))
				FillPath()
			EndIf
			
			StopVectorDrawing()
		EndIf
	EndProcedure
	
	Procedure DrawLine(*Data.GadgetData)
		Protected Index = ListIndex(*Data\Content_DisplayedLines()) - *Data\State_VerticalScroll, ContentLoop, ContentLoopEnd, YPos = *Data\Meas_Header_Height + Index * #Style_Line_Height
		
		; Body
		If (Index + *Data\State_VerticalScroll) % 2 Or *Data\Content_DisplayedLines()\Object\State
			VectorSourceColor(SetAlpha($FF,*Data\Colors_Body_AltBack))
		Else
			VectorSourceColor(SetAlpha($FF,*Data\Colors_Body_Back))
		EndIf
		AddPathBox(*Data\Meas_List_Width, YPos, *Data\Meas_Body_Width, #Style_Line_Height)
		If *Data\Content_DisplayedLines()\Object\State
			FillPath(#PB_Path_Preserve)
			VectorSourceColor(SetAlpha(*Data\Colors_List_FillBlending(*Data\Content_DisplayedLines()\Object\State),*Data\Colors_List_Front))
			FillPath()
		EndIf
		FillPath()
		
		ContentLoopEnd = *Data\State_HorizontalScroll + *Data\Meas_Column_Visible
		
		For ContentLoop = *Data\State_HorizontalScroll To ContentLoopEnd
			If *Data\Content_DisplayedLines()\Object\Mediablocks(ContentLoop)
				DrawMediaBlock(*Data, YPos, *Data\Content_DisplayedLines()\Object\Mediablocks(ContentLoop))
				ContentLoop = *Data\Content_DisplayedLines()\Object\Mediablocks(ContentLoop)\LastBlock
			ElseIf *Data\Meas_Column_Width > #Style_Column_MinimumDisplaySize
				If *Data\Content_DisplayedLines()\Object\DataPoints(ContentLoop)
					DrawDataPoint(*Data, 0, YPos)
				EndIf
			EndIf
		Next
		
		; List
		AddPathBox(0, YPos , *Data\Meas_List_Width, #Style_Line_Height)
		VectorSourceColor(SetAlpha($FF, *Data\Colors_List_Back))
		If *Data\Content_DisplayedLines()\Object\State
			FillPath(#PB_Path_Preserve)
			VectorSourceColor(SetAlpha(*Data\Colors_List_FillBlending(*Data\Content_DisplayedLines()\Object\State),*Data\Colors_List_Front))
		EndIf
		FillPath()
		
		If *Data\Content_DisplayedLines()\Object\Fold
			If Index = *Data\Draw_WarmToggle
				If *Data\Content_DisplayedLines()\Object\State = #State_Cold
					VectorSourceColor(SetAlpha(*Data\Colors_List_FillBlending(#State_Hot),*Data\Colors_List_Front))
				Else
					VectorSourceColor(SetAlpha($FF,*Data\Colors_List_Back))
				EndIf
				MaterialVector::AddPathRoundedBox(*Data\Content_DisplayedLines()\Object\HOffset - 5, YPos + #Style_List_FoldOffset - 5, #Style_List_FoldSize + 10, #Style_List_FoldSize + 10, 4)
				FillPath()
				MaterialVector::Draw(MaterialVector::#Chevron, *Data\Content_DisplayedLines()\Object\HOffset,
				                     YPos + #Style_List_FoldOffset,
				                     #Style_List_FoldSize,
				                     SetAlpha(#Color_Blending_Front_Hot ,*Data\Colors_List_Front), 0,
				                     MaterialVector::#style_rotate_90 * *Data\Content_DisplayedLines()\Object\Fold)
			Else
				MaterialVector::Draw(MaterialVector::#Chevron, *Data\Content_DisplayedLines()\Object\HOffset,
				                     YPos + #Style_List_FoldOffset,
				                     #Style_List_FoldSize,
				                     SetAlpha(#Color_Blending_Front_Warm ,*Data\Colors_List_Front), 0,
				                     MaterialVector::#style_rotate_90 * *Data\Content_DisplayedLines()\Object\Fold)
			EndIf
			MovePathCursor(*Data\Content_DisplayedLines()\Object\HOffset + #Style_List_FoldIconOffset, YPos + #Style_List_TextVOffset)
		Else
			MovePathCursor(*Data\Content_DisplayedLines()\Object\HOffset, YPos + #Style_List_TextVOffset)
		EndIf
		VectorSourceColor(SetAlpha(#Color_Blending_Front_Warm ,*Data\Colors_List_Front))
		DrawVectorText(*Data\Content_DisplayedLines()\Object\Text)
	EndProcedure
	
	Procedure DrawMediaBlock(*Data.GadgetData, YPos, *Block.Mediablock)
		Protected Start, Finish, FirstBlock, LastBlock, loop, Mediablock = #True
		
		Start = (*Block\FirstBlock - *Data\State_HorizontalScroll) * *Data\Meas_Column_Width
		Finish = (*Block\LastBlock - *Block\FirstBlock) * *Data\Meas_Column_Width
		
		If Finish + Start > (*Data\State_HorizontalScroll + *Data\Meas_Column_Visible) * *Data\Meas_Column_Width
			LastBlock = *Data\State_HorizontalScroll + *Data\Meas_Column_Visible
			Finish = (LastBlock - *Block\FirstBlock) * *Data\Meas_Column_Width
		Else
			LastBlock = *Block\LastBlock
		EndIf
		
		If Start < -#Style_Body_DefaultColumnWidth
			FirstBlock = *Data\State_HorizontalScroll
			Start = *Data\Meas_List_Width - 1
			Finish = (LastBlock - FirstBlock) * *Data\Meas_Column_Width + 1
			Mediablock = #False
		Else
			Start + *Data\Meas_List_Width
			FirstBlock = *Block\FirstBlock
		EndIf
		
		If Mediablock
			AddPathMediaBlock(Start, YPos + #Style_MediaBlock_Margin, Finish, #Style_MediaBlock_Height, #Style_Body_DefaultColumnWidth)
		Else
			AddPathBox(Start, YPos + #Style_MediaBlock_Margin, Finish, #Style_MediaBlock_Height)
		EndIf
		
		VectorSourceColor( SetAlpha(*Data\Colors_Body_FillBlending(*Block\State), *Data\Content_DisplayedLines()\Object\Color))
		FillPath(#PB_Path_Preserve)
		VectorSourceColor( SetAlpha(*Data\Colors_Body_StrokeBlending(*Block\State), *Data\Content_DisplayedLines()\Object\Color))
		StrokePath(2)
		
		If *Data\Meas_Column_Width > #Style_Column_MinimumDisplaySize
			For loop = FirstBlock To LastBlock
				If *Data\Content_DisplayedLines()\Object\DataPoints(loop)
					
				EndIf
			Next
		EndIf
	EndProcedure
	
	Procedure DrawDataPoint(*Data.GadgetData, x, y)
		
	EndProcedure
	
	Procedure AddPathMediaBlock(x, y, Width, Height, Radius)
		MovePathCursor(x + Width, y)
		AddPathArc(x, y, x,y + Height, Radius)
		AddPathLine(x, y + Height)
		AddPathLine(x + Width, y + Height)
		ClosePath()
	EndProcedure
	
	; Misc
	Procedure ScrollVertical(Gadget)
		Protected *Data.GadgetData = GetGadgetData(Gadget), ScrollbarPosition = GetGadgetState(*Data\Comp_VScrollBar)
		If Not *Data\State_VerticalScroll = ScrollbarPosition
			*Data\State_VerticalScroll = ScrollbarPosition
			ProcedureReturn #True
		EndIf
	EndProcedure
	
	Procedure ScrollHorizontal(Gadget)
		Protected *Data.GadgetData = GetGadgetData(Gadget), ScrollbarPosition = GetGadgetState(*Data\Comp_HScrollBar)
		If Not *Data\State_HorizontalScroll = ScrollbarPosition
			*Data\State_HorizontalScroll = ScrollbarPosition
			ProcedureReturn #True
		EndIf
	EndProcedure
	
	Procedure Refit(Gadget)
		Protected *Data.GadgetData = GetGadgetData(Gadget)

		*Data\Meas_Gadget_Width = GadgetWidth(Gadget)
		*Data\Meas_Gadget_Height = GadgetHeight(Gadget)
		*Data\Meas_Content_Height = *Data\Meas_Gadget_Height - *Data\Meas_Header_Height
		*Data\Meas_Body_Width = *Data\Meas_Gadget_Width - *Data\Meas_List_Width
		*Data\Meas_Line_Visible = *Data\Meas_Content_Height / #Style_Line_Height
		
		If *Data\Meas_Line_Total >= *Data\Meas_Line_Visible
			SetGadgetAttribute(*Data\Comp_VScrollBar, #PB_ScrollBar_Maximum, *Data\Meas_Line_Total)
			SetGadgetAttribute(*Data\Comp_VScrollBar, #PB_ScrollBar_PageLength, *Data\Meas_Line_Visible)
			*Data\Meas_VScrollBar_Visible = #True
			*Data\Meas_Body_Width - *Data\Meas_VScrollBar_Width
			ScrollVertical(Gadget)
		Else
			SetGadgetAttribute(*Data\Comp_VScrollBar, #PB_ScrollBar_Maximum, 1)
			*Data\State_VerticalScroll = 0
			*Data\Meas_VScrollBar_Visible = #False
		EndIf
		
		*Data\Meas_Column_Visible = *Data\Meas_Body_Width / *Data\Meas_Column_Width
		
		If *Data\Content_Duration > *Data\Meas_Column_Visible
			*Data\Meas_HScrollBar_Visible = #True
			SetGadgetAttribute(*Data\Comp_HScrollBar, #PB_ScrollBar_PageLength, *Data\Meas_Column_Visible)
			ScrollHorizontal(Gadget)
		Else
			*Data\Meas_Column_Visible = *Data\Content_Duration
			SetGadgetAttribute(*Data\Comp_HScrollBar, #PB_ScrollBar_Maximum, 1)
			*Data\State_HorizontalScroll = 0
			*Data\Meas_HScrollBar_Visible = #False
		EndIf
		
		If *Data\Meas_VScrollBar_Visible
			ResizeGadget(*Data\Comp_VScrollBar, *Data\Meas_Gadget_Width - *Data\Meas_VScrollBar_Width, #PB_Ignore, #PB_Ignore, *Data\Meas_Content_Height - *Data\Meas_HScrollBar_Visible * *Data\Meas_HScrollbar_Height)
			HideGadget(*Data\Comp_VScrollBar, #False)
		Else
			HideGadget(*Data\Comp_VScrollBar, #True)
		EndIf
		
		If *Data\Meas_HScrollBar_Visible
			ResizeGadget(*Data\Comp_HScrollBar, *Data\Meas_List_Width, *Data\Meas_Gadget_Height - *Data\Meas_HScrollbar_Height, *Data\Meas_Body_Width, *Data\Meas_HScrollbar_Height)
			HideGadget(*Data\Comp_HScrollBar, #False)
		Else
			HideGadget(*Data\Comp_HScrollBar, #True)
		EndIf
		
		If *Data\Meas_HScrollBar_Visible And *Data\Meas_VScrollBar_Visible
			ResizeGadget(*Data\Comp_CornerCover, *Data\Meas_Gadget_Width - *Data\Meas_VScrollBar_Width, *Data\Meas_Gadget_Height - *Data\Meas_HScrollbar_Height, #PB_Ignore, #PB_Ignore)
			HideGadget(*Data\Comp_CornerCover, #False)
		Else
			HideGadget(*Data\Comp_CornerCover, #True)
		EndIf
		
	EndProcedure
	
	Procedure RecurciveDelete(*Data.GadgetData, *Line.Line)
		
	EndProcedure
	
	Procedure ResizeMB(*Block.MediaBlock, Start, Finish)
		
	EndProcedure
	
	Procedure MoveMB(*Block.MediaBlock, Offset)
		
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
	
	Procedure ToggleFold(Gadget, Item)
		Protected *Data.GadgetData = GetGadgetData(Gadget), *Line.Line, Index, Offset
		
		SelectElement(*Data\Content_DisplayedLines(), Item)
		Index = ListIndex(*Data\Content_DisplayedLines())
		
		*Line.Line = *Data\Content_DisplayedLines()\Object
		
		If *Data\Content_DisplayedLines()\Object\Fold = #Folded
			*Data\Content_DisplayedLines()\Object\Fold = #Unfolded
			Offset = RecurciveUnFold(*Data.GadgetData, *Data\Content_DisplayedLines()\Object)
			
			If *Data\State_SelectedLine > Index
				*Data\State_SelectedLine + Offset
			EndIf
			
		Else
			*Data\Content_DisplayedLines()\Object\Fold = #Folded
			Offset = RecurciveFold(*Data.GadgetData, *Data\Content_DisplayedLines()\Object)
			
			If *Data\State_SelectedLine > Index + Offset
				*Data\State_SelectedLine - Offset
			ElseIf *Data\State_SelectedLine > Index
				SelectElement(*Data\Content_DisplayedLines(), *Data\State_SelectedLine)
				*Data\Content_DisplayedLines()\Object\State = #State_Cold
				*Data\State_SelectedLine = -1
			EndIf
			
		EndIf
		
		*Data\Meas_Line_Total = ListSize(*Data\Content_DisplayedLines()) -1
		
		Refit(Gadget)
		Redraw(Gadget)
	EndProcedure
	;}
EndModule













































; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 1175
; FirstLine = 419
; Folding = v0BQG-48PAAw
; EnableXP