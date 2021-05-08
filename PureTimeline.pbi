CompilerIf Not Defined(MaterialVector, #PB_Module)
	IncludeFile "MaterialVector\MaterialVector.pbi"
CompilerEndIf

CompilerIf Not Defined(CanvasButton, #PB_Module)
	IncludeFile "CanvasButton\CanvasButton.pbi"
CompilerEndIf

CompilerIf Not Defined(TextBox, #PB_Module)
	IncludeFile "Textbox\Textbox.pbi"
CompilerEndIf

CompilerIf Not Defined(ScrollBar, #PB_Module)
	IncludeFile "MaterialScrollBar\ScrollBar.pbi"
CompilerEndIf

CompilerIf Not Defined(SortLinkedList, #PB_Module) ; Couldn't figure how to sort the selected lists with the built in structured list sort, so I'll use this one : https://www.purebasic.fr/english/viewtopic.php?f=12&t=72352 
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

CompilerIf Not Defined(GadgetTimer, #PB_Module)
	IncludeFile "GadgetTimer\GadgetTimer.pbi"
CompilerEndIf

CompilerIf Not Defined(TaskList, #PB_Module)
	IncludeFile "TaskList\TaskList.pbi"
CompilerEndIf

DeclareModule PureTL
	; Public variables, structures, constants...
	EnumerationBinary ;Gadget Flags
		#Default = 0
	EndEnumeration
	
	Enumeration ; Line Flags
		#Line_Default = 0
		#Line_Folder
	EndEnumeration
	
	Enumeration ; Media block flags
		#MB_Default = 0
		#MB_FixedSize
		#MB_FreeSize
	EndEnumeration
	
	; Public procedures declaration
	Declare Gadget(Gadget, X, Y, Width, Height, Flags = #Default)
	Declare Free(Gadget)
	
	; State
	Declare GetActiveLine(Gadget)
	Declare SetActiveLine(Gadget, LineID)
	Declare Freeze(Gadget, State)
	Declare SetTaskList(Gadget, TaskList)
	
	; Line stuff
	Declare AddLine(Gadget, Position, Text.s, Parent = 0, Flags = #Line_Default)
	Declare RemoveLine(Gadget, Position, Parent = 0)
	
	Declare GetLineID(Gadget, Position, Parent = 0)
	Declare GetLineText(Gadget, LineID)
	
	Declare SetLineText(Gadget, LineID, Text.s)
	
	; Media block
	
	
	; Data point
	
	
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
	Enumeration ; State
		#Cold
		#Warm
		#Hot
	EndEnumeration
	
	Enumeration ;Fold
		#NoFold
		#Folded
		#Unfolded
	EndEnumeration
	
	Enumeration ;User Action
		#Action_Hover = 0
		#Action_List_InitDrag
		#Action_List_Drag
		#Action_List_Rename
	EndEnumeration
	
	;Tasks
	#CreateLine = "CreateLine"
	#DeleteLine = "DeleteLine"
	#SwitchLineOrder= "SwitchLineOrder"
	#RenameLine = "RenameLine"
	
	Structure MediaBlock
		UUID.s
	EndStructure
	
	Structure DataPoint
		UUID.s
	EndStructure
	
	Structure Line
		UUID.s
		Type.b
		Name.s
		Folded.i
		VerticalOffset.i
		HorizontalOfsset.i
		Flags.i
		State.i
		Icon.s
		
		*Parent.Line
		
		List *Childrens.Line()
		
		*DisplayListAdress
		*ParentListAdress
		
		Array *MediaBlocks.MediaBlock(1)
		Array *DataPoints.DataPoint(1)
	EndStructure
	
	Structure GadgetData
		; Components
		Comp_Container.i
		Comp_Body.i
		Comp_List.i
		Comp_VScrollBar.i
		Comp_HScrollBar.i
		Comp_Rename.i
		
		Comp_Button_AddFolder.i
		Comp_Button_AddLine.i
		Comp_Button_Remove.i
		Comp_Button_Up.i
		Comp_Button_Down.i
		
		; State
		State_TaskList.i
		State_ActiveLine.i
		State_HoverLine.i
		State_HoverFoldButton.i
		State_Duration.i
		State_UserAction.i
		
		List *State_DataPoints.DataPoint()
		List *State_MediaBlocks.MediaBlock()
		
		; Action
		Action_Drag_OriginX.i
		Action_Drag_OriginY.i
		Action_Drag_Image.i
		Action_Drag_Window.i
		*Action_Drag_Line.Line
		Action_Drag_Position.i
		
		; Measurement
		Meas_List_Height.i
		Meas_List_Width.i
		
		Meas_Body_Height.i
		Meas_Body_Width.i
		
		Meas_Displayed_Lines.i
		Meas_Displayed_Columns.i
		
		Meas_TL_ColumnWidth.i
		
		Meas_VPosition.i
		Meas_HPosition.i
		
		; Colors
		Color_List_Back_Alternate.l[3]
		Color_List_Back.l[3]
		Color_List_Front.l[3]
		Color_General_Line.l
		
		Color_Primary_Back.l[3]
		Color_Primary_Front.l[3]
		
		Color_Danger_Back.l[3]
		Color_Danger_Front.l[3]
		
		; Content
		List *Cont_Line_List.Line()
		List *Cont_Displayed_List.Line()
		Cont_Displayed_Line.i
		
		Map Lines.Line(2048)
		Map MediaBlocks.MediaBlock(2048)
		Map DataPoints.DataPoint(2048)
	EndStructure
	
	Structure Task
		XMLID.i
		XML.s
	EndStructure
		
	;{ Default Setting
	#Default_Duration = 300
	;}
	
	;{ Style
	
	; Size
	#Size_TL_Height = 58
	#Size_TL_DefaultColumnWidth = 6
	#Size_TL_MaxColumnWidth = 15
	#Size_TL_MinColumnWidth = 1
	
	#Size_List_MinimumWidth = 230
	#Size_List_Text_VerticalMargin = (#Size_TL_Height - 16) / 2
	#Size_List_Text_HorizontalMargin = 30
	#Size_List_Icon_VerticalMargin = (#Size_TL_Height - 20) / 2
	#Size_List_Icon_Offset = 34
	#Size_SubItemOffset = 11
	
	#Size_Header_Height = 60
	#Size_Header_ButtonSize = 40
	#Size_Header_VerticalMargin = (#Size_Header_Height - #Size_Header_ButtonSize) / 2
	
	#Size_Line_Thick = 2
	#Size_Line_Thin = 1
	
	#Size_Scrollbar_Thickness = 12
	
	; Colors
	#Colors_List_Back_Alternate_Cold = $30364F
	#Colors_List_Back_Alternate_Warm = $2D3A5E
	#Colors_List_Back_Alternate_Hot = $334571
; 	#Colors_List_Back_Alternate_Warm = $354164
; 	#Colors_List_Back_Alternate_Hot = $3A4B76
	
	#Colors_List_Back_Cold = $272E48     
	#Colors_List_Back_Warm = $2D3A5E
	#Colors_List_Back_Hot = $334571
	
	#Colors_List_Front_Cold = $8A99B5
; 	#Colors_List_Front_Warm = $8397BC
; 	#Colors_List_Front_Hot = $7E96C3
	#Colors_List_Front_Warm = $8A99B5
	#Colors_List_Front_Hot = $8A99B5
	
	#Color_Primary_Back_Cold = $272E48
	#Color_Primary_Back_Warm = $719DF0
	#Color_Primary_Back_Hot  = $437DEC
	
	#Color_Primary_Front_Cold = $5A8DEE
	#Color_Primary_Front_Warm = $FFFFFF
	#Color_Primary_Front_Hot  = $FFFFFF
	
	#Color_Danger_Back_Cold = $272E48
	#Color_Danger_Back_Warm = $FF7575
	#Color_Danger_Back_Hot  = $FF4243
	
	#Color_Danger_Front_Cold = $FF5B5C
	#Color_Danger_Front_Warm = $FFFFFF
	#Color_Danger_Front_Hot  = $FFFFFF
	
	#Color_Scrollbar_Back = $212639
	#Color_Scrollbar_FrontCold = $787B86
	#Color_Scrollbar_FrontWarm = $656873
	#Color_Scrollbar_FrontHot = $434651
	
	#Colors_General_Line = $1A233A
	
	; Fonts
	Global FontBold = FontID(LoadFont(#PB_Any, "Rubik Medium", 12, #PB_Font_HighQuality))
	Global Font = FontID(LoadFont(#PB_Any, "Rubik", 12, #PB_Font_HighQuality))
	Global IconSolid = FontID(LoadFont(#PB_Any, "Font Awesome 5 Pro Solid", 16, #PB_Font_HighQuality))
	Global Icon = FontID(LoadFont(#PB_Any, "Font Awesome 5 Pro Regular", 16, #PB_Font_HighQuality))
	
	; FontAwesome shortcut
	#FontAwesome_Folder_Open = ""
	#FontAwesome_Folder = ""
	#FontAwesome_Chevron_Right = ""
	#FontAwesome_Chevron_Down = ""
	
	; Misc
	
	;}
	
	;{ Corners
	Procedure ROTATE_90(image)  ; There is a bug with vector rotation in 5.73, so I grabbed that from here : https://www.purebasic.fr/english/viewtopic.php?p=437174#p437174
		Protected a,b,c,e,f,h,s,w,x,y,ym,xm,tempImg,depth, Result
		
		If IsImage(image) = 0 : ProcedureReturn 0 : EndIf
		
		StartDrawing(ImageOutput(image))
		w = OutputWidth()
		h = OutputHeight()
		f = DrawingBufferPixelFormat() & $7F
		StopDrawing()
		
		If f = #PB_PixelFormat_32Bits_RGB Or f = #PB_PixelFormat_32Bits_BGR
			depth = 32
		ElseIf f = #PB_PixelFormat_24Bits_RGB Or f = #PB_PixelFormat_24Bits_BGR
			depth = 24
		Else
			ProcedureReturn 0
		EndIf
		
		If w > h : s = w : Else : s = h : EndIf ; find the largest dimension
		
		tempImg = CreateImage(#PB_Any,s,s,depth) ; make a square working area
		
		StartDrawing(ImageOutput(tempImg))
		If depth = 32 : DrawingMode(#PB_2DDrawing_AllChannels) : EndIf
		
		DrawImage(ImageID(image),0,0)
		
		ym = s/2-1 ; max y loop value
		xm = s/2-(s!1&1) ; max x value, subtract 1 if 's' is even
		s-1
		
		For y = 0 To ym
			For x = 0 To xm
				e = Point(x,y)
				a = s-x : Plot(x,y,Point(y,a))
				b = s-y : Plot(y,a,Point(a,b))
				c = s-a : Plot(a,b,Point(b,c))
				Plot(b,c,e)
			Next x
		Next y
		
		StopDrawing()
		
		Result = GrabImage(tempImg,#PB_Any,s-h+1,0,h,w) ; right
		
		FreeImage(tempImg)
		ProcedureReturn Result
	EndProcedure
	
	Global CornerUL = CatchImage(#PB_Any, ?Corner)
	Global CornerUR = ROTATE_90(CornerUL)
	Global CornerDR = ROTATE_90(CornerUR)
	Global CornerDL = CreateImage(#PB_Any, 3, 3)
	StartDrawing(ImageOutput(CornerDL))
	Box(0, 0, 3, 3, SetAlpha($FF, FixColor(#Colors_List_Back_Cold)))
	DrawAlphaImage(ImageID(CornerUL), 0, 0)
	StopDrawing()
	FreeImage(CornerUL) 
	CornerUL = CornerDL
	CornerDL = ROTATE_90(CornerDR)
	;}
	;}
	
	;{ Private procedures declaration
	; Non specific
	Declare Min(a, b)
	Declare Max(a, b)
	Declare.s UUID()
	
	; Line stuff
	Declare _AddLine(*GadgetData.GadgetData, Position, Text.s, *Parent.Line, Flags, UUID.s)
	Declare _RemoveLine(*GadgetData.GadgetData, Position, *Parent.Line)
	Declare Recurcive_RemoveLine(*GadgetData.GadgetData, *Line.Line, XMLNode)
	Declare RenameLine(*GadgetData.GadgetData, *Line.Line, *Task.Task = 0)
	Declare HandlerRenameString(hWnd, uMsg, wParam, lParam)
	
	; Handler
	Declare Handler_Body()
	Declare Handler_List()
	Declare Handler_Button_AddFolder()
	Declare Handler_Button_AddLine()
	Declare Handler_Button_RemoveLine()
	Declare Handler_Button_Up()
	Declare Handler_Button_Down()
	Declare Handler_HScrollBar()
	Declare Handler_VScrollBar()
	Declare Handler_UndoRedo(*Task.Task, Redo)
	
	; Redraw
	Declare Redraw(Gadget)
	
	; Misc
	Declare Refit(Gadget)
	Declare ToggleFold(Gadget)
	Declare VerticalFocus(*GadgetData.GadgetData)
	Declare HorizontalFocus(*GadgetData.GadgetData)
	;}
	
	;{ Public procedures
	Procedure Gadget(Gadget, X, Y, Width, Height, Flags = #Default)
		Protected Result = ContainerGadget(Gadget, X, Y, Width, Height, #PB_Container_BorderLess), *GadgetData.GadgetData
		Protected CanvasList = CanvasGadget(#PB_Any, 0, #Size_Header_Height, #Size_List_MinimumWidth, Height - #Size_Header_Height, #PB_Canvas_Container | #PB_Canvas_Keyboard)
		CloseGadgetList()
		Protected CanvasBody = CanvasGadget(#PB_Any, #Size_List_MinimumWidth, 0, Width - #Size_List_MinimumWidth, Height, #PB_Canvas_Container | #PB_Canvas_Keyboard)
		If Gadget = #PB_Any
			Gadget = Result
		EndIf
		
		If Result And CanvasBody And CanvasList
			*GadgetData = AllocateStructure(GadgetData)
			
			With *GadgetData
				\Comp_Body = CanvasBody
				\Comp_List = CanvasList
				
				;Measurement
				\Meas_List_Width = #Size_List_MinimumWidth
				\Meas_TL_ColumnWidth = #Size_TL_DefaultColumnWidth
				
				;Colors
				\Color_List_Back_Alternate[#Cold] = FixColor(#Colors_List_Back_Alternate_Cold)
				\Color_List_Back_Alternate[#Warm] = FixColor(#Colors_List_Back_Alternate_Warm)
				\Color_List_Back_Alternate[#Hot] = FixColor(#Colors_List_Back_Alternate_Hot)
				 
				\Color_List_Back[#Cold] = FixColor(#Colors_List_Back_Cold)
				\Color_List_Back[#Warm] = FixColor(#Colors_List_Back_Warm)
				\Color_List_Back[#Hot] = FixColor(#Colors_List_Back_Hot)
				
				\Color_List_Front[#Cold] = FixColor(#Colors_List_Front_Cold)
				\Color_List_Front[#Warm] = FixColor(#Colors_List_Front_Warm)
				\Color_List_Front[#Hot] =  FixColor(#Colors_List_Front_Hot)
				
				\Color_General_Line = FixColor(#Colors_General_Line)
				
				\Color_Primary_Back[#Cold] = FixColor(#Color_Primary_Back_Cold)
				\Color_Primary_Back[#Warm] = FixColor(#Color_Primary_Back_Warm)
				\Color_Primary_Back[#Hot] =  FixColor(#Color_Primary_Back_Hot)
				
				\Color_Primary_Front[#Cold] = FixColor(#Color_Primary_Front_Cold)
				\Color_Primary_Front[#Warm] = FixColor(#Color_Primary_Front_Warm)
				\Color_Primary_Front[#Hot] =  FixColor(#Color_Primary_Front_Hot)
				
				\Color_Danger_Back[#Cold] = FixColor(#Color_Danger_Back_Cold)
				\Color_Danger_Back[#Warm] = FixColor(#Color_Danger_Back_Warm)
				\Color_Danger_Back[#Hot] =  FixColor(#Color_Danger_Back_Hot)
				
				\Color_Danger_Front[#Cold] = FixColor(#Color_Danger_Front_Cold)
				\Color_Danger_Front[#Warm] = FixColor(#Color_Danger_Front_Warm)
				\Color_Danger_Front[#Hot] =  FixColor(#Color_Danger_Front_Hot)
				
				; State
				\State_ActiveLine = -1
				\State_HoverLine = -1
				\State_HoverFoldButton = -1
				\State_Duration = #Default_Duration
				
				; Action
				\Action_Drag_Position = -2
				
				SetGadgetData(CanvasBody, *GadgetData)
				BindGadgetEvent(CanvasBody, @Handler_Body())
				
				SetGadgetData(CanvasList, *GadgetData)
				BindGadgetEvent(CanvasList, @Handler_List())
				
				SetGadgetData(Gadget, *GadgetData)
				SetGadgetColor(Gadget, #PB_Gadget_BackColor, \Color_List_Back[#Cold])
				
				\Comp_HScrollBar = ScrollBar::Gadget(#PB_Any, 0, \Meas_Body_Height - #Size_Scrollbar_Thickness, \Meas_Body_Width, #Size_Scrollbar_Thickness, 0, \State_Duration, 10)
				HideGadget(\Comp_HScrollBar, #True)
				SetGadgetColor(\Comp_HScrollBar, #PB_Gadget_BackColor, SetAlpha($FF, \Color_List_Back[#Cold]))
				SetGadgetColor(\Comp_HScrollBar, #PB_Gadget_LineColor, SetAlpha($FF, FixColor(#Color_Scrollbar_Back)))
				SetGadgetColor(\Comp_HScrollBar, #PB_Gadget_FrontColor, SetAlpha($FF, FixColor(#Color_Scrollbar_FrontCold)))
				SetGadgetColor(\Comp_HScrollBar, ScrollBar::#Color_FrontWarm, SetAlpha($FF, FixColor(#Color_Scrollbar_FrontWarm)))
				SetGadgetColor(\Comp_HScrollBar, ScrollBar::#Color_FrontHot, SetAlpha($FF, FixColor(#Color_Scrollbar_FrontHot)))
				SetGadgetData(\Comp_HScrollBar, *GadgetData)
				BindGadgetEvent(\Comp_HScrollBar, @Handler_HScrollBar(), #PB_EventType_Change)
				
				\Comp_VScrollBar = ScrollBar::Gadget(#PB_Any, \Meas_Body_Width - #Size_Scrollbar_Thickness, #Size_Header_Height, #Size_Scrollbar_Thickness, \Meas_List_Height, 0, 9, 10, ScrollBar::#Vertical)
				HideGadget(\Comp_VScrollBar, #True)
				CloseGadgetList()
				SetGadgetColor(\Comp_VScrollBar, #PB_Gadget_BackColor, SetAlpha($FF, \Color_List_Back[#Cold]))
				SetGadgetColor(\Comp_VScrollBar, #PB_Gadget_LineColor, SetAlpha($FF, FixColor(#Color_Scrollbar_Back)))
				SetGadgetColor(\Comp_VScrollBar, #PB_Gadget_FrontColor, SetAlpha($FF, FixColor(#Color_Scrollbar_FrontCold)))
				SetGadgetColor(\Comp_VScrollBar, ScrollBar::#Color_FrontWarm, SetAlpha($FF, FixColor(#Color_Scrollbar_FrontWarm)))
				SetGadgetColor(\Comp_VScrollBar, ScrollBar::#Color_FrontHot, SetAlpha($FF, FixColor(#Color_Scrollbar_FrontHot)))
				SetGadgetData(\Comp_VScrollBar, *GadgetData)
				BindGadgetEvent(\Comp_VScrollBar, @Handler_VScrollBar(), #PB_EventType_Change)
				
				Protected Margin = ((\Meas_List_Width - 5 * #Size_Header_ButtonSize + 4)) / 2
				
				\Comp_Button_AddFolder = CanvasButton::Gadget(#PB_Any, Margin, #Size_Header_VerticalMargin, #Size_Header_ButtonSize, #Size_Header_ButtonSize, "", MaterialVector::#Folder, CanvasButton::#MaterialVector | MaterialVector::#Style_Outline | CanvasButton::#Rounded_Left | CanvasButton::#Outline)
				SetGadgetColor(\Comp_Button_AddFolder, CanvasButton::#BackColor_Cold, SetAlpha($FF ,\Color_Primary_Back[#Cold]))
				SetGadgetColor(\Comp_Button_AddFolder, CanvasButton::#BackColor_Warm, SetAlpha($FF ,\Color_Primary_Back[#Warm]))
				SetGadgetColor(\Comp_Button_AddFolder, CanvasButton::#BackColor_Hot, SetAlpha($FF ,\Color_Primary_Back[#Hot]))
				
				SetGadgetColor(\Comp_Button_AddFolder, CanvasButton::#FrontColor_Cold, SetAlpha($FF ,\Color_Primary_Front[#Cold]))
				SetGadgetColor(\Comp_Button_AddFolder, CanvasButton::#FrontColor_Warm, SetAlpha($FF ,\Color_Primary_Front[#Warm]))
				SetGadgetColor(\Comp_Button_AddFolder, CanvasButton::#FrontColor_Hot, SetAlpha($FF , \Color_Primary_Front[#Hot]))
				
				SetGadgetData(\Comp_Button_AddFolder, *GadgetData)
				BindGadgetEvent(\Comp_Button_AddFolder, @Handler_Button_AddFolder(), #PB_EventType_Change)
				
				\Comp_Button_AddLine = CanvasButton::Gadget(#PB_Any, Margin + #Size_Header_ButtonSize - 1, #Size_Header_VerticalMargin, #Size_Header_ButtonSize, #Size_Header_ButtonSize, "", MaterialVector::#Plus, CanvasButton::#MaterialVector | CanvasButton::#Outline)
				SetGadgetColor(\Comp_Button_AddLine, CanvasButton::#BackColor_Cold, SetAlpha($FF ,\Color_Primary_Back[#Cold]))
				SetGadgetColor(\Comp_Button_AddLine, CanvasButton::#BackColor_Warm, SetAlpha($FF ,\Color_Primary_Back[#Warm]))
				SetGadgetColor(\Comp_Button_AddLine, CanvasButton::#BackColor_Hot, SetAlpha($FF ,\Color_Primary_Back[#Hot]))
				
				SetGadgetColor(\Comp_Button_AddLine, CanvasButton::#FrontColor_Cold, SetAlpha($FF ,\Color_Primary_Front[#Cold]))
				SetGadgetColor(\Comp_Button_AddLine, CanvasButton::#FrontColor_Warm, SetAlpha($FF ,\Color_Primary_Front[#Warm]))
				SetGadgetColor(\Comp_Button_AddLine, CanvasButton::#FrontColor_Hot, SetAlpha($FF , \Color_Primary_Front[#Hot]))
				
				SetGadgetData(\Comp_Button_AddLine, *GadgetData)
				BindGadgetEvent(\Comp_Button_AddLine, @Handler_Button_AddLine(), #PB_EventType_Change)
				
				\Comp_Button_Remove = CanvasButton::Gadget(#PB_Any, Margin + #Size_Header_ButtonSize * 2 - 2, #Size_Header_VerticalMargin, #Size_Header_ButtonSize, #Size_Header_ButtonSize, "", MaterialVector::#Minus, CanvasButton::#MaterialVector | CanvasButton::#Outline)
				SetGadgetColor(\Comp_Button_Remove, CanvasButton::#BackColor_Cold, SetAlpha($FF ,\Color_Primary_Back[#Cold]))
				SetGadgetColor(\Comp_Button_Remove, CanvasButton::#BackColor_Warm, SetAlpha($FF ,\Color_Danger_Back[#Warm]))
				SetGadgetColor(\Comp_Button_Remove, CanvasButton::#BackColor_Hot, SetAlpha($FF ,\Color_Danger_Back[#Hot]))
				
				SetGadgetColor(\Comp_Button_Remove, CanvasButton::#FrontColor_Cold, SetAlpha($FF ,\Color_Primary_Front[#Cold]))
				SetGadgetColor(\Comp_Button_Remove, CanvasButton::#FrontColor_Warm, SetAlpha($FF ,\Color_Danger_Front[#Warm]))
				SetGadgetColor(\Comp_Button_Remove, CanvasButton::#FrontColor_Hot, SetAlpha($FF , \Color_Danger_Front[#Hot]))
				
				SetGadgetData(\Comp_Button_Remove, *GadgetData)
				BindGadgetEvent(\Comp_Button_Remove, @Handler_Button_RemoveLine(), #PB_EventType_Change)
				
				\Comp_Button_Up = CanvasButton::Gadget(#PB_Any, Margin + #Size_Header_ButtonSize * 3 - 3, #Size_Header_VerticalMargin, #Size_Header_ButtonSize, #Size_Header_ButtonSize, "", MaterialVector::#Chevron, CanvasButton::#MaterialVector | CanvasButton::#Outline)
				SetGadgetColor(\Comp_Button_Up, CanvasButton::#BackColor_Cold, SetAlpha($FF ,\Color_Primary_Back[#Cold]))
				SetGadgetColor(\Comp_Button_Up, CanvasButton::#BackColor_Warm, SetAlpha($FF ,\Color_Primary_Back[#Warm]))
				SetGadgetColor(\Comp_Button_Up, CanvasButton::#BackColor_Hot, SetAlpha($FF ,\Color_Primary_Back[#Hot]))
				
				SetGadgetColor(\Comp_Button_Up, CanvasButton::#FrontColor_Cold, SetAlpha($FF ,\Color_Primary_Front[#Cold]))
				SetGadgetColor(\Comp_Button_Up, CanvasButton::#FrontColor_Warm, SetAlpha($FF ,\Color_Primary_Front[#Warm]))
				SetGadgetColor(\Comp_Button_Up, CanvasButton::#FrontColor_Hot, SetAlpha($FF , \Color_Primary_Front[#Hot]))
				
				SetGadgetData(\Comp_Button_Up, *GadgetData)
				BindGadgetEvent(\Comp_Button_Up, @Handler_Button_Up(), #PB_EventType_Change)
				
				\Comp_Button_Down = CanvasButton::Gadget(#PB_Any, Margin + #Size_Header_ButtonSize * 4 - 4, #Size_Header_VerticalMargin, #Size_Header_ButtonSize, #Size_Header_ButtonSize, "", MaterialVector::#Chevron, CanvasButton::#MaterialVector| MaterialVector::#Style_rotate_180 | CanvasButton::#Rounded_Right | CanvasButton::#Outline)
				SetGadgetColor(\Comp_Button_Down, CanvasButton::#BackColor_Cold, SetAlpha($FF ,\Color_Primary_Back[#Cold]))
				SetGadgetColor(\Comp_Button_Down, CanvasButton::#BackColor_Warm, SetAlpha($FF ,\Color_Primary_Back[#Warm]))
				SetGadgetColor(\Comp_Button_Down, CanvasButton::#BackColor_Hot, SetAlpha($FF ,\Color_Primary_Back[#Hot]))
				
				SetGadgetColor(\Comp_Button_Down, CanvasButton::#FrontColor_Cold, SetAlpha($FF ,\Color_Primary_Front[#Cold]))
				SetGadgetColor(\Comp_Button_Down, CanvasButton::#FrontColor_Warm, SetAlpha($FF ,\Color_Primary_Front[#Warm]))
				SetGadgetColor(\Comp_Button_Down, CanvasButton::#FrontColor_Hot, SetAlpha($FF , \Color_Primary_Front[#Hot]))
				
				SetGadgetData(\Comp_Button_Down, *GadgetData)
				BindGadgetEvent(\Comp_Button_Down, @Handler_Button_Down(), #PB_EventType_Change)
				
				ImageGadget(#PB_Any, 0, 0, 3, 3, ImageID(CornerUL))
				CloseGadgetList()
				
				
				Refit(Gadget)
				Redraw(Gadget)
			EndWith
		Else
			If Result
				FreeGadget(Gadget)
			EndIf
			
			Result = 0
			
			If CanvasBody
				FreeGadget(CanvasBody)
			EndIf
			
			If CanvasList
				FreeGadget(CanvasList)
			EndIf
		EndIf
		
		ProcedureReturn Result
	EndProcedure
	
	Procedure Free(Gadget)
		
	EndProcedure
	
	; State
	Procedure GetActiveLine(Gadget)
		Protected *GadgetData.GadgetData = GetGadgetData(Gadget), *Result
		
		If *GadgetData\State_ActiveLine > -1
			SelectElement(*GadgetData\Cont_Displayed_List(), *GadgetData\State_ActiveLine)
			*Result = *GadgetData\Cont_Displayed_List()
		EndIf
		
		ProcedureReturn *Result
	EndProcedure
	
	Procedure SetActiveLine(Gadget, *Line.Line)
		Protected *GadgetData.GadgetData = GetGadgetData(Gadget)
		
		If *Line\DisplayListAdress
			If *GadgetData\State_ActiveLine > -1
				SelectElement(*GadgetData\Cont_Displayed_List(), *GadgetData\State_ActiveLine)
				*GadgetData\Cont_Displayed_List()\State = #Cold
			EndIf
			
			ChangeCurrentElement(*GadgetData\Cont_Displayed_List(), *Line\DisplayListAdress)
			*GadgetData\Cont_Displayed_List()\State = #Hot
			*GadgetData\State_ActiveLine = ListIndex(*GadgetData\Cont_Displayed_List())
			
			VerticalFocus(*GadgetData)
			Redraw(*GadgetData\Comp_Container)
		EndIf
		
	EndProcedure
	
	Procedure Freeze(Gadget, State)
		
	EndProcedure
	
	Procedure SetTaskList(Gadget, TaskList) ; Ok
		Protected *GadgetData.GadgetData = GetGadgetData(Gadget)
 		*GadgetData\State_TaskList = TaskList
	EndProcedure
	
	; Line stuff
	Procedure RemoveLine(Gadget, Position, *Parent.Line = 0)
		Protected *GadgetData.GadgetData = GetGadgetData(Gadget), *Line.Line
		Protected *Task.Task = AllocateStructure(Task), XML, MainNode, Item
		
		XML = CreateXML(#PB_Any)
 		MainNode = CreateXMLNode(RootXMLNode(XML), "Tasks") 
		
		If *Parent
			SelectElement(*Parent\Childrens(), Position)
			*Line = *Parent\Childrens()
		Else
			SelectElement(*GadgetData\Cont_Displayed_List(), Position)
			*Line = *GadgetData\Cont_Displayed_List()
		EndIf
		
		Recurcive_RemoveLine(*GadgetData, *Line, MainNode)
		
		*Task\XML = ComposeXML(XML, #PB_XML_NoDeclaration)
		FreeXML(XML)
		
		TaskList::NewTask(*GadgetData\State_TaskList, *Task, @Handler_UndoRedo())
	EndProcedure
	
	Procedure AddLine(Gadget, Position, Text.s, *Parent.Line = 0, Flags = #Line_Default)
		Protected *GadgetData.GadgetData = GetGadgetData(Gadget), *Result.Line
 		Protected *Task.Task = AllocateStructure(Task), UUID.s = UUID(), MainNode, Item, Visible
 		
 		*Task\XMLID = CreateXML(#PB_Any)
 		MainNode = CreateXMLNode(RootXMLNode(*Task\XMLID), "Tasks") 
 		Item = CreateXMLNode(MainNode, #CreateLine)
 		
		SetXMLAttribute(Item, "Gadget", Str(Gadget))
		SetXMLAttribute(Item, "Position", Str(Position))
		SetXMLAttribute(Item, "UUID", UUID)
		
		If *Parent
			SetXMLAttribute(Item, "Parent", *Parent\UUID)
			Visible = Bool(*Parent\Folded = #Unfolded And *Parent\DisplayListAdress)
		Else
			Visible = #True
			SetXMLAttribute(Item, "Parent", "0")
		EndIf
		
		SetXMLAttribute(Item, "Flags", Str(Flags))
		
		If Text = ""
			If Flags & #Line_Folder
				Text = "New Folder"
			Else
				Text = "New Line"
			EndIf
			SetXMLAttribute(Item, "Text", Text)
			
			*Result = _AddLine(*GadgetData, Position, Text.s, *Parent.Line, Flags, UUID)
			
			If Visible = #True
				RenameLine(*GadgetData, *Result, *Task)
			Else
				*Task\XML = ComposeXML(*Task\XMLID, #PB_XML_NoDeclaration)
				FreeXML(*Task\XMLID)
				
				TaskList::NewTask(*GadgetData\State_TaskList, *Task, @Handler_UndoRedo())
			EndIf
		Else
			SetXMLAttribute(Item, "Text", Text)
			*Task\XML = ComposeXML(*Task\XMLID, #PB_XML_NoDeclaration)
			FreeXML(*Task\XMLID)
			
			TaskList::NewTask(*GadgetData\State_TaskList, *Task, @Handler_UndoRedo())
 			*Result = _AddLine(*GadgetData, Position, Text.s, *Parent.Line, Flags, UUID)
		EndIf
		
		ProcedureReturn *Result
	EndProcedure
			
	Procedure GetLineID(Gadget, Position, Parent = 0)
		
	EndProcedure
	
	Procedure GetLineText(Gadget, LineID)
		
	EndProcedure
	
	Procedure SetLineText(Gadget, LineID, Text.s)
		
	EndProcedure
	
	; Media block
	
	
	; Data point
	
	
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
	
	Procedure.s UUID()
		Protected i, GUID.s
		
		For i = 0 To 15
			GUID + RSet(Hex(Random(255) & $FF), 2, "0")
		Next
		
		ProcedureReturn GUID
	EndProcedure
	
	; Line Stuff
	Procedure _AddLine(*GadgetData.GadgetData, Position, Text.s, *Parent.Line, Flags, UUID.s)
		Protected *NewLine.Line
		
		With *GadgetData
			
			*NewLine = AddMapElement(\Lines(), UUID , #PB_Map_NoElementCheck)
			*NewLine\UUID = UUID
			
			If *Parent
				If Position = -1 Or Position >= ListSize(*Parent\Childrens())
					LastElement(*Parent\Childrens())
					If ListSize(*Parent\Childrens()) And *Parent\Childrens()\DisplayListAdress
						ChangeCurrentElement(\Cont_Displayed_List(), *Parent\Childrens()\DisplayListAdress)
					EndIf
				ElseIf Position > 0
					SelectElement(*Parent\Childrens(), Position - 1)
					If ListSize(*Parent\Childrens()) And *Parent\Childrens()\DisplayListAdress
						ChangeCurrentElement(\Cont_Displayed_List(), *Parent\Childrens()\DisplayListAdress)
					EndIf
				Else
					ResetList(*Parent\Childrens())
				EndIf
				
				*NewLine\ParentListAdress = AddElement(*Parent\Childrens())
				*NewLine\Parent = *Parent
				*NewLine\HorizontalOfsset = *Parent\HorizontalOfsset + #Size_SubItemOffset
				
				*Parent\Childrens() = *NewLine
				
				If *Parent\Folded = #Unfolded And *Parent\DisplayListAdress
					*NewLine\DisplayListAdress = AddElement(\Cont_Displayed_List())
					\Cont_Displayed_List() = *NewLine
					\Cont_Displayed_Line + 1
					SetGadgetAttribute(\Comp_VScrollBar, #PB_ScrollBar_Maximum, \Cont_Displayed_Line - 1)
				Else
					*Parent\Folded = #Folded
				EndIf
			Else
				If Position = -1 Or Position >= ListSize(\Cont_Line_List())
					LastElement(\Cont_Line_List())
					LastElement(\Cont_Displayed_List())
				ElseIf Position > 0
					SelectElement(\Cont_Line_List(), Position)
					ChangeCurrentElement(\Cont_Displayed_List(), \Cont_Line_List()\DisplayListAdress)
					PreviousElement(\Cont_Line_List())
					PreviousElement(\Cont_Displayed_List())
				Else
					ResetList(\Cont_Line_List())
					ResetList(\Cont_Displayed_List())
				EndIf
				
				*NewLine\ParentListAdress = AddElement(\Cont_Line_List())
				*NewLine\DisplayListAdress = AddElement(\Cont_Displayed_List())
				
				\Cont_Displayed_List() = *NewLine
				\Cont_Line_List() = *NewLine
				
				*NewLine\HorizontalOfsset = #Size_List_Text_HorizontalMargin
			EndIf
			
			*NewLine\Name = Text
			*NewLine\Type = Flags & #Line_Folder
			
			If *NewLine\Type = #Line_Folder
				*NewLine\HorizontalOfsset + #Size_List_Icon_Offset
				*NewLine\Icon = #FontAwesome_Folder
			EndIf
			
			
			*NewLine\VerticalOffset + #Size_List_Text_VerticalMargin
			
			*NewLine\Flags = Flags
			
			If *NewLine\DisplayListAdress
				\Cont_Displayed_Line + 1
				SetGadgetAttribute(\Comp_VScrollBar, #PB_ScrollBar_Maximum, \Cont_Displayed_Line - 1)
			EndIf
			
			Refit(\Comp_Container)
			Redraw(\Comp_Container)
		EndWith
		
		ProcedureReturn *NewLine
		
	EndProcedure
	
	Procedure _RemoveLine(*GadgetData.GadgetData, Position, *Parent.Line)
		Protected *Line.Line
		
		With *GadgetData
			
			If *Parent
				SelectElement(*Parent\Childrens(), Position)
				*Line = *Parent\Childrens()
				DeleteElement(*Parent\Childrens())
				If ListSize(*Parent\Childrens()) = 0
					*Parent\Folded = #NoFold
					If *Parent\Type = #Line_Folder
						*Parent\Icon = #FontAwesome_Folder
					Else
						*Parent\Icon = #FontAwesome_Chevron_Right
					EndIf
				EndIf
			Else
				SelectElement(\Cont_Line_List(), Position)
				*Line = \Cont_Line_List()
				DeleteElement(\Cont_Line_List())
			EndIf
			
			If *Line\DisplayListAdress
				ChangeCurrentElement(\Cont_Displayed_List(), *Line\DisplayListAdress)
				
				If ListIndex(\Cont_Displayed_List()) = \State_ActiveLine
					\State_ActiveLine = -1
				ElseIf ListIndex(\Cont_Displayed_List()) < \State_ActiveLine
					\State_ActiveLine -1
				EndIf
				
				If ListIndex(\Cont_Displayed_List()) = \State_HoverLine
					\State_HoverLine = -1
				ElseIf ListIndex(\Cont_Displayed_List()) < \State_HoverLine
					\State_HoverLine -1
				EndIf
				
				DeleteElement(\Cont_Displayed_List())
				\Cont_Displayed_Line - 1
				SetGadgetAttribute(\Comp_VScrollBar, #PB_ScrollBar_Maximum, \Cont_Displayed_Line - 1)
			EndIf
			
			Refit(\Comp_Container)
			Redraw(\Comp_Container)
			DeleteMapElement(\Lines(), *Line\UUID)
			
		EndWith
	EndProcedure
	
	Procedure Recurcive_RemoveLine(*GadgetData.GadgetData, *Line.Line, XMLNode)
		Protected Item, Position
				
		ForEach *Line\Childrens()
			Recurcive_RemoveLine(*GadgetData.GadgetData, *Line\Childrens(), XMLNode)
		Next
		
		Item = CreateXMLNode(XMLNode, #DeleteLine)
		SetXMLAttribute(Item, "Gadget", Str(*GadgetData\Comp_Container))
		SetXMLAttribute(Item, "Text", *Line\Name)
		SetXMLAttribute(Item, "UUID", *Line\UUID)
		
		If *Line\Parent
			ChangeCurrentElement(*Line\Parent\Childrens(), *Line\ParentListAdress)
			Position = ListIndex(*Line\Parent\Childrens())
			SetXMLAttribute(Item, "Parent", *Line\Parent\UUID)
		Else
			ChangeCurrentElement(*GadgetData\Cont_Line_List(), *Line\ParentListAdress)
			Position = ListIndex(*GadgetData\Cont_Line_List())
			SetXMLAttribute(Item, "Parent", "0")
		EndIf
		
		SetXMLAttribute(Item, "Position", Str(Position))
		SetXMLAttribute(Item, "Flags", Str(*Line\Flags))
 		
 		_RemoveLine(*GadgetData, Position, *Line\Parent)
		
	EndProcedure
	
	Procedure RenameLine(*GadgetData.GadgetData, *Line.Line, *Task.Task = 0)
		Protected Y
		
		SetActiveLine(*GadgetData\Comp_Container, *Line)
		Y = (*GadgetData\State_ActiveLine - *GadgetData\Meas_VPosition) * #Size_TL_Height
		
		OpenGadgetList(*GadgetData\Comp_List)
		*GadgetData\Comp_Rename = StringGadget(#PB_Any, *Line\HorizontalOfsset - 4, Y + *Line\VerticalOffset - 2, *GadgetData\Meas_List_Width - *Line\HorizontalOfsset - 15, 25, *Line\Name)
		SendMessage_(GadgetID(*GadgetData\Comp_Rename), #EM_SETSEL, 0, Len(*Line\Name))
		SetGadgetFont(*GadgetData\Comp_Rename, FontBold)
		SetGadgetColor(*GadgetData\Comp_Rename, #PB_Gadget_BackColor, *GadgetData\Color_List_Back[#Hot])
		SetGadgetColor(*GadgetData\Comp_Rename, #PB_Gadget_FrontColor, *GadgetData\Color_List_Front[#Hot])
		SetGadgetData(*GadgetData\Comp_Rename, *GadgetData)
		SetProp_(GadgetID(*GadgetData\Comp_Rename), "oldproc", SetWindowLongPtr_(GadgetID(*GadgetData\Comp_Rename), #GWL_WNDPROC, @HandlerRenameString()))
		SetActiveGadget(*GadgetData\Comp_Rename)
		
		SetProp_(GadgetID(*GadgetData\Comp_Rename), "gadget", *GadgetData\Comp_Rename)
		SetProp_(GadgetID(*GadgetData\Comp_Rename), "Task", *Task)
		
		CloseGadgetList()
		*GadgetData\State_UserAction = #Action_List_Rename
	EndProcedure
	
	Procedure MoveLine(*GadgetData.GadgetData, *Line.Line, Position, *Parent.Line = 0)
		Protected *ParentAdress
		If *Line\DisplayListAdress
			ChangeCurrentElement(*GadgetData\Cont_Displayed_List(), *Line\DisplayListAdress)
			
			If ListIndex(*GadgetData\Cont_Displayed_List()) < Position
				Position - 1
			EndIf
			
			DeleteElement(*GadgetData\Cont_Displayed_List())
			*Line\DisplayListAdress = 0
			*GadgetData\Cont_Displayed_Line - 1
			SetGadgetAttribute(*GadgetData\Comp_VScrollBar, #PB_ScrollBar_Maximum, *GadgetData\Cont_Displayed_Line - 1)
		EndIf
		If *Line\ParentListAdress
			If *Line\Parent
				ChangeCurrentElement(*Line\Parent\Childrens(), *Line\ParentListAdress)
				DeleteElement(*Line\Parent\Childrens())
			Else
				ChangeCurrentElement(*GadgetData\Cont_Line_List(), *Line\ParentListAdress)
				DeleteElement(*GadgetData\Cont_Line_List())
			EndIf
			*Line\ParentListAdress = 0
			*Line\Parent = 0
		EndIf
		
		If *Parent
			If Position = 0
				If *Parent\Folded = #NoFold
					*Parent\Folded = #Unfolded
					*Parent\Icon = #FontAwesome_Folder_Open
					
				ElseIf *Parent\Folded = #Folded
					ChangeCurrentElement(*GadgetData\Cont_Displayed_List(), *Parent\DisplayListAdress)
					ToggleFold(*GadgetData\Comp_Container)
				EndIf
				
				ResetList(*Parent\Childrens())
				ChangeCurrentElement(*GadgetData\Cont_Displayed_List(), *Parent\DisplayListAdress)
				*Line\DisplayListAdress = AddElement(*GadgetData\Cont_Displayed_List())
				*GadgetData\Cont_Displayed_List() = *Line
				*GadgetData\Cont_Displayed_Line + 1
				SetGadgetAttribute(*GadgetData\Comp_VScrollBar, #PB_ScrollBar_Maximum, *GadgetData\Cont_Displayed_Line - 1)
				
			Else
				SelectElement(*Parent\Childrens(), Position -1)
				If *Parent\Childrens()\DisplayListAdress
					ChangeCurrentElement(*GadgetData\Cont_Displayed_List(), *Parent\Childrens()\DisplayListAdress)
					*Line\DisplayListAdress = AddElement(*GadgetData\Cont_Displayed_List())
					*GadgetData\Cont_Displayed_List() = *Line
					*GadgetData\Cont_Displayed_Line + 1
					SetGadgetAttribute(*GadgetData\Comp_VScrollBar, #PB_ScrollBar_Maximum, *GadgetData\Cont_Displayed_Line - 1)
				EndIf
			EndIf
			*Line\HorizontalOfsset = *Parent\HorizontalOfsset + #Size_SubItemOffset
			*Line\ParentListAdress = AddElement(*Parent\Childrens())
			*Line\Parent = *Parent
			*Parent\Childrens() = *Line
		Else
			If Position = 0
				ResetList(*GadgetData\Cont_Line_List())
				ResetList(*GadgetData\Cont_Displayed_List())
			Else
				SelectElement(*GadgetData\Cont_Line_List(), Position -1)
				ChangeCurrentElement(*GadgetData\Cont_Displayed_List(), *GadgetData\Cont_Line_List()\DisplayListAdress)
			EndIf
			*Line\ParentListAdress = AddElement(*GadgetData\Cont_Line_List())
			*Line\DisplayListAdress = AddElement(*GadgetData\Cont_Displayed_List())
			*Line\HorizontalOfsset = #Size_List_Text_HorizontalMargin
			*GadgetData\Cont_Displayed_List() = *Line
			*GadgetData\Cont_Line_List() = *Line
			*GadgetData\Cont_Displayed_Line + 1
			SetGadgetAttribute(*GadgetData\Comp_VScrollBar, #PB_ScrollBar_Maximum, *GadgetData\Cont_Displayed_Line - 1)
		EndIf
		
		*Line\HorizontalOfsset + Bool(*Line\Folded Or *Line\Type = #Line_Folder) * #Size_List_Icon_Offset
	EndProcedure
	
	; Handler
	Procedure Handler_Body()
		Protected *GadgetData.GadgetData = GetGadgetData(EventGadget())
		
		With *GadgetData
			Protected MouseX = GetGadgetAttribute(\Comp_Body, #PB_Canvas_MouseX), MouseY = GetGadgetAttribute(\Comp_Body, #PB_Canvas_MouseY)
			
			Select EventType()
				Case #PB_EventType_MouseMove
					
					
			EndSelect
		EndWith
		
	EndProcedure
	
	Procedure Handler_List()
		Protected *GadgetData.GadgetData = GetGadgetData(EventGadget()), MouseX, MouseY, Line, Redraw, *Line.Line, *Task.Task
		Protected HoverLine = - 1, HoverButton = - 1
		
		With *GadgetData
			Select \State_UserAction
				Case #Action_Hover ;{
					Select EventType()
						Case #PB_EventType_MouseMove ;{
							MouseX = GetGadgetAttribute(\Comp_List, #PB_Canvas_MouseX)
							MouseY = GetGadgetAttribute(\Comp_List, #PB_Canvas_MouseY)
							
							If MouseX > 0 Or MouseY > 0
								Line = MouseY / #Size_TL_Height + \Meas_VPosition
								
								If Line < \Cont_Displayed_Line
									SelectElement(\Cont_Displayed_List(), Line)
									
									MouseY % #Size_TL_Height
									
									If \Cont_Displayed_List()\Folded And MouseX < \Cont_Displayed_List()\HorizontalOfsset - 6 And MouseX > \Cont_Displayed_List()\HorizontalOfsset - #Size_List_Icon_Offset - 6 And MouseY > 13 And MouseY < #Size_TL_Height - 13
										HoverButton = Line
									ElseIf Line <> \State_ActiveLine
										HoverLine = Line
									EndIf
								EndIf
								
								If HoverButton <> \State_HoverFoldButton
									\State_HoverFoldButton = HoverButton
									Redraw = #True
								EndIf
								
								If HoverLine <> \State_HoverLine
									If \State_HoverLine > -1
										SelectElement(\Cont_Displayed_List(), \State_HoverLine)
										\Cont_Displayed_List()\State = #Cold	
										\State_HoverLine = -1
									EndIf
									
									\State_HoverLine = HoverLine
									
									If \State_HoverLine > -1
										SelectElement(\Cont_Displayed_List(), \State_HoverLine)
										\Cont_Displayed_List()\State = #Warm
									EndIf
									
									Redraw = #True
								EndIf
								
								If Redraw 
									Redraw(\Comp_Container)
								EndIf
							EndIf
							;}
						Case #PB_EventType_MouseLeave ;{
							If \State_HoverLine > -1
								SelectElement(\Cont_Displayed_List(), \State_HoverLine)
								\Cont_Displayed_List()\State = #Cold	
								\State_HoverLine = -1
								
								Redraw(\Comp_Container)
							EndIf
							;}
						Case #PB_EventType_LeftButtonDown ;{
							If \State_HoverFoldButton > -1
								SelectElement(\Cont_Displayed_List(), \State_HoverFoldButton)
								ToggleFold(\Comp_Container)
								Redraw(\Comp_Container)
							Else
								If \State_HoverLine > -1
									If \State_ActiveLine > -1
										SelectElement(\Cont_Displayed_List(), \State_ActiveLine)
										\Cont_Displayed_List()\State = #Cold
									EndIf
									
									\State_ActiveLine = \State_HoverLine
									\State_HoverLine = -1
									
									SelectElement(\Cont_Displayed_List(), \State_ActiveLine)
									\Cont_Displayed_List()\State = #Hot
									
									Redraw(\Comp_Container)
								EndIf
								
								MouseY = GetGadgetAttribute(\Comp_List, #PB_Canvas_MouseY)
								
								If MouseY / #Size_TL_Height + \Meas_VPosition = \State_ActiveLine
									SelectElement(\Cont_Displayed_List(), \State_ActiveLine)
									If \Cont_Displayed_List()\Folded = #Unfolded
										ToggleFold(*GadgetData\Comp_Container)
										Redraw(\Comp_Container)
									EndIf
									
									\State_UserAction = #Action_List_InitDrag
									\Action_Drag_OriginX = GetGadgetAttribute(\Comp_List, #PB_Canvas_MouseX)
									\Action_Drag_OriginY = MouseY
								EndIf
							EndIf
							;}
						Case #PB_EventType_LeftDoubleClick ;{
							;}
						Case #PB_EventType_KeyDown ;{
							Select GetGadgetAttribute(\Comp_List, #PB_Canvas_Key)
								Case #PB_Shortcut_F2 ;{ Rename
									If \State_ActiveLine > -1
										SelectElement(\Cont_Displayed_List(), \State_ActiveLine)
										*Line = \Cont_Displayed_List()
										*Task.Task = AllocateStructure(Task)
										*Task\XMLID = CreateXML(#PB_Any)
										CreateXMLNode(RootXMLNode(*Task\XMLID), "Tasks")
										
										RenameLine(*GadgetData, *Line, *Task)
										
									EndIf
								;}
							EndSelect
							;}
					EndSelect
					;}
				Case #Action_List_InitDrag ;{
					Select EventType()
						Case #PB_EventType_LeftButtonUp
							\State_UserAction = #Action_Hover
						Case #PB_EventType_MouseMove
							If Abs(GetGadgetAttribute(\Comp_List, #PB_Canvas_MouseX) - \Action_Drag_OriginX) + Abs(GetGadgetAttribute(\Comp_List, #PB_Canvas_MouseY) - \Action_Drag_OriginY) > 11
								\State_UserAction = #Action_List_Drag
								SelectElement(\Cont_Displayed_List(), \State_ActiveLine)
								\Action_Drag_Line = \Cont_Displayed_List()
								\State_ActiveLine = -1
								DeleteElement(\Cont_Displayed_List())
								\Action_Drag_Line\DisplayListAdress = 0
								
								If \Action_Drag_Line\Parent
									ChangeCurrentElement(\Action_Drag_Line\Parent\Childrens(), \Action_Drag_Line\ParentListAdress)
									DeleteElement(\Action_Drag_Line\Parent\Childrens())
								Else
									ChangeCurrentElement(\Cont_Line_List(), \Action_Drag_Line\ParentListAdress)
									DeleteElement(\Cont_Line_List())
								EndIf
								\Action_Drag_Line\ParentListAdress = 0
								\Action_Drag_Line\Parent = 0
								
								\Cont_Displayed_Line - 1
								SetGadgetAttribute(\Comp_VScrollBar, #PB_ScrollBar_Maximum, \Cont_Displayed_Line - 1)
								Refit(\Comp_Container)
								Redraw(\Comp_Container)
								
								\Action_Drag_Image = CreateImage(#PB_Any, \Meas_List_Width, #Size_TL_Height)
								StartDrawing(ImageOutput(\Action_Drag_Image))
								Box(0, 0, \Meas_List_Width, #Size_TL_Height, \Color_List_Back[#Hot])
								FrontColor(\Color_List_Front[#Hot])
								DrawingFont(FontBold)
								DrawingMode(#PB_2DDrawing_Transparent)
								
								DrawText(\Action_Drag_Line\HorizontalOfsset, \Action_Drag_Line\VerticalOffset, \Action_Drag_Line\Name)
								If \Action_Drag_Line\Folded
									DrawingFont(IconSolid)
									DrawText(\Action_Drag_Line\HorizontalOfsset - #Size_List_Icon_Offset, #Size_List_Icon_VerticalMargin, \Action_Drag_Line\Icon)
								ElseIf \Action_Drag_Line\Type = #Line_Folder
									DrawingFont(Icon)
									DrawText(\Action_Drag_Line\HorizontalOfsset - #Size_List_Icon_Offset, #Size_List_Icon_VerticalMargin, #FontAwesome_Folder)
								EndIf
								StopDrawing()
								
								\Action_Drag_Window = OpenWindow(#PB_Any, DesktopMouseX() + 15, DesktopMouseY() - 0.5 * #Size_TL_Height, \Meas_List_Width, #Size_TL_Height, "", #PB_Window_BorderLess | #PB_Window_Invisible)
								ImageGadget(#PB_Any, 0, 0, \Meas_List_Width, #Size_TL_Height, ImageID(\Action_Drag_Image))
								
								SetWindowLongPtr_(WindowID(\Action_Drag_Window),#GWL_EXSTYLE,#WS_EX_LAYERED)
								SetLayeredWindowAttributes_(WindowID(\Action_Drag_Window),0,140,#LWA_ALPHA)
								HideWindow(\Action_Drag_Window, #False, #PB_Window_NoActivate)
							EndIf
					EndSelect
					;}
				Case #Action_List_Drag ;{
					Select EventType()
						Case #PB_EventType_MouseMove
							MouseX = GetGadgetAttribute(\Comp_List, #PB_Canvas_MouseX)
							MouseY = GetGadgetAttribute(\Comp_List, #PB_Canvas_MouseY)
							
							If MouseX >= 0 And MouseX < \Meas_List_Width And MouseY >= 0 And MouseY < \Meas_List_Height
								Line = Min(Round(MouseY / #Size_TL_Height, #PB_Round_Nearest) + \Meas_VPosition, \Cont_Displayed_Line) - 1
								If \Action_Drag_Position <> Line
									\Action_Drag_Position = Line
									Redraw(\Comp_Container)
								EndIf
							ElseIf \Action_Drag_Position > - 1
								\Action_Drag_Position = - 1
								Redraw(\Comp_Container)
							EndIf
						
							ResizeWindow(\Action_Drag_Window, DesktopMouseX() + 15, DesktopMouseY() - 0.5 * #Size_TL_Height, #PB_Ignore, #PB_Ignore)
							
						Case #PB_EventType_LeftButtonUp
							\State_UserAction = #Action_Hover
							CloseWindow(\Action_Drag_Window)
							If \Action_Drag_Position = - 1
								MoveLine(*GadgetData, \Action_Drag_Line, 0)
							Else
								SelectElement(\Cont_Displayed_List(), \Action_Drag_Position)
							
								If \Cont_Displayed_List()\Parent
									ChangeCurrentElement(\Cont_Displayed_List()\Parent\Childrens(), \Cont_Displayed_List()\ParentListAdress)
									MoveLine(*GadgetData, \Action_Drag_Line, ListIndex(\Cont_Displayed_List()\Parent\Childrens()) + 1, \Cont_Displayed_List()\Parent)
								ElseIf \Cont_Displayed_List()\Type = #Line_Folder
									MoveLine(*GadgetData, \Action_Drag_Line, 0, \Cont_Displayed_List())
								Else
									ChangeCurrentElement(\Cont_Line_List(), \Cont_Displayed_List()\ParentListAdress)
									MoveLine(*GadgetData, \Action_Drag_Line, ListIndex(\Cont_Line_List()) + 1)
								EndIf
							EndIf
							
							\Action_Drag_Position = -2
							\Action_Drag_Line\State = #Hot
							\State_ActiveLine = ListIndex(\Cont_Displayed_List())
							Refit(\Comp_Container)
							Redraw(\Comp_Container)
					EndSelect
					;}
				Case #Action_List_Rename ;{
					
					;}
			EndSelect
		EndWith
	EndProcedure
	
	Procedure Handler_Button_AddFolder()
		Protected Gadget = EventGadget(), *GadgetData.GadgetData = GetGadgetData(Gadget)
		Protected *CurrentLine.Line = GetActiveLine(Gadget), Position
		
		If Not *CurrentLine
			AddLine(*GadgetData\Comp_Container, -1, "", 0, #Line_Folder)
		Else
			If *CurrentLine\Parent
				If *CurrentLine\Parent\Parent
					ChangeCurrentElement(*GadgetData\Cont_Line_List(), *CurrentLine\Parent\Parent\ParentListAdress)
				Else
					ChangeCurrentElement(*GadgetData\Cont_Line_List(), *CurrentLine\Parent\ParentListAdress)
				EndIf
			Else
				ChangeCurrentElement(*GadgetData\Cont_Line_List(), *CurrentLine\ParentListAdress)
			EndIf
			
			Position = ListIndex(*GadgetData\Cont_Line_List())
			AddLine(*GadgetData\Comp_Container, Position + 1, "", *CurrentLine\Parent, #Line_Folder)
				
		EndIf
	EndProcedure
	
	Procedure Handler_Button_AddLine()
		Protected Gadget = EventGadget(), *GadgetData.GadgetData = GetGadgetData(Gadget)
		Protected *CurrentLine.Line = GetActiveLine(Gadget), Position
		
		If Not *CurrentLine
			AddLine(*GadgetData\Comp_Container, -1, "")
		Else
			If *CurrentLine\Type = #Line_Folder
				AddLine(*GadgetData\Comp_Container, -1, "", *CurrentLine)
			Else
				If *CurrentLine\Parent
					ChangeCurrentElement(*CurrentLine\Parent\Childrens(), *CurrentLine\ParentListAdress)
					Position = ListIndex(*CurrentLine\Parent\Childrens())
				Else
					ChangeCurrentElement(*GadgetData\Cont_Line_List(), *CurrentLine\ParentListAdress)
					Position = ListIndex(*GadgetData\Cont_Line_List())
				EndIf
				
				AddLine(*GadgetData\Comp_Container, Position + 1, "", *CurrentLine\Parent)
				
			EndIf
		EndIf
	EndProcedure
	
	Procedure Handler_Button_RemoveLine()
		Protected Gadget = EventGadget(), *GadgetData.GadgetData = GetGadgetData(Gadget)
		Protected *CurrentLine.Line = GetActiveLine(Gadget), Position
		
		If *CurrentLine
			If *CurrentLine\Parent
				ChangeCurrentElement(*CurrentLine\Parent\Childrens(), *CurrentLine\ParentListAdress)
				Position = ListIndex(*CurrentLine\Parent\Childrens())
			Else
				ChangeCurrentElement(*GadgetData\Cont_Line_List(), *CurrentLine\ParentListAdress)
				Position = ListIndex(*GadgetData\Cont_Line_List())
			EndIf
			
			RemoveLine(Gadget, Position, *CurrentLine\Parent)
			
		EndIf
	EndProcedure
	
	Procedure Handler_Button_Up()
		Protected Gadget = EventGadget(), *GadgetData.GadgetData = GetGadgetData(Gadget)
		Protected *CurrentLine.Line = GetActiveLine(Gadget), Position
		
		With *GadgetData
			If *CurrentLine
				ChangeCurrentElement(\Cont_Displayed_List(), *CurrentLine\DisplayListAdress)
				Position = ListIndex(\Cont_Displayed_List())
				
			EndIf
		EndWith
	EndProcedure
	
	Procedure Handler_Button_Down()
		
	EndProcedure
	
	Procedure Handler_VScrollBar()
		Protected *GadgetData.GadgetData = GetGadgetData(EventGadget())
		*GadgetData\Meas_VPosition = GetGadgetState(*GadgetData\Comp_VScrollBar)
		Redraw(*GadgetData\Comp_Container)
	EndProcedure
	
	Procedure Handler_HScrollBar()
		
	EndProcedure
	
	Procedure HandlerRenameString(hWnd, uMsg, wParam, lParam)
		Protected oldproc = GetProp_(hWnd, "oldproc"), Gadget, *GadgetData.GadgetData, *Task.Task, Item, NewName.s
		
		Select uMsg
			Case #WM_NCDESTROY
				RemoveProp_(hWnd, "oldproc")
				RemoveProp_(hWnd, "gadget")
				RemoveProp_(hWnd, "Task")
			Case #WM_KEYDOWN
				Gadget = GetProp_(hWnd, "gadget")
				If wParam = #VK_RETURN And GetGadgetText(Gadget) <> ""
					*GadgetData = GetGadgetData(GetProp_(hWnd, "gadget"))
					SetActiveGadget(*GadgetData\Comp_List)
				EndIf
				ProcedureReturn #False
			Case #WM_KILLFOCUS
				*Task = GetProp_(hWnd, "Task")
				Gadget = GetProp_(hWnd, "gadget")
				*GadgetData = GetGadgetData(Gadget)
				NewName = GetGadgetText(Gadget)
				
				If *Task
					SelectElement(*GadgetData\Cont_Displayed_List(), *GadgetData\State_ActiveLine)
					If NewName = "" Or NewName = *GadgetData\Cont_Displayed_List()\Name
						If XMLChildCount(ChildXMLNode(RootXMLNode(*Task\XMLID)))
							*Task\XML = ComposeXML(*Task\XMLID, #PB_XML_NoDeclaration)
							FreeXML(*Task\XMLID)
							
							TaskList::NewTask(*GadgetData\State_TaskList, *Task, @Handler_UndoRedo())
						Else
							FreeXML(*Task\XMLID)
							FreeStructure(*Task)
						EndIf
					Else
						Item = CreateXMLNode(ChildXMLNode(RootXMLNode(*Task\XMLID)), #RenameLine)
						SetXMLAttribute(Item, "UUID", *GadgetData\Cont_Displayed_List()\UUID)
						SetXMLAttribute(Item, "OldName", *GadgetData\Cont_Displayed_List()\Name)
						SetXMLAttribute(Item, "NewName", NewName)
						
						*Task\XML = ComposeXML(*Task\XMLID, #PB_XML_NoDeclaration)
						FreeXML(*Task\XMLID)
						
						TaskList::NewTask(*GadgetData\State_TaskList, *Task, @Handler_UndoRedo())
						*GadgetData\Cont_Displayed_List()\Name = NewName
						Redraw(*GadgetData\Comp_Container)
					EndIf
				EndIf
				
				*GadgetData\State_UserAction = #Action_Hover
				FreeGadget(Gadget)
				ProcedureReturn #False
		EndSelect
		
		ProcedureReturn CallWindowProc_(oldproc, hWnd, uMsg, wParam, lParam)
	EndProcedure
	
	Procedure Handler_UndoRedo(*Task.Task, Redo)
		Protected *GadgetData.GadgetData, XML = ParseXML(#PB_Any, *Task\XML), Loop, TaskCount, TaskNode, Task, *Line.Line
		Protected Data0
		
		TaskNode = ChildXMLNode(RootXMLNode(XML))
		TaskCount = XMLChildCount(TaskNode)
		
		If Redo ;{ Redo
			For loop = 1 To TaskCount
				Task = ChildXMLNode(TaskNode, Loop)
				
				*GadgetData.GadgetData = GetGadgetData( Val(GetXMLAttribute(Task, "Gadget")))
				
				If *GadgetData\State_UserAction <> #Action_Hover
					FreeXML(XML)
					ProcedureReturn #False
				EndIf
				
				Select GetXMLNodeName(Task)
					Case #CreateLine
						*GadgetData.GadgetData = GetGadgetData( Val(GetXMLAttribute(Task, "Gadget")))
						
						_AddLine(*GadgetData,
						         Val(GetXMLAttribute(Task, "Position")),
						         GetXMLAttribute(Task, "Text"),
						         FindMapElement(*GadgetData\Lines(), GetXMLAttribute(Task, "Parent")),
						         Val(GetXMLAttribute(Task, "Flags")),
						         GetXMLAttribute(Task, "UUID"))
					Case #DeleteLine
						*GadgetData.GadgetData = GetGadgetData( Val(GetXMLAttribute(Task, "Gadget")))
						
						FindMapElement(*GadgetData\Lines(), GetXMLAttribute(Task, "UUID"))
						
						If *GadgetData\Lines()\Parent
							ChangeCurrentElement(*GadgetData\Lines()\Parent\Childrens(), *GadgetData\Lines()\ParentListAdress)
							Data0 = ListIndex(*GadgetData\Lines()\Parent\Childrens())
						Else
							ChangeCurrentElement(*GadgetData\Cont_Line_List(), *GadgetData\Lines()\ParentListAdress)
							Data0 = ListIndex(*GadgetData\Cont_Line_List())
						EndIf
						
						_RemoveLine(*GadgetData, Data0, *GadgetData\Lines()\Parent)
						
					Case #RenameLine
						*Line = FindMapElement(*GadgetData\Lines(), GetXMLAttribute(Task, "UUID"))
						*Line\Name = GetXMLAttribute(Task, "NewName")
						Redraw(*GadgetData\Comp_Container)
				EndSelect
			Next
			;}
		Else ;{ Undo
			For loop = TaskCount To 1 Step -1
				Task = ChildXMLNode(TaskNode, Loop)
				
				*GadgetData.GadgetData = GetGadgetData( Val(GetXMLAttribute(Task, "Gadget")))
				
				If *GadgetData\State_UserAction <> #Action_Hover
					FreeXML(XML)
					ProcedureReturn #False
				EndIf
				
				Select GetXMLNodeName(Task)
					Case #CreateLine
						FindMapElement(*GadgetData\Lines(), GetXMLAttribute(Task, "UUID"))
						
						If *GadgetData\Lines()\Parent
							ChangeCurrentElement(*GadgetData\Lines()\Parent\Childrens(), *GadgetData\Lines()\ParentListAdress)
							Data0 = ListIndex(*GadgetData\Lines()\Parent\Childrens())
						Else
							ChangeCurrentElement(*GadgetData\Cont_Line_List(), *GadgetData\Lines()\ParentListAdress)
							Data0 = ListIndex(*GadgetData\Cont_Line_List())
						EndIf
						
						_RemoveLine(*GadgetData, Data0, *GadgetData\Lines()\Parent)
					Case #DeleteLine
						_AddLine(*GadgetData,
						         Val(GetXMLAttribute(Task, "Position")),
						         GetXMLAttribute(Task, "Text"),
						         FindMapElement(*GadgetData\Lines(), GetXMLAttribute(Task, "Parent")),
						         Val(GetXMLAttribute(Task, "Flags")),
						         GetXMLAttribute(Task, "UUID"))
					Case #RenameLine
						*Line = FindMapElement(*GadgetData\Lines(), GetXMLAttribute(Task, "UUID"))
						*Line\Name = GetXMLAttribute(Task, "OldName")
						Redraw(*GadgetData\Comp_Container)
				EndSelect
			Next
		EndIf ;}
		FreeXML(XML)
		
		ProcedureReturn #True
	EndProcedure
	
	; Redraw
	Procedure Redraw(Gadget)
		Protected *GadgetData.GadgetData = GetGadgetData(Gadget), ListLoop, ListLoopMax, ListIndex
		
		With *GadgetData
			StartDrawing(CanvasOutput(\Comp_List))
			StartVectorDrawing(CanvasVectorOutput(\Comp_Body))
			
			;{ List
			Box(0, 0, \Meas_List_Width, \Meas_List_Height, \Color_List_Back[#cold])
			DrawingFont(FontBold)
			DrawingMode(#PB_2DDrawing_Transparent)
			;}
			
			;{ Body
			AddPathBox(0, 0, \Meas_Body_Width, \Meas_Body_Height)
			VectorSourceColor(SetAlpha($FF, \Color_List_Back[#cold]))
			FillPath()
			
			MovePathCursor(0, #Size_Header_Height - 0.5)
			AddPathLine(\Meas_Body_Width, 0, #PB_Path_Relative)
			VectorSourceColor(SetAlpha($FF, \Color_General_Line))
			StrokePath(#Size_Line_Thin)
			;}
			
			;{ Content
			ListLoopMax = Min(\Meas_Displayed_Lines, \Cont_Displayed_Line) - 1
			SelectElement(\Cont_Displayed_List(), \Meas_VPosition)
			
			ListIndex = Max(ListIndex(\Cont_Displayed_List()), 0)
			
			If \Action_Drag_Position = ListIndex - 1
				If \Action_Drag_Position = -1
					Box(#Size_List_Text_HorizontalMargin, 0, \Meas_List_Height, 3, \Color_List_Front[#Hot])
				Else
					PreviousElement(\Cont_Displayed_List())
					Box(\Cont_Displayed_List()\HorizontalOfsset, 0, \Meas_List_Height, 3, \Color_List_Front[#Hot])
					NextElement(\Cont_Displayed_List())
				EndIf
			EndIf
			
			For ListLoop = 0 To ListLoopMax
				If \Cont_Displayed_List()\State
					Box(0, ListLoop * #Size_TL_Height, \Meas_List_Width, #Size_TL_Height, \Color_List_Back[\Cont_Displayed_List()\State])
				EndIf
				
				DrawText(\Cont_Displayed_List()\HorizontalOfsset, ListLoop * #Size_TL_Height + \Cont_Displayed_List()\VerticalOffset, \Cont_Displayed_List()\Name, \Color_List_Front[\Cont_Displayed_List()\State])
				
				If \Cont_Displayed_List()\Folded
					
					If ListIndex = \State_HoverFoldButton
						RoundBox(\Cont_Displayed_List()\HorizontalOfsset - #Size_List_Icon_Offset - 6, ListLoop * #Size_TL_Height + 13, #Size_List_Icon_Offset, #Size_TL_Height - 26, 2, 2, \Color_List_Back[Bool( \Cont_Displayed_List()\State = #Cold ) * #Hot])
					EndIf
					
					DrawingFont(IconSolid)
					
					DrawText(\Cont_Displayed_List()\HorizontalOfsset - #Size_List_Icon_Offset, ListLoop * #Size_TL_Height + #Size_List_Icon_VerticalMargin, \Cont_Displayed_List()\Icon, \Color_List_Front[\Cont_Displayed_List()\State])
					
					DrawingFont(FontBold)
				ElseIf \Cont_Displayed_List()\Type = #Line_Folder
					DrawingFont(Icon)
					DrawText(\Cont_Displayed_List()\HorizontalOfsset - #Size_List_Icon_Offset, ListLoop * #Size_TL_Height + #Size_List_Icon_VerticalMargin, #FontAwesome_Folder, \Color_List_Front[\Cont_Displayed_List()\State])
					DrawingFont(FontBold)
				EndIf
				
				If Not ListIndex % 2
					AddPathBox(0, ListLoop * #Size_TL_Height + #Size_Header_Height, \Meas_Body_Width, #Size_TL_Height)
					VectorSourceColor(SetAlpha($FF, \Color_List_Back_Alternate[\Cont_Displayed_List()\State]))
					FillPath()
				ElseIf \Cont_Displayed_List()\State
					AddPathBox(0, ListLoop * #Size_TL_Height + #Size_Header_Height, \Meas_Body_Width, #Size_TL_Height)
					VectorSourceColor(SetAlpha($FF, \Color_List_Back[\Cont_Displayed_List()\State]))
					FillPath()
				EndIf
				
				If \Action_Drag_Position = ListIndex
					Box(\Cont_Displayed_List()\HorizontalOfsset, (ListLoop + 1) * #Size_TL_Height, \Meas_List_Height, - 3, \Color_List_Front[#Hot])
				EndIf
				
				ListIndex + 1
				
				If Not NextElement(\Cont_Displayed_List())
					Break
				EndIf
			Next
			;}
			
			Box(\Meas_List_Width - #Size_Line_Thin, 0, #Size_Line_Thin, \Meas_List_Height, \Color_General_Line)
			
			;{ Corners
			DrawAlphaImage(ImageID(CornerDL), 0, \Meas_List_Height -3)
			MovePathCursor(\Meas_Body_Width - 3, 0)
			DrawVectorImage(ImageID(CornerUR))
			
			MovePathCursor(\Meas_Body_Width - 3, \Meas_Body_Height - 3)
			DrawVectorImage(ImageID(CornerDR))
			;}
			StopVectorDrawing()
			StopDrawing()
			
		EndWith
	EndProcedure
	
	; Misc
	Procedure Refit(Gadget)
		Protected Visible_VScrollbar, Visible_HScrollbar
		Protected *GadgetData.GadgetData = GetGadgetData(Gadget)
		
		With *GadgetData
			Protected Width = GadgetWidth(\Comp_Container), Height = GadgetHeight(\Comp_Container)
			
			\Meas_List_Height = Height - #Size_Header_Height
			
			ResizeGadget(\Comp_List, #PB_Ignore, #PB_Ignore, \Meas_List_Width, \Meas_List_Height)
			
			\Meas_Body_Height = Height
			\Meas_Body_Width = Width - \Meas_List_Width
			
			\Meas_Displayed_Lines = Round(\Meas_List_Height / #Size_TL_Height, #PB_Round_Up)
			
			If \Meas_Displayed_Lines <= \Cont_Displayed_Line
				Visible_VScrollbar = #True
			EndIf
			
			\Meas_Displayed_Columns = Round((\Meas_Body_Width - Visible_VScrollbar * #Size_Scrollbar_Thickness)  / \Meas_TL_ColumnWidth, #PB_Round_Up)
			
			If \Meas_Displayed_Columns <= \State_Duration
				Visible_HScrollbar = #True
				ResizeGadget(\Comp_HScrollBar, #PB_Ignore, \Meas_Body_Height - #Size_Scrollbar_Thickness, \Meas_Body_Width - Visible_VScrollbar * #Size_Scrollbar_Thickness, #Size_Scrollbar_Thickness)
				SetGadgetAttribute(\Comp_HScrollBar, #PB_ScrollBar_PageLength, \Meas_Displayed_Columns - 1)
				HideGadget(\Comp_HScrollBar, #False)
				\Meas_HPosition = GetGadgetState(\Comp_HScrollBar)
			Else
				HideGadget(\Comp_HScrollBar, #True)
				SetGadgetState(\Comp_HScrollBar, 0)
				SetGadgetAttribute(\Comp_HScrollBar, #PB_ScrollBar_PageLength, 1)
				\Meas_HPosition = 0
			EndIf
			
			If Visible_VScrollbar
				ResizeGadget(\Comp_VScrollBar, \Meas_Body_Width - #Size_Scrollbar_Thickness, #PB_Ignore, #Size_Scrollbar_Thickness, \Meas_List_Height - Visible_HScrollbar * #Size_Scrollbar_Thickness)
				SetGadgetAttribute(\Comp_VScrollBar, #PB_ScrollBar_PageLength, \Meas_Displayed_Lines - 1)
				HideGadget(\Comp_VScrollBar, #False)
				\Meas_VPosition = GetGadgetState(\Comp_VScrollBar)
			Else
				HideGadget(\Comp_VScrollBar, #True)
				SetGadgetState(\Comp_VScrollBar, 0)
				SetGadgetAttribute(\Comp_VScrollBar, #PB_ScrollBar_PageLength, 1)
				\Meas_VPosition = 0
			EndIf
			
		EndWith
	EndProcedure
	
	Procedure RecurciveFold(*GadgetData.GadgetData, *Line.Line)
		Protected Result
		
		ForEach *Line\Childrens()
			NextElement(*GadgetData\Cont_Displayed_List())
			*Line\Childrens()\DisplayListAdress = 0
			*Line\Childrens()\State = #Cold
			Result + 1
			
			If *Line\Childrens()\Folded = #Unfolded
				Result + RecurciveFold(*GadgetData, *Line\Childrens())
			EndIf
			
			DeleteElement(*GadgetData\Cont_Displayed_List())
		Next
		
		ProcedureReturn Result
	EndProcedure
	
	Procedure RecurciveUnfold(*GadgetData.GadgetData, *Line.Line)
		Protected Result
		
		ForEach *Line\Childrens()
			AddElement(*GadgetData\Cont_Displayed_List())
			*GadgetData\Cont_Displayed_List() = *Line\Childrens()
			*Line\Childrens()\DisplayListAdress = @*GadgetData\Cont_Displayed_List()
			Result + 1
			
			If *Line\Childrens()\Folded = #Unfolded
				Result + RecurciveUnfold(*GadgetData, *Line\Childrens())
			EndIf
		Next
		
		ProcedureReturn Result
	EndProcedure
	
	Procedure ToggleFold(Gadget)
		Protected *GadgetData.GadgetData = GetGadgetData(Gadget), Offset, Position, *Line.Line
		
		With *GadgetData
			Position = ListIndex(\Cont_Displayed_List())
			
			If \Cont_Displayed_List()\Folded = #Folded
				\Cont_Displayed_List()\Folded = #Unfolded
				
				If \Cont_Displayed_List()\Type = #Line_Folder
					\Cont_Displayed_List()\Icon = #FontAwesome_Folder_Open
				Else
					\Cont_Displayed_List()\Icon = #FontAwesome_Chevron_Down
				EndIf
				
				Offset = RecurciveUnfold(*GadgetData, \Cont_Displayed_List())
				
				If \State_ActiveLine > Position
					\State_ActiveLine + Offset
				EndIf
				
			Else
				*Line = \Cont_Displayed_List()
				\Cont_Displayed_List()\Folded = #Folded
				
				If \Cont_Displayed_List()\Type = #Line_Folder
					\Cont_Displayed_List()\Icon = #FontAwesome_Folder
				Else
					\Cont_Displayed_List()\Icon = #FontAwesome_Chevron_Right
				EndIf
				
				Offset = - RecurciveFold(*GadgetData, \Cont_Displayed_List())
				
				If \State_ActiveLine > Position
					If \State_ActiveLine <= Position - Offset
						\State_ActiveLine = Position
						*Line\State = #Hot
					Else
						\State_ActiveLine + Offset
					EndIf
				EndIf
			EndIf
			
			\Cont_Displayed_Line + Offset
			SetGadgetAttribute(\Comp_VScrollBar, #PB_ScrollBar_Maximum, \Cont_Displayed_Line - 1)
			Refit(\Comp_Container)
			PostEvent(#PB_Event_Gadget, 0, \Comp_List, #PB_EventType_MouseMove)
		EndWith
	EndProcedure
	
	Procedure VerticalFocus(*GadgetData.GadgetData)
		With *GadgetData
			If \State_ActiveLine > -1
				If \State_ActiveLine < \Meas_VPosition
					SetGadgetState(\Comp_VScrollBar, \State_ActiveLine)
				ElseIf \State_ActiveLine >= \Meas_VPosition + \Meas_Displayed_Lines - 1
					SetGadgetState(\Comp_VScrollBar, \State_ActiveLine - \Meas_Displayed_Lines + 2)
				EndIf
				
				\Meas_VPosition = GetGadgetState(\Comp_VScrollBar)
				PostEvent(#PB_Event_Gadget, 0, \Comp_List, #PB_EventType_MouseMove)
			EndIf
		EndWith
	EndProcedure
	
	Procedure HorizontalFocus(*GadgetData.GadgetData)
		
	EndProcedure
	;}
	
	DataSection
		Corner:
		Data.b $89,$50,$4E,$47,$0D,$0A,$1A,$0A,$00,$00,$00,$0D,$49,$48,$44,$52
		Data.b $00,$00,$00,$03,$00,$00,$00,$03,$08,$06,$00,$00,$00,$56,$28,$B5
		Data.b $BF,$00,$00,$00,$1A,$49,$44,$41,$54,$78,$DA,$63,$90,$54,$B6,$FC
		Data.b $0F,$C4,$FD,$40,$AC,$C8,$00,$62,$30,$C0,$00,$58,$04,$0A,$00,$81
		Data.b $E1,$04,$A9,$ED,$11,$40,$C3,$00,$00,$00,$00,$49,$45,$4E,$44,$AE
		Data.b $42,$60,$82
	EndDataSection
	
EndModule













































; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 1328
; FirstLine = 350
; Folding = AAYgIZAQABgggAg
; EnableXP