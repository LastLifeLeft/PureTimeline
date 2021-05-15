UsePNGImageDecoder()

IncludeFile "PureTimeline.pbi"

Global TaskList = TaskList::Create()

Procedure Handler_UndoRedo()
	If EventMenu() = 0
		TaskList::Undo(TaskList)
	Else
		TaskList::Redo(TaskList)
	EndIf
EndProcedure

Procedure Handler_CloseWindow()
	End
EndProcedure

Procedure Handler_SizeWindow()
  	PureTL::Resize(0, #PB_Ignore, #PB_Ignore, WindowWidth(0) - 20, WindowHeight(0) - 20)
EndProcedure
Global line, ParentLine

OpenWindow(0, 0, 0, 700, 400, "PureTimeline Example", #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_SizeGadget)

SetWindowColor(0, $3A231A)

PureTL::Gadget(0, 10, 10, 680, 380)
PureTL::SetTaskList(0, TaskList)
ParentLine = PureTL::AddLine(0, -1, "Scene", 0, PureTL::#Line_Folder)
line = PureTL::AddLine(0, -1, "Background", ParentLine)
PureTL::AddMediaBlock(0, line, 11, 31, "󰕧", "S01E03_cave.mp4", $00CFDD)
line = PureTL::AddLine(0, -1, "HDRI", ParentLine)
PureTL::AddMediaBlock(0, line, 0, 100, "󰋩", "Cave", $FDAC41)
line = PureTL::AddLine(0, -1, "Camera", ParentLine)
PureTL::AddMediaBlock(0, line, 27, 101, "󰻇", "Dramatic zoom", $39DA8A )
ParentLine = PureTL::AddLine(0, -1, "Actors", 0, PureTL::#Line_Folder)
PureTL::AddLine(0, -1, "Broken bot", ParentLine)
line = PureTL::AddLine(0, -1, "Overlay")
PureTL::AddMediaBlock(0, line, 20, 21, "󱄤", "Fade In", $FF5B5C)
PureTL::AddMediaBlock(0, line, 57, 40, "󱄤", "Something", $FF5B5C)

BindEvent(#PB_Event_CloseWindow, @Handler_CloseWindow())
AddKeyboardShortcut(0, #PB_Shortcut_Control | #PB_Shortcut_Z, 0)
AddKeyboardShortcut(0, #PB_Shortcut_Control | #PB_Shortcut_Y, 1)
BindEvent(#PB_Event_Menu, @Handler_UndoRedo())
BindEvent(#PB_Event_SizeWindow, @Handler_SizeWindow())

Repeat
	WaitWindowEvent()
ForEver
; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 40
; Folding = 0
; EnableXP