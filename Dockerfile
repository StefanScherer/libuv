FROM microsoft/windowsservercore

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';"]

ENV VISUAL_CPP_BUILD_TOOLS_URL "https://download.microsoft.com/download/5/f/7/5f7acaeb-8363-451f-9425-68a90f98b238/visualcppbuildtools_full.exe"

RUN Write-Host ('Downloading {0}...' -f $Env:VISUAL_CPP_BUILD_TOOLS_URL); \
	Invoke-WebRequest $Env:VISUAL_CPP_BUILD_TOOLS_URL \
		-OutFile visualcppbuildtools_full.exe -UseBasicParsing ; \
	Write-Host 'Installing Visual C++ Build Tools (can take a while)...'; \
	Start-Process -FilePath 'visualcppbuildtools_full.exe' -ArgumentList '/quiet', '/NoRestart' -Wait ; \
	Remove-Item .\visualcppbuildtools_full.exe

RUN [Environment]::SetEnvironmentVariable('PATH', ${Env:ProgramFiles(x86)} + '\Microsoft Visual Studio 14.0\VC\bin\amd64;' + ${Env:ProgramFiles(x86)} + '\Windows Kits\10\bin\x64;' + $env:PATH, [EnvironmentVariableTarget]::Machine);

RUN Write-Host 'Configuring environment'; \
	pushd 'C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC' ; \
	cmd /c 'vcvarsall.bat amd64&set' | foreach { if ($_ -match '=') { $v = $_.split('='); setx /M $v[0] $v[1] } } ; \
	popd

ENV GIT_VERSION 2.8.1

RUN (New-Object System.Net.WebClient).DownloadFile('https://github.com/git-for-windows/git/releases/download/v{0}.windows.1/Git-{0}-64-bit.exe' -f $env:GIT_VERSION, 'gitinstaller.exe') ; \
  Start-Process .\gitinstaller.exe -ArgumentList '/VERYSILENT /SUPPRESSMSGBOXES /CLOSEAPPLICATIONS /DIR=c:\git' -Wait ; \
  $env:PATH = 'C:\git\cmd;C:\git\bin;C:\git\usr\bin;{0}' -f $env:PATH ; \
  [Environment]::SetEnvironmentVariable('PATH', $env:PATH, [EnvironmentVariableTarget]::Machine) ; \
  Remove-Item .\gitinstaller.exe

ENV PYTHON_VERSION 2.7.12
ENV PYTHON_RELEASE 2.7.12

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 9.0.1

RUN $url = ('https://www.python.org/ftp/python/{0}/python-{1}.amd64.msi' -f $env:PYTHON_RELEASE, $env:PYTHON_VERSION); \
	Write-Host ('Downloading {0} ...' -f $url); \
	(New-Object System.Net.WebClient).DownloadFile($url, 'python.msi'); \
	\
	Write-Host 'Installing ...'; \
	Start-Process msiexec -Wait \
		-ArgumentList @( \
			'/i', \
			'python.msi', \
			'/quiet', \
			'/qn', \
			'TARGETDIR=C:\Python', \
			'ALLUSERS=1', \
			'ADDLOCAL=DefaultFeature,Extensions,TclTk,Tools,PrependPath' \
		); \
	\
	$env:PATH = [Environment]::GetEnvironmentVariable('PATH', [EnvironmentVariableTarget]::Machine); \
	\
	Write-Host 'Verifying install ...'; \
	Write-Host '  python --version'; python --version; \
	\
	Write-Host 'Removing ...'; \
	Remove-Item python.msi -Force; \
	\
	$pipInstall = ('pip=={0}' -f $env:PYTHON_PIP_VERSION); \
	Write-Host ('Installing {0} ...' -f $pipInstall); \
	(New-Object System.Net.WebClient).DownloadFile('https://bootstrap.pypa.io/get-pip.py', 'get-pip.py'); \
	python get-pip.py $pipInstall; \
	Remove-Item get-pip.py -Force; \
	\
	Write-Host 'Verifying pip install ...'; \
	pip --version; \
	\
	Write-Host 'Complete.';

# install "virtualenv", since the vast majority of users of this image will want it
RUN pip install --no-cache-dir virtualenv

ENV GYP_MSVS_VERSION 2015

COPY . /code
WORKDIR /code
