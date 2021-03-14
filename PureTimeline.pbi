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
		#LightTheme = 0
		
		#DarkTheme
		#Header
		#Border
	EndEnumeration
	
	EnumerationBinary ; Items flags
		#Item_AutoFill = 1
	EndEnumeration
	
	Enumeration ;Content Type
		#Content_Media
		#Content_DataPoints
	EndEnumeration
	
	#DefaultDuration = 119
	
	; Public procedures declaration
	Declare Gadget(Gadget, X, Y, Width, Height, Flags = #Default)
	
	Declare AddItem(Gadget, Name.s, Position, ParentID = 0, Flags = #Default)
	Declare AddMediaBlock(Gadget, Item, SubItem, Start, Finish, ID, Color)
	Declare AddDataPoint(Gadget, Item, SubItem, Position, ID, Color)
	
	Declare GetItemID(Gadget, Position, ParentID = 0)
	
	Declare SetDuration(Gadget, Duration)
	
	Declare RemoveItem(Gadget, Item)
	
	
	
	Declare Freeze(Gadget, State) ;Disable the redrawing of the gadget (Should be used before a large amount is done to avoid CPU consumption spike)
	Declare Resize(Gadget, x, y, Width, Height)
	
EndDeclareModule

Module PureTL
	EnableExplicit
	;{ Private variables, structures, constants...
	
	Enumeration ;Fold
		#NoFold
		#Folded
		#Unfolded
	EndEnumeration
	
	Enumeration ; MediaBlock Type
		#MediaBlock_Start
		#MediaBlock_Body
		#MediaBlock_End
	EndEnumeration
	
	EnumerationBinary
		#Redraw_Body = 0
		#Redraw_Header
		#Redraw_ItemList
		#Redraw_StateOnly
		#Redraw_Everything = #Redraw_Header | #Redraw_ItemList
	EndEnumeration
	
	Structure Content
		MediaBlock_Color.l
		MediaBlock_End.l
		MediaBlock_Origin.l
		MediaBlock_ID.i
		
		DataPoint.b
		DataPoint_Color.b
		DataPoint_Count.i
		DataPoint_ID.i
	EndStructure

	Structure Itemlist
		*item.Item
	EndStructure
	
	Structure Item
		Name.s
		Folded.b
		AutoFill.b
		DisplayListAdress.i
		*Parent.Item
		List Items.Itemlist()
		; 		Array ContentArray.Content(#DefaultDuration)
		
		;Draw info
		XOffset.i
; 		Image.i
	EndStructure
	
	
	Structure GadgetData
		;Flags & options
		Header.b
		Border.b
		
		;Componants
		VScrollbar_ID.i
		VScrollbar_Visible.b
		VScrollbar_Width.i
		VScrollbar_Page.i
		VScrollbar_Position.i
		
		HScrollbar_ID.i
		HScrollbar_Visible.b
		HScrollbar_Height.i
		HScrollbar_Page.i
		HScrollbar_Position.i
		
		ButtonPlay_ID.i
		ButtonEnd_ID.i
		ButtonStart_ID.i
		
		;state
		ItemList_Width.i
		State.i
		PreviousState.i
		Warm.i
		PreviousWarm.i
		
		Duration.i
		
		;Redraw
		Frozen.b
		YOffset.i
		XOffset.i
		Body_Height.i
		Body_Width.i
		Body_ColumnWidth.i
		FontID.i
		Font.i
		FontSize.i
		VisibleItems.i												;current maximum number of displayable item. Will change when resizing or showing/hiding the header
		VisibleColumns.i											;current  maximum number of displayable time unit. Will change when resizing or zooming.
			
		Color_Border.i
		
		Color_Body_Back.i
		Color_Body_BackAlt.i
		Color_Body_BackHot.i
		
		Color_ItemList_Back.i
		Color_ItemList_Front.i
		Color_ItemList_BackHot.i
		Color_ItemList_FrontHot.i
		Color_ItemList_BackWarm.i
		Color_ItemList_FrontWarm.i
		
		List DisplayList.Itemlist()
		
		;Items
		List Items.Itemlist()
		
	EndStructure
	
	;Style
	#Style_Header_Height = 60
	#Style_Header_ButtonSize = 30
	#Style_Header_ButtonSpace = 20
	#Style_BorderThickness = 1
	
	#Style_ItemList_Width = 240
	#Style_ItemList_ItemHeight = 58
	
	#Style_ItemList_XOffset = 24
	#Style_ItemList_FoldSize = 12
	#Style_ItemList_FoldOffset = 10
	#Style_ItemList_RoundedBoxOffset = 8
	#Style_ItemList_SubItemOffset = 12
	
	#Style_ItemList_FoldVOffset = (#Style_ItemList_ItemHeight - #Style_ItemList_FoldSize) / 2 + 1
	#Style_ItemList_TextVOffset = (#Style_ItemList_ItemHeight - 20) / 2
	#Style_ItemList_FontSize	= 20
	
	#Style_VectorText = #True 										; I find the vector drawn text to impair readability too much on Windows, so we'll fallback on the classic 2D drawing for text... Though drawing twice on the same canvas provokes the occasional flikering.
	
	#Style_Body_DefaultColumnWidth = 15
	#Style_Body_Margin = 2											; Number of empty column placed at the start and the end of the timeline, making the gadget more legible.
	
	Global DefaultFont = LoadFont(#PB_Any, "Bebas Neue", #Style_ItemList_FontSize, #PB_Font_HighQuality)
	
	;Colors
	CompilerIf #PB_Compiler_OS = #PB_OS_Windows ; RGB/GBR switcharoo...
		#Color_Border = $FF101010
		
		#Color_ItemList_Dark_Back = $FF36312F
		#Color_ItemList_Dark_BackHot = $FF433C39
		#Color_ItemList_Dark_BackWarm = $FF3C3734
		
		#Color_ItemList_Dark_Front = $FF97928E
		#Color_ItemList_Dark_FrontHot = $FFFFFFFF
		#Color_ItemList_Dark_FrontWarm = $FFDEDDDC
		
		#Color_ItemList_Light_Back = $FFF5F3F2
		#Color_ItemList_Light_BackHot = $FFDCD7D4
		#Color_ItemList_Light_BackWarm = $FFEDEAE8
		
		#Color_ItemList_Light_Front = $FF80746A
		#Color_ItemList_Light_FrontHot = $FF070606
		#Color_ItemList_Light_FrontWarm = $FF38332E
		
		#Color_Body_Dark_Back    = $FF393532
		#Color_Body_Dark_BackAlt = $FF3F3936
		#Color_Body_Dark_BackHot = $FF46403C
		
		#Color_Body_Light_Back    = $FFF3EDEA
		#Color_Body_Light_BackAlt = $FFE9E3E0
		#Color_Body_Light_BackHot = $FFDCD7D4
		
		
	CompilerElse
		#Color_Border = $101010FF
		
		#Color_ItemList_Dark_Back = $2F3136FF
		#Color_ItemList_Dark_BackHot = $393C43FF
		#Color_ItemList_Dark_BackWarm = $34373CFF
		
		#Color_ItemList_Dark_Front = $8E9297FF
		#Color_ItemList_Dark_FrontHot = $FFFFFFFF
		#Color_ItemList_Dark_FrontWarm = $DCDDDEFF
		
		#Color_ItemList_Light_Back = $F2F3F5FF
		#Color_ItemList_Light_BackHot = $D4D7DCFF
		#Color_ItemList_Light_BackWarm = $E8EAEDFF
		
		#Color_ItemList_Light_Front = $6A7480FF
		#Color_ItemList_Light_FrontHot = $060607FF
		#Color_ItemList_Light_FrontWarm = $2E3338FF
		
		#Color_Body_Dark_Back = $323539FF
		#Color_Body_Dark_BackAlt = $36393FFF
		#Color_Body_Dark_BackHot = $3C4046FF
		
		#Color_Body_Light_Back    = $FFEAEDF3
		#Color_Body_Light_BackAlt = $FFE0E3E9
		#Color_Body_Light_BackHot = $D4D7DCFF
		
	CompilerEndIf
	
	;Icons
	
	;}
	
	; Private procedures declaration
	Declare Redraw(Gadget, RedrawPart = #Redraw_Body)
	
	Declare HandlerCanvas()
	
	Declare HandlerVScrollbar()
	
	Declare Refit(Gadget)
	
	Declare ToggleFold(Gadget, *Item.Item)
	
	Macro FocusOnSelection
		If *Data\State < *Data\VScrollbar_Position
			SetGadgetState(*Data\VScrollbar_ID, *Data\State)
			*Data\VScrollbar_Position = GetGadgetState(*Data\VScrollbar_ID)
		ElseIf *Data\State >= *Data\VScrollbar_Position + *Data\VisibleItems
			SetGadgetState(*Data\VScrollbar_ID, *Data\State - *Data\VisibleItems + 1)
			*Data\VScrollbar_Position = GetGadgetState(*Data\VScrollbar_ID)
		EndIf
	EndMacro
	
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
				\Color_Border = #Color_Border
				
				If Flags & #DarkTheme
					\Color_Body_Back = #Color_Body_Dark_Back
					\Color_Body_BackAlt = #Color_Body_Dark_BackAlt
					\Color_Body_BackHot = #Color_Body_Dark_BackHot
					
					\Color_ItemList_Back = #Color_ItemList_Dark_Back
					\Color_ItemList_Front = #Color_ItemList_Dark_Front
					\Color_ItemList_BackHot = #Color_ItemList_Dark_BackHot
					\Color_ItemList_FrontHot = #Color_ItemList_Dark_FrontHot
					\Color_ItemList_BackWarm = #Color_ItemList_Dark_BackWarm
					\Color_ItemList_FrontWarm = #Color_ItemList_Dark_FrontWarm
					
					Theme = CanvasButton::#DarkTheme
				Else
					\Color_Body_Back = #Color_Body_Light_Back
					\Color_Body_BackAlt = #Color_Body_Light_BackAlt
					\Color_Body_BackHot = #Color_Body_Light_BackHot
					
					\Color_ItemList_Back = #Color_ItemList_Light_Back
					\Color_ItemList_Front = #Color_ItemList_Light_Front
					\Color_ItemList_BackHot = #Color_ItemList_Light_BackHot
					\Color_ItemList_FrontHot = #Color_ItemList_Light_FrontHot
					\Color_ItemList_BackWarm = #Color_ItemList_Light_BackWarm
					\Color_ItemList_FrontWarm = #Color_ItemList_Light_FrontWarm
					
					Theme = CanvasButton::#LightTheme
				EndIf
				
				\Border = Bool(Flags & #Border) * #Style_BorderThickness
				\Header = Bool(Flags & #Header)
				
				If \Header
					\ButtonStart_ID = CanvasButton::GadgetImage(#PB_Any,
					                                                 (#Style_ItemList_Width - 3 * #Style_Header_ButtonSize - 2 * #Style_Header_ButtonSpace) * 0.5, (#Style_Header_Height - #Style_Header_ButtonSize) * 0.5,
					                                                 #Style_Header_ButtonSize,
					                                                 #Style_Header_ButtonSize,
					                                                 MaterialVector::#Skip,
					                                                 CanvasButton::#MaterialVectorIcon | Theme | MaterialVector::#style_rotate_180)
					CanvasButton::SetColor(\ButtonStart_ID, CanvasButton::#ColorType_BackCold, \Color_ItemList_Back)
					CanvasButton::SetColor(\ButtonStart_ID, CanvasButton::#ColorType_BackWarm, \Color_ItemList_Back)
					CanvasButton::SetColor(\ButtonStart_ID, CanvasButton::#ColorType_BackHot, \Color_ItemList_Back)
					
					\ButtonPlay_ID = CanvasButton::GadgetImage(#PB_Any, (#Style_ItemList_Width - 3 * #Style_Header_ButtonSize - 2 * #Style_Header_ButtonSpace) * 0.5 + #Style_Header_ButtonSize + #Style_Header_ButtonSpace,
					                                                (#Style_Header_Height - #Style_Header_ButtonSize) * 0.5,
					                                                #Style_Header_ButtonSize,
					                                                #Style_Header_ButtonSize,
					                                                MaterialVector::#Play,
					                                                CanvasButton::#MaterialVectorIcon | Theme)
					CanvasButton::SetColor(\ButtonPlay_ID, CanvasButton::#ColorType_BackCold, \Color_ItemList_Back)
					CanvasButton::SetColor(\ButtonPlay_ID, CanvasButton::#ColorType_BackWarm, \Color_ItemList_Back)
					CanvasButton::SetColor(\ButtonPlay_ID, CanvasButton::#ColorType_BackHot, \Color_ItemList_Back)
					
					\ButtonEnd_ID = CanvasButton::GadgetImage(#PB_Any, (#Style_ItemList_Width - 3 * #Style_Header_ButtonSize - 2 * #Style_Header_ButtonSpace) * 0.5 + (#Style_Header_ButtonSize + #Style_Header_ButtonSpace) * 2, (#Style_Header_Height - #Style_Header_ButtonSize) * 0.5,
					                                               #Style_Header_ButtonSize,
					                                               #Style_Header_ButtonSize,
					                                               MaterialVector::#Skip,
					                                               CanvasButton::#MaterialVectorIcon | Theme)
					
					CanvasButton::SetColor(\ButtonEnd_ID, CanvasButton::#ColorType_BackCold, \Color_ItemList_Back)
					CanvasButton::SetColor(\ButtonEnd_ID, CanvasButton::#ColorType_BackWarm, \Color_ItemList_Back)
					CanvasButton::SetColor(\ButtonEnd_ID, CanvasButton::#ColorType_BackHot, \Color_ItemList_Back)
				EndIf
				
				\ItemList_Width = #Style_ItemList_Width
				\YOffset = \Border + \Header * #Style_Header_Height
				\Body_ColumnWidth = #Style_Body_DefaultColumnWidth
				
				\State = -1
				\PreviousState = -1
				\PreviousWarm = -1
				\Duration = #DefaultDuration
				
				\VScrollbar_ID = ScrollBarGadget(#PB_Any, 0, \YOffset, 20, \Body_Height, 0, 10, 10,   #PB_ScrollBar_Vertical)
				BindGadgetEvent(\VScrollbar_ID, @HandlerVScrollbar())
				\VScrollbar_Width = GadgetWidth(\VScrollbar_ID, #PB_Gadget_RequiredSize)
				\VScrollbar_Visible = #False
				HideGadget(\VScrollbar_ID, #True)
				SetGadgetData(\VScrollbar_ID, Gadget)
				
				\HScrollbar_ID = ScrollBarGadget(#PB_Any, 0, \YOffset, 20, \Body_Height, 0, \Duration + #Style_Body_Margin, 10)
				\HScrollbar_Height = GadgetHeight(\HScrollbar_ID, #PB_Gadget_RequiredSize)
				\HScrollbar_Visible = #False
				HideGadget(\HScrollbar_ID, #True)
				SetGadgetData(\HScrollbar_ID, Gadget)
				
				\FontID = FontID(DefaultFont)
				\Font = DefaultFont
				\FontSize = #Style_ItemList_FontSize
			EndWith
			CloseGadgetList()
			
			SetGadgetData(Gadget, *Data)
			BindGadgetEvent(Gadget, @HandlerCanvas())
			
			Refit(Gadget)
		EndIf
		
		ProcedureReturn Result
	EndProcedure
	
	Procedure AddItem(Gadget, Name.s, Position, *Parent.Item = 0, Flags = #Default)
		Protected *Data.GadgetData = GetGadgetData(Gadget), *Result.Item = AllocateStructure(Item)
		
		If *Parent.Item ;{ Add a subitem
			If Position = -1 Or Position >= ListSize(*Parent\Items())
				If *Parent\DisplayListAdress And *Parent\Folded = #Unfolded
					If ListSize(*Parent\Items()) = 0
						ChangeCurrentElement(*Data\DisplayList(), *Parent\DisplayListAdress)
					Else
						LastElement(*Parent\Items())
						ChangeCurrentElement(*Data\DisplayList(), *Parent\Items()\item\DisplayListAdress)
					EndIf
					AddElement(*Data\DisplayList())
					*Result\DisplayListAdress = @*Data\DisplayList()
					*Data\DisplayList()\item = *Result
				Else
					LastElement(*Parent\Items())
				EndIf
				AddElement(*Parent\Items())
			Else
				If *Parent\DisplayListAdress And *Parent\Folded = #Unfolded
					If Position = 0
						ChangeCurrentElement(*Data\DisplayList(), *Parent\DisplayListAdress)
					Else
						SelectElement(*Parent\Items(), Position)
						ChangeCurrentElement(*Data\DisplayList(), *Parent\Items()\item\DisplayListAdress)
					EndIf
					AddElement(*Data\DisplayList())
					*Result\DisplayListAdress = @*Data\DisplayList()
					*Data\DisplayList()\item = *Result
				Else
					SelectElement(*Parent\Items(), Position)
				EndIf
				
				InsertElement(*Parent\Items())
			EndIf
			
			*Parent\Items()\item = *Result
			
			If *Parent\Folded = #NoFold
				*Parent\Folded = #Folded
			EndIf
			
			*Result\Parent = *Parent
			*Result\XOffset = *Parent\XOffset + #Style_ItemList_SubItemOffset + #Style_ItemList_FoldSize + #Style_ItemList_FoldOffset
			;}
		Else ;{ add a normal item
			If Position = -1 Or Position >= ListSize(*Data\Items())
				LastElement(*Data\Items())
				AddElement(*Data\Items())
				LastElement(*Data\DisplayList())
				AddElement(*Data\DisplayList())
			Else
				SelectElement(*Data\Items(), Position)
				InsertElement(*Data\Items())
				NextElement(*Data\Items())
				ChangeCurrentElement(*Data\DisplayList(), *Data\Items()\item\DisplayListAdress)
				InsertElement(*Data\DisplayList())
			EndIf
			
			*Data\Items()\item = *Result
			*Result\DisplayListAdress = @*Data\DisplayList()
			*Result\XOffset = #Style_ItemList_XOffset
			*Data\DisplayList()\item = *Result
		EndIf ;}
		
		*Result\AutoFill = Flags & #Item_AutoFill
		*Result\Name = Name
		
		;redim le tableau de contenu
		
		
		;There might be a need to display the vscrollingbar now...
		Refit(Gadget)
		
		ProcedureReturn *Result
	EndProcedure
	
	Procedure GetItemID(Gadget, Position, ParentID = 0)
		
	EndProcedure
	
	Procedure RemoveItem(Gadget, Item)
		
	EndProcedure
	
	Procedure SetDuration(Gadget, Duration)
		Protected *Data.GadgetData = GetGadgetData(Gadget)
		
		*Data\Duration = Duration
		
		SetGadgetAttribute(*Data\HScrollbar_ID, #PB_ScrollBar_Maximum, *Data\Duration + #Style_Body_Margin)
		Refit(Gadget)
	EndProcedure
	
	Procedure Freeze(Gadget, State)
		Protected *Data.GadgetData = GetGadgetData(Gadget)
		*Data\Frozen = State
		
		If *Data\Frozen And Not State
			*Data\Frozen = #False
			Redraw(Gadget, #True)
		EndIf
		
		*Data\Frozen = State
	EndProcedure
	
	Procedure Resize(Gadget, x, y, Width, Height)
		ResizeGadget(Gadget, x, y, Width, Height)
		Refit(Gadget)
	EndProcedure
	
	Procedure AddMediaBlock(Gadget, Item, SubItem, Start, Finish, ID, Color)
		
	EndProcedure
	
	Procedure AddDataPoint(Gadget, Item, SubItem, Position, ID, Color)
		
	EndProcedure
	
	; Private procedures
	Procedure Redraw(Gadget, RedrawPart = #Redraw_Body)
		Protected *data.GadgetData = GetGadgetData(Gadget)
		Protected Loop, YPos
		
		If *data\Frozen
			ProcedureReturn #False
		EndIf
		
		StartVectorDrawing(CanvasVectorOutput(Gadget))
		VectorFont(*data\FontID, *data\FontSize)
		
		If RedrawPart & #Redraw_StateOnly ;{
			If *Data\PreviousWarm > -1
				
				SelectElement(*data\DisplayList(), *Data\PreviousWarm)
				YPos = *data\YOffset + #Style_ItemList_ItemHeight * (ListIndex(*data\DisplayList()) - *data\VScrollbar_Position)
				
				AddPathBox(*data\Border, YPos, *data\ItemList_Width - 1, #Style_ItemList_ItemHeight)
				VectorSourceColor(*data\Color_ItemList_Back)
				FillPath()
				
				VectorSourceColor(*data\Color_ItemList_Front)
				MovePathCursor(*data\Border + *data\DisplayList()\item\XOffset + Bool(*data\DisplayList()\item\Folded) * (#Style_ItemList_FoldSize + #Style_ItemList_FoldOffset),
				               YPos + #Style_ItemList_TextVOffset)
				DrawVectorText(*data\DisplayList()\item\Name)
				
				If *data\DisplayList()\item\Folded = #Folded
					MaterialVector::Draw(MaterialVector::#Chevron, *data\Border + *data\DisplayList()\item\XOffset,
					                     YPos + #Style_ItemList_FoldVOffset,
					                     #Style_ItemList_FoldSize,
					                     *data\Color_ItemList_Front, 0,
					                     MaterialVector::#style_rotate_90)
				ElseIf *data\DisplayList()\item\Folded = #Unfolded
					MaterialVector::Draw(MaterialVector::#Chevron, *data\Border + *data\DisplayList()\item\XOffset,
					                     YPos + #Style_ItemList_FoldVOffset,
					                     #Style_ItemList_FoldSize,
					                     *data\Color_ItemList_Front, 0,
					                     MaterialVector::#style_rotate_180)
				EndIf
				
				*Data\PreviousWarm = -1
			EndIf
			
			If *Data\Warm > -1
				SelectElement(*data\DisplayList(), *Data\Warm)
				YPos = *data\YOffset + #Style_ItemList_ItemHeight * (ListIndex(*data\DisplayList()) - *data\VScrollbar_Position)
				
				MaterialVector::AddPathRoundedBox(*data\DisplayList()\item\XOffset - #Style_ItemList_RoundedBoxOffset, YPos, *data\ItemList_Width - *data\DisplayList()\item\XOffset, #Style_ItemList_ItemHeight, 6)
				VectorSourceColor(*data\Color_ItemList_BackWarm)
				FillPath()
				
				VectorSourceColor(*data\Color_ItemList_FrontWarm)
				MovePathCursor(*data\Border + *data\DisplayList()\item\XOffset + Bool(*data\DisplayList()\item\Folded) * (#Style_ItemList_FoldSize + #Style_ItemList_FoldOffset),
				               YPos + #Style_ItemList_TextVOffset)
				DrawVectorText(*data\DisplayList()\item\Name)
				
				If *data\DisplayList()\item\Folded = #Folded
					MaterialVector::Draw(MaterialVector::#Chevron, *data\Border + *data\DisplayList()\item\XOffset,
					                     YPos + #Style_ItemList_FoldVOffset,
					                     #Style_ItemList_FoldSize,
					                     *data\Color_ItemList_FrontWarm, 0,
					                     MaterialVector::#style_rotate_90)
				ElseIf *data\DisplayList()\item\Folded = #Unfolded
					MaterialVector::Draw(MaterialVector::#Chevron, *data\Border + *data\DisplayList()\item\XOffset,
					                     YPos + #Style_ItemList_FoldVOffset,
					                     #Style_ItemList_FoldSize,
					                     *data\Color_ItemList_FrontWarm, 0,
					                     MaterialVector::#style_rotate_180)
				EndIf
			EndIf
			
			
			StopVectorDrawing()
			ProcedureReturn #True
		EndIf ;}
		
		;{ Header
		If RedrawPart & #Redraw_Header
			; Redraw the header
			AddPathBox(*data\Border, *data\Border, *data\ItemList_Width, #Style_Header_Height)
			VectorSourceColor(*data\Color_ItemList_Back)
			FillPath()
		EndIf
		;}
		
		If RedrawPart & #Redraw_ItemList
			AddPathBox(*data\Border, *data\YOffset, *data\ItemList_Width, *data\Body_Height)
			VectorSourceColor(*data\Color_ItemList_Back)
			FillPath()
		EndIf
		
		AddPathBox(*data\XOffset, *data\YOffset, *data\Body_Width, *data\Body_Height)
		VectorSourceColor(*data\Color_Body_Back)
		FillPath()
		
		If SelectElement(*data\DisplayList(), *data\VScrollbar_Position)
			For Loop = 0 To *data\VisibleItems
				YPos = Loop * #Style_ItemList_ItemHeight + *data\YOffset
				
				If ListIndex(*data\DisplayList()) = *data\State
					If RedrawPart & #Redraw_ItemList
						MaterialVector::AddPathRoundedBox(*data\DisplayList()\item\XOffset - #Style_ItemList_RoundedBoxOffset, YPos, *data\ItemList_Width, #Style_ItemList_ItemHeight, 6)
						VectorSourceColor(*data\Color_ItemList_BackHot)
						FillPath()
					EndIf
					
					AddPathBox(*data\XOffset, *data\YOffset + (Loop) * #Style_ItemList_ItemHeight, *data\Body_Width, #Style_ItemList_ItemHeight)
					VectorSourceColor(*data\Color_Body_BackHot)
					FillPath()
				ElseIf (Loop + *data\VScrollbar_Position) % 2
					AddPathBox(*data\XOffset, *data\YOffset + (Loop) * #Style_ItemList_ItemHeight, *data\Body_Width, #Style_ItemList_ItemHeight)
					VectorSourceColor(*data\Color_Body_BackAlt)
					FillPath()
				EndIf
				
				If RedrawPart & #Redraw_ItemList
					If ListIndex(*data\DisplayList()) = *data\State
						If *data\DisplayList()\item\Folded = #Folded
							MaterialVector::Draw(MaterialVector::#Chevron, *data\Border + *data\DisplayList()\item\XOffset,
							                     YPos + #Style_ItemList_FoldVOffset,
							                     #Style_ItemList_FoldSize,
							                     *data\Color_ItemList_FrontHot, 0,
							                     MaterialVector::#style_rotate_90)
							
						ElseIf *data\DisplayList()\item\Folded = #Unfolded
							MaterialVector::Draw(MaterialVector::#Chevron, *data\Border + *data\DisplayList()\item\XOffset,
							                     YPos + #Style_ItemList_FoldVOffset,
							                     #Style_ItemList_FoldSize,
							                     *data\Color_ItemList_FrontHot, 0,
							                     MaterialVector::#style_rotate_180)
						EndIf
						VectorSourceColor(*data\Color_ItemList_FrontHot)
					Else
						If *data\DisplayList()\item\Folded = #Folded
							MaterialVector::Draw(MaterialVector::#Chevron, *data\Border + *data\DisplayList()\item\XOffset,
							                     YPos + #Style_ItemList_FoldVOffset,
							                     #Style_ItemList_FoldSize,
							                     *data\Color_ItemList_Front, 0,
							                     MaterialVector::#style_rotate_90)
						ElseIf *data\DisplayList()\item\Folded = #Unfolded
							MaterialVector::Draw(MaterialVector::#Chevron, *data\Border + *data\DisplayList()\item\XOffset,
							                     YPos + #Style_ItemList_FoldVOffset,
							                     #Style_ItemList_FoldSize,
							                     *data\Color_ItemList_Front, 0,
							                     MaterialVector::#style_rotate_180)
						EndIf
						VectorSourceColor(*data\Color_ItemList_Front)
					EndIf
					
					If RedrawPart & #Redraw_ItemList
						MovePathCursor(*data\Border + *data\DisplayList()\item\XOffset + Bool(*data\DisplayList()\item\Folded) * (#Style_ItemList_FoldSize + #Style_ItemList_FoldOffset),
						               YPos + #Style_ItemList_TextVOffset)
						DrawVectorText(*data\DisplayList()\item\Name)
					EndIf
					
					If Not NextElement(*Data\DisplayList())
						Break
					EndIf
				EndIf
			Next
		EndIf
		
		;{ Border
		CompilerIf #Style_VectorText
			If *data\Border
				AddPathBox(0, 0, VectorOutputWidth(), VectorOutputHeight())
			EndIf
		CompilerEndIf
		
		MovePathCursor(*data\XOffset - 0.5, *data\YOffset + 0.5)
		AddPathLine(0, *data\Body_Height, #PB_Path_Relative)
		VectorSourceColor(*data\Color_Border)
		StrokePath(1)
		;}
		
		StopVectorDrawing()
	EndProcedure
	
	Procedure HandlerCanvas()
		Protected Gadget = EventGadget(), *Data.GadgetData = GetGadgetData(Gadget)
		Protected MouseX = GetGadgetAttribute(Gadget, #PB_Canvas_MouseX), MouseY = GetGadgetAttribute(Gadget, #PB_Canvas_MouseY)
		Protected Item
		
		Select EventType()
			Case #PB_EventType_MouseMove
				If MouseY <= *data\YOffset ;{ Header
					If *Data\Warm > -1
						*Data\PreviousWarm = *Data\Warm
						*Data\Warm = -1
						Redraw(Gadget, #Redraw_StateOnly)
					EndIf
					;}
				ElseIf MouseX < *data\XOffset ;{ Itemlist
					Item = Round((MouseY - *data\YOffset) / #Style_ItemList_ItemHeight, #PB_Round_Down) + *data\VScrollbar_Position
					
					If Item <> *Data\Warm 
						*Data\PreviousWarm = *Data\Warm
						If Item <> *Data\State And Item < ListSize(*Data\DisplayList())
							*Data\Warm = Item
						Else
							*Data\Warm = -1
						EndIf
						Redraw(Gadget, #Redraw_StateOnly)
					EndIf
					
					;}
				Else ;{ Timeline
					If *Data\Warm > -1
						*Data\PreviousWarm = *Data\Warm
						*Data\Warm = -1
						Redraw(Gadget, #Redraw_StateOnly)
					EndIf
					
					
					;}
				EndIf
			Case #PB_EventType_LeftButtonDown
				If MouseY <= *data\YOffset ; Header
					
				ElseIf MouseX < *data\XOffset ;{ Itemlist
					Item = Round((MouseY - *data\YOffset) / #Style_ItemList_ItemHeight, #PB_Round_Down) + *data\VScrollbar_Position
					
					If Item <> *Data\State
						*Data\Warm = -1
						*Data\State = Item
						Redraw(Gadget, #Redraw_ItemList)
					EndIf
					;}
				Else ; Timeline
					
				EndIf
			Case #PB_EventType_MouseLeave
				If *Data\Warm > -1
					*Data\PreviousWarm = *Data\Warm
					*Data\Warm = -1
					Redraw(Gadget, #Redraw_StateOnly)
				EndIf
			Case #PB_EventType_LeftButtonDown
			Case #PB_EventType_LeftDoubleClick
			Case #PB_EventType_KeyDown
			Case #PB_EventType_MouseWheel ;{
				If *data\VScrollbar_Visible
					SetGadgetState(*data\VScrollbar_ID, GetGadgetState(*data\VScrollbar_ID) - GetGadgetAttribute(Gadget, #PB_Canvas_WheelDelta))
					Item = GetGadgetState(*data\VScrollbar_ID)
					If Item <> *data\VScrollbar_Position
						*data\VScrollbar_Position = Item
						Redraw(Gadget, #Redraw_ItemList)
					EndIf
				EndIf
				;}
		EndSelect
		
		
	EndProcedure
	
	Procedure ToggleFold(Gadget, *Item.Item)
		
	EndProcedure
	
	Procedure HandlerVScrollbar()
		Protected Gadget = EventGadget()
		Protected State = GetGadgetState(Gadget)
		Protected Canvas = GetGadgetData(Gadget)
		Protected *data.GadgetData = GetGadgetData(Canvas)
		
		If Not (State = *data\VScrollbar_Position)
			*data\VScrollbar_Position = State
			Redraw(Canvas, #Redraw_ItemList)
		EndIf
	EndProcedure
	
	Procedure SearchDisplayedItem(*Data.GadgetData, *Adress)
		
	EndProcedure
	
	Procedure Refit(Gadget)
		Protected Height = GadgetHeight(Gadget), Width = GadgetWidth(Gadget)
		Protected *data.GadgetData = GetGadgetData(Gadget)
		Protected DisplayedItemCount = ListSize(*Data\DisplayList())
		
		*data\XOffset = *data\Border + *data\ItemList_Width
		*data\Body_Height = Height - *data\YOffset - *data\Border
		*data\Body_Width = Width - *data\ItemList_Width - 2 * *data\Border
		*data\VisibleItems = Round(*data\Body_Height / #Style_ItemList_ItemHeight, #PB_Round_Down)
		
		If DisplayedItemCount >= *data\VisibleItems
			*data\VScrollbar_Visible = #True
			SetGadgetAttribute(*data\VScrollbar_ID, #PB_ScrollBar_Maximum, DisplayedItemCount - 1)
			SetGadgetAttribute(*data\VScrollbar_ID, #PB_ScrollBar_PageLength, *data\VisibleItems)
		Else
			*data\VScrollbar_Visible = #False
			SetGadgetState(*data\VScrollbar_ID, 0)
			*data\VScrollbar_Position = 0
		EndIf
		
		If *data\VScrollbar_Visible
			ResizeGadget(*data\VScrollbar_ID, Width - *data\VScrollbar_Width, *data\YOffset, *data\VScrollbar_Width, *data\Body_Height)
			HideGadget(*data\VScrollbar_ID, #False)
		Else
			HideGadget(*data\VScrollbar_ID, #True)
		EndIf
		
		Redraw(Gadget, #Redraw_Everything)
	EndProcedure
EndModule













































; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 745
; FirstLine = 335
; Folding = cYA6v-
; EnableXP