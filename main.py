import argparse
import subprocess
import sys
import os

def run_make_command(command):
    """Runs the make command with the given target and streams output in real-time."""
    # Get the directory where the script (main.py) is located
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Change the working directory to the location of the script
    os.chdir(script_dir)

    try:
        # Open the process and stream its output line by line
        process = subprocess.Popen(['make', command], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        
        # Stream standard output
        for line in process.stdout:
            print(line.decode(), end="")

        # Stream standard error
        for line in process.stderr:
            print(line.decode(), end="", file=sys.stderr)

        process.wait()  # Wait for the process to finish

    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {e.stderr.decode()}")
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="CyMaIS Sphinx Documentation Management Tool")

    # Subcommands for various make targets
    subparsers = parser.add_subparsers(dest="command", help="Available commands for managing the CyMaIS Sphinx documentation")

    # Add subcommands and descriptions
    subparsers.add_parser("up", help="Build and start the Docker container with the necessary environment.")
    subparsers.add_parser("install", help="Install the required dependencies and copy the source files.")
    subparsers.add_parser("clean", help="Clean up generated files and reset the environment.")
    subparsers.add_parser("html", help="Generate the HTML documentation using Sphinx.")
    subparsers.add_parser("help", help="Show help and instructions for each available command.")

    # Parse arguments
    args = parser.parse_args()

    # Call corresponding functions based on the command
    if args.command:
        run_make_command(args.command)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
