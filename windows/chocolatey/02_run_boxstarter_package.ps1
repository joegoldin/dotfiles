$cred=Get-Credential Joe
cd installers
Install-BoxstarterPackage -PackageName choco_install.ps1 -Credential $cred
