#!/bin/bash

#!/bin/bash

PORT=8080
PID=$(lsof -t -i:$PORT)

if [ -n "$PID" ]; then
    echo "Killing process on port $PORT (PID: $PID)"
    kill -9 $PID
else
    echo "No process found on port $PORT"
fi
