#  Test suite for cltest

This is the test file for the `cltest` program. Yes, the program can test itself!

This file runs all the files inside the `testme` folder and checks the results. The command line options are also tested.

    Usage: ./cltest testme.md


## Preparing

Make sure we're on the same folder as `cltest`, since all the file paths here are relative, not absolute.

```
$ test -f ./cltest; echo $?
0
$ test -d ./testme/; echo $?
0
$
```

Set a default terminal width of 80 columns. It's used by separator lines.

```
$ COLUMNS=80
$ export COLUMNS
$
```

Ok. Now the real tests begins.

## Variables are persistent between tests?

```
$ echo $COLUMNS
80
$ not_exported=1
$ echo $not_exported
1
$ echo $not_exported  #→ 1
$ echo $not_exported  #→ --regex ^1$
```

## Check the temporary dir creation

```
$ TMPDIR___SAVE="$TMPDIR"
$ TMPDIR=/XXnotfoundXX
$ export TMPDIR
$ ./cltest testme/ok-1.sh 2>&1 | sed 's/cltest\.[0-9]*$/cltest.NNN/'
mkdir: /XXnotfoundXX: No such file or directory
cltest: Error: cannot create temporary dir: /XXnotfoundXX/cltest.NNN
$ TMPDIR="$TMPDIR___SAVE"
$
```

## I/O, file reading  (message and exit code)

```
$ ./cltest XXnotfoundXX.sh; echo $?
cltest: Error: cannot read input file: XXnotfoundXX.sh
2
$ ./cltest .
cltest: Error: cannot read input file: .
$ ./cltest ./
cltest: Error: cannot read input file: ./
$ ./cltest /etc
cltest: Error: cannot read input file: /etc
$
```

## No test found (message and exit code)

```
$ ./cltest testme/no-test-found.sh; echo $?
cltest: Error: no test found in input file: testme/no-test-found.sh
2
$ ./cltest testme/empty-file.sh
cltest: Error: no test found in input file: testme/empty-file.sh
$ ./cltest testme/empty-prompt-file.sh
cltest: Error: no test found in input file: testme/empty-prompt-file.sh
$ ./cltest testme/empty-prompts-file.sh
cltest: Error: no test found in input file: testme/empty-prompts-file.sh
$
```

## Option --version

```
$ v="$(grep ^tt_my_version= ./cltest | cut -d = -f 2 | tr -d \')"
$ ./cltest -V | grep "^cltest ${v}$" > /dev/null; echo $?
0
$ ./cltest --version | grep "^cltest ${v}$" > /dev/null; echo $?
0
$
```

## Option --help

```
$ ./cltest | sed -n '1p; $p'
Usage: cltest [options] <file ...>
      --prompt STRING         Set prompt string (default: '$ ')
$ ./cltest -h | sed -n '1p; $p'
Usage: cltest [options] <file ...>
      --prompt STRING         Set prompt string (default: '$ ')
$ ./cltest --help
Usage: cltest [options] <file ...>

Options:
  -1, --first                 Stop execution upon first failed test
  -l, --list                  List all the tests (no execution)
  -L, --list-run              List all the tests with OK/FAIL status
  -t, --test RANGE            Run specific tests, by number (1,2,4-7)
  -s, --skip RANGE            Skip specific tests, by number (1,2,4-7)
      --pre-flight COMMAND    Execute command before running the first test
      --post-flight COMMAND   Execute command after running the last test
  -q, --quiet                 Quiet operation, no output shown
  -v, --verbose               Show each test being executed
  -V, --version               Show program version and exit

Customization options:
      --color WHEN            Set when to use colors: auto, always, never
      --diff-options OPTIONS  Set diff command options (default: '-u')
      --inline-prefix PREFIX  Set inline output prefix (default: '#→ ')
      --prefix PREFIX         Set command line prefix (default: '')
      --prompt STRING         Set prompt string (default: '$ ')
$
```

## Option --quiet and exit code

```
$ ./cltest -q testme/ok-2.sh; echo $?
0
$ ./cltest --quiet testme/ok-2.sh; echo $?
0
$ ./cltest --quiet testme/ok-2.sh testme/ok-2.sh; echo $?
0
$ ./cltest --quiet testme/fail-2.sh; echo $?
1
$ ./cltest --quiet testme/fail-2.sh testme/fail-2.sh; echo $?
1
$ ./cltest --quiet testme/ok-2.sh testme/fail-2.sh; echo $?
1
$
```

## Option --quiet also silences --verbose

```
$ ./cltest --quiet --verbose testme/ok-2.sh
$ ./cltest --quiet --verbose testme/fail-2.sh
$ ./cltest --quiet --verbose testme/ok-2.sh testme/ok-2.sh
$ ./cltest --quiet --verbose testme/ok-2.sh testme/fail-2.sh
$
```

## Option --quiet has no effect in error messages

```
$ ./cltest --quiet /etc
cltest: Error: cannot read input file: /etc
$
```

## Option --quiet has no effect in --debug

```
# $ ./cltest --quiet --debug testme/ok-2.sh
# [INPUT_LINE: $ echo ok]
# [  LINE_CMD: $ echo ok]
# [   NEW_CMD: echo ok]
# [INPUT_LINE: ok]
# [    LINE_*: ok]
# [   OK_TEXT: ok]
# [INPUT_LINE: $ echo ok  #→ ok]
# [  LINE_CMD: $ echo ok  #→ ok]
# [      EVAL: echo ok]
# [    OUTPUT: ok]
# [   NEW_CMD: echo ok  ]
# [ OK_INLINE: ok]
# [   OK_TEXT: ok]
# [      EVAL: echo ok  ]
# [    OUTPUT: ok]
# [  LOOP_OUT: $test_command=]
# $
```

## Option --color

```
$ ./cltest --color foo testme/ok-1.sh
cltest: Error: invalid value 'foo' for --color. Use: auto, always or never.
$ ./cltest --color always testme/ok-1.sh
[32mOK:[m 1 of 1 tests passed
$ ./cltest --color yes testme/ok-1.sh
[32mOK:[m 1 of 1 tests passed
$ ./cltest --color never testme/ok-1.sh
OK: 1 of 1 tests passed
$ ./cltest --color no testme/ok-1.sh
OK: 1 of 1 tests passed
$
## Note: Inside this file, the output is not a terminal,
##       so the default is no colored output.
$ ./cltest testme/ok-1.sh
OK: 1 of 1 tests passed
$
## Note: The real default '--color auto' cannot be tested here.
##       Test it by hand at the command line.
## $ ./cltest testme/ok-1.sh
## [32mOK![m The single test has passed.
## $ ./cltest --color auto testme/ok-1.sh
## [32mOK![m The single test has passed.
## $
```

## Option --list

```
$ ./cltest --list testme/empty-file.sh
cltest: Error: no test found in input file: testme/empty-file.sh
$ ./cltest -l testme/no-nl-command.sh; echo $?
#1	printf 'ok\n'
#2	printf 'fail'
#3	printf 'ok\nok\nfail'
#4	printf 'ok\n'    
#5	printf 'fail'    
#6	printf 'ok'; echo   
0
$ ./cltest --list testme/no-nl-command.sh
#1	printf 'ok\n'
#2	printf 'fail'
#3	printf 'ok\nok\nfail'
#4	printf 'ok\n'    
#5	printf 'fail'    
#6	printf 'ok'; echo   
$ ./cltest --list testme/no-nl-command.sh testme/ok-1.sh; echo $?
---------------------------------------- testme/no-nl-command.sh
#1	printf 'ok\n'
#2	printf 'fail'
#3	printf 'ok\nok\nfail'
#4	printf 'ok\n'    
#5	printf 'fail'    
#6	printf 'ok'; echo   
---------------------------------------- testme/ok-1.sh
#7	echo ok
0
$
```

## Option --list-run

```
$ ./cltest --list-run testme/empty-file.sh
cltest: Error: no test found in input file: testme/empty-file.sh
$ ./cltest --list-run --color yes testme/no-nl-command.sh; echo $?
[32m#1	printf 'ok\n'[m
[31m#2	printf 'fail'[m
[31m#3	printf 'ok\nok\nfail'[m
[32m#4	printf 'ok\n'    [m
[31m#5	printf 'fail'    [m
[32m#6	printf 'ok'; echo   [m
1
$ ./cltest --list-run testme/no-nl-command.sh; echo $?
#1	OK	printf 'ok\n'
#2	FAIL	printf 'fail'
#3	FAIL	printf 'ok\nok\nfail'
#4	OK	printf 'ok\n'    
#5	FAIL	printf 'fail'    
#6	OK	printf 'ok'; echo   
1
$ ./cltest -L testme/no-nl-command.sh
#1	OK	printf 'ok\n'
#2	FAIL	printf 'fail'
#3	FAIL	printf 'ok\nok\nfail'
#4	OK	printf 'ok\n'    
#5	FAIL	printf 'fail'    
#6	OK	printf 'ok'; echo   
$ ./cltest -L testme/no-nl-command.sh testme/ok-1.sh; echo $?
---------------------------------------- testme/no-nl-command.sh
#1	OK	printf 'ok\n'
#2	FAIL	printf 'fail'
#3	FAIL	printf 'ok\nok\nfail'
#4	OK	printf 'ok\n'    
#5	FAIL	printf 'fail'    
#6	OK	printf 'ok'; echo   
---------------------------------------- testme/ok-1.sh
#7	OK	echo ok
1
$ ./cltest -L testme/ok-1.sh; echo $?
#1	OK	echo ok
0
$
```

## Option --verbose is not effective in --list and --list-run

```
$ ./cltest --verbose --list testme/ok-2.sh
#1	echo ok
#2	echo ok  
$ ./cltest --verbose --list-run testme/ok-2.sh
#1	OK	echo ok
#2	OK	echo ok  
$
```

## Option --test and --skip combined with --list and --list-run

```
$ ./cltest --list -t 99 testme/ok-10.sh
cltest: Error: no test found for the specified number or range '99'
$ ./cltest --list-run -t 99 testme/ok-10.sh
cltest: Error: no test found for the specified number or range '99'
$ ./cltest --list -s 1-10 testme/ok-10.sh
cltest: Error: no test found. Maybe '--skip 1-10' was too much?
$ ./cltest --list-run -s 1-10 testme/ok-10.sh
cltest: Error: no test found. Maybe '--skip 1-10' was too much?
$ ./cltest --list -t 9 -s 9 testme/ok-10.sh
cltest: Error: no test found. The combination of -t and -s resulted in no tests.
$ ./cltest --list-run -t 9 -s 9 testme/ok-10.sh
cltest: Error: no test found. The combination of -t and -s resulted in no tests.
$ ./cltest --list -t 3,5-7 testme/ok-10.sh
#3	echo 3 
#5	echo 5 
#6	echo 6 
#7	echo 7 
$ ./cltest --list-run -t 3,5-7 testme/ok-10.sh
#3	OK	echo 3 
#5	OK	echo 5 
#6	OK	echo 6 
#7	OK	echo 7 
$ ./cltest --list -t 3,5-7 -s 6 testme/ok-10.sh
#3	echo 3 
#5	echo 5 
#7	echo 7 
$ ./cltest --list-run -t 3,5-7 -s 6 testme/ok-10.sh
#3	OK	echo 3 
#5	OK	echo 5 
#7	OK	echo 7 
$ ./cltest --list -t 1,3,5-7 testme/ok-1.sh testme/fail-2.sh testme/ok-10.sh
---------------------------------------- testme/ok-1.sh
#1	echo ok
---------------------------------------- testme/fail-2.sh
#3	echo ok  
---------------------------------------- testme/ok-10.sh
#5	echo 2 
#6	echo 3 
#7	echo 4 
$ ./cltest --list-run -t 1,3,5-7 testme/ok-1.sh testme/fail-2.sh testme/ok-10.sh
---------------------------------------- testme/ok-1.sh
#1	OK	echo ok
---------------------------------------- testme/fail-2.sh
#3	FAIL	echo ok  
---------------------------------------- testme/ok-10.sh
#5	OK	echo 2 
#6	OK	echo 3 
#7	OK	echo 4 
$
$ ./cltest --list -t 1,3,5-7 -s 3,6 testme/ok-1.sh testme/fail-2.sh testme/ok-10.sh
---------------------------------------- testme/ok-1.sh
#1	echo ok
---------------------------------------- testme/fail-2.sh
---------------------------------------- testme/ok-10.sh
#5	echo 2 
#7	echo 4 
$ ./cltest --list-run -t 1,3,5-7 -s 3,6 testme/ok-1.sh testme/fail-2.sh testme/ok-10.sh
---------------------------------------- testme/ok-1.sh
#1	OK	echo ok
---------------------------------------- testme/fail-2.sh
---------------------------------------- testme/ok-10.sh
#5	OK	echo 2 
#7	OK	echo 4 
$
```

## Single file, OK

```
$ ./cltest testme/ok-1.sh
OK: 1 of 1 tests passed
$ ./cltest testme/ok-2.sh
OK: 2 of 2 tests passed
$ ./cltest testme/ok-50.sh
OK: 50 of 50 tests passed
$ ./cltest testme/ok-100.sh
OK: 100 of 100 tests passed
$ ./cltest --verbose testme/ok-2.sh
#1	echo ok
#2	echo ok  
OK: 2 of 2 tests passed
$
```

## Multifile, all OK

```
$ ./cltest testme/ok-2.sh testme/ok-2.sh
Testing file testme/ok-2.sh
Testing file testme/ok-2.sh

     ok  fail  skip
      2     -     -    testme/ok-2.sh
      2     -     -    testme/ok-2.sh

OK: 4 of 4 tests passed
$ ./cltest testme/ok-[0-9]*.sh
Testing file testme/ok-1.sh
Testing file testme/ok-10.sh
Testing file testme/ok-100.sh
Testing file testme/ok-2.sh
Testing file testme/ok-50.sh

     ok  fail  skip
      1     -     -    testme/ok-1.sh
     10     -     -    testme/ok-10.sh
    100     -     -    testme/ok-100.sh
      2     -     -    testme/ok-2.sh
     50     -     -    testme/ok-50.sh

OK: 163 of 163 tests passed
$ ./cltest --verbose testme/ok-?.sh testme/ok-10.sh
Testing file testme/ok-1.sh
#1	echo ok
Testing file testme/ok-2.sh
#2	echo ok
#3	echo ok  
Testing file testme/ok-10.sh
#4	echo 1 
#5	echo 2 
#6	echo 3 
#7	echo 4 
#8	echo 5 
#9	echo 6 
#10	echo 7 
#11	echo 8 
#12	echo 9 
#13	echo 10 

     ok  fail  skip
      1     -     -    testme/ok-1.sh
      2     -     -    testme/ok-2.sh
     10     -     -    testme/ok-10.sh

OK: 13 of 13 tests passed
$
```

## Multifile, OK and fail

```
$ ./cltest testme/ok-1.sh testme/fail-1.sh testme/ok-2.sh testme/fail-2.sh
Testing file testme/ok-1.sh
Testing file testme/fail-1.sh
--------------------------------------------------------------------------------
[FAILED #2, line 1] echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------
Testing file testme/ok-2.sh
Testing file testme/fail-2.sh
--------------------------------------------------------------------------------
[FAILED #5, line 1] echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------
[FAILED #6, line 3] echo ok  
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------

     ok  fail  skip
      1     -     -    testme/ok-1.sh
      -     1     -    testme/fail-1.sh
      2     -     -    testme/ok-2.sh
      -     2     -    testme/fail-2.sh

FAIL: 3 of 6 tests failed
$ ./cltest --verbose testme/ok-1.sh testme/fail-1.sh testme/ok-2.sh testme/fail-2.sh
Testing file testme/ok-1.sh
#1	echo ok
Testing file testme/fail-1.sh
#2	echo ok
--------------------------------------------------------------------------------
[FAILED #2, line 1] echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------
Testing file testme/ok-2.sh
#3	echo ok
#4	echo ok  
Testing file testme/fail-2.sh
#5	echo ok
--------------------------------------------------------------------------------
[FAILED #5, line 1] echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------
#6	echo ok  
--------------------------------------------------------------------------------
[FAILED #6, line 3] echo ok  
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------

     ok  fail  skip
      1     -     -    testme/ok-1.sh
      -     1     -    testme/fail-1.sh
      2     -     -    testme/ok-2.sh
      -     2     -    testme/fail-2.sh

FAIL: 3 of 6 tests failed
$
```

## Fail messages

```
$ ./cltest testme/fail-messages.sh
--------------------------------------------------------------------------------
[FAILED #1, line 3] echo fail  
@@ -1 +1 @@
-ok
+fail
--------------------------------------------------------------------------------
[FAILED #2, line 4] echo fail  
@@ -1 +1 @@
-ok
+fail
--------------------------------------------------------------------------------
[FAILED #3, line 8] echo fail
@@ -1 +1 @@
-ok
+fail
--------------------------------------------------------------------------------
[FAILED #4, line 10] echo fail
@@ -1,3 +1 @@
-ok 1
-ok 2
-ok 3
+fail
--------------------------------------------------------------------------------
[FAILED #5, line 18] echo fail  
@@ -1,5 +1 @@
-Lorem ipsum dolor sit amet, consectetur adipiscing elit.
-Proin euismod blandit pharetra.
-Vestibulum eu neque eget lorem gravida commodo a cursus massa.
-Fusce sit amet lorem sem.
-Donec eu quam leo.
+fail
--------------------------------------------------------------------------------
[FAILED #6, line 22] echo fail  
Expected 9 lines, got 1.
--------------------------------------------------------------------------------
[FAILED #7, line 26] echo fail  
egrep '^[0-9]+$' failed in:
fail
--------------------------------------------------------------------------------
[FAILED #8, line 30] echo fail  
Perl regex '^[0-9]+$' not matched in:
fail
--------------------------------------------------------------------------------
[FAILED #9, line 34] echo fail  
Perl regex '^[0-9]+$' not matched in:
fail
--------------------------------------------------------------------------------

FAIL: 9 of 9 tests failed
$
```

## Fails

```
$ ./cltest testme/fail-1.sh
--------------------------------------------------------------------------------
[FAILED #1, line 1] echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------

FAIL: 1 of 1 tests failed
$ ./cltest testme/fail-2.sh
--------------------------------------------------------------------------------
[FAILED #1, line 1] echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------
[FAILED #2, line 3] echo ok  
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------

FAIL: 2 of 2 tests failed
$ ./cltest testme/fail-50.sh | tail -1
FAIL: 50 of 50 tests failed
$ ./cltest -1 testme/fail-2.sh
--------------------------------------------------------------------------------
[FAILED #1, line 1] echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------
$ ./cltest --first testme/fail-2.sh
--------------------------------------------------------------------------------
[FAILED #1, line 1] echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------
$ ./cltest --first --verbose testme/fail-2.sh
#1	echo ok
--------------------------------------------------------------------------------
[FAILED #1, line 1] echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------
$ ./cltest --verbose testme/fail-2.sh
#1	echo ok
--------------------------------------------------------------------------------
[FAILED #1, line 1] echo ok
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------
#2	echo ok  
--------------------------------------------------------------------------------
[FAILED #2, line 3] echo ok  
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------

FAIL: 2 of 2 tests failed
$
```

## Inline output with #→

```
$ ./cltest --verbose testme/inline.sh
#1	echo 'one space' 
#2	echo 'one tab'	
#3	echo 'multi spaces'           
#4	echo 'multi tabs'				
#5	echo 'mixed'  	 		 	
#6	echo ' leading space' 
#7	echo '    leading spaces' 
#8	printf '\tleading tab\n' 
#9	printf '\t\tleading tabs\n' 
#10	echo 'trailing space ' 
#11	echo 'trailing spaces    ' 
#12	printf 'trailing tab\t\n' 
#13	printf 'trailing tabs\t\t\n' 
#14	echo ' ' 
#15	echo '    ' 
#16	printf '\t\n' 
#17	printf '\t\t\t\n' 
#18	printf ' \t  \t\t   \n' 
#19	echo "both inline and normal output"  
OK: 19 of 19 tests passed
$
```

## Inline match modes

```
$ ./cltest --list-run testme/inline-match-text.sh
#1	OK	echo 'abc'                    
#2	OK	echo 'abc'                    
#3	OK	printf '%s\n' '\t'            
#4	OK	printf '%s\n' '\n'            
#5	OK	echo '$PWD'                   
#6	OK	echo '$(date)'                
#7	OK	echo '$'                      
#8	OK	echo '>'                      
#9	OK	echo '?'                      
#10	OK	echo '!'                      
#11	OK	echo '*'                      
#12	OK	echo '['                      
#13	OK	echo '('                      
#14	OK	echo                          
#15	OK	echo "not inline output"      #→
#16	OK	echo '123456789'              
#17	OK	echo '1 3   7 9'              
#18	OK	echo '    5    '              
#19	OK	echo ' leading space'         
#20	OK	echo '    leading spaces'     
#21	OK	printf '\tleading tab\n'      
#22	OK	printf '\t\tleading tabs\n'   
#23	OK	echo 'trailing space '        
#24	OK	echo 'trailing spaces    '    
#25	OK	printf 'trailing tab\t\n'     
#26	OK	printf 'trailing tabs\t\t\n'  
#27	OK	echo ' '                      
#28	FAIL	echo '   '                    
#29	OK	printf '\t\n'                 
#30	OK	printf '\t\t\t\n'             
#31	OK	printf ' \t  \t\t   \n'       
#32	OK	printf 'ok\n'                 
#33	FAIL	printf 'fail'                 
#34	OK	printf 'ok'; echo             
#35	FAIL	echo 'fail'                   
#36	FAIL	echo 'fail'                   
#37	OK	echo ' ok'                    
#38	OK	echo '--text'                 
#39	OK	echo '--textual'              
#40	OK	echo '--text is cool'         
$ ./cltest --list-run testme/inline-match-eval.sh
#1	OK	folder=$(pwd)
#2	OK	echo $folder                  
#3	OK	var='abc'
#4	OK	echo abc                      
#5	OK	echo 4                        
#6	OK	today=$(date +%D)
#7	OK	echo "Today is $today"        
#8	OK	printf 'ok'                   
#9	OK	echo ' leading space'         
#10	OK	echo '    leading spaces'     
#11	OK	printf '\tleading tab\n'      
#12	OK	printf '\t\tleading tabs\n'   
#13	OK	echo 'trailing space '        
#14	OK	echo 'trailing spaces    '    
#15	OK	printf 'trailing tab\t\n'     
#16	OK	printf 'trailing tabs\t\t\n'  
#17	OK	echo ' '                      
#18	OK	echo '   '                    
#19	OK	printf '\t\n'                 
#20	OK	printf '\t\t\t\n'             
#21	OK	printf ' \t  \t\t   \n'       
#22	FAIL	echo 'fail'                   
#23	FAIL	echo 'fail'                   
#24	OK	echo '--eval'                 
#25	OK	echo '--evaluate'             
#26	OK	echo '--eval is evil'         
$ ./cltest --list-run testme/inline-match-egrep.sh
#1	OK	echo 'abc123'                 
#2	OK	echo 'abc123'                 
#3	OK	echo 'abc123'                 
#4	OK	echo 'abc123'                 
#5	OK	echo 'abc123'                 
#6	OK	echo 'abc123'                 
#7	OK	echo 'abc123'                 
#8	OK	echo 'abc123'                 
#9	OK	echo 'abc 123'                
#10	OK	echo ' '                      
#11	OK	echo '    '                   
#12	OK	printf '\t\n'                 
#13	OK	printf '\t\t\t\n'             
#14	OK	printf ' \t  \t\t   \n'       
#15	OK	printf 'may\tfail'            
#16	FAIL	printf 'may\tfail'            
#17	OK	printf 'will\tmatch'          
#18	FAIL	printf 'will\nfail'           
#19	FAIL	printf 'will\nfail'           
#20	OK	printf '1\n2\n3\n4\nok\n'     
#21	OK	printf 'ok'                   
#22	OK	printf 'ok\n'                 
#23	FAIL	echo 'fail'                   
#24	FAIL	echo 'fail'                   
#25	OK	echo ' ok'                    
#26	OK	echo '--egrep'                
#27	OK	echo '--egreppal'             
#28	OK	echo '--egrep is cool'        
$ ./cltest --list-run testme/inline-match-perl.sh
#1	OK	echo 'abc123'                 
#2	OK	echo 'abc123'                 
#3	OK	echo 'abc123'                 
#4	OK	echo 'abc123'                 
#5	OK	echo 'abc123'                 
#6	OK	echo 'abc123'                 
#7	OK	echo 'abc123'                 
#8	OK	echo 'abc123'                 
#9	OK	echo 'abc 123'                
#10	OK	echo ' '                      
#11	OK	echo '    '                   
#12	OK	printf '\t\n'                 
#13	OK	printf '\t\t\t\n'             
#14	OK	printf ' \t  \t\t   \n'       
#15	OK	echo '01/01/2013'             
#16	OK	echo "won't fail"             
#17	OK	printf 'will\tmatch'          
#18	OK	printf 'will\tmatch'          
#19	OK	printf 'will\tmatch'          
#20	FAIL	printf 'will\nfail'           
#21	OK	printf 'will\nmatch'          
#22	FAIL	printf 'will\nfail'           
#23	OK	printf 'will\nmatch'          
#24	FAIL	printf 'will\nfail'           
#25	OK	printf 'will\nmatch'          
#26	OK	printf 'ok'                   
#27	OK	printf 'ok\n'                 
#28	OK	printf '1\n2\n3\n'            
#29	OK	printf '1\n2\n3\n'            
#30	FAIL	echo 'fail'                   
#31	FAIL	echo 'fail'                   
#32	OK	echo ' ok'                    
#33	OK	echo '--perl'                 
#34	OK	echo '--perlism'              
#35	OK	echo '--perl is cool'         
$ ./cltest --list-run testme/inline-match-file.sh
#1	OK	printf '$ echo ok\nok\n'      
#2	OK	echo 'ok' > /tmp/foo.txt
#3	OK	echo 'ok'                     
#4	FAIL	echo 'fail'                   
#5	FAIL	echo 'fail'                   
#6	OK	echo '--file'                 
#7	OK	echo '--filer'                
#8	OK	echo '--file is cool'         
$ ./cltest --list-run testme/inline-match-lines.sh
#1	OK	a=1                           
#2	OK	echo 'ok'                     
#3	OK	printf '1\n2\n3\n'            
#4	OK	printf 'no-nl'                
#5	OK	printf '1\n2\nno-nl'          
#6	FAIL	echo 'fail'                   
#7	FAIL	echo 'fail'                   
#8	FAIL	echo 'fail'                   
#9	FAIL	echo 'fail'                   
#10	OK	echo '--lines'                 
#11	OK	echo '--linesout'             
#12	OK	echo '--lines is cool'         
$ ./cltest --first testme/inline-match-lines.sh
--------------------------------------------------------------------------------
[FAILED #6, line 16] echo 'fail'                   
Expected 99 lines, got 1.
--------------------------------------------------------------------------------
$ ./cltest testme/inline-match-egrep-error-1.sh
cltest: Error: empty --egrep at line 1 of testme/inline-match-egrep-error-1.sh
$ ./cltest testme/inline-match-egrep-error-2.sh 2>&1 | sed 's/^egrep: .*/egrep: ERROR_MSG/'
egrep: ERROR_MSG
cltest: Error: check your inline egrep regex at line 1 of testme/inline-match-egrep-error-2.sh
$ ./cltest testme/inline-match-perl-error-1.sh
cltest: Error: empty --perl at line 1 of testme/inline-match-perl-error-1.sh
$ ./cltest testme/inline-match-perl-error-2.sh
Unmatched ( in regex; marked by <-- HERE in m/( <-- HERE / at -e line 1.
cltest: Error: check your inline Perl regex at line 1 of testme/inline-match-perl-error-2.sh
$ ./cltest testme/inline-match-file-error-1.sh
cltest: Error: empty --file at line 1 of testme/inline-match-file-error-1.sh
$ ./cltest testme/inline-match-file-error-2.sh
cltest: Error: cannot read inline output file 'XXnotfoundXX', from line 1 of testme/inline-match-file-error-2.sh
$ ./cltest testme/inline-match-file-error-3.sh
cltest: Error: cannot read inline output file '/etc/', from line 1 of testme/inline-match-file-error-3.sh
$ ./cltest testme/inline-match-lines-error-1.sh
cltest: Error: --lines requires a number. See line 1 of testme/inline-match-lines-error-1.sh
$ ./cltest testme/inline-match-lines-error-2.sh
cltest: Error: --lines requires a number. See line 1 of testme/inline-match-lines-error-2.sh
$ ./cltest testme/inline-match-lines-error-3.sh
cltest: Error: --lines requires a number. See line 1 of testme/inline-match-lines-error-3.sh
$ ./cltest testme/inline-match-lines-error-4.sh
cltest: Error: --lines requires a number. See line 1 of testme/inline-match-lines-error-4.sh
$ ./cltest testme/inline-match-eval-error-1.sh
cltest: Error: empty --eval at line 1 of testme/inline-match-eval-error-1.sh
$ ./cltest testme/inline-match-eval-error-2.sh 2>&1 | sed 's/line [0-9][0-9]*/line N/'
./cltest: eval: line N: unexpected EOF while looking for matching `)'
./cltest: eval: line N: syntax error: unexpected end of file
--------------------------------------------------------------------------------
[FAILED #1, line N] echo 'error: syntax error'  
@@ -0,0 +1 @@
+error: syntax error
--------------------------------------------------------------------------------

FAIL: 1 of 1 tests failed
$
```

## Option -t, --test

```
$ ./cltest -t - testme/ok-2.sh
cltest: Error: invalid argument for -t or --test: -
$ ./cltest -t -1 testme/ok-2.sh
cltest: Error: invalid argument for -t or --test: -1
$ ./cltest -t 1- testme/ok-2.sh
cltest: Error: invalid argument for -t or --test: 1-
$ ./cltest -t 1--2 testme/ok-2.sh
cltest: Error: invalid argument for -t or --test: 1--2
$ ./cltest -t 1-2-3 testme/ok-2.sh
cltest: Error: invalid argument for -t or --test: 1-2-3
$ ./cltest -t 99 testme/ok-2.sh
cltest: Error: no test found for the specified number or range '99'
$ ./cltest -t '' testme/ok-2.sh
OK: 2 of 2 tests passed
$ ./cltest -t 0 testme/ok-2.sh
OK: 2 of 2 tests passed
$ ./cltest -t ,,,0,0-0,,, testme/ok-2.sh
OK: 2 of 2 tests passed
$ ./cltest --verbose -t 1 testme/ok-10.sh
#1	echo 1 
OK: 1 of 10 tests passed (9 skipped)
$ ./cltest --verbose --test 1 testme/ok-10.sh
#1	echo 1 
OK: 1 of 10 tests passed (9 skipped)
$ ./cltest --verbose -t 0-1,1-0 testme/ok-10.sh
#1	echo 1 
OK: 1 of 10 tests passed (9 skipped)
$ ./cltest --verbose -t 1-1 testme/ok-10.sh
#1	echo 1 
OK: 1 of 10 tests passed (9 skipped)
$ ./cltest --verbose -t 1,1,1,0,1 testme/ok-10.sh
#1	echo 1 
OK: 1 of 10 tests passed (9 skipped)
$ ./cltest --verbose -t 10-20 testme/ok-10.sh
#10	echo 10 
OK: 1 of 10 tests passed (9 skipped)
$ ./cltest --verbose -t 3,2,1 testme/ok-10.sh
#1	echo 1 
#2	echo 2 
#3	echo 3 
OK: 3 of 10 tests passed (7 skipped)
$ ./cltest --verbose -t 3-1 testme/ok-10.sh
#1	echo 1 
#2	echo 2 
#3	echo 3 
OK: 3 of 10 tests passed (7 skipped)
$ ./cltest --verbose -t 1,5,13 testme/ok-?.sh testme/ok-10.sh
Testing file testme/ok-1.sh
#1	echo ok
Testing file testme/ok-2.sh
Testing file testme/ok-10.sh
#5	echo 2 
#13	echo 10 

     ok  fail  skip
      1     -     -    testme/ok-1.sh
      -     -     2    testme/ok-2.sh
      2     -     8    testme/ok-10.sh

OK: 3 of 13 tests passed (10 skipped)
$ ./cltest --verbose -t 1,5 testme/ok-[12].sh testme/fail-2.sh
Testing file testme/ok-1.sh
#1	echo ok
Testing file testme/ok-2.sh
Testing file testme/fail-2.sh
#5	echo ok  
--------------------------------------------------------------------------------
[FAILED #5, line 3] echo ok  
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------

     ok  fail  skip
      1     -     -    testme/ok-1.sh
      -     -     2    testme/ok-2.sh
      -     1     1    testme/fail-2.sh

FAIL: 1 of 5 tests failed (3 skipped)
$ ./cltest --verbose -t 1 testme/ok-[12].sh testme/fail-2.sh
Testing file testme/ok-1.sh
#1	echo ok
Testing file testme/ok-2.sh
Testing file testme/fail-2.sh

     ok  fail  skip
      1     -     -    testme/ok-1.sh
      -     -     2    testme/ok-2.sh
      -     -     2    testme/fail-2.sh

OK: 1 of 5 tests passed (4 skipped)
$
```

## Option -s, --skip

```
$ ./cltest -s - testme/ok-2.sh
cltest: Error: invalid argument for -s or --skip: -
$ ./cltest -s -1 testme/ok-2.sh
cltest: Error: invalid argument for -s or --skip: -1
$ ./cltest -s 1- testme/ok-2.sh
cltest: Error: invalid argument for -s or --skip: 1-
$ ./cltest -s 1--2 testme/ok-2.sh
cltest: Error: invalid argument for -s or --skip: 1--2
$ ./cltest -s 1-2-3 testme/ok-2.sh
cltest: Error: invalid argument for -s or --skip: 1-2-3
$ ./cltest -s 99 testme/ok-2.sh
OK: 2 of 2 tests passed
$ ./cltest -s '' testme/ok-2.sh
OK: 2 of 2 tests passed
$ ./cltest -s 0 testme/ok-2.sh
OK: 2 of 2 tests passed
$ ./cltest -s ,,,0,0-0,,, testme/ok-2.sh
OK: 2 of 2 tests passed
$ ./cltest -s 1 testme/ok-1.sh
cltest: Error: no test found. Maybe '--skip 1' was too much?
$ ./cltest --verbose -s 1 testme/ok-2.sh
#2	echo ok  
OK: 1 of 2 tests passed (1 skipped)
$ ./cltest --verbose --skip 1 testme/ok-2.sh
#2	echo ok  
OK: 1 of 2 tests passed (1 skipped)
$ ./cltest --verbose -s 0-1,1-0 testme/ok-2.sh
#2	echo ok  
OK: 1 of 2 tests passed (1 skipped)
$ ./cltest --verbose -s 1-1 testme/ok-2.sh
#2	echo ok  
OK: 1 of 2 tests passed (1 skipped)
$ ./cltest --verbose -s 1,1,1,0,1 testme/ok-2.sh
#2	echo ok  
OK: 1 of 2 tests passed (1 skipped)
$ ./cltest --verbose -s 2-10 testme/ok-2.sh
#1	echo ok
OK: 1 of 2 tests passed (1 skipped)
$ ./cltest --verbose -s 10,9,8,7,6,5,4 testme/ok-10.sh
#1	echo 1 
#2	echo 2 
#3	echo 3 
OK: 3 of 10 tests passed (7 skipped)
$ ./cltest --verbose -s 10-4 testme/ok-10.sh
#1	echo 1 
#2	echo 2 
#3	echo 3 
OK: 3 of 10 tests passed (7 skipped)
$ ./cltest --verbose -s 2,3,13 testme/ok-?.sh testme/ok-10.sh
Testing file testme/ok-1.sh
#1	echo ok
Testing file testme/ok-2.sh
Testing file testme/ok-10.sh
#4	echo 1 
#5	echo 2 
#6	echo 3 
#7	echo 4 
#8	echo 5 
#9	echo 6 
#10	echo 7 
#11	echo 8 
#12	echo 9 

     ok  fail  skip
      1     -     -    testme/ok-1.sh
      -     -     2    testme/ok-2.sh
      9     -     1    testme/ok-10.sh

OK: 10 of 13 tests passed (3 skipped)
$ ./cltest --verbose -s 2,3,4 testme/ok-[12].sh testme/fail-2.sh
Testing file testme/ok-1.sh
#1	echo ok
Testing file testme/ok-2.sh
Testing file testme/fail-2.sh
#5	echo ok  
--------------------------------------------------------------------------------
[FAILED #5, line 3] echo ok  
@@ -1 +1 @@
-fail
+ok
--------------------------------------------------------------------------------

     ok  fail  skip
      1     -     -    testme/ok-1.sh
      -     -     2    testme/ok-2.sh
      -     1     1    testme/fail-2.sh

FAIL: 1 of 5 tests failed (3 skipped)
$ ./cltest --verbose -s 2-10 testme/ok-[12].sh testme/fail-2.sh
Testing file testme/ok-1.sh
#1	echo ok
Testing file testme/ok-2.sh
Testing file testme/fail-2.sh

     ok  fail  skip
      1     -     -    testme/ok-1.sh
      -     -     2    testme/ok-2.sh
      -     -     2    testme/fail-2.sh

OK: 1 of 5 tests passed (4 skipped)
$
```

## Option --test combined with --skip

```
$ ./cltest -t 9 -s 9 testme/ok-10.sh
cltest: Error: no test found. The combination of -t and -s resulted in no tests.
$ ./cltest -s 9 -t 9 testme/ok-10.sh  # -s always wins
cltest: Error: no test found. The combination of -t and -s resulted in no tests.
$ ./cltest --verbose -t 3,5-7 -s 6 testme/ok-10.sh
#3	echo 3 
#5	echo 5 
#7	echo 7 
OK: 3 of 10 tests passed (7 skipped)
$ ./cltest --verbose -t 1,3,5-7 -s 3,6 testme/ok-1.sh testme/fail-2.sh testme/ok-10.sh
Testing file testme/ok-1.sh
#1	echo ok
Testing file testme/fail-2.sh
Testing file testme/ok-10.sh
#5	echo 2 
#7	echo 4 

     ok  fail  skip
      1     -     -    testme/ok-1.sh
      -     -     2    testme/fail-2.sh
      2     -     8    testme/ok-10.sh

OK: 3 of 13 tests passed (10 skipped)
$

```

## Option --diff-options

```
$ ./cltest testme/option-diff-options.sh
--------------------------------------------------------------------------------
[FAILED #1, line 3] echo "	diff -w to ignore spaces    "
@@ -1 +1 @@
-diff -w    to ignore    spaces
+	diff -w to ignore spaces    
--------------------------------------------------------------------------------
[FAILED #2, line 5] echo "	diff -w now inline    "  
@@ -1 +1 @@
-diff    -w    now    inline
+	diff -w now inline    
--------------------------------------------------------------------------------

FAIL: 2 of 2 tests failed
$ ./cltest --diff-options '-u -w' testme/option-diff-options.sh
OK: 2 of 2 tests passed
$
```

## Option --prompt

```
$ ./cltest --verbose testme/option-prompt.sh
cltest: Error: no test found in input file: testme/option-prompt.sh
$ ./cltest --verbose --prompt 'prompt$ ' testme/option-prompt.sh
#1	echo "1"  
#2	echo "2"
#3	echo "3"
OK: 3 of 3 tests passed
$ ./cltest --verbose --prompt '♥ ' testme/option-prompt-unicode.sh
#1	echo "1"  
#2	echo "2"
#3	echo "3"
OK: 3 of 3 tests passed
$
```

## Option --inline-prefix

```
$ ./cltest testme/option-inline-prefix.sh
--------------------------------------------------------------------------------
[FAILED #1, line 3] echo "1 space" #==> 1 space
@@ -0,0 +1 @@
+1 space
--------------------------------------------------------------------------------
[FAILED #2, line 4] echo "8 spaces"        #==> 8 spaces
@@ -0,0 +1 @@
+8 spaces
--------------------------------------------------------------------------------
[FAILED #3, line 5] echo "2 tabs"		#==> 2 tabs
@@ -0,0 +1 @@
+2 tabs
--------------------------------------------------------------------------------

FAIL: 3 of 3 tests failed
$ ./cltest --inline-prefix '#==>' testme/option-inline-prefix.sh
--------------------------------------------------------------------------------
[FAILED #1, line 3] echo "1 space" 
@@ -1 +1 @@
- 1 space
+1 space
--------------------------------------------------------------------------------
[FAILED #2, line 4] echo "8 spaces"        
@@ -1 +1 @@
- 8 spaces
+8 spaces
--------------------------------------------------------------------------------
[FAILED #3, line 5] echo "2 tabs"		
@@ -1 +1 @@
- 2 tabs
+2 tabs
--------------------------------------------------------------------------------

FAIL: 3 of 3 tests failed
$ ./cltest --inline-prefix '#==> ' testme/option-inline-prefix.sh
OK: 3 of 3 tests passed
$
```

## Option --prefix

```
$ ./cltest --verbose --prefix '    ' testme/option-prefix.sh
#1	echo "1"  
#2	echo "2"
#3	echo "3"
#4	echo "4"
#5	echo "5"  
#6	echo; echo "6"; echo; echo "7"
OK: 6 of 6 tests passed
$ ./cltest --verbose --prefix 4 testme/option-prefix.sh
#1	echo "1"  
#2	echo "2"
#3	echo "3"
#4	echo "4"
#5	echo "5"  
#6	echo; echo "6"; echo; echo "7"
OK: 6 of 6 tests passed
$ ./cltest --verbose --prefix '\t' testme/option-prefix-tab.sh
#1	echo "1"  
#2	echo "2"
#3	echo "3"
#4	echo "4"
#5	echo "5"  
#6	echo; echo "6"; echo; echo "7"
OK: 6 of 6 tests passed
$ ./cltest --verbose --prefix tab testme/option-prefix-tab.sh
#1	echo "1"  
#2	echo "2"
#3	echo "3"
#4	echo "4"
#5	echo "5"  
#6	echo; echo "6"; echo; echo "7"
OK: 6 of 6 tests passed
$
```

## Option --prefix: glob gotchas

```
$ ./cltest --verbose --prefix '?' testme/option-prefix-glob.sh
#1	echo 'prefix ?'	
#2	echo 'prefix ?'
OK: 2 of 2 tests passed
$ ./cltest --verbose --prefix '*' testme/option-prefix-glob.sh
#1	echo 'prefix *'	
#2	echo 'prefix *'
OK: 2 of 2 tests passed
$ ./cltest --verbose --prefix '#' testme/option-prefix-glob.sh
#1	echo 'prefix #'	
#2	echo 'prefix #'
OK: 2 of 2 tests passed
$ ./cltest --verbose --prefix '%' testme/option-prefix-glob.sh
#1	echo 'prefix %'	
#2	echo 'prefix %'
OK: 2 of 2 tests passed
$ ./cltest --verbose --prefix '##' testme/option-prefix-glob.sh
#1	echo 'prefix ##'	
#2	echo 'prefix ##'
OK: 2 of 2 tests passed
$ ./cltest --verbose --prefix '%%' testme/option-prefix-glob.sh
#1	echo 'prefix %%'	
#2	echo 'prefix %%'
OK: 2 of 2 tests passed
$ ./cltest --verbose --prefix '#*' testme/option-prefix-glob.sh
#1	echo 'prefix #*'	
#2	echo 'prefix #*'
OK: 2 of 2 tests passed
$ ./cltest --verbose --prefix '*#' testme/option-prefix-glob.sh
#1	echo 'prefix *#'	
#2	echo 'prefix *#'
OK: 2 of 2 tests passed
$ ./cltest --verbose --prefix '%*' testme/option-prefix-glob.sh
#1	echo 'prefix %*'	
#2	echo 'prefix %*'
OK: 2 of 2 tests passed
$ ./cltest --verbose --prefix '*%' testme/option-prefix-glob.sh
#1	echo 'prefix *%'	
#2	echo 'prefix *%'
OK: 2 of 2 tests passed
$
```

## Option --prompt: glob gotchas (char + space)

```
$ ./cltest --verbose --prompt '? ' testme/option-prompt-glob-space.sh
#1	echo 'prompt ? '	
#2	echo 'prompt ? '
OK: 2 of 2 tests passed
$ ./cltest --verbose --prompt '* ' testme/option-prompt-glob-space.sh
#1	echo 'prompt * '	
#2	echo 'prompt * '
OK: 2 of 2 tests passed
$ ./cltest --verbose --prompt '# ' testme/option-prompt-glob-space.sh
#1	echo 'prompt # '	
#2	echo 'prompt # '
OK: 2 of 2 tests passed
$ ./cltest --verbose --prompt '% ' testme/option-prompt-glob-space.sh
#1	echo 'prompt % '	
#2	echo 'prompt % '
OK: 2 of 2 tests passed
$ ./cltest --verbose --prompt '## ' testme/option-prompt-glob-space.sh
#1	echo 'prompt ## '	
#2	echo 'prompt ## '
OK: 2 of 2 tests passed
$ ./cltest --verbose --prompt '%% ' testme/option-prompt-glob-space.sh
#1	echo 'prompt %% '	
#2	echo 'prompt %% '
OK: 2 of 2 tests passed
$ ./cltest --verbose --prompt '#* ' testme/option-prompt-glob-space.sh
#1	echo 'prompt #* '	
#2	echo 'prompt #* '
OK: 2 of 2 tests passed
$ ./cltest --verbose --prompt '*# ' testme/option-prompt-glob-space.sh
#1	echo 'prompt *# '	
#2	echo 'prompt *# '
OK: 2 of 2 tests passed
$ ./cltest --verbose --prompt '%* ' testme/option-prompt-glob-space.sh
#1	echo 'prompt %* '	
#2	echo 'prompt %* '
OK: 2 of 2 tests passed
$ ./cltest --verbose --prompt '*% ' testme/option-prompt-glob-space.sh
#1	echo 'prompt *% '	
#2	echo 'prompt *% '
OK: 2 of 2 tests passed
$
```

## Option --prompt: glob gotchas (chars only)

```
$ ./cltest --verbose --prompt '?' testme/option-prompt-glob-1.sh
#1	echo 'prompt ?'	
#2	echo 'prompt ?'
OK: 2 of 2 tests passed
$ ./cltest --verbose --prompt '*' testme/option-prompt-glob-1.sh
#1	echo 'prompt *'	
#2	echo 'prompt *'
OK: 2 of 2 tests passed
$ ./cltest --verbose --prompt '#' testme/option-prompt-glob-1.sh
#1	echo 'prompt #'	
#2	echo 'prompt #'
OK: 2 of 2 tests passed
$ ./cltest --verbose --prompt '%' testme/option-prompt-glob-1.sh
#1	echo 'prompt %'	
#2	echo 'prompt %'
OK: 2 of 2 tests passed
$ ./cltest --verbose --prompt '##' testme/option-prompt-glob-2.sh
#1	echo 'prompt ##'	
#2	echo 'prompt ##'
OK: 2 of 2 tests passed
$ ./cltest --verbose --prompt '%%' testme/option-prompt-glob-2.sh
#1	echo 'prompt %%'	
#2	echo 'prompt %%'
OK: 2 of 2 tests passed
$ ./cltest --verbose --prompt '#*' testme/option-prompt-glob-2.sh
#1	echo 'prompt #*'	
#2	echo 'prompt #*'
OK: 2 of 2 tests passed
$ ./cltest --verbose --prompt '*#' testme/option-prompt-glob-2.sh
#1	echo 'prompt *#'	
#2	echo 'prompt *#'
OK: 2 of 2 tests passed
$ ./cltest --verbose --prompt '%*' testme/option-prompt-glob-2.sh
#1	echo 'prompt %*'	
#2	echo 'prompt %*'
OK: 2 of 2 tests passed
$ ./cltest --verbose --prompt '*%' testme/option-prompt-glob-2.sh
#1	echo 'prompt *%'	
#2	echo 'prompt *%'
OK: 2 of 2 tests passed
$
```

## Options --pre-flight and --post-flight

```
$ ./cltest --pre-flight 'tt_test_number=99; tt_nr_total_tests=99' testme/ok-1.sh
OK: 100 of 100 tests passed
$ ./cltest --post-flight 'tt_nr_total_fails=50' testme/ok-50.sh

FAIL: 50 of 50 tests failed
$ ./cltest --pre-flight 'false' testme/ok-1.sh
cltest: Error: pre-flight command failed with status=1: false
$
```

## Options terminator -- 

```
$ ./cltest -t 99 -- --quiet
cltest: Error: cannot read input file: --quiet
$
```

## File - meaning STDIN (no support for now)

```
$ cat testme/ok-1.sh | ./cltest -
cltest: Error: cannot read input file: -
$
```

## Gotchas

```
$ ./cltest testme/exit-code.sh
OK: 2 of 2 tests passed
$ ./cltest testme/blank-output.sh
OK: 10 of 10 tests passed
$ ./cltest testme/special-chars.sh
OK: 206 of 206 tests passed
$ ./cltest --verbose testme/windows.sh
#1	echo "a file with CRLF line ending"
#2	echo "inline output"  
#3	echo "inline regex"  
OK: 3 of 3 tests passed
$ ./cltest --verbose testme/close-command.sh
#1	echo 1
#2	echo 2
#3	echo 3
OK: 3 of 3 tests passed
$ ./cltest --verbose testme/multi-commands.sh
#1	echo 1; echo 2; echo 3; echo 4; echo 5
#2	(echo 1; echo 2; echo 3; echo 4; echo 5) | sed -n 3p
#3	(echo 1; echo 2; echo 3; echo 4; echo 5) | sed -n 3p  
OK: 3 of 3 tests passed
$ ./cltest --verbose testme/stdout-stderr.sh
#1	echo "stdout"
#2	echo "stdout" 2> /dev/null
#3	echo "stderr" 1>&2
#4	echo "stdout" > /dev/null
#5	echo "stdout" 2> /dev/null 1>&2
#6	cp XXnotfoundXX foo
#7	cp XXnotfoundXX foo > /dev/null
#8	cp XXnotfoundXX foo 2>&1
#9	cp XXnotfoundXX foo 2> /dev/null
#10	cp XXnotfoundXX foo > /dev/null 2>&1
OK: 10 of 10 tests passed
$ ./cltest testme/cd.sh testme/ok-2.sh
Testing file testme/cd.sh
Testing file testme/ok-2.sh

     ok  fail  skip
      1     -     -    testme/cd.sh
      2     -     -    testme/ok-2.sh

OK: 3 of 3 tests passed
$ ./cltest --verbose testme/no-nl-file-1.sh
#1	printf '%s\n' 'a file with no \n at the last line'
OK: 1 of 1 tests passed
$ ./cltest --verbose testme/no-nl-file-2.sh
#1	printf '%s\n' 'another file with no \n at the last line'
OK: 1 of 1 tests passed
$ ./cltest --verbose testme/no-nl-file-3.sh
#1	printf '%s\n' 'oneliner, no \n'  
OK: 1 of 1 tests passed
$ ./cltest --verbose testme/no-nl-command.sh
#1	printf 'ok\n'
#2	printf 'fail'
--------------------------------------------------------------------------------
[FAILED #2, line 6] printf 'fail'
@@ -1 +1 @@
-fail
+fail
\ No newline at end of file
--------------------------------------------------------------------------------
#3	printf 'ok\nok\nfail'
--------------------------------------------------------------------------------
[FAILED #3, line 8] printf 'ok\nok\nfail'
@@ -1,3 +1,3 @@
 ok
 ok
-fail
+fail
\ No newline at end of file
--------------------------------------------------------------------------------
#4	printf 'ok\n'    
#5	printf 'fail'    
--------------------------------------------------------------------------------
[FAILED #5, line 17] printf 'fail'    
@@ -1 +1 @@
-fail
+fail
\ No newline at end of file
--------------------------------------------------------------------------------
#6	printf 'ok'; echo   

FAIL: 3 of 6 tests failed
$
```

## And now, the colored output tests

```
$ ./cltest --color yes --first testme/fail-2.sh
[31m--------------------------------------------------------------------------------[m
[31m[FAILED #1, line 1] echo ok[m
@@ -1 +1 @@
-fail
+ok
[31m--------------------------------------------------------------------------------[m
$
```
