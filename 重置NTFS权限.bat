takeown /f * /r /SKIPSL
icacls * /t /q /c /l /reset
icacls * /grant "%username%":(OI)(CI)F  /T /q /c /l