CompilerIf Not Defined(MaterialVector, #PB_Module)
	IncludeFile "MaterialVector\MaterialVector.pbi"
CompilerEndIf

CompilerIf Not Defined(CanvasButton, #PB_Module)
	IncludeFile "CanvasButton\CanvasButton.pbi"
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
	
	;}
	
	;{ Private procedures declaration
	; Non specific
	Declare Min(a, b)
	Declare Max(a, b)
	;}
	
	;{ Public procedures
	Procedure Gadget(Gadget, X, Y, Width, Height, Flags = #Default)
		Protected Result = CanvasGadget(X, Y, Width, Height, #PB_Canvas_Container)
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
	;}
EndModule













































; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 386
; Folding = EAH5z
; EnableXP