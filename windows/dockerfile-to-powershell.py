from ast import Not
import string
import sys
import getopt
from datetime import datetime
from dockerfile_parse import DockerfileParser

# This script imports dockerfile-parse project (see https://github.com/containerbuildsystem/dockerfile-parse)
# Before running the script run: python3 -m pip install -r requirements.txt
#
# This python script generates Powershell script which when executed will perform the same
# steps as the Docker when it builds an image from the same Dockerfile. This script runs
# the same commands and effectively simulates Docker image build but without Docker. Accordingly
# when generated Powershell script is run on a clean Windows machine or VM it should
# produce the same final state as built Docker container. If, for example, the Dockerfile creates
# Windows build-ready container then the generated powershell script when run should make Windows
# machine or VM build-ready as well.
#
# This script processes only specified Dockerfile although in the future we can attempt to
# process Dockerfile of the bases image as well (and may be recursively up as much as we can)
#
# This script in theory should work with any Windows Dockerfile. However it had been tested
# only with https://github.com/DataDog/datadog-agent-buildimages/blob/main/windows/Dockerfile.
# It is possible that the Dockerfile modification may break the this python script or the
# generated powershell. We will try to address future issues as soon as we can.
#
# There are few nuances which you should be aware when looking on the Python or the generated
# Powershell scripts:
#   a) Currently Datadog environment makes the Docker to be executed in the C:\ directory.
#      Accordingly Powershell script changes current location to C:\ in the beginning and after
#      each command execution (in case command changed that location). You will see invocation
#      of "Set-Location \" after each RUN command.
#
#   b) Simulation of Docker build image execution is not literal for RUN commands. Instead of
#      spawning a shell or a process to execute run command generated script invokes these
#      commands directly. The pros that it is simpler and faster but the cons that if the
#      command failed it will break main script execution. In future we may either wrap it
#      into error handling block or indeed spawn a separate process.
#
#      In addition this approach will make impossible to run generated powershell more than
#      once on the same machine because some commands refuse to run if certain directories
#      already exist (but offending process can be commented out).    
#
#   c) Because a command may change an environment variable which can be used in subsequent
#      RUN command we generate powershell call after each RUN command to update sessions'
#      environment variables. You will see invocation of "Update-SessionEnvironment \" after
#      each RUN command.
#
#   d) In addition each command is echoed on the console and each command is measured. We also
#      print a reference to the Dockerfile line number where powershell script line was
#      derived from.


# ===========================================================
#
# U T I L I T Y 
#
def getCommandLine():
   cmdLine = ''
   for arg in sys.argv:
      if ' ' in arg:
         cmdLine += '"{}" '.format(arg)
      else:
         cmdLine += "{} ".format(arg)

   return cmdLine

class Args(object):
    pass

class Context(object):
    pass

def usage():
   print('Usage: dockerfile-to-powershell.py <arguments>\n')
   print('Example')
   print('   dockerfile-to-powershell.py -d .\\Dockerfile -p .\\build.ps1 -a WINDOWS_VERSION=1809\n')
   print('Required arguments')
   print('  -d <Docker file path>     # INPUT')
   print('  -p <Powershell file path> # OUTPUT>')
   print('')
   print('Optional arguments')
   print('  -a dockerarg1=val1        # See Dockerfile ARG')
   print('  -a dockerargN=valN')


def parseParams(argv):
   dockerFilePath = ''
   powershellFilePath = ''
   dockerArgs = {}
   try:
      opts, args = getopt.getopt(argv,'d:p:a:')
   except getopt.GetoptError:
      print('dockerfile-to-powershell.py -d <Docker file path> -p <Powershell file path> [-a dockerarg1=val1 ...]')
      sys.exit(1)

   for opt, arg in opts:
      if opt == '-d':
         dockerFilePath = arg
      elif opt == '-p':
         powershellFilePath = arg
      elif opt == '-a':
         # Split and validate
         nameValue = arg.split('=')
         if len(nameValue) != 2 or len(nameValue[0].strip()) == 0 or len(nameValue[1].strip()) == 0:
            print('invalid docker argument "{}"'.format(arg))
            sys.exit(2)

         dockerArgs[nameValue[0].strip().upper()] = nameValue[1].strip()

   # Validate that both required parameters are provided
   if (len(dockerFilePath) == 0 or len(powershellFilePath) == 0):
      usage()
      sys.exit(1)

   retArgs = Args()
   retArgs.dockerFilePath = dockerFilePath
   retArgs.powershellFilePath = powershellFilePath
   retArgs.dockerArgs = dockerArgs

   return retArgs

# Parse Dockerfile into array of instructions. Currently we are using 
# https://github.com/containerbuildsystem/dockerfile-parse
def parseDockerFile(dockerFilePath):
   try:
      with open(dockerFilePath, 'r') as dockerFile:
         dockerFileContent = dockerFile.read()

      dockerParser = DockerfileParser()
      dockerParser.content = dockerFileContent
      return dockerParser
   except Exception as inst:
      errMsg = 'Failed to open "{}" Dockerfile. Please validate that it is accessible'.format(dockerFilePath)
      print(errMsg)
      sys.exit(1)


# Open/Create powershell file for writing
def createPowershellFile(powershellFilePath):
   try:
      return open(powershellFilePath, 'w')
   except Exception as inst:
      print('Failed to create "{}" powershell file. Please validate that it is accessible'.format(powershellFile))
      sys.exit(1)


# https://docs.docker.com/engine/reference/builder/#environment-replacement
def replaceArgOrEnv(dockerArgs, value):

   # No need to replace?
   if value[0] != '$':
      return value

   # Find terminating '}'
   replacingValue = ''
   suffix = ''
   if value[1] == '{':
      nameValue = value[2:].split('}')
      if len(nameValue) == 1:
         return value # no termination is found then it is just no-replacement string
      
      replacingValue = nameValue[0]
      suffix = nameValue[1]
   else:
      replacingValue = value[1:]

   # If we do not have + or - replacement
   nameValue = replacingValue.split(':')
   if len(nameValue) == 1:
       replacedValue = dockerArgs.get(replacingValue)
       return replacedValue + suffix if replacedValue != None else '' + suffix


   # We can have only one ':'
   if len(nameValue) != 2:
      print('The ENV replacement format "{}" is not supported or understood'.format(value))
      exit(1)

   # We can have only + or minus
   minus = nameValue[1][0] == '-'
   plus = nameValue[1][0] == '+'
   if not minus and not plus:
      print('The ENV replacement format "{}" is not supported or understood'.format(value))
      exit(1)

   replacingValue = nameValue[0]
   defaultValue = nameValue[1][1:]

   # '-'
   if minus:
      return dockerArgs.get(replacingValue) + suffix if dockerArgs.get(replacingValue) != None else defaultValue + suffix

   # '+'
   return defaultValue + suffix if dockerArgs.get(replacingValue) != None else '' + suffix


# ===========================================================
#
# G E N E R A T E
#

# ===========================================================
# ARG
#
def lineGenerator_ARG(context, powershellFile, dockerArgs, dockerLine):
   generateDockerfileReferenceComment(powershellFile, dockerLine)

   # Check for default value ARG
   nameValue = dockerLine['value'].split('=')
   if len(nameValue) == 2:
      # Add default argument as if it was not provided
      argValueNorm = nameValue[0].strip().upper()
      if not argValueNorm in dockerArgs:
         dockerArgs[argValueNorm] = nameValue[1].strip()
   elif len(nameValue) == 1:
      # Get argument and print it as a comment
      val = dockerArgs.get(nameValue[0].strip())
      if val != None:
         powershellFile.write('# ARG={}\n'.format(val))
      else:
         powershellFile.write('# ARG=<None>')
   else:
      print('The ARG instruction format is not supported or understood'.format(dockerLine['content']))
      sys.exit(1)

   powershellFile.write('\n')

# ===========================================================
# FROM
#
def lineGenerator_FROM(context, powershellFile, dockerArgs, dockerLine):
   generateDockerfileReferenceComment(powershellFile, dockerLine)

   value = dockerLine['value']

   powershellFile.write('# Base Image: {}\n\n'.format(value))

      

# ===========================================================
# SHELL
#
def lineGenerator_SHELL(context, powershellFile, dockerArgs, dockerLine):
   generateDockerfileReferenceComment(powershellFile, dockerLine)

   # Parse and concatenate to sting string a value like this
   #    ["powershell", "-Command"]
   shell = ''
   for shellValue in dockerLine['value'][1:-1].split(','):
      shellValue = shellValue.strip()[1:-1].strip()
      shell = shell + ' ' + shellValue if len(shell) > 0 else shellValue

   dockerArgs['SHELL'] = shell
   powershellFile.write('# SHELL="{}"\n\n'.format(shell))

# ===========================================================
# COMMENT
#
def lineGenerator_COMMENT(context, powershellFile, dockerArgs, dockerLine):
   powershellFile.write(dockerLine['content'])

# ===========================================================
# ENV
#
def lineGenerator_ENV(context, powershellFile, dockerArgs, dockerLine):
   generateDockerfileReferenceComment(powershellFile, dockerLine)

   nameValue = dockerLine['value'].split(' ')
   if len(nameValue) == 1:
      nameValue = dockerLine['value'].split('=')
   
   envName = nameValue[0].strip()
   value = nameValue[1].strip()
   envValue = replaceArgOrEnv(dockerArgs, value) if value[0] != '"' else value[1:-1]

   powershellFile.write("[System.Environment]::SetEnvironmentVariable('{}','{}')\n\n".format(envName, envValue))

   # add ENV to dockerArgs (because ${xxx} replacement looks similar)
   dockerArgs[envName.upper()] = envValue

# ===========================================================
# LABEL
#
def lineGenerator_LABEL(context, powershellFile, dockerArgs, dockerLine):
   generateDockerfileReferenceComment(powershellFile, dockerLine)

   nameValue = dockerLine['value'].split('=')
   if len(nameValue) != 2:
      print('The LABEL instruction format is not supported or understood'.format(dockerLine['content']))
      sys.exit(1)

   label = nameValue[0].strip()
   valueRaw = nameValue[1].strip()
   value = replaceArgOrEnv(dockerArgs, valueRaw) if valueRaw[0] != '"' else valueRaw[1:-1]

   powershellFile.write("# LABEL resolved: {}='{}'\n\n".format(label, value))

# ===========================================================
# RUN
#
def lineGenerator_RUN(context, powershellFile, dockerArgs, dockerLine):
   generateDockerfileReferenceComment(powershellFile, dockerLine)

   # There are two forms of RUN but we are using only one currently
   runRaw = dockerLine['content'][4:]
   runNoEscapedQuotes = runRaw.replace("\\\"", "\"")
   runLines = runNoEscapedQuotes.split('\\\n')

   firstRunLine = runLines[0]
   shell = dockerArgs['SHELL']
   powershellC = 'powershell -c '
   powershellCIdx = firstRunLine.lower().find(powershellC)
   powershellCommand = 'powershell -command '
   powershellCommandIdx = firstRunLine.lower().find(powershellCommand)
   shellIsPowershell = True if shell.lower().find('powershell -command') == 0 else False

   # Replace powershell script invokation with simple "Call operator &"
   firstLineCmd = ''
   if shellIsPowershell:
      if powershellCIdx == 0:
         firstLineCmd = '{}'.format(firstRunLine[len(powershellC):])
      elif powershellCommandIdx == 0:
         firstLineCmd = '{}'.format(firstRunLine[len(powershellCommand):])
      else:
         firstLineCmd = '{}'.format(firstRunLine)
   else:
      firstLineCmd = '{} {}'.format(dockerArgs['SHELL'], firstRunLine)

   # Start stopwatch
   powershellFile.write('$stopwatch = [system.diagnostics.stopwatch]::StartNew()\n')

   # Show step #
   context.currentTaskIndex += 1
   generateProgress(context, powershellFile, firstLineCmd)

   # This will run it
   if len(runLines) == 1:
      powershellFile.write(firstLineCmd)
   else:
      powershellFile.write('{}`\n'.format(firstLineCmd))
      for idx in range(1, len(runLines)):
         if idx <  len(runLines) - 1:
            powershellFile.write('{}`\n'.format(runLines[idx]))
         else:
            powershellFile.write('{}\n'.format(runLines[idx]))


   # Restore environment
   powershellFile.write("""# Restore location and reload environment in case if they were changed
Set-Location \ 
Update-SessionEnvironment
# Measure taken time
$stopwatch.Stop()
$timeTaken = $stopwatch.Elapsed.ToString("dd\.hh\:mm\:ss")
Write-Host "... this step executed in $timeTaken`n"

""")
 

# ===========================================================
# COPY
#
def lineGenerator_COPY(context, powershellFile, dockerArgs, dockerLine):
   generateDockerfileReferenceComment(powershellFile, dockerLine)

   nameValues = dockerLine['value'].split()

   context.currentTaskIndex += 1

   dest = nameValues[len(nameValues) - 1].replace('/', '\\')

   # Copy each of the few src
   for srcIdx in range(len(nameValues) - 1):
      src = nameValues[srcIdx].replace('/', '\\')
      cmd = 'copy $ImageRepoPath\{} {}'.format(src, dest)
      generateProgress(context, powershellFile, cmd)
      powershellFile.write('{}\n'.format(cmd))

   powershellFile.write('Write-Host\n\n')


# ===========================================================
# ENTRYPOINT
#
def lineGenerator_ENTRYPOINT(context, powershellFile, dockerArgs, dockerLine):
   generateDockerfileReferenceComment(powershellFile, dockerLine)
   powershellFile.write('\n\n')

def lineGenerator_CMD(context, powershellFile, dockerArgs, dockerLine):
   generateDockerfileReferenceComment(powershellFile, dockerLine)
   powershellFile.write('\n\n')

def getLineGeneratorsMap():
   lineHandlersMap = {      
      'ARG': lineGenerator_ARG,
      'FROM': lineGenerator_FROM,
      'SHELL': lineGenerator_SHELL,
      'COMMENT': lineGenerator_COMMENT,
      'ENV': lineGenerator_ENV,
      'LABEL': lineGenerator_LABEL,
      'RUN': lineGenerator_RUN,
      'COPY': lineGenerator_COPY,
      'ENTRYPOINT': lineGenerator_ENTRYPOINT,
      'CMD': lineGenerator_CMD
   }
   return lineHandlersMap

def getTaskCountersMap():
   taskCountersMap = {      
      'ARG': 0,
      'FROM': 0,
      'SHELL': 0,
      'COMMENT': 0,
      'ENV': 0,
      'LABEL': 0,
      'RUN': 1,
      'COPY': 1,
      'ENTRYPOINT': 0,
      'CMD': 0
   }
   return taskCountersMap

def generatePowershell(dockerParser, powershellFile, dockerArgs):

   # Add header to the powershell file
   generatePowershellHeader(powershellFile)

   # Calculate counters
   context = Context()
   context.currentTaskIndex = 0
   context.totalTask = 0
   taskCountersMap = getTaskCountersMap()
   for dockerLine in dockerParser.structure:      
      context.totalTask += taskCountersMap[dockerLine['instruction']]

   # Process Dockerfile line by line
   lineHandlersMap = getLineGeneratorsMap()
   for dockerLine in dockerParser.structure:      
      lineHandlersMap[dockerLine['instruction']](context, powershellFile, dockerArgs, dockerLine)

   # Generate footer
   generateFooter(powershellFile)

   # close the file
   powershellFile.close()

def generatePowershellHeader(powershellFile):
   powershellFile.write('# Automatically generated by\n')
   powershellFile.write('#  {}\n'.format(getCommandLine()))
   powershellFile.write('#  on {}\n'.format(datetime.now().strftime('%m/%d/%Y %H:%M:%S')))

   powershellFile.write("""
# WARNING!!!
#  If this script had been generated from https://github.com/DataDog/datadog-agent-buildimages/blob/main/windows/Dockerfile
#  you need to install .NET 4.8 before running it from one of three sources
#     * https://dotnet.microsoft.com/en-us/download/dotnet-framework/net48
#     * https://support.microsoft.com/en-us/topic/microsoft-net-framework-4-8-offline-installer-for-windows-9d23f658-3b97-68ab-d013-aa3c3e7495e0
#     * https://github.com/microsoft/dotnet-framework-docker/blob/528e53c63f429860d99d55409b0018d225059f0c/src/runtime/4.8/windowsservercore-ltsc2019/Dockerfile

#  If you try to run this script more than once some commands may fail and break the script. It will be addressed better
#  in the future but for now you may need to comment out offending commands

# Usage: .\<this-script.ps1> -ImageReporPath <image repo path>
#    -ImageReporPath is required parameter. You need to clone the
#    same report as the one used for building Docker image.
#    Specifically it is https://github.com/DataDog/datadog-agent-buildimages
Param(
    [Parameter(Mandatory)]
    [string]
    $ImageRepoPath
)
$ImageRepoExists = Test-Path $ImageRepoPath
if (!$ImageRepoExists) {
    Write-Host "Provided \'ImageRepoPath\' ($ImageRepoPath) path does not exist. Please provide valid argument"
    Exit
   
# Currently Docker run everything in the root. And we have to keep it this way
Set-Location \

$totalStopwatch = [system.diagnostics.stopwatch]::StartNew()

function Update-SessionEnvironment {
   foreach ($s in 'Machine','User') {
      [Environment]::GetEnvironmentVariables($s).GetEnumerator().
      Where({$_.Key -ne 'PATH'}) | ForEach-Object {
      [Environment]::SetEnvironmentVariable($_.Key,$_.Value,'Process') }}

   $env:PATH = ( ('Machine','User').ForEach({
      [Environment]::GetEnvironmentVariable('PATH',$_)}).
      Split(';').Where({$_}) | Select-Object -Unique ) -join ';'
}
""")

def generateProgress(context, powershellFile, cmd):
   powershellFile.write("Write-Host @'\n")
   powershellFile.write('[{}/{}] Starting to {} ...\n'.format(context.currentTaskIndex, context.totalTask, cmd))
   powershellFile.write("'@\n")

def generateFooter(powershellFile):
   powershellFile.write("""$totalStopwatch.Stop()
$timeTaken = $totalStopwatch.Elapsed.ToString("dd\.hh\:mm\:ss")
Write-Host "Script executed in $timeTaken"
""")

def generateDockerfileReferenceComment(powershellFile, dockerLine):
   lines = dockerLine['content'].split('\n')  
   powershellFile.write('# Line: {}, Content: {}\n'.format((dockerLine['startline'] + 1), lines[0]))
   if len(lines) > 1:
      for lineIdx in range(1, len(lines) -1):
         powershellFile.write('# {}\n'.format(lines[lineIdx]))

# ===========================================================
#
# M A I N
#

def main(argv):
   # Get parameters
   args = parseParams(argv)

   # Parse Dockerfile
   dockerParser = parseDockerFile(args.dockerFilePath)

   # Create powershell file
   powershellFile = createPowershellFile(args.powershellFilePath)

   generatePowershell(dockerParser, powershellFile, args.dockerArgs)

if __name__ == '__main__':
    main(sys.argv[1:])
