CompilerIf Not Defined(MaterialVector, #PB_Module)
	IncludeFile "MaterialVector\MaterialVector.pbi"
CompilerEndIf

CompilerIf Not Defined(CanvasButton, #PB_Module)
	IncludeFile "CanvasButton\CanvasButton.pbi"
CompilerEndIf

CompilerIf Not Defined(SortLinkedList, #PB_Module) ; Couldn't figure out a nice way to sort the selected lists with the built in structured list sort, so I'll use this one : https://www.purebasic.fr/english/viewtopic.php?f=12&t=72352 
	DeclareModule SortLinkedList
		
		; v 1.10  March 2, 2019
		
		; Procedure Compare(*p1, *p2)
		; <0 The element pointed to by *p1 goes before the element pointed to by *p2
		;  0 The element pointed to by *p1 is equivalent to the element pointed to by *p2
		; >0 The element pointed to by *p1 goes after the element pointed to by *p2
		
		Declare _SortLinkedList_ (*LinkedList, *Compare, First=0, Last=-1)
		
		Declare SortLinkedListD (List LinkedList.d(), *Compare, First=0, Last=-1)
		Declare SortLinkedListI (List LinkedList.i(), *Compare, First=0, Last=-1)
		Declare SortLinkedListS (List LinkedList.s(), *Compare, First=0, Last=-1)
		
	EndDeclareModule
	
	Module SortLinkedList
		DisableDebugger
		EnableExplicit
		
		;- >> Structures <<
		
		Structure PB_ListHeader
			*Next.PB_ListHeader
			*Previous.PB_ListHeader
			Element.i[0]
		EndStructure
		
		Structure PB_List
			*First.PB_ListHeader
			*Last.PB_ListHeader
			*Current.PB_ListHeader
			*PtrCurrentVariable.Integer
			NBElements.i
			Index.i
			*StructureMap
			*Allocator
			*PositionStack
			*Object
			ElementSize.i
			ElementType.l
			IsIndexInvalid.b
			IsDynamic.b
			IsDynamicObject.b
		EndStructure
		
		;- >> Prototypes <<   
		
		Prototype.i ProtoCompare (*p1, *p2)
		Prototype Proto_SortLinkedListD (List LinkedList.d(), *Compare, First=0, Last=-1)
		Prototype Proto_SortLinkedListI (List LinkedList.i(), *Compare, First=0, Last=-1)
		Prototype Proto_SortLinkedListS (List LinkedList.s(), *Compare, First=0, Last=-1)
		
		;- >> Procedures << 
		
		Procedure _SortLinkedList_ (*LinkedList.PB_List, *Compare.ProtoCompare, First=0, Last=-1)
			Protected Dim *ListHead(31)
			Protected Dim *ListTail(31)
			Protected.PB_ListHeader *EqualItems, *List, *List1, *List2, *Next, *P, *Stop, *Tail, *Tail1, *Tail2
			Protected.i Count, Direction, Fractional, FractionalCount, i, ListSize0, NumItems, NumLists
			
			; Check parameters and return if there is nothing to sort
			If *LinkedList And *Compare And *LinkedList\NBElements
				If First < 0 : First = 0 : EndIf
				If Last < 0 Or Last >= *LinkedList\NBElements
					Last = *LinkedList\NBElements - 1
				EndIf
				NumItems = Last - First + 1
				If NumItems <= 1
					ProcedureReturn
				EndIf     
			Else
				ProcedureReturn
			EndIf
			
			; Invalidate the current index value
			*LinkedList\IsIndexInvalid = #True
			
			; Seek the first element to sort
			If First << 1 < *LinkedList\NBElements
				; Seek element starting from beginning
				i = First
				*List = *LinkedList\First
				While i
					*List = *List\Next
					i - 1
				Wend 
			Else
				; Seek element starting from end
				i = *LinkedList\NBElements - 1 - First
				*List = *LinkedList\Last
				While i
					*List = *List\Previous
					i - 1
				Wend
			EndIf
			
			; Store pointer to previous element
			*P = *List\Previous
			
			; Calculate the initial list size so that
			; the number of lists is a power of two
			ListSize0 = NumItems >> 3
			For i = 0 To 5
				ListSize0 | ListSize0 >> (1 << i)
			Next
			NumLists = ListSize0 + 1
			ListSize0 = NumItems / NumLists
			Fractional = NumItems - NumLists * ListSize0
			
			;- >> Sort <<
			While NumItems
				
				;- >> Build list using insertion sort <<
				*Next = *List\Next
				*Tail = *List
				*List\Next = #Null
				*List\Previous = #Null
				*List1 = *List
				*EqualItems = #Null
				Direction = 0
				
				Count = ListSize0
				FractionalCount + Fractional
				If FractionalCount >= NumLists
					FractionalCount - NumLists
					Count + 1
				EndIf
				NumItems - Count
				
				While Count > 1
					*List2 = *Next
					*Next = *List2\Next
					
					; Compare against previous insertion point
					i = *Compare(@*List1\Element, @*List2\Element)
					If i = 0
						; No search; insert directly after previous insertion point
						If *EqualItems = #Null
							*EqualItems = *List1
						EndIf   
						*Stop = *List1
					Else
						If i > 0
							; Search back from previous insertion point
							If *EqualItems
								*List1 = *EqualItems
							EndIf
							*Stop = #Null
							*List1 = *List1\Previous
							If Direction And Direction <> -1
								Direction = -2
							Else
								Direction = -1
							EndIf           
						Else
							; Search back from tail
							*Stop = *List1
							*List1 = *Tail
							If Direction And Direction <> 1
								Direction = -2
							Else
								Direction = 1
							EndIf
						EndIf
						*EqualItems = #Null
					EndIf
					; Backward search
					While *List1 <> *Stop And *Compare(@*List1\Element, @*List2\Element) > 0
						*List1 = *List1\Previous
					Wend
					; Insert
					If *List1
						; Insert *List2 after *List1
						*List2\Next = *List1\Next
						*List2\Previous = *List1
						If *List2\Next
							*List2\Next\Previous = *List2
						Else
							*Tail = *List2
						EndIf
						*List1\Next = *List2             
					Else
						; Insert *List2 before *List
						*List2\Next = *List
						*List2\Previous = #Null
						*List\Previous = *List2
						*List = *List2
					EndIf
					*List1 = *List2
					
					Count - 1
				Wend
				
				; Merge with other list(s)
				For i = 0 To 31
					If *ListHead(i)
						If *List
							*List1 = *ListHead(i)
							*Tail1 = *ListTail(i)
							*List2 = *List
							*Tail2 = *Tail
							
							;- >> Merge List1 and List2 <<
							
							If Direction = -1 And *Compare(@*List1\Element, @*Tail2\Element) > 0
								; Entire List1 goes after List2
								*Tail2\Next = *List1
								*List1\Previous = *Tail2
								*List = *List2
								*Tail = *Tail1
							ElseIf Direction >= 0 And *Compare(@*Tail1\Element, @*List2\Element) <= 0
								; Entire List2 goes after List1
								*Tail1\Next = *List2
								*List2\Previous = *Tail1
								*List = *List1
								*Tail = *Tail2
							Else
								Direction = -2
								; Merge List1 and List2 element by element
								
								If *Compare(@*List1\Element, @*List2\Element) <= 0
									*List = *List1
									*List1 = *List1\Next
								Else
									*List = *List2
									*List2 = *List2\Next
								EndIf
								*Tail = *List
								
								While *List1 And *List2
									If *Compare(@*List1\Element, @*List2\Element) <= 0
										*Tail\Next = *List1
										*List1\Previous = *Tail
										*Tail = *List1
										*List1 = *List1\Next
									Else
										*Tail\Next = *List2
										*List2\Previous = *Tail
										*Tail = *List2
										*List2 = *List2\Next
									EndIf
								Wend
								
								If *List1
									*Tail\Next = *List1
									*List1\Previous = *Tail
									*Tail = *Tail1
								ElseIf *List2
									*Tail\Next = *List2
									*List2\Previous = *Tail
									*Tail = *Tail2
								EndIf
								
							EndIf
							
							;- >> End of merge <<
							
						Else
							*List = *ListHead(i)
							*Tail = *ListTail(i)
						EndIf
						*ListHead(i) = #Null
					ElseIf NumItems
						Break
					EndIf
				Next
				
				If NumItems
					If i > 31 : i = 31 : EndIf
					*ListHead(i) = *List
					*ListTail(i) = *Tail
					*List = *Next
				EndIf
				
			Wend
			
			; Update *First and *Last when needed
			If First = 0
				*LinkedList\First = *List
			Else
				*P\Next = *List
				*List\Previous = *P
			EndIf
			If Last = *LinkedList\NBElements - 1
				*LinkedList\Last = *Tail
			Else
				*Tail\Next = *Next
				*Next\Previous = *Tail
			EndIf
			
		EndProcedure 
		
		Procedure SortLinkedListD (List LinkedList.d(), *Compare, First=0, Last=-1)
			Protected SortLinkedList.Proto_SortLinkedListD = @_SortLinkedList_()
			SortLinkedList(LinkedList(), *Compare, First, Last)
		EndProcedure
		
		Procedure SortLinkedListI (List LinkedList.i(), *Compare, First=0, Last=-1)
			Protected SortLinkedList.Proto_SortLinkedListI = @_SortLinkedList_()
			SortLinkedList(LinkedList(), *Compare, First, Last)
		EndProcedure
		
		Procedure SortLinkedListS (List LinkedList.s(), *Compare, First=0, Last=-1)
			Protected SortLinkedList.Proto_SortLinkedListS = @_SortLinkedList_()
			SortLinkedList(LinkedList(), *Compare, First, Last)
		EndProcedure
		
	EndModule
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
		#Action_ItemResize
		#Action_ItemResizeInit
		#Action_ItemMove
		#Action_ItemMoveInit
		#Action_PlayerMove
	EndEnumeration
	
	; Functionality
	#Func_LineSelection = #False
	#Func_AutoDragScroll = #True		; Will enable the automatic scroll when the user is draging/resizing something outside of the gadget. This uses a few sketchy methods to achieve its goal...
	
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
	
	; Misc
	#Misc_DragTimer = 42
	#Misc_DragTimerDuration = 33
	#Misc_DragScrollStep = 2
	
	#Misc_DefaultDuration = 360
	
	#Misc_ResizeHotZone = 7
	#Misc_ResizeFromFirst = 0
	#Misc_ResizeFromLast = 1
	
	
	Structure MediaBlock
		BlockType.b
		FirstBlock.i
		LastBlock.i
		Icon.i
		State.b
		*Line.Line
		*StateListElement
	EndStructure
	
	Structure DataPoint
		Position.i
		State.b
		*Line.Line
	EndStructure
	
	Structure DPAdress 				; Dirty workaround for the structured list sorting procedures
		*Object.DataPoint
	EndStructure
	
	Structure MBAdress				; Dirty workaround for the structured list sorting procedures
		*Object.MediaBlock
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
		
		List *Content_Lines.Line()
		Array *DataPoints.DataPoint(1)
		Array *MediaBlocks.MediaBlock(1)
	EndStructure
	
	Structure GadgetData
		; Content
		List *Content_Lines.Line()
		List *Content_DisplayedLines.Line()
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
		Comp_Canvas.i
		CompilerIf #Func_AutoDragScroll
			Comp_TimerWindow.i
		CompilerEndIf
		
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
		List *State_SelectedMediaBlocks.MediaBlock()
		List *State_SelectedDataPoints.DataPoint()
		State_UserAction.i
		State_VerticalScroll.i
		State_HorizontalScroll.i
		
		; Drag...
		Drag_Origin.i
		Drag_Offset.i
		Drag_ScrollOffset.i
		Drag_DeselectMB.i
		Drag_KeepMB.i
		Drag_ScrollStep.i
		Drag_Direction.b
		CompilerIf #Func_AutoDragScroll
			Drag_Timer.i
		CompilerEndIf
		
		; Resize
		*Resize_MediaBlock.MediaBlock
		
		; Player
		PlayerX.i
		Player_Enabled.b
		Player_Position.i
		Player_OriginX.i
		Player_Step.b
		Player_Hover.b
		
		; Drawing informations
		Draw_WarmToggle.i
		Draw_WarmLine.i
		*Draw_WarmDataPoint.DataPoint
		*Draw_WarmMediaBlock.MediaBlock
		Drag_Step.b
		
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
	Declare HandlerTimerWindow()
	
	; Drawing
	Declare Redraw(Gadget)
	Declare DrawLine(*Data.GadgetData)
	Declare DrawMediaBlock(*Data.GadgetData, YPos, *Block.MediaBlock)
	Declare DrawDataPoint(*Data.GadgetData, x, y)
	Declare AddPathMediaBlock(x, y, Width, Height, Radius)
	
	; Misc
	Declare ScrollVertical(Gadget)
	Declare ScrollHorizontal(Gadget)
	Declare Refit(Gadget)
	Declare RecurciveDelete(*Data.GadgetData, *Line.Line)
	Declare ResizeMB(*Data.GadgetData, *Block.MediaBlock, Start, Finish)
	Declare MoveMB(*Data.GadgetData, *Block.MediaBlock, Offset, ForceDirection = #False)
	Declare RecurciveFold(*Data.GadgetData, *Line.Line)
	Declare RecurciveUnFold(*Data.GadgetData, *Line.Line)
	Declare ToggleFold(Gadget, Item)
	Declare CompareAscending(*a.MBAdress, *b.MBAdress)
	Declare CompareDescending(*a.MBAdress, *b.MBAdress)
	
	Prototype Proto_SortMediaBlocks(List LinkedList.MediaBlock(), *Compare, First=0, Last=-1)
	Global SortMediaBlocks.Proto_SortMediaBlocks = SortLinkedList::@_SortLinkedList_()
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
				
				\Content_Duration = #Misc_DefaultDuration + #Style_Body_ColumnMargin * 2
				
				; Components
				\Comp_VScrollBar = ScrollBarGadget(#PB_Any, 0, \Meas_Header_Height, 10, 10, 0, 10, 10, #PB_ScrollBar_Vertical)
				\Meas_VScrollBar_Width = GadgetWidth(\Comp_VScrollBar, #PB_Gadget_RequiredSize)
				ResizeGadget(\Comp_VScrollBar, #PB_Ignore, #PB_Ignore, \Meas_VScrollBar_Width, #PB_Ignore)
				HideGadget(\Comp_VScrollBar, #True)
				BindGadgetEvent(\Comp_VScrollBar, @HandlerVScrollbar())
				SetGadgetData(\Comp_VScrollBar, Gadget)
				
				\Comp_HScrollbar = ScrollBarGadget(#PB_Any, 0, 0, 10, 10, 0, \Content_Duration - 1, 10)
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
				
				\Comp_LitSplitter = ContainerGadget(#PB_Any, \Meas_List_Width - 1, \Meas_Header_Height, 1, Height - \Meas_Header_Height, #PB_Container_BorderLess)
				SetGadgetColor(\Comp_LitSplitter, #PB_Gadget_BackColor, $000000)
				CloseGadgetList()
				
				\Comp_CornerCover = ContainerGadget(#PB_Any, \Meas_List_Width - 1, \Meas_Header_Height, \Meas_VScrollBar_Width, \Meas_HScrollbar_Height, #PB_Container_BorderLess)
				SetGadgetColor(\Comp_CornerCover, #PB_Gadget_BackColor, \Colors_Body_Back)
				HideGadget(\Comp_CornerCover, #True)
				
				CloseGadgetList()
				
				\Comp_Canvas = Gadget
				
				CompilerIf #Func_AutoDragScroll
					\Comp_TimerWindow = OpenWindow(#PB_Any, 0, 0, 100, 100, "", #PB_Window_Invisible)
					BindEvent(#PB_Event_Timer, @HandlerTimerWindow(), \Comp_TimerWindow)
					SetWindowData(\Comp_TimerWindow, *Data)
				CompilerEndIf
				
				; Player
				\Player_Position = #Style_Body_ColumnMargin
			EndWith
			
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
					*PreviousLine = *ParentID\Content_Lines()
				EndIf
			Else
				If Position = 0
					ResetList(*ParentID\Content_Lines())
					*PreviousLine = *ParentID
				Else
					SelectElement(*ParentID\Content_Lines(), Position - 1)
					*PreviousLine = *ParentID\Content_Lines()
				EndIf
			EndIf
			
			AddElement(*ParentID\Content_Lines())
			*ParentID\Content_Lines() = *NewLine
			
			*NewLine\HOffset = *ParentID\HOffset + #Style_List_TextHOffset
			
			If *ParentID\Fold = #Unfolded 
				If *ParentID\DisplayListAdress
					ChangeCurrentElement(*Data\Content_DisplayedLines(), *PreviousLine)
					AddElement(*Data\Content_DisplayedLines())
					*Data\Content_DisplayedLines() = *NewLine
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
				ChangeCurrentElement(*Data\Content_DisplayedLines(), *Data\Content_Lines()\DisplayListAdress)
				InsertElement(*Data\Content_DisplayedLines())
				InsertElement(*Data\Content_Lines())
			EndIf
			
			*Data\Content_DisplayedLines() = *NewLine
			*Data\Content_Lines() = *NewLine
			
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
				ProcedureReturn *ParentID\Content_Lines()
			EndIf
		Else
			Protected *Data.GadgetData = GetGadgetData(Gadget)
			If SelectElement(*Data\Content_Lines(), Position)
				ProcedureReturn *Data\Content_Lines()
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
		Protected Gadget = EventGadget(), *Data.GadgetData = GetGadgetData(Gadget)
		Protected MouseX = GetGadgetAttribute(Gadget, #PB_Canvas_MouseX), MouseY = GetGadgetAttribute(Gadget, #PB_Canvas_MouseY)
		Protected Line, Column, Modifiers
		Protected WarmLine = -1, WarmToggle = -1, *WarmMediaBlock.MediaBlock, *WarmDataPoint.DataPoint, Redraw, *Resize_MediaBlock.MediaBlock, PlayerHover
		
		Select EventType()
			Case #PB_EventType_MouseMove ;{
				Select *Data\State_UserAction
					Case #Action_Hover ;{
						If MouseY < *Data\Meas_Header_Height ;{ Hovering over the header
							If MouseX > *Data\PlayerX And MouseX < *Data\PlayerX + #Style_Player_TopWidth And MouseY < #Style_Player_TopHeight
								PlayerHover = #True
							EndIf
							;}
						ElseIf MouseX < *Data\Meas_List_Width ;{ Hovering over the list
							MouseY - *Data\Meas_Header_Height
							Line = MouseY / #Style_Line_Height + *Data\State_VerticalScroll
							If Line <= *Data\Meas_Line_Total
								MouseY % #Style_Line_Height
								;Check if the mouse is hovering above the fold
								SelectElement(*Data\Content_DisplayedLines(), Line)
								If (*Data\Content_DisplayedLines()\Fold And
								    MouseX > *Data\Content_DisplayedLines()\HOffset -4 And
								    MouseX < *Data\Content_DisplayedLines()\HOffset + #Style_List_FoldSize + 4 And
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
							MouseY - *Data\Meas_Header_Height
							Line = MouseY / #Style_Line_Height + *Data\State_VerticalScroll
							If Line <= *Data\Meas_Line_Total
								SelectElement(*Data\Content_DisplayedLines(), Line)
								MouseX - *Data\Meas_List_Width
								Column = MouseX / *Data\Meas_Column_Width + *Data\State_HorizontalScroll
								If Column <= *Data\Content_Duration
									MouseY % #Style_Line_Height
									If *Data\Content_DisplayedLines()\DataPoints(Column) And #False
										
									ElseIf MouseY > #Style_MediaBlock_Margin And MouseY < #Style_MediaBlock_Margin + #Style_MediaBlock_Height
										If *Data\Content_DisplayedLines()\MediaBlocks(Column)
											*WarmMediaBlock = *Data\Content_DisplayedLines()\MediaBlocks(Column)
											If *WarmMediaBlock\State = #State_Hot
												If MouseX < (*WarmMediaBlock\FirstBlock - *Data\State_HorizontalScroll) * *Data\Meas_Column_Width + #Misc_ResizeHotZone
													*Resize_MediaBlock = *WarmMediaBlock
													*Data\Drag_Direction = #Misc_ResizeFromFirst
												ElseIf MouseX > (*WarmMediaBlock\LastBlock - *Data\State_HorizontalScroll + 1) * *Data\Meas_Column_Width - #Misc_ResizeHotZone
													*Resize_MediaBlock = *WarmMediaBlock
													*Data\Drag_Direction = #Misc_ResizeFromLast
												EndIf
											EndIf
										EndIf
									EndIf
								EndIf
							EndIf
						EndIf ;}
						;{ Redraw
						If *Data\Draw_WarmLine <> WarmLine
							StartLocalRedrawing
							If *Data\Draw_WarmLine > - 1
								SelectElement(*Data\Content_DisplayedLines(), *Data\Draw_WarmLine)
								*Data\Content_DisplayedLines()\State = #State_Cold
								*Data\Draw_WarmLine = -1
								DrawLine(*Data)
							EndIf
							
							If WarmLine > -1
								*Data\Draw_WarmLine = WarmLine
								SelectElement(*Data\Content_DisplayedLines(), *Data\Draw_WarmLine)
								*Data\Content_DisplayedLines()\State = #State_Warm
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
							If *Data\Draw_WarmDataPoint
								Modifiers = GetGadgetAttribute(Gadget, #PB_Canvas_Modifiers)
							EndIf
							
							If *WarmDataPoint
								
							EndIf
						EndIf
						
						If *Data\Draw_WarmMediaBlock <> *WarmMediaBlock
							StartLocalRedrawing
							If *Data\Draw_WarmMediaBlock And *Data\Draw_WarmMediaBlock\State = #State_Warm
								*Data\Draw_WarmMediaBlock\State = #State_Cold
								ChangeCurrentElement(*Data\Content_DisplayedLines(), *Data\Draw_WarmMediaBlock\Line\DisplayListAdress)
								DrawLine(*Data)
								*Data\Draw_WarmMediaBlock = 0
							EndIf
							
							If *WarmMediaBlock And *WarmMediaBlock\State = #State_Cold
								ChangeCurrentElement(*Data\Content_DisplayedLines(), *WarmMediaBlock\Line\DisplayListAdress)
								*WarmMediaBlock\State = #State_Warm
								DrawLine(*Data)
							EndIf
							
							*Data\Draw_WarmMediaBlock = *WarmMediaBlock
						EndIf
						
						If *Data\Resize_MediaBlock <> *Resize_MediaBlock
							If *Data\Resize_MediaBlock
								*Data\Resize_MediaBlock = 0
								SetGadgetAttribute(Gadget, #PB_Canvas_Cursor, #PB_Cursor_Default)
							EndIf
							
							If *Resize_MediaBlock
								*Data\Resize_MediaBlock = *Resize_MediaBlock
								SetGadgetAttribute(Gadget, #PB_Canvas_Cursor, #PB_Cursor_LeftRight)
							EndIf
						EndIf
						
						If Redraw
							StopVectorDrawing()
						EndIf
						
						*Data\Player_Hover = PlayerHover
						
						;}
						;}
					Case #Action_ItemMove, #Action_ItemResize, #Action_PlayerMove ;{
						If MouseX < *Data\Meas_List_Width 
							If *Data\State_HorizontalScroll
								CompilerIf #Func_AutoDragScroll
									If *Data\Drag_Timer = #False
										*Data\Drag_Timer = -1
										AddWindowTimer(*Data\Comp_TimerWindow, #Misc_DragTimer, #Misc_DragTimerDuration)
									EndIf
								CompilerElse
									*Data\Drag_ScrollStep + 1
									If *Data\Drag_ScrollStep = #Misc_DragScrollStep
										*Data\Drag_ScrollStep = 0
										SetGadgetState(*Data\Comp_HScrollbar, GetGadgetState(*Data\Comp_HScrollbar) - 1)
										If ScrollHorizontal(Gadget)
											*Data\Drag_ScrollOffset - 1
											*Data\Drag_Offset - 1
											Redraw(Gadget)
										EndIf
									EndIf
								CompilerEndIf
							EndIf
						ElseIf MouseX > *Data\Meas_List_Width + *Data\Meas_Body_Width 
							If *Data\State_HorizontalScroll < *Data\Content_Duration - *Data\Meas_Column_Visible
								CompilerIf #Func_AutoDragScroll
									If *Data\Drag_Timer = #False
										*Data\Drag_Timer = 1
										AddWindowTimer(*Data\Comp_TimerWindow, #Misc_DragTimer, #Misc_DragTimerDuration)
									EndIf
								CompilerElse
									*Data\Drag_ScrollStep + 1
									If *Data\Drag_ScrollStep = #Misc_DragScrollStep
										*Data\Drag_ScrollStep = 0
										SetGadgetState(*Data\Comp_HScrollbar, GetGadgetState(*Data\Comp_HScrollbar) + 1)
										If ScrollHorizontal(Gadget)
											*Data\Drag_ScrollOffset + 1
											*Data\Drag_Offset + 1
											Redraw(Gadget)
										EndIf
									EndIf
								CompilerEndIf
							EndIf
						Else
							CompilerIf #Func_AutoDragScroll
								If *Data\Drag_Timer
									*Data\Drag_Timer = #False
									
									*Data\Drag_Origin - (*Data\Drag_ScrollOffset * *Data\Meas_Column_Width)
									
									*Data\Drag_ScrollOffset = 0
								EndIf
							CompilerEndIf
							
							Column = (MouseX - *Data\Drag_Origin) / *Data\Meas_Column_Width
							If *Data\State_UserAction = #Action_PlayerMove
								If Not *Data\Drag_Offset = Column
									*Data\Drag_Offset = Column
									Column = Min(max(*Data\Player_Position + *Data\Drag_Offset, #Style_Body_ColumnMargin), *Data\Content_Duration - #Style_Body_ColumnMargin)
									*Data\PlayerX = (Column - *Data\State_HorizontalScroll) * *Data\Meas_Column_Width + *Data\Meas_List_Width - #Style_Player_TopOffset - 0.5
									Redraw(Gadget)
								EndIf
							Else
								If Not *Data\Drag_Offset = Column
									*Data\Drag_Offset = Column
									Redraw(Gadget)
								EndIf
							EndIf
						EndIf
						;}
					Case #Action_ItemMoveInit, #Action_ItemResizeInit ;{
						If Abs(MouseX - *Data\Drag_Origin) > 4
							*Data\Drag_DeselectMB = #False
							*Data\Drag_KeepMB = #False
							*Data\Drag_ScrollStep = 0
							*Data\Drag_ScrollOffset = 0
							
							If *Data\State_UserAction = #Action_ItemMoveInit
								*Data\State_UserAction = #Action_ItemMove
								ForEach *Data\State_SelectedDataPoints()
									*Data\State_SelectedDataPoints()\State = #State_Drag
								Next
								
								ForEach *Data\State_SelectedMediaBlocks()
									*Data\State_SelectedMediaBlocks()\State = #State_Drag
								Next
							Else
								*Data\State_UserAction = #Action_ItemResize
								ForEach *Data\State_SelectedMediaBlocks()
									*Data\State_SelectedMediaBlocks()\State = #State_Resize
								Next
							EndIf
						EndIf
						;}
				EndSelect
				;}
			Case #PB_EventType_MouseLeave ;{
				;}
			Case #PB_EventType_LeftButtonDown ;{
				If *Data\State_UserAction= #Action_Hover
					If MouseY < *Data\Meas_Header_Height ;{
						If *Data\Player_Hover
							*Data\State_UserAction = #Action_PlayerMove
							*Data\Drag_Origin = MouseX
							*Data\Drag_ScrollStep = 0
							*Data\Drag_ScrollOffset = 0
							SetGadgetAttribute(Gadget, #PB_Canvas_Cursor, #PB_Cursor_LeftRight)
						EndIf
						;}
					ElseIf MouseX < *Data\Meas_List_Width;{ 
						If *Data\Draw_WarmLine > -1
							StartLocalRedrawing
							If *Data\State_SelectedLine > -1
								SelectElement(*Data\Content_DisplayedLines(), *Data\State_SelectedLine)
								*Data\Content_DisplayedLines()\State = #State_Cold
								DrawLine(*Data)
							EndIf
							
							*Data\State_SelectedLine = *Data\Draw_WarmLine
							*Data\Draw_WarmLine = - 1
							
							SelectElement(*Data\Content_DisplayedLines(), *Data\State_SelectedLine)
							*Data\Content_DisplayedLines()\State = #State_Hot
							DrawLine(*Data)
							StopVectorDrawing()
						ElseIf *Data\Draw_WarmToggle > -1
							ToggleFold(Gadget, *Data\Draw_WarmToggle)
						EndIf
						;}
					Else;{ Body
						Modifiers = GetGadgetAttribute(Gadget, #PB_Canvas_Modifiers)
						If *Data\Draw_WarmMediaBlock
							If Modifiers & #PB_Canvas_Command
								If *Data\Draw_WarmMediaBlock\State = #State_Hot
									*Data\Drag_DeselectMB = #True
								Else
									*Data\Draw_WarmMediaBlock\State = #State_Hot
									*Data\Draw_WarmMediaBlock\StateListElement = AddElement(*Data\State_SelectedMediaBlocks())
									*Data\State_SelectedMediaBlocks() = *Data\Draw_WarmMediaBlock
								EndIf
								ChangeCurrentElement(*Data\Content_DisplayedLines(), *Data\Draw_WarmMediaBlock\Line\DisplayListAdress)
								StartLocalRedrawing
								DrawLine(*Data)
								StopVectorDrawing()
							Else
								If *Data\Draw_WarmMediaBlock\State = #State_Hot
									If ListSize(*Data\State_SelectedDataPoints()) Or ListSize(*Data\State_SelectedMediaBlocks())
										*Data\Drag_KeepMB = #True
									EndIf
								ElseIf ListSize(*Data\State_SelectedDataPoints()) Or ListSize(*Data\State_SelectedMediaBlocks())
									ForEach *Data\State_SelectedDataPoints()
										*Data\State_SelectedDataPoints()\State = #State_Cold
										DeleteElement(*Data\State_SelectedDataPoints())
									Next
									
									ForEach *Data\State_SelectedMediaBlocks()
										*Data\State_SelectedMediaBlocks()\State = #State_Cold
										DeleteElement(*Data\State_SelectedMediaBlocks())
									Next
									
									*Data\Draw_WarmMediaBlock\State = #State_Hot
									*Data\Draw_WarmMediaBlock\StateListElement = AddElement(*Data\State_SelectedMediaBlocks())
									*Data\State_SelectedMediaBlocks() = *Data\Draw_WarmMediaBlock
									
									Redraw(Gadget)
								Else
									*Data\Draw_WarmMediaBlock\State = #State_Hot
									*Data\Draw_WarmMediaBlock\StateListElement = AddElement(*Data\State_SelectedMediaBlocks())
									*Data\State_SelectedMediaBlocks() = *Data\Draw_WarmMediaBlock
									ChangeCurrentElement(*Data\Content_DisplayedLines(), *Data\Draw_WarmMediaBlock\Line\DisplayListAdress)
									StartLocalRedrawing
									DrawLine(*Data)
									StopVectorDrawing()
								EndIf
							EndIf
							If *Data\Resize_MediaBlock
								*Data\State_UserAction = #Action_ItemResizeInit
								If *Data\Drag_Direction 
									*Data\Drag_Origin = (*Data\Resize_MediaBlock\LastBlock - *Data\State_HorizontalScroll + 1) * *Data\Meas_Column_Width + *Data\Meas_List_Width
								Else
									*Data\Drag_Origin =  (*Data\Resize_MediaBlock\FirstBlock - *Data\State_HorizontalScroll) * *Data\Meas_Column_Width + *Data\Meas_List_Width
								EndIf
							Else
								*Data\State_UserAction = #Action_ItemMoveInit
								*Data\Drag_Origin = MouseX
							EndIf
						ElseIf *Data\Draw_WarmDataPoint
							
						Else
							If Not Modifiers & #PB_Canvas_Command
								ForEach *Data\State_SelectedDataPoints()
									*Data\State_SelectedDataPoints()\State = #State_Cold
									DeleteElement(*Data\State_SelectedDataPoints())
								Next
								
								ForEach *Data\State_SelectedMediaBlocks()
									*Data\State_SelectedMediaBlocks()\State = #State_Cold
									DeleteElement(*Data\State_SelectedMediaBlocks())
								Next
								Redraw(Gadget)
							EndIf
						EndIf
					EndIf;}
				EndIf
				;}
			Case #PB_EventType_LeftButtonUp ;{
				Select *Data\State_UserAction
					Case #Action_Hover ;{
						
						;}
					Case #Action_ItemResize ;{
						If *Data\Drag_Direction = #Misc_ResizeFromFirst
							SortMediaBlocks(*Data\State_SelectedMediaBlocks(), @CompareAscending())
						Else
							SortMediaBlocks(*Data\State_SelectedMediaBlocks(), @CompareDescending())
						EndIf
						
						ForEach *Data\State_SelectedMediaBlocks()
							*Data\State_SelectedMediaBlocks()\State = #State_Hot
							ResizeMB(*Data.GadgetData, *Data\State_SelectedMediaBlocks(), *Data\Drag_Offset, *Data\Drag_Direction)
						Next
						
						*Data\State_UserAction = #Action_Hover
						Redraw(Gadget)
						;}
					Case #Action_ItemMove ;{
						CompilerIf #Func_AutoDragScroll
							*Data\Drag_Timer = #False
						CompilerEndIf
						; Reordering the list to avoid items being moved several time during a multi-items drag...
						If *Data\Drag_Offset > 0
							SortMediaBlocks(*Data\State_SelectedMediaBlocks(), @CompareDescending())
						Else
							SortMediaBlocks(*Data\State_SelectedMediaBlocks(), @CompareAscending())
						EndIf
						
						ForEach *Data\State_SelectedDataPoints()
							*Data\State_SelectedDataPoints()\State = #State_Hot
						Next
						
						ForEach *Data\State_SelectedMediaBlocks()
							*Data\State_SelectedMediaBlocks()\State = #State_Hot
							MoveMB(*Data, *Data\State_SelectedMediaBlocks(), *Data\Drag_Offset)
						Next
						
						*Data\State_UserAction = #Action_Hover
						Redraw(Gadget)
						;}
					Case #Action_ItemMoveInit, #Action_ItemResizeInit ;{
						*Data\State_UserAction = #Action_Hover
						If *Data\Drag_DeselectMB
							*Data\Drag_DeselectMB = #False
							*Data\Draw_WarmMediaBlock\State = #State_Warm
							ChangeCurrentElement(*Data\State_SelectedMediaBlocks(), *Data\Draw_WarmMediaBlock\StateListElement)
							DeleteElement(*Data\State_SelectedMediaBlocks())
							ChangeCurrentElement(*Data\Content_DisplayedLines(), *Data\Draw_WarmMediaBlock\Line\DisplayListAdress)
							StartLocalRedrawing
							DrawLine(*Data)
							StopVectorDrawing()
						ElseIf *Data\Drag_KeepMB
							ForEach *Data\State_SelectedDataPoints()
								*Data\State_SelectedDataPoints()\State = #State_Cold
								DeleteElement(*Data\State_SelectedDataPoints())
							Next
							
							ForEach *Data\State_SelectedMediaBlocks()
								*Data\State_SelectedMediaBlocks()\State = #State_Cold
								DeleteElement(*Data\State_SelectedMediaBlocks())
							Next
							
							*Data\Draw_WarmMediaBlock\State = #State_Hot
							*Data\Draw_WarmMediaBlock\StateListElement = AddElement(*Data\State_SelectedMediaBlocks())
							*Data\State_SelectedMediaBlocks() = *Data\Draw_WarmMediaBlock
							
							Redraw(Gadget)
							*Data\Drag_KeepMB = #False
						EndIf
						;}
					Case #Action_PlayerMove;{
						*Data\Player_Position = Min(max(*Data\Player_Position + *Data\Drag_Offset, #Style_Body_ColumnMargin), *Data\Content_Duration - #Style_Body_ColumnMargin)
						*Data\State_UserAction = #Action_Hover
						SetGadgetAttribute(Gadget, #PB_Canvas_Cursor, #PB_Cursor_Default)
						;}
				EndSelect
				;}
			Case #PB_EventType_MouseWheel;{
				If (GetGadgetAttribute(Gadget, #PB_Canvas_Modifiers) & #PB_Canvas_Control)
					If GetGadgetAttribute(Gadget, #PB_Canvas_WheelDelta) = 1
						If *Data\Meas_Column_Width < #Style_Body_MaximumColumnWidth
							*Data\Meas_Column_Width + 1
						EndIf
					Else
						If *Data\Meas_Column_Width > 1
							*Data\Meas_Column_Width - 1
						EndIf
					EndIf
					Refit(Gadget)
					Redraw(Gadget)
				Else
					SetGadgetState(*Data\Comp_VScrollBar, GetGadgetState(*Data\Comp_VScrollBar) - GetGadgetAttribute(Gadget, #PB_Canvas_WheelDelta))
					If ScrollVertical(Gadget)
						Redraw(Gadget)
					EndIf
				EndIf
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
	
	CompilerIf #Func_AutoDragScroll
		Procedure HandlerTimerWindow()
			Protected Window = EventWindow(), *Data.GadgetData = GetWindowData(Window), Column
			
			If EventTimer() = #Misc_DragTimer
				If *Data\Drag_Timer > 0
					If *Data\State_HorizontalScroll < *Data\Content_Duration - *Data\Meas_Column_Visible
						SetGadgetState(*Data\Comp_HScrollbar, GetGadgetState(*Data\Comp_HScrollbar) + 1)
						If ScrollHorizontal(*Data\Comp_Canvas)
							*Data\Drag_ScrollOffset + 1
							*Data\Drag_Offset + 1
							If *Data\State_UserAction = #Action_PlayerMove
								Column = Min(max(*Data\Player_Position + *Data\Drag_Offset, #Style_Body_ColumnMargin), *Data\Content_Duration - #Style_Body_ColumnMargin)
								*Data\PlayerX = (Column - *Data\State_HorizontalScroll) * *Data\Meas_Column_Width + *Data\Meas_List_Width - #Style_Player_TopOffset - 0.5
							EndIf
							Redraw(*Data\Comp_Canvas)
						EndIf
					Else
						*Data\Drag_Timer = #False
						*Data\Drag_Origin - (*Data\Drag_ScrollOffset * *Data\Meas_Column_Width)
						*Data\Drag_ScrollOffset = 0
						RemoveWindowTimer(Window, #Misc_DragTimer)
					EndIf
				ElseIf *Data\Drag_Timer < 0
					If *Data\State_HorizontalScroll
						SetGadgetState(*Data\Comp_HScrollbar, GetGadgetState(*Data\Comp_HScrollbar) - 1)
						If ScrollHorizontal(*Data\Comp_Canvas)
							*Data\Drag_ScrollOffset - 1
							*Data\Drag_Offset - 1
							If *Data\State_UserAction = #Action_PlayerMove
								Column = Min(max(*Data\Player_Position + *Data\Drag_Offset, #Style_Body_ColumnMargin), *Data\Content_Duration - #Style_Body_ColumnMargin)
								*Data\PlayerX = (Column - *Data\State_HorizontalScroll) * *Data\Meas_Column_Width + *Data\Meas_List_Width - #Style_Player_TopOffset - 0.5
							EndIf
							Redraw(*Data\Comp_Canvas)
						EndIf
					Else
						*Data\Drag_Timer = #False
						*Data\Drag_Origin - (*Data\Drag_ScrollOffset * *Data\Meas_Column_Width)
						*Data\Drag_ScrollOffset = 0
						RemoveWindowTimer(Window, #Misc_DragTimer)
					EndIf
				Else
					RemoveWindowTimer(Window, #Misc_DragTimer)
				EndIf
			EndIf
		EndProcedure
	CompilerEndIf

	; Drawing
	Procedure Redraw(Gadget)
		Protected *Data.GadgetData = GetGadgetData(Gadget)
		Protected LineLoop, LineLoopEnd, YPos, Height
		Protected ContentLoop, ContentLoopEnd
		Protected PlayerX
		
		If Not *Data\Draw_Freeze
			StartVectorDrawing(CanvasVectorOutput(Gadget))
			VectorFont(FontID(*Data\Draw_Font), *Data\Draw_FontSize)
			
			; Header
			AddPathBox(*Data\Meas_List_Width,0 , *Data\Meas_Body_Width + *Data\Meas_VScrollBar_Width, *Data\Meas_Header_Height)
			VectorSourceColor(SetAlpha($FF, *Data\Colors_Header_Back))
			FillPath()
			MovePathCursor(*Data\Meas_List_Width, *Data\Meas_Header_Height)
			AddPathLine(*Data\Meas_Body_Width, 0)
			VectorSourceColor(SetAlpha($FF, *Data\Colors_Header_Back))
			FillPath()
			
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
			
			;Player
			If *Data\PlayerX + #Style_Player_TopWidth  > *Data\Meas_List_Width
				MovePathCursor(*Data\PlayerX, 0)
				AddPathLine(0, #Style_Player_TopSquare, #PB_Path_Relative)
				AddPathLine(#Style_Player_TopOffset - 0.5, #Style_Player_TopHeight - #Style_Player_TopSquare, #PB_Path_Relative)
				AddPathLine(#Style_Player_Width, 0, #PB_Path_Relative)
				AddPathLine(#Style_Player_TopOffset - 0.5, - (#Style_Player_TopHeight - #Style_Player_TopSquare), #PB_Path_Relative)
				AddPathLine(0, - #Style_Player_TopSquare, #PB_Path_Relative)
				ClosePath()
				MovePathCursor(#Style_Player_TopOffset - 0.5, #Style_Player_TopHeight, #PB_Path_Relative)
				AddPathBox(0,0, #Style_Player_Width, VectorOutputHeight(), #PB_Path_Relative)
				VectorSourceColor(SetAlpha($FF, FixColor(#Color_Player)))
				FillPath()
			EndIf
			
			; Content
			LineLoopEnd = min(*Data\Meas_Line_Visible, *Data\Meas_Line_Total - *Data\State_VerticalScroll)
			SelectElement(*Data\Content_DisplayedLines(), *Data\State_VerticalScroll)
			
			For LineLoop = 0 To LineLoopEnd
				DrawLine(*Data)
				NextElement(*Data\Content_DisplayedLines())
			Next
						
			StopVectorDrawing()
		EndIf
	EndProcedure
	
	Procedure DrawLine(*Data.GadgetData)
		Protected Index = ListIndex(*Data\Content_DisplayedLines()) - *Data\State_VerticalScroll, ContentLoop, ContentLoopEnd, YPos = *Data\Meas_Header_Height + Index * #Style_Line_Height
		Protected DragFirstBlock, DragLastBlock
		; Body
		If (Index + *Data\State_VerticalScroll) % 2 Or *Data\Content_DisplayedLines()\State
			VectorSourceColor(SetAlpha($FF,*Data\Colors_Body_AltBack))
		Else
			VectorSourceColor(SetAlpha($FF,*Data\Colors_Body_Back))
		EndIf
		AddPathBox(*Data\Meas_List_Width, YPos, *Data\Meas_Body_Width, #Style_Line_Height)
		If *Data\Content_DisplayedLines()\State
			FillPath(#PB_Path_Preserve)
			VectorSourceColor(SetAlpha(*Data\Colors_List_FillBlending(*Data\Content_DisplayedLines()\State),*Data\Colors_List_Front))
			FillPath()
		EndIf
		FillPath()
		
		ContentLoopEnd = *Data\State_HorizontalScroll + *Data\Meas_Column_Visible
		
		For ContentLoop = max(0, *Data\State_HorizontalScroll - 1) To ContentLoopEnd
			If *Data\Content_DisplayedLines()\Mediablocks(ContentLoop)
				DrawMediaBlock(*Data, YPos, *Data\Content_DisplayedLines()\Mediablocks(ContentLoop))
				ContentLoop = *Data\Content_DisplayedLines()\Mediablocks(ContentLoop)\LastBlock
			ElseIf *Data\Meas_Column_Width > #Style_Column_MinimumDisplaySize
				If *Data\Content_DisplayedLines()\DataPoints(ContentLoop)
					DrawDataPoint(*Data, 0, YPos)
				EndIf
			EndIf
		Next
		
		; Draw the scroll and resize effect
		If *Data\State_UserAction = #Action_ItemMove
			ForEach *Data\State_SelectedMediaBlocks()
				If *Data\State_SelectedMediaBlocks()\Line = *Data\Content_DisplayedLines()
					
					DragFirstBlock = *Data\State_SelectedMediaBlocks()\FirstBlock + *Data\Drag_Offset
					If DragFirstBlock < #Style_Body_ColumnMargin
						DragFirstBlock = #Style_Body_ColumnMargin
					EndIf
					
					DragLastBlock = DragFirstBlock + (*Data\State_SelectedMediaBlocks()\LastBlock - *Data\State_SelectedMediaBlocks()\FirstBlock)
					If DragLastBlock > *Data\Content_Duration - #Style_Body_ColumnMargin
						DragLastBlock = *Data\Content_Duration - #Style_Body_ColumnMargin
						DragFirstBlock = DragLastBlock - (*Data\State_SelectedMediaBlocks()\LastBlock - *Data\State_SelectedMediaBlocks()\FirstBlock)
					EndIf
					
					AddPathMediaBlock((DragFirstBlock - *Data\State_HorizontalScroll) * *Data\Meas_Column_Width - 1  + *Data\Meas_List_Width,
					                  YPos + #Style_MediaBlock_Margin - 1,
					                  (DragLastBlock - DragFirstBlock + 1) * *Data\Meas_Column_Width + 2,
					                  #Style_MediaBlock_Height + 2, #Style_Body_DefaultColumnWidth)
					VectorSourceColor(SetAlpha($FF, $F0F0F0))
					StrokePath(2)
				EndIf
			Next
		ElseIf *Data\State_UserAction = #Action_ItemResize
			ForEach *Data\State_SelectedMediaBlocks()
				If *Data\State_SelectedMediaBlocks()\Line = *Data\Content_DisplayedLines()
					
					DragFirstBlock = *Data\State_SelectedMediaBlocks()\FirstBlock + Bool(*Data\Drag_Direction = #Misc_ResizeFromFirst) * *Data\Drag_Offset
					If DragFirstBlock < #Style_Body_ColumnMargin
						DragFirstBlock = #Style_Body_ColumnMargin
					ElseIf DragFirstBlock >= *Data\State_SelectedMediaBlocks()\LastBlock
						DragFirstBlock = *Data\State_SelectedMediaBlocks()\LastBlock - 1
					EndIf
					
					DragLastBlock = *Data\State_SelectedMediaBlocks()\LastBlock + Bool(*Data\Drag_Direction = #Misc_ResizeFromLast) * *Data\Drag_Offset
					If DragLastBlock > *Data\Content_Duration - #Style_Body_ColumnMargin
						DragLastBlock = *Data\Content_Duration - #Style_Body_ColumnMargin
					ElseIf DragLastBlock <=  *Data\State_SelectedMediaBlocks()\FirstBlock
						DragLastBlock = *Data\State_SelectedMediaBlocks()\FirstBlock + 1
					EndIf
					
					AddPathMediaBlock((DragFirstBlock - *Data\State_HorizontalScroll) * *Data\Meas_Column_Width - 1  + *Data\Meas_List_Width,
					                  YPos + #Style_MediaBlock_Margin - 1,
					                  (DragLastBlock - DragFirstBlock + 1) * *Data\Meas_Column_Width + 2,
					                  #Style_MediaBlock_Height + 2, #Style_Body_DefaultColumnWidth)
					VectorSourceColor(SetAlpha($FF, $F0F0F0))
					StrokePath(2)
				EndIf
			Next
		EndIf
		
		; PLayer
		If *Data\PlayerX + #Style_Player_TopWidth > *Data\Meas_List_Width 
			MovePathCursor(*Data\PlayerX + #Style_Player_TopOffset - 0.5, YPos)
			AddPathBox(0,0, #Style_Player_Width, #Style_Line_Height, #PB_Path_Relative)
			VectorSourceColor(SetAlpha($FF, FixColor(#Color_Player)))
			FillPath()
		EndIf
		
		; List
		AddPathBox(0, YPos , *Data\Meas_List_Width, #Style_Line_Height)
		VectorSourceColor(SetAlpha($FF, *Data\Colors_List_Back))
		If *Data\Content_DisplayedLines()\State
			FillPath(#PB_Path_Preserve)
			VectorSourceColor(SetAlpha(*Data\Colors_List_FillBlending(*Data\Content_DisplayedLines()\State),*Data\Colors_List_Front))
		EndIf
		FillPath()

		
		If *Data\Content_DisplayedLines()\Fold
			If Index = *Data\Draw_WarmToggle
				If *Data\Content_DisplayedLines()\State = #State_Cold
					VectorSourceColor(SetAlpha(*Data\Colors_List_FillBlending(#State_Hot),*Data\Colors_List_Front))
				Else
					VectorSourceColor(SetAlpha($FF,*Data\Colors_List_Back))
				EndIf
				MaterialVector::AddPathRoundedBox(*Data\Content_DisplayedLines()\HOffset - 5, YPos + #Style_List_FoldOffset - 5, #Style_List_FoldSize + 10, #Style_List_FoldSize + 10, 4)
				FillPath()
				MaterialVector::Draw(MaterialVector::#Chevron, *Data\Content_DisplayedLines()\HOffset,
				                     YPos + #Style_List_FoldOffset,
				                     #Style_List_FoldSize,
				                     SetAlpha(#Color_Blending_Front_Hot ,*Data\Colors_List_Front), 0,
				                     MaterialVector::#style_rotate_90 * *Data\Content_DisplayedLines()\Fold)
			Else
				MaterialVector::Draw(MaterialVector::#Chevron, *Data\Content_DisplayedLines()\HOffset,
				                     YPos + #Style_List_FoldOffset,
				                     #Style_List_FoldSize,
				                     SetAlpha(#Color_Blending_Front_Warm ,*Data\Colors_List_Front), 0,
				                     MaterialVector::#style_rotate_90 * *Data\Content_DisplayedLines()\Fold)
			EndIf
			MovePathCursor(*Data\Content_DisplayedLines()\HOffset + #Style_List_FoldIconOffset, YPos + #Style_List_TextVOffset)
		Else
			MovePathCursor(*Data\Content_DisplayedLines()\HOffset, YPos + #Style_List_TextVOffset)
		EndIf
		VectorSourceColor(SetAlpha(#Color_Blending_Front_Warm ,*Data\Colors_List_Front))
		DrawVectorText(*Data\Content_DisplayedLines()\Text)
	EndProcedure
	
	Procedure DrawMediaBlock(*Data.GadgetData, YPos, *Block.Mediablock)
		Protected Start, Finish, FirstBlock, LastBlock, loop, CompleteBlock = #True, DragFirstBlock, DragLastBlock
		
		Start = (*Block\FirstBlock - *Data\State_HorizontalScroll) * *Data\Meas_Column_Width
		Finish = (*Block\LastBlock - *Block\FirstBlock + 1) * *Data\Meas_Column_Width 
		
		If Finish + Start > (*Data\State_HorizontalScroll + *Data\Meas_Column_Visible) * *Data\Meas_Column_Width
			LastBlock = *Data\State_HorizontalScroll + *Data\Meas_Column_Visible
			Finish = (LastBlock - *Block\FirstBlock + 1) * *Data\Meas_Column_Width
		Else
			LastBlock = *Block\LastBlock
		EndIf
		
		If Start < -#Style_Body_DefaultColumnWidth
			FirstBlock = *Data\State_HorizontalScroll
			Start = *Data\Meas_List_Width - 1
			Finish = (LastBlock - FirstBlock + 1) * *Data\Meas_Column_Width + 1
			CompleteBlock = #False
		Else
			Start + *Data\Meas_List_Width
			FirstBlock = *Block\FirstBlock
		EndIf
		
		If *Block\State = #State_Hot
			If CompleteBlock
				AddPathMediaBlock(Start - 1, YPos + #Style_MediaBlock_Margin - 1, Finish + 2, #Style_MediaBlock_Height + 2, #Style_Body_DefaultColumnWidth)
			Else
				AddPathBox(Start - 1, YPos + #Style_MediaBlock_Margin - 1, Finish + 2, #Style_MediaBlock_Height + 2)
			EndIf
			VectorSourceColor(SetAlpha($FF, $F0F0F0))
			StrokePath(3)
		EndIf
		
		If CompleteBlock
			AddPathMediaBlock(Start, YPos + #Style_MediaBlock_Margin, Finish, #Style_MediaBlock_Height, #Style_Body_DefaultColumnWidth)
		Else
			AddPathBox(Start, YPos + #Style_MediaBlock_Margin, Finish, #Style_MediaBlock_Height)
		EndIf
		
		VectorSourceColor( SetAlpha(*Data\Colors_Body_FillBlending(*Block\State), *Data\Content_DisplayedLines()\Color))
		FillPath(#PB_Path_Preserve)
		VectorSourceColor( SetAlpha(*Data\Colors_Body_StrokeBlending(*Block\State), *Data\Content_DisplayedLines()\Color))
		StrokePath(2)
		
		If *Data\Meas_Column_Width > #Style_Column_MinimumDisplaySize
			For loop = FirstBlock To LastBlock
				If *Data\Content_DisplayedLines()\DataPoints(loop)
					
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
			*Data\PlayerX = (*Data\Player_Position - *Data\State_HorizontalScroll) * *Data\Meas_Column_Width + *Data\Meas_List_Width - #Style_Player_TopOffset - 0.5
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
			SetGadgetAttribute(*Data\Comp_HScrollBar, #PB_ScrollBar_Maximum, *Data\Content_Duration - 1)
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
		
		*Data\PlayerX = (*Data\Player_Position - *Data\State_HorizontalScroll) * *Data\Meas_Column_Width + *Data\Meas_List_Width - #Style_Player_TopOffset - 0.5
		
	EndProcedure
	
	Procedure RecurciveDelete(*Data.GadgetData, *Line.Line)
		
	EndProcedure
	
	Procedure ResizeMB(*Data.GadgetData, *Block.MediaBlock, Offset, Direction)
		Protected TargetFirstBlock, TargetLastBlock, Loop, Success, TargetOffset, ResultOffset, TempBlock
		
		For Loop = *Block\FirstBlock To *Block\LastBlock
			*Block\Line\MediaBlocks(Loop) = 0
		Next
		
		If Direction = #Misc_ResizeFromFirst
			TargetFirstBlock = Min(max(*Block\FirstBlock + Offset, #Style_Body_ColumnMargin), *Block\LastBlock - 1)
			TargetLastBlock = *Block\LastBlock
			If Offset < 0
				For Loop = TargetFirstBlock To *Block\FirstBlock
					If *Block\Line\MediaBlocks(Loop)
						TempBlock = *Block\Line\MediaBlocks(Loop)\LastBlock
						TargetOffset = TargetFirstBlock - *Block\Line\MediaBlocks(Loop)\LastBlock - 1
						ResultOffset = MoveMB(*Data, *Block\Line\MediaBlocks(Loop), TargetOffset, #True)
						If TargetOffset <> ResultOffset
							TargetFirstBlock - (TargetOffset - ResultOffset)
						EndIf
						Loop = TempBlock
					EndIf
				Next
			EndIf
		Else
			TargetFirstBlock = *Block\FirstBlock
			TargetLastBlock = max(Min(*Block\LastBlock + Offset, *Data\Content_Duration - #Style_Body_ColumnMargin), *Block\FirstBlock + 1)
			If Offset > 0
				For Loop = TargetLastBlock To *Block\LastBlock Step -1
					If *Block\Line\MediaBlocks(Loop)
						TempBlock = *Block\Line\MediaBlocks(Loop)\FirstBlock
						TargetOffset = TargetLastBlock - *Block\Line\MediaBlocks(Loop)\FirstBlock + 1
						ResultOffset = MoveMB(*Data, *Block\Line\MediaBlocks(Loop), TargetOffset, #True)
						If TargetOffset <> ResultOffset
							TargetFirstBlock - (TargetOffset - ResultOffset)
						EndIf
						Loop = TempBlock
					EndIf
				Next
			EndIf
		EndIf
		
		*Block\FirstBlock = TargetFirstBlock
		*Block\LastBlock = TargetLastBlock
		
		For Loop = *Block\FirstBlock To *Block\LastBlock
			*Block\Line\MediaBlocks(Loop) = *Block
		Next
	EndProcedure
	
	Procedure MoveMB(*Data.GadgetData, *Block.MediaBlock, Offset, ForceDirection = #False)
		Protected BlockDuration = *Block\LastBlock - *Block\FirstBlock + 1, loop
		Protected TargetFirstBlock, TargetLastBlock, TargetOffset, ResultOffset
		
		For loop = *Block\FirstBlock To *Block\LastBlock
			*Block\Line\MediaBlocks(Loop) = 0
		Next
		
		If *Block\FirstBlock + Offset < #Style_Body_ColumnMargin
			Offset = #Style_Body_ColumnMargin - *Block\FirstBlock 
		EndIf
		
		If *Block\LastBlock + Offset > *Data\Content_Duration - #Style_Body_ColumnMargin
			Offset - ((*Block\LastBlock + Offset) - (*Data\Content_Duration - #Style_Body_ColumnMargin))
		EndIf
		 
		TargetFirstBlock =  *Block\FirstBlock + Offset
		TargetLastBlock = *Block\LastBlock + Offset
		
		If Offset > 0
			For loop = TargetLastBlock To TargetFirstBlock Step -1 ; Can't use a variable as a step?
				If *Block\Line\MediaBlocks(Loop)
					; This is used to determine in which direction the block should be moved. I'm expecting it to fail in some edge cases but have no time to test it. If it's the case, set ForceDirection's default value to #true
					If ForceDirection 
						TargetOffset = TargetLastBlock - *Block\Line\MediaBlocks(Loop)\FirstBlock +1
					Else
						If TargetFirstBlock < (*Block\Line\MediaBlocks(Loop)\FirstBlock + *Block\Line\MediaBlocks(Loop)\LastBlock) * 0.5 
							TargetOffset = TargetLastBlock - *Block\Line\MediaBlocks(Loop)\FirstBlock + 1
						Else
							TargetOffset = TargetFirstBlock - *Block\Line\MediaBlocks(Loop)\LastBlock - 1
						EndIf
					EndIf
					
					ResultOffset = MoveMB(*Data, *Block\Line\MediaBlocks(Loop), TargetOffset, ForceDirection)
					
					If Not ResultOffset = TargetOffset
						Offset = Offset - (TargetOffset - ResultOffset)
						TargetFirstBlock =  *Block\FirstBlock + Offset
						TargetLastBlock = *Block\LastBlock + Offset
					EndIf
				EndIf
			Next
		Else
			For loop = TargetFirstBlock To TargetLastBlock
				If *Block\Line\MediaBlocks(Loop)
					If ForceDirection 
						TargetOffset = TargetFirstBlock - *Block\Line\MediaBlocks(Loop)\LastBlock - 1
					Else
						If TargetFirstBlock < (*Block\Line\MediaBlocks(Loop)\FirstBlock + *Block\Line\MediaBlocks(Loop)\LastBlock) * 0.5 
							TargetOffset = TargetLastBlock - *Block\Line\MediaBlocks(Loop)\FirstBlock + 1
						Else
							TargetOffset = TargetFirstBlock - *Block\Line\MediaBlocks(Loop)\LastBlock - 1
						EndIf
					EndIf
					ResultOffset = MoveMB(*Data, *Block\Line\MediaBlocks(Loop), TargetOffset, ForceDirection)
					
					If Not ResultOffset = TargetOffset
						Offset = Offset - (TargetOffset - ResultOffset)
						TargetFirstBlock =  *Block\FirstBlock + Offset
						TargetLastBlock = *Block\LastBlock + Offset
					EndIf
				EndIf
			Next
		EndIf
		
		*Block\FirstBlock = TargetFirstBlock
		*Block\LastBlock =  TargetLastBlock
		
		For loop = *Block\FirstBlock To *Block\LastBlock
			*Block\Line\MediaBlocks(Loop) = *Block
		Next
		
		ProcedureReturn Offset
	EndProcedure
	
	Procedure RecurciveFold(*Data.GadgetData, *Line.Line)
		Protected Result
		
		ForEach *Line\Content_Lines()
			NextElement(*Data\Content_DisplayedLines())
			
			If *Line\Content_Lines()\Fold = #Unfolded
				Result + RecurciveFold(*Data.GadgetData, *Line\Content_Lines())
			EndIf
			
			DeleteElement(*Data\Content_DisplayedLines())
			*Line\Content_Lines()\DisplayListAdress = 0
			Result + 1
		Next
		
		ProcedureReturn Result
	EndProcedure
	
	Procedure RecurciveUnFold(*Data.GadgetData, *Line.Line)
		Protected Result
		
		ForEach *Line\Content_Lines()
			AddElement(*Data\Content_DisplayedLines())
			*Data\Content_DisplayedLines() = *Line\Content_Lines()
			*Line\Content_Lines()\DisplayListAdress= @*Data\Content_DisplayedLines()
			
			If *Line\Content_Lines()\Fold = #Unfolded
				Result + RecurciveUnFold(*Data.GadgetData, *Line\Content_Lines())
			EndIf
			Result + 1
		Next
		
		ProcedureReturn Result
	EndProcedure
	
	Procedure ToggleFold(Gadget, Item)
		Protected *Data.GadgetData = GetGadgetData(Gadget), *Line.Line, Index, Offset
		
		SelectElement(*Data\Content_DisplayedLines(), Item)
		Index = ListIndex(*Data\Content_DisplayedLines())
		
		*Line.Line = *Data\Content_DisplayedLines()
		
		If *Data\Content_DisplayedLines()\Fold = #Folded
			*Data\Content_DisplayedLines()\Fold = #Unfolded
			Offset = RecurciveUnFold(*Data.GadgetData, *Data\Content_DisplayedLines())
			
			If *Data\State_SelectedLine > Index
				*Data\State_SelectedLine + Offset
			EndIf
			
		Else
			*Data\Content_DisplayedLines()\Fold = #Folded
			Offset = RecurciveFold(*Data.GadgetData, *Data\Content_DisplayedLines())
			
			If *Data\State_SelectedLine > Index + Offset
				*Data\State_SelectedLine - Offset
			ElseIf *Data\State_SelectedLine > Index
				SelectElement(*Data\Content_DisplayedLines(), *Data\State_SelectedLine)
				*Data\Content_DisplayedLines()\State = #State_Cold
				*Data\State_SelectedLine = -1
			EndIf
			
		EndIf
		
		*Data\Meas_Line_Total = ListSize(*Data\Content_DisplayedLines()) -1
		
		Refit(Gadget)
		Redraw(Gadget)
	EndProcedure
	
	Procedure CompareAscending(*a.MBAdress, *b.MBAdress)
		ProcedureReturn *a\Object\FirstBlock - *b\Object\FirstBlock
	EndProcedure
	
	Procedure CompareDescending(*a.MBAdress, *b.MBAdress)
		ProcedureReturn *b\Object\FirstBlock - *a\Object\FirstBlock
	EndProcedure
	;}
EndModule













































; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 1495
; FirstLine = 398
; Folding = 8X8vAEjEBAAuAA+
; EnableXP