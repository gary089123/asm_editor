
.386
.model flat, stdcall      ; 32 bit memory model
option casemap :none      ; case sensitive

include \masm32\INCLUDE\windows.inc
include \masm32\INCLUDE\masm32.inc
include \masm32\INCLUDE\gdi32.inc
include \masm32\INCLUDE\user32.inc
include \masm32\INCLUDE\kernel32.inc
include \masm32\INCLUDE\comdlg32.inc


includelib \masm32\LIB\masm32.lib
includelib \masm32\LIB\gdi32.lib
includelib \masm32\LIB\user32.lib
includelib \masm32\LIB\kernel32.lib
includelib \masm32\LIB\comdlg32.lib


WinMain proto :DWORD,:DWORD,:DWORD,:DWORD
EditControl proto :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
hEditProc proto :DWORD,:DWORD,:DWORD, :DWORD



m2m MACRO M1, M2
    push M2
    pop  M1
ENDM

return MACRO arg
    mov eax, arg
    ret
ENDM



.data
    Appname db "超簡陋編輯器",0
    ClassName db "Class of GUI",0
    ButtonClass db "button",0
    ButtonText1 db "開新檔案",0
    ButtonText2 db "開啟舊檔",0
    ButtonText3 db "儲存檔案",0
    ButtonText4 db "另存新檔",0
    OpenMsg db "Opened at ",0
    OpenByt db " bytes",0
    CloseMsg db "Saved at ",0
    CloseByt db " bytes",0
    sfTest db "Test",0
    nStr db 0,0
    szFileName    db 260 dup(0)
    ofn           OPENFILENAME <>  ; structure
    ReDLL db "RICHED20.DLL",0
    EditMl db "RichEdit20a",0
    Untitled db "Untitled",0

.data?
    hInstance HINSTANCE ?
    CommandLine LPSTR ?
    hRichEd dd ?
    lpfnhEditProc dd ?
    hWnd dd ?

.code




; -----------------procedure-------------------------

ofCallBack proc dwCookie:DWORD,pbBuff:DWORD,cb:DWORD,pcb:DWORD

    invoke ReadFile,dwCookie,pbBuff,cb,pcb,NULL

    mov eax, 0
    ret

ofCallBack endp

; ----------------------------------------------------------

sfCallBack proc dwCookie:DWORD,pbBuff:DWORD,cb:DWORD,pcb:DWORD

    invoke WriteFile,dwCookie,pbBuff,cb,pcb,NULL

    mov eax, 0
    ret

sfCallBack endp

; --------------------------------------------------

StreamFileIn proc hEdit:DWORD,lpszFileName:DWORD

    LOCAL hFile :DWORD
    LOCAL fSiz  :DWORD
    LOCAL ofs   :OFSTRUCT
    LOCAL est   :EDITSTREAM
    LOCAL buffer[32]:BYTE
    LOCAL aval[8]:BYTE

    invoke OpenFile,lpszFileName,ADDR ofs,OF_READ
    mov hFile, eax

    mov est.dwCookie, eax
    mov est.dwError, 0
    mov eax, offset ofCallBack
    mov est.pfnCallback, eax

    invoke SendMessage,hEdit,EM_STREAMIN,SF_TEXT,ADDR est

    invoke GetFileSize,hFile,NULL
    mov fSiz, eax

    invoke CloseHandle,hFile



    mov buffer[0], 0

    invoke szCatStr,ADDR buffer,ADDR OpenMsg

    invoke dwtoa,fSiz,ADDR aval
    invoke szCatStr,ADDR buffer,ADDR aval
    invoke szCatStr,ADDR buffer,ADDR OpenByt

    invoke SendMessage,hEdit,EM_SETMODIFY,0,0

    mov eax, 0
    ret

StreamFileIn endp

; --------------------------------------------------

StreamFileOut proc hEdit:DWORD,lpszFileName:DWORD

    LOCAL hFile :DWORD
    LOCAL fSiz  :DWORD
    LOCAL ofs   :OFSTRUCT
    LOCAL est   :EDITSTREAM
    LOCAL buffer[32]:BYTE
    LOCAL aval[8]:BYTE

    invoke GetWindowTextLength,hEdit
    mov fSiz, eax
    mov buffer[0], 0

    invoke szCatStr,ADDR buffer,ADDR CloseMsg

    invoke dwtoa,fSiz,ADDR aval
    invoke szCatStr,ADDR buffer,ADDR aval
    invoke szCatStr,ADDR buffer,ADDR CloseByt

    invoke OpenFile,lpszFileName,ADDR ofs,OF_CREATE
    mov hFile, eax

    mov est.dwCookie, eax
    mov est.dwError, 0
    mov eax, offset sfCallBack
    mov est.pfnCallback, eax

    invoke SendMessage,hEdit,EM_STREAMOUT,SF_TEXT,ADDR est
    invoke CloseHandle,hFile

    invoke SendMessage,hEdit,EM_SETMODIFY,0,0

    mov eax, 0
    ret

StreamFileOut endp
;--------------------------------------------------------  

;--------------------------------------------------------
GetFileName proc hParent:DWORD,lpTitle:DWORD,lpFilter:DWORD

    mov ofn.lStructSize,        sizeof OPENFILENAME
    m2m ofn.hwndOwner,          hParent
    m2m ofn.hInstance,          hInstance
    m2m ofn.lpstrFilter,        lpFilter
    m2m ofn.lpstrFile,          offset szFileName
    mov ofn.nMaxFile,           sizeof szFileName
    m2m ofn.lpstrTitle,         lpTitle
    mov ofn.Flags,              OFN_EXPLORER or OFN_FILEMUSTEXIST or \
                                OFN_LONGNAMES

    invoke GetOpenFileName,ADDR ofn

    ret

GetFileName endp

;--------------------------------------------------------
SaveFileName proc hParent:DWORD,lpTitle:DWORD,lpFilter:DWORD

    mov ofn.lStructSize,        sizeof OPENFILENAME
    m2m ofn.hwndOwner,          hParent
    m2m ofn.hInstance,          hInstance
    m2m ofn.lpstrFilter,        lpFilter
    m2m ofn.lpstrFile,          offset szFileName
    mov ofn.nMaxFile,           sizeof szFileName
    m2m ofn.lpstrTitle,         lpTitle
    mov ofn.Flags,              OFN_EXPLORER or OFN_LONGNAMES
                                
    invoke GetSaveFileName,ADDR ofn

    ret

SaveFileName endp

;--------------------------------------------------------



start:
    invoke GetModuleHandle,NULL
    mov hInstance ,eax

    invoke GetCommandLine
    mov CommandLine ,eax
    

    invoke WinMain,hInstance, NULL, CommandLine,SW_SHOWDEFAULT
    invoke ExitProcess ,eax
    

    WinMain proc hInst :DWORD,hPrevInst :DWORD, CmdLine :DWORD,CmdShow :DWORD
        LOCAL wc   :WNDCLASSEX
        LOCAL msg  :MSG
        LOCAL hwnd :HWND

        mov wc.cbSize,         sizeof WNDCLASSEX
        mov wc.style,          CS_BYTEALIGNWINDOW
        mov wc.lpfnWndProc,    offset WndProc
        mov wc.cbClsExtra,     NULL
        mov wc.cbWndExtra,     NULL
        push hInst
        pop wc.hInstance
        mov wc.hbrBackground,  NULL
        mov wc.lpszMenuName,   NULL
        mov wc.lpszClassName,  offset ClassName
        invoke LoadIcon,NULL,IDI_APPLICATION
        mov wc.hIcon ,eax
        mov wc.hIconSm,eax
        invoke LoadCursor,NULL,IDC_ARROW
        mov wc.hCursor,eax


        invoke RegisterClassEx,addr wc
        invoke CreateWindowEx,NULL,addr ClassName,addr Appname,WS_OVERLAPPEDWINDOW,CW_USEDEFAULT,CW_USEDEFAULT,800,600,0,0,hInst,0
        mov hwnd ,eax
        invoke ShowWindow,hwnd,CmdShow
        invoke UpdateWindow,hwnd

        .WHILE TRUE
            invoke GetMessage, addr msg,0,0,0
        .BREAK .IF (!eax)
            invoke TranslateMessage, addr msg
            invoke DispatchMessage,addr msg
        .ENDW
        mov eax,msg.wParam

        RET
    WinMain endp


    WndProc proc hwnd:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

        LOCAL tl     :DWORD
        LOCAL buffer1[128]:BYTE
         
        .IF uMsg==WM_DESTROY
            invoke PostQuitMessage,0
        .ELSEIF uMsg==WM_CREATE
            invoke CreateWindowEx,0,addr ButtonClass,addr ButtonText1,WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON,0,0,100,30,hwnd,1,hInstance,0
            invoke CreateWindowEx,0,addr ButtonClass,addr ButtonText2,WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON,100,0,100,30,hwnd,2,hInstance,0
            invoke CreateWindowEx,0,addr ButtonClass,addr ButtonText3,WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON,300,0,100,30,hwnd,3,hInstance,0
            invoke CreateWindowEx,0,addr ButtonClass,addr ButtonText4,WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON,200,0,100,30,hwnd,4,hInstance,0
            invoke LoadLibrary,ADDR ReDLL
            invoke EditControl,hwnd,0,35,784,520,0
            mov hRichEd, eax
        .ELSEIF uMsg==WM_COMMAND
            .if wParam == 1
                @@:
                invoke SendMessage,hwnd,WM_SETTEXT,0,ADDR Untitled
                invoke SendMessage,hRichEd,WM_SETTEXT,0,0
                invoke SendMessage,hRichEd,EM_SETMODIFY,0,0

            .elseif wParam ==2
                jmp @F
                szTitleO   db "開啟舊檔",0
                szFilterO  db "所有檔案",0,"*.*",0,"文件",0,"*.TEXT",0,0
                @@:

                mov szFileName[0],0
                invoke GetFileName,hwnd,ADDR szTitleO,ADDR szFilterO

                cmp szFileName[0],0 
                je @F
                invoke StreamFileIn,hRichEd,ADDR szFileName
                invoke SetWindowText,hwnd,ADDR szFileName
                @@:

            .elseif wParam ==3
                invoke SendMessage,hwnd,WM_GETTEXTLENGTH,0,0
                mov tl, eax
                inc tl              ; 1 extra for zero terminator

                invoke GetWindowText,hwnd,ADDR buffer1,tl
                invoke lstrcmp,ADDR buffer1,ADDR Untitled

                cmp eax, 0          ; eax is zero is strings are equal
                jne @F
                jmp FileSaveAs
                @@:

                invoke StreamFileOut,hRichEd,ADDR buffer1
                invoke SendMessage,hRichEd,EM_SETMODIFY,0,0
            .elseif wParam ==4
            FileSaveAs:
                jmp @F
                szTitleS   db "Save file as",0
                szFilterS  db "All files",0,"*.*",0,"Text files",0,"*.TEXT",0,0
                @@:

                mov szFileName[0],0
                invoke SaveFileName,hwnd,ADDR szTitleS,ADDR szFilterS

                cmp szFileName[0],0  ;<< zero if cancel pressed in dlgbo?<?L          je @F
                invoke StreamFileOut,hRichEd,ADDR szFileName
                invoke SendMessage,hRichEd,EM_SETMODIFY,0,0
                invoke SendMessage,hwnd,WM_SETTEXT,0,ADDR szFileName
                @@:
            .endif
        .ELSEIF uMsg == WM_SETFOCUS
            invoke SetFocus,hRichEd
        .ELSE
            invoke DefWindowProc,hwnd,uMsg,wParam,lParam
            ret
        .ENDIF
            xor eax,eax
            ret
    WndProc endp
    ;-------------------------------------

    EditControl proc hParent:DWORD, x:DWORD, y:DWORD, wd:DWORD, ht:DWORD, ID:DWORD

    LOCAL hEdit:DWORD

  
    invoke CreateWindowEx,0,ADDR EditMl,0, WS_VISIBLE or ES_SUNKEN or WS_CHILDWINDOW or WS_CLIPSIBLINGS or ES_MULTILINE or WS_VSCROLL or ES_AUTOVSCROLL or ES_NOHIDESEL or WS_HSCROLL or ES_AUTOHSCROLL,x,y,wd,ht,hParent,ID,hInstance,NULL
    mov hEdit, eax

    invoke SetWindowLong,hEdit,GWL_WNDPROC,hEditProc
    mov lpfnhEditProc, eax

    invoke SendMessage,hEdit,WM_SETFONT,eax,0

    invoke SendMessage,hEdit,EM_EXLIMITTEXT,0,100000000
    invoke SendMessage,hEdit,EM_SETOPTIONS,ECOOP_XOR,ECO_SELECTIONBAR

    mov eax, hEdit
    ret

EditControl endp

;-----------------------------------------------
hEditProc proc hCtl   :DWORD,uMsg:DWORD,wParam :DWORD,lParam :DWORD

    LOCAL Pt    :POINT
    LOCAL hSM   :DWORD

    .if uMsg == WM_KEYUP
      
    .elseif uMsg == WM_RBUTTONDOWN
        invoke GetCursorPos,ADDR Pt
        mov hSM, eax
        invoke TrackPopupMenu,hSM,TPM_LEFTALIGN or TPM_LEFTBUTTON, Pt.x,Pt.y,0, hWnd,NULL

    .endif

    invoke CallWindowProc,lpfnhEditProc,hCtl,uMsg,wParam,lParam

    ret

hEditProc endp





end start