10 REM N4CWENTERM - Net4CPC Terminal
20 REM Network configuration is now in N4C.CFG
30 MODE 2
40 PRINT "Loading N4C-EWEN Terminal..."
50 PRINT
60 REM Load combined binary (charset + program)
70 MEMORY &6800-1
80 LOAD "EWENN4C.BIN",&6800
90 REM Install RSX
100 CALL &7000
110 REM Setup screen
120 MODE 2:BORDER 0:INK 0,0:INK 1,26
130 PRINT "Ewen-Term Communications program, v3.0 N4C installed."
140 PRINT
150 PRINT "Type |TERM to start terminal mode"
160 PRINT
170 REM Auto-start terminal (uncomment to enable)
180 REM |TERM
