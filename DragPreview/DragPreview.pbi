DeclareModule DragPreview
	
	Declare Create(Image, ParentWindow)
	Declare Free(Image)
EndDeclareModule


Module DragPreview
	EnableExplicit 
	
	Procedure Follow(WindowID, Message, WParam, LParam)
	EndProcedure
	
	Procedure Hijack(hWnd, uMsg, wParam, lParam)
		Protected oldproc = GetProp_(hWnd, "DragPreview_oldproc"), X.w, Y.w, Window, WindowID
		
		If uMsg = #WM_MOUSEMOVE
			WindowID = WindowID(GetProp_(hWnd, "DragPreview_Window"))
			X = DesktopMouseX()
			Y = DesktopMouseY()
			
			SetWindowPos_(WindowID, 0, X, Y, 0, 0, #SWP_NOSIZE)
		ElseIf uMsg = #WM_LBUTTONUP
			Debug "c'est fini :D"
			ReleaseCapture_()
			
		EndIf
		
		ProcedureReturn CallWindowProc_(oldproc, hWnd, uMsg, wParam, lParam)
	EndProcedure
	
	Procedure Create(Image, ParentWindow)
		Protected Width = ImageWidth(Image), Height = ImageHeight(Image), Result
		Result = OpenWindow(#PB_Any, DesktopMouseX() + 10, DesktopMouseY() + 0.5 * Height, Width, Height, "", #PB_Window_BorderLess | #PB_Window_Invisible, WindowID(ParentWindow))
		ImageGadget(#PB_Any, 0, 0, Width, Height, ImageID(Image))
		SetProp_(WindowID(ParentWindow), "DragPreview_Window", Result)
		SetWindowLongPtr_(WindowID(Result),#GWL_EXSTYLE,#WS_EX_LAYERED)
		SetLayeredWindowAttributes_(WindowID(Result),0,140,#LWA_ALPHA)
		HideWindow(Result, #False, #PB_Window_NoActivate)
		
; 		SetWindowCallback(@Follow(), Result)
 		SetCapture_(WindowID(ParentWindow))
		
		SetProp_(WindowID(ParentWindow), "DragPreview_oldproc", SetWindowLongPtr_(WindowID(ParentWindow), #GWL_WNDPROC, @Hijack()))
		
		ProcedureReturn Result
	EndProcedure
	
; 	Procedure Free(ID)
; 		RemoveProp_(WindowID(ID), "X")
; 		RemoveProp_(WindowID(ID), "Y")
; 		RemoveProp_(WindowID(ID), "Window")
; 		SetWindowCallback(0, ID)
; 		CloseWindow(ID)
; 	EndProcedure
EndModule


CompilerIf #PB_Compiler_IsMainFile
	CreateImage(0, 120, 40)
	StartDrawing(ImageOutput(0))
	Box(0, 0, 120, 40, $0000FF)
	StopDrawing()
	
	Global Preview
	
	Procedure Display()
		Debug "ok"
		Preview = DragPreview::Create( 0, 0)
	EndProcedure
	
	Procedure Release()
		Debug "!!"
 		DragPreview::Free(Preview)
	EndProcedure
	
	OpenWindow(0, 10, 10, 200, 200, "testouille", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
	CanvasGadget(0, 0, 0, 200, 200)
	BindGadgetEvent(0, @Display(), #PB_EventType_LeftButtonDown)
	BindGadgetEvent(0, @Release(), #PB_EventType_LeftButtonUp)
	                
	
	
	
	Repeat
		WaitWindowEvent()
	ForEver
CompilerEndIf
; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 47
; Folding = --
; EnableXP