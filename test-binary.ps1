# TEST ONLY: generates a trivial, never-before-seen .exe using the in-box .NET Framework compiler
# (no downloads needed), to check whether a plain Dockerfile COPY of ANY brand-new executable hangs,
# or whether the hang is specific to windows-code-signer.exe. Remove before merging.
Add-Type -OutputType ConsoleApplication -OutputAssembly ".\test-binary.exe" -TypeDefinition @"
public class Test { public static void Main() { System.Console.WriteLine("hello"); } }
"@
