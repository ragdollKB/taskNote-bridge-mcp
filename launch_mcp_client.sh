#!/bin/bash

# MCP Client wrapper for VS Code
# This script connects to the Swift MCP server (running in the macOS app) via TCP
# and bridges stdio from VS Code to that TCP connection.

# Set up environment
export PYTHONUNBUFFERED=1

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Swift MCP server connection details (must match the running Swift app's MCP server port)
MCP_PORT=${MCP_PORT:-8000} # Default to 8000 for the Swift server
MCP_HOST=${MCP_HOST:-localhost}

# Check if the Swift MCP server (macOS app) is accessible on the specified port
# We won't try to start it from here, the app must be running independently.
if ! nc -z $MCP_HOST $MCP_PORT > /dev/null 2>&1; then
    echo "Error: Swift MCP server does not appear to be running or accessible on $MCP_HOST:$MCP_PORT." >&2
    echo "Please ensure the 'Things MCP' macOS application is running and the MCP server is enabled within it." >&2
    exit 1
fi

echo "Connecting to Swift MCP server on $MCP_HOST:$MCP_PORT" >&2

# Connect to the TCP server and bridge stdio
# Ensure you have a Python environment capable of running this.
# If .venv/bin/python is not correct, adjust to your Python interpreter path.
exec "$SCRIPT_DIR/.venv/bin/python" -c "
import asyncio
import sys
import json
import os

MCP_HOST = os.getenv('MCP_HOST', 'localhost')
MCP_PORT = int(os.getenv('MCP_PORT', '8000'))

async def bridge_stdio_to_tcp():
    # sys.stderr.write(f'Attempting to connect to {MCP_HOST}:{MCP_PORT}\n') # Debug
    try:
        reader, writer = await asyncio.open_connection(MCP_HOST, MCP_PORT)
    except ConnectionRefusedError:
        sys.stderr.write(f'Error: Connection refused when connecting to {MCP_HOST}:{MCP_PORT}. Is the Swift app running and server active?\n')
        sys.exit(1)
    except Exception as e:
        sys.stderr.write(f'Error connecting to {MCP_HOST}:{MCP_PORT}: {e}\n')
        sys.exit(1)
    
    # sys.stderr.write(f'Successfully connected to {MCP_HOST}:{MCP_PORT}\n') # Debug

    async def forward_stdin_to_tcp():
        try:
            while True:
                line = await asyncio.get_event_loop().run_in_executor(None, sys.stdin.readline)
                if not line:
                    # sys.stderr.write('stdin closed, closing TCP writer.\n') # Debug
                    writer.close()
                    await writer.wait_closed()
                    break
                # sys.stderr.write(f'stdin -> tcp: {line.strip()}\n') # Debug
                writer.write(line.encode())
                await writer.drain()
        except Exception as e:
            sys.stderr.write(f'Error in forward_stdin_to_tcp: {e}\n')
        finally:
            if not writer.is_closing():
                writer.close()
                await writer.wait_closed()

    async def forward_tcp_to_stdout():
        try:
            while True:
                line = await reader.readline()
                if not line:
                    # sys.stderr.write('TCP reader closed.\n') # Debug
                    break
                # sys.stderr.write(f'tcp -> stdout: {line.decode().strip()}\n') # Debug
                sys.stdout.write(line.decode())
                sys.stdout.flush()
        except Exception as e:
            sys.stderr.write(f'Error in forward_tcp_to_stdout: {e}\n')
        finally:
            # No need to close writer here, stdin forwarder handles it
            pass

    # Run both forwarding tasks concurrently
    stdin_task = asyncio.create_task(forward_stdin_to_tcp())
    stdout_task = asyncio.create_task(forward_tcp_to_stdout())
    
    done, pending = await asyncio.wait(
        [stdin_task, stdout_task],
        return_when=asyncio.FIRST_COMPLETED,
    )
    
    for task in pending:
        task.cancel()
    # sys.stderr.write('Bridge tasks completed or cancelled.\n') # Debug

if __name__ == '__main__':
    try:
        asyncio.run(bridge_stdio_to_tcp())
    except KeyboardInterrupt:
        sys.stderr.write('Bridge interrupted by user.\n') # Debug
    except Exception as e:
        sys.stderr.write(f'Unhandled error in bridge: {e}\n') # Debug
"
