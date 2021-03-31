IncludeFile "PureTimeline.pbi"

Procedure Handler_CloseWindow()
	End
EndProcedure

Procedure Handler_SizeWindow()
 	PureTL::Resize(0, #PB_Ignore, #PB_Ignore, WindowWidth(0) - 20, WindowHeight(0) - 20)
EndProcedure

OpenWindow(0, 0, 0, 700, 400, "PureTimeline Example", #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_SizeGadget)
SmartWindowRefresh(0, #True)
PureTL::Gadget(0, 10, 10, 680, 380)
PureTL::Freeze(0, #True)
PureTL::AddLine(0, -1, "Line 1")
Line = PureTL::AddLine(0, -1, "Line 2")
PureTL::AddLine(0, -1, "SubLine 1", Line)
SubLine = PureTL::AddLine(0, -1, "SubLine 2", Line)
PureTL::AddLine(0, -1, "SubLine 3", Line)
PureTL::AddLine(0, -1, "SubSubLine 1", SubLine)
PureTL::AddLine(0, -1, "SubSubLine 2", SubLine)
PureTL::AddLine(0, -1, "SubSubLine 3", SubLine)
PureTL::AddLine(0, -1, "SubSubLine 4", SubLine)
PureTL::AddLine(0, -1, "Line 3")
PureTL::AddLine(0, -1, "Line 4")
PureTL::AddLine(0, -1, "Line 5")
PureTL::AddLine(0, -1, "Line 6")
PureTL::AddLine(0, -1, "Line 7")

Line = PureTL::GetLineID(0, 0)
PureTL::AddMediaBlock(0, Line, 3, 6)
PureTL::AddMediaBlock(0, Line, 11, 19)
Line = PureTL::GetLineID(0, 1)
PureTL::AddMediaBlock(0, Line, 3, 21, MaterialVector::#Video)
Line = PureTL::GetLineID(0, 2)
PureTL::AddMediaBlock(0, Line, 3, 21, MaterialVector::#Music)

Line = PureTL::GetLineID(0, 3)
PureTL::AddDataPoint(0, Line, 31)
PureTL::AddDataPoint(0, Line, 32)
PureTL::AddDataPoint(0, Line, 33)
PureTL::AddDataPoint(0, Line, 44)

PureTL::AddMediaBlock(0, Line, 12, 32)

Line = PureTL::GetLineID(0, 4)
 PureTL::AddMediaBlock(0, Line, 3, 21, MaterialVector::#Accessibility)
Line = PureTL::GetLineID(0, 5)
PureTL::AddMediaBlock(0, Line, 3, 21)
Line = PureTL::GetLineID(0, 6)
PureTL::AddMediaBlock(0, Line, 3, 21)

PureTL::Freeze(0, #False)
WindowBounds(0, 700, 400, #PB_Ignore, #PB_Ignore)
BindEvent(#PB_Event_CloseWindow, @Handler_CloseWindow())
BindEvent(#PB_Event_SizeWindow, @Handler_SizeWindow())

Repeat
	WaitWindowEvent()
ForEver
; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 46
; Folding = 9
; EnableXP