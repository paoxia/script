#!/bin/bash

# Find and force-stop processes using the configured network port.
# Change PORT below to target a different service.

#!/bin/bash

PORT=8080
# lsof emits process IDs only; multiple matching processes may be returned.
PID=$(lsof -t -i:$PORT)

if [ -n "$PID" ]; then
    echo "Killing process on port $PORT (PID: $PID)"
    # Leave PID unquoted so each returned process ID becomes a separate kill argument.
    kill -9 $PID
else
    echo "No process found on port $PORT"
fi
