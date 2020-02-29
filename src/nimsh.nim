from strutils import split
import os, tables, posix

const
  statusOk = 1
  statusNg = 0

proc nimshCd(args: seq[string]): int =
  if args.len < 2:
    stderr.writeLine("nimsh: expected argument to 'cd'")
  else:
    setCurrentDir(args[1])
  return statusOk

proc nimshExit(args: seq[string]): int =
  return statusNg

const
  builtinCommands = {
    "cd": nimshCd,
    "exit": nimshExit
  }.toTable

proc nimshLaunch(args: seq[string]): int =
  let pid = fork()
  if pid == 0:
    if execvp(args[0].cstring, allocCStringArray(args)) == -1:
      stderr.writeLine "nimsh"
  elif pid < 0:
    stderr.writeLine "nimsh"
  else:
    var status: cint
    while (not WIFEXITED(status)) and (not WIFSIGNALED(status)):
      discard waitpid(pid, status, WUNTRACED)
  return statusOk

proc nimshExec(args: seq[string]): int =
  if args.len < 1: return statusOk
  for cmdName, cmd in builtinCommands:
    if args[0] == cmdName:
      return cmd(args)
  return nimshLaunch(args)

proc nimshLoop =
  const
    tokenDelimiter = {'\t', '\r', '\n', '\a', ' '}
  var
    line: string
    args: seq[string]
    status = statusOk
  while status != statusNg:
    stdout.write("nimsh > ")
    if not stdin.readLine(line):
      break
    args = line.split(tokenDelimiter)
    status = nimshExec(args)
    sleep 100

proc main: int =
  nimshLoop()

when isMainModule:
  quit main()
