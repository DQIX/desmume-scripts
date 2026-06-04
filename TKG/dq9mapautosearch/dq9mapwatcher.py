import os
import time
import webbrowser

TXT_FILE = "dq9mapoutput.txt"

last_mtime = 0

while True:
    try:
        mtime = os.path.getmtime(TXT_FILE)

        if mtime != last_mtime:
            last_mtime = mtime

            with open(TXT_FILE, "r") as f:
                url = f.read()

            if url:
                print(f"{url}")
                webbrowser.open(url)

    except FileNotFoundError:
        pass

    time.sleep(0.1)
