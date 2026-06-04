## Automated Map Search
Automatically opens Grotto Searcher for newly obtained treasure maps<br>
(https://github.com/DQIX/Grotto-Searcher)<br>
Original idea by Paws<br>
https://www.youtube.com/watch?v=XsDvc71ekfY
## How to Use
- Download dq9maploader.lua and dq9mapwatcher.py
- Put them in the same directory
- Run the lua file
  - In desmume go to tools -> lua scripting -> new lua script window -> browse
- Run the python file
  - In the directory, enter "cmd" in the address bar
  - In cmd, enter "python dq9mapwatcher.py"
- Obtain a treasure map
  - The lua file will automatically create "dq9mapoutput.txt" in the directory
  - "(rank) (seed) @ (location)" will be printed in the lua console
  - The python file will automatically open the link in "dq9mapoutput.txt" in your default browser
