from ast import Not
import sys
import getopt
import re
from datetime import datetime
from dockerfile_parse import DockerfileParser

# This script imports dockerfile-parse project
#  https://github.com/containerbuildsystem/dockerfile-parse
# Before running the script run: python3 -m pip install -r requirements.txt
#
# This python script generates Powershell script which when executed will perform the
# same steps as the Docker when it builds an image from the same Dockerfile. This
# script runs the same commands and effectively simulates Docker image build but
# without Docker. Accordingly when generated Powershell script is run on a clean
# Windows machine or VM it should produce the same final state as built Docker
# container. If, for example, the Dockerfile creates Windows build-ready container
# then the generated Powershell script when run should make Windows machine or VM
# build-ready as well.
#
# This script processes only specified Dockerfile although in the future we can
# attempt to process Dockerfile of the bases image as well (and may be recursively up
# as much as we can)
#
# This script in theory should work with any Windows Dockerfile. However it had been
# tested mostly with 
#     https://github.com/DataDog/datadog-agent-buildimages/blob/main/windows/Dockerfile.
# It is possible that the Dockerfile modification may break the this python script or
# the generated Powershell. We will try to address future issues as soon as we can.
#
# There are few nuances which you should be aware when looking on the Python or the
# generated Powershell scripts:
#   a) This script fasciliate two separate phases of running Dockerized Powershell
#      script. n
#   b) Generated Powershell script "memorizes" current Powershell directory and 
#      restores it after each RUN command executed (in case it had been changed).
#      It also means that before the script it run one need to make sure to set
#      current directory to the one which would be expected by the Docker when
#      it build images. E.g. for datadog-agent-buildimages repository current
#      directory need to be seto to C:\ because that is where Docker build image
#      will run. Note: Unfortunately it is not explicit information but implied
#      by some of its RUN and COPY commands.
#
#   b) Simulation of Docker build image execution is not literal for RUN commands.
#      Instead of spawning a shell or a process to execute run command generated script
#      invokes these commands directly. The pros that it is simpler and faster but the
#      cons that if the command failed it will break main script execution. In future
#      we may either wrap it into error handling block or indeed spawn a separate
#      process.
#
#      In addition this approach will make impossible to run generated Powershell
#      more than once on the same machine because some commands refuse to run if
#      certain directories already exist (but offending process can be commented out).    
#
#   d) Because a command may change an environment variable which can be used in
#      subsequent RUN command we generate Powershell call after each RUN command to
#      update sessions' environment variables. You will see invocation of
#      "Update-SessionEnvironment \" after each RUN command.
#
#   e) In addition each command is echoed on the console and each command is
#      measured. We also print a reference to the Dockerfile line number where
#      Powershell script line was derived from.
#
#   f) If you already generated and run Powershell script and corresponding Dockerfile
#      had been changed you can still re-generate newer version of the Powershell
#      script and try to re-apply it again. However your mileage may vary (and it
#      depends very much on the Dockerfile content) ...
#         * It may actually just work.
#         * You may need to comment out everything except the difference between old
#           and new Powershell script.
#         * You may need to explicitly uninstall or remove previously deployed
#           applications, files or other artifacts


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
   print("""Usage: dockerfile-to-powershell.py <arguments>
Example
   dockerfile-to-powershell.py -d .\\Dockerfile -p .\\build.ps1 -a WINDOWS_VERSION=1809
Required arguments
  -d <Docker file path>     # INPUT
  -p <Powershell file path> # OUTPUT>

Optional arguments
  -a dockerarg1=val1        # Used as Dockerfile ARG instruction
  ...
  -a dockerargN=valN
  """)


def parseParams(argv):
   dockerFilePath = ''
   powershellFilePath = ''
   verbose = False
   dockerArgs = {}
   try:
      opts, args = getopt.getopt(argv,'d:p:a:-v')
   except getopt.GetoptError:
      print('dockerfile-to-powershell.py -d <Docker file path> -p <Powershell file path> [-a dockerarg1=val1 ...][-v]')
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
      elif opt == '-v':
         verbose = True

   # Validate that both required parameters are provided
   if (len(dockerFilePath) == 0 or len(powershellFilePath) == 0):
      usage()
      sys.exit(1)

   retArgs = Args()
   retArgs.dockerFilePath = dockerFilePath
   retArgs.powershellFilePath = powershellFilePath
   retArgs.dockerArgs = dockerArgs
   retArgs.verbose = verbose

   return retArgs

# Parse Dockerfile into array of instructions. Currently we are using 
# https://github.com/containerbuildsystem/dockerfile-parse
def parseDockerFile(dockerFilePath):
   try:
      with open(dockerFilePath, 'r') as dockerFile:
         dockerFileContent = dockerFile.read()

      dockerParser = DockerfileParser()

      # If dockerFilePath is not "Dockerfile" then dockerParser.content will create "Dockerfile" file
      # which is not desirable and have to be fixed in future. This behavior is part of the dockerfile
      # parser sub-module
      dockerParser.content = dockerFileContent

      return dockerParser
   except Exception as inst:
      errMsg = 'Failed to open "{}" Dockerfile. Please validate that it is accessible'.format(dockerFilePath)
      print(errMsg)
      sys.exit(1)


# Open/Create Powershell file for writing
def createPowershellFile(powershellFilePath):
   try:
      return open(powershellFilePath, 'w')
   except Exception as inst:
      print('Failed to create "{}" Powershell file. Please validate that it is accessible'.format(powershellFile))
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
def lineGenerator_ARG(context, powershellFile, args, dockerLine):
   generateDockerfileReferenceComment(powershellFile, dockerLine, args.verbose)

   # Check for default value ARG
   nameValue = dockerLine['value'].split('=')
   if len(nameValue) == 2:
      # Add default argument as if it was not provided
      argValueNorm = nameValue[0].strip().upper()
      if not argValueNorm in args.dockerArgs:
         args.dockerArgs[argValueNorm] = nameValue[1].strip()
   elif len(nameValue) == 1:
      # Get argument and print it as a comment
      val = args.dockerArgs.get(nameValue[0].strip())
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
def lineGenerator_FROM(context, powershellFile, args, dockerLine):
   generateDockerfileReferenceComment(powershellFile, dockerLine, args.verbose)

   value = dockerLine['value']

   powershellFile.write('# Base Image: {}\n\n'.format(value))

      

# ===========================================================
# SHELL
#
def lineGenerator_SHELL(context, powershellFile, args, dockerLine):
   generateDockerfileReferenceComment(powershellFile, dockerLine, args.verbose)

   # Parse and concatenate to sting string a value like this
   #    ["powershell", "-Command"]
   shell = ''
   for shellValue in dockerLine['value'][1:-1].split(','):
      shellValue = shellValue.strip()[1:-1].strip()
      shell = shell + ' ' + shellValue if len(shell) > 0 else shellValue

   args.dockerArgs['SHELL'] = shell
   powershellFile.write('# SHELL="{}"\n\n'.format(shell))

# ===========================================================
# COMMENT
#
def lineGenerator_COMMENT(context, powershellFile, args, dockerLine):
   powershellFile.write(dockerLine['content'])

# ===========================================================
# ENV
#
def lineGenerator_ENV(context, powershellFile, args, dockerLine):
   generateDockerfileReferenceComment(powershellFile, dockerLine, args.verbose)

   nameValue = dockerLine['value'].split(' ')
   if len(nameValue) == 1:
      nameValue = dockerLine['value'].split('=')
   
   envName = nameValue[0].strip()
   value = nameValue[1].strip()
   envValue = replaceArgOrEnv(args.dockerArgs, value) if value[0] != '"' else value[1:-1]

   powershellFile.write("[System.Environment]::SetEnvironmentVariable('{}','{}')\n\n".format(envName, envValue))

   # add ENV to dockerArgs (because ${xxx} replacement looks similar)
   args.dockerArgs[envName.upper()] = envValue

# ===========================================================
# LABEL
#
def lineGenerator_LABEL(context, powershellFile, args, dockerLine):
   generateDockerfileReferenceComment(powershellFile, dockerLine, args.verbose)

   nameValue = dockerLine['value'].split('=')
   if len(nameValue) != 2:
      print('The LABEL instruction format is not supported or understood'.format(dockerLine['content']))
      sys.exit(1)

   label = nameValue[0].strip()
   valueRaw = nameValue[1].strip()
   value = replaceArgOrEnv(args.dockerArgs, valueRaw) if valueRaw[0] != '"' else valueRaw[1:-1]

   powershellFile.write("# LABEL resolved: {}='{}'\n\n".format(label, value))

# ===========================================================
# RUN
#
def lineGenerator_RUN(context, powershellFile, args, dockerLine):
   generateDockerfileReferenceComment(powershellFile, dockerLine, args.verbose)

   # There are two forms of RUN but we are using only one currently
   runRaw = dockerLine['content'][4:]
   runNoEscapedQuotes = runRaw.replace("\\\"", "\"")
   runNoEscapedTick = runNoEscapedQuotes.replace("`", "")

   runLines = runNoEscapedTick.split('\\\n')

   firstRunLine = runLines[0]
   shell = args.dockerArgs['SHELL']
   powershellC = 'powershell -c '
   powershellCIdx = firstRunLine.lower().find(powershellC)
   powershellCommand = 'powershell -command '
   powershellCommandIdx = firstRunLine.lower().find(powershellCommand)
   shellIsPowershell = True if shell.lower().find('powershell -command') == 0 else False

   # Replace Powershell script invokation with simple "Call operator &"
   firstLineCmd = ''
   if shellIsPowershell:
      if powershellCIdx == 0:
         firstLineCmd = '{}'.format(firstRunLine[len(powershellC):])
      elif powershellCommandIdx == 0:
         firstLineCmd = '{}'.format(firstRunLine[len(powershellCommand):])
      else:
         firstLineCmd = '{}'.format(firstRunLine)
   else:
      firstLineCmd = '{} {}'.format(args.dockerArgs['SHELL'], firstRunLine)

   # Start stopwatch
   powershellFile.write('$stopwatch = [system.diagnostics.stopwatch]::StartNew()\n')

   # Show step #
   context.currentTaskIndex += 1
   generateProgress(context, powershellFile, args.verbose, firstLineCmd)

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
Set-Location $origLocation
# [Environment]::CurrentDirectory = $origLocation ## In some future cases this line may need to be executed
Update-SessionEnvironment
# Measure taken time
$stopwatch.Stop()
$timeTaken = $stopwatch.Elapsed.ToString("dd\.hh\:mm\:ss")
Write-Host "... this step executed in $timeTaken`n"

""")
 

# ===========================================================
# COPY
#
def lineGenerator_COPY(context, powershellFile, args, dockerLine):
   generateDockerfileReferenceComment(powershellFile, dockerLine, args.verbose)
   
   # Remove Dockerfile based specific "--from=xxx" construct. We can do it
   # because Docker base image should be accessible in file system during
   # Powershell script run
   copyNoFrom = re.sub('--from=\S+',  '', dockerLine['value']).strip()
   nameValues = copyNoFrom.split()

   context.currentTaskIndex += 1

   dest = nameValues[len(nameValues) - 1].replace('/', '\\')

   # Copy each of the few src
   for srcIdx in range(len(nameValues) - 1):
      src = nameValues[srcIdx].replace('/', '\\')

      # Absolute path will copy AS IS (it usually part of "--from=xxx")
      srcPath = src if len(src) > 2 and src[1] == ':' else '$DockerRepoPath\{}'.format(src)
      
      # Need to dynamically detect if the source is directory and copy as directory
      # currently copy is good only for files
      cmd = 'copy {} {}'.format(srcPath, dest)
      generateProgress(context, powershellFile, args.verbose, cmd)
      powershellFile.write('{}\n'.format(cmd))

   powershellFile.write('Write-Host\n\n')


# ===========================================================
# ENTRYPOINT
#
def lineGenerator_ENTRYPOINT(context, powershellFile, args, dockerLine):
   generateDockerfileReferenceComment(powershellFile, dockerLine, args.verbose)
   powershellFile.write('\n\n')

def lineGenerator_CMD(context, powershellFile, args, dockerLine):
   generateDockerfileReferenceComment(powershellFile, dockerLine, args.verbose)
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

def generatePowershell(dockerParser, powershellFile, args):

   # Add header to the Powershell file
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
      lineHandlersMap[dockerLine['instruction']](context, powershellFile, args, dockerLine)

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
#  If this script had been generated from ...
#      https://github.com/DataDog/datadog-agent-buildimages/blob/main/windows/Dockerfile
#  ... which is currently based ...
#      on mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-ltsc2019
#  ... image, then you will need to install .NET 4.8 before running it from one of three sources
#     * https://dotnet.microsoft.com/en-us/download/dotnet-framework/net48
#     * https://support.microsoft.com/en-us/topic/microsoft-net-framework-4-8-offline-installer-for-windows-9d23f658-3b97-68ab-d013-aa3c3e7495e0
#     * https://github.com/microsoft/dotnet-framework-docker/blob/528e53c63f429860d99d55409b0018d225059f0c/src/runtime/4.8/windowsservercore-ltsc2019/Dockerfile
#
#  Similarly, for other Dockerfiles you need to make sure that you prepare Windows machine to
#  be matching its Dockerfile's BASE image.
#
#  If you try to run this script more than once some commands may fail and break the script.
#  It may be addressed better in the future but for now you may need to comment out offending
#  commands. If after running generated from the Dockerfile Powershell script the Dockerfile
#  had been modified and you wish to apply these changes, then in contrast to applying newly
#  generated Powershell script your mileage may vary (and it depends very much on the Dockerfile
#  content) ...
#    * It may actually just work
#    * You may need to comment out everything except the difference between old and new
#      Powershell script
#    * You may need to explicitly uninstall or remove previously deployed applications, files
#      or other artifacts
#
# Usage: .\<this-script.ps1> -DockerRepoPath <repo path>
#    -DockerRepoPath is required parameter. You need to clone the
#    same repo as the one used for building Docker image.
#    Specifically it is https://github.com/DataDog/datadog-agent-buildimages
Param(
    [Parameter(Mandatory)]
    [string]
    $DockerRepoPath
)

$DockerRepoPathExists = Test-Path $DockerRepoPath
if (!$DockerRepoPathExists) {
    Write-Host "Provided \'DockerRepoPath\' ($DockerRepoPath) path does not exist. Please provide valid argument"
    Exit
}
   
# Save current location and sync it to .NET current location (it is not automatic and needed in some cases)
#    https://stackoverflow.com/questions/11246068/why-dont-net-objects-in-powershell-use-the-current-directory
$origLocation = Get-Location
[Environment]::CurrentDirectory = $origLocation
# Currently Docker run everything in the root. And we have to keep it this way
Set-Location $origLocation

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

def generateProgress(context, powershellFile, verbose, cmd):
   powershellFile.write("Write-Host @'\n")
   if verbose:
      powershellFile.write('[{}/{}] Starting to {} ...\n'.format(context.currentTaskIndex, context.totalTask, cmd))
   else:
      powershellFile.write('Starting to {} ...\n'.format(cmd))

   powershellFile.write("'@\n")

def generateFooter(powershellFile):
   powershellFile.write("""$totalStopwatch.Stop()
$timeTaken = $totalStopwatch.Elapsed.ToString("dd\.hh\:mm\:ss")
Write-Host "Script executed in $timeTaken"
""")

def generateDockerfileReferenceComment(powershellFile, dockerLine, verbose):
   lines = dockerLine['content'].split('\n')
   if verbose:
      powershellFile.write('# Line: {}, Content: {}\n'.format((dockerLine['startline'] + 1), lines[0]))
   else:
      powershellFile.write('# Content: {}\n'.format(lines[0]))

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

   # Create Powershell file
   powershellFile = createPowershellFile(args.powershellFilePath)

   generatePowershell(dockerParser, powershellFile, args)

if __name__ == '__main__':
    main(sys.argv[1:])
