Clear-Host;
Write-Host "Downloading and Installing oh-myz-sh fonts...";

#Next line may be requires to add or change something, may be all :(
$fonts = (New-Object -ComObject Shell.Application).Namespace(0x14);

(@{
	name = 'MesloLGS NF Regular.ttf';
	url = 'https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf';
	},@{
		name = 'MesloLGS NF Bold.ttf';
		url = 'https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf';
	},@{
		 name = 'MesloLGS NF Italic.ttf';
		url = 'https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf';
	},@{
		 name = 'MesloLGS NF Bold Italic.ttf';
		url = 'https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf';
	}
) | ForEach-Object {
	$destFile = ${env:temp}+ "\" + $_.name;
	$fontFile = ${env:windir}+ "\fonts\" + $_.name;
	if (Test-Path -Path $destFile -PathType Leaf) {
		Remove-Item -Path $destFile -Force;
	}

	if(Test-Path -Path $fontFile -PathType Leaf) {
		Remove-Item -Path $fontFile -Force;
	}
	Write-Host "Downloading and installing font" $_.name;
	Invoke-WebRequest -URI ($_.url) -OutFile $destFile;
	Get-ChildItem $destFile | ForEach-Object{
		#Next line may be requires to add or change something, may be all :(
		$fonts.CopyHere($_.fullname)
	};
	if (Test-Path -Path $destFile -PathType Leaf) {
		Remove-Item -Path $destFile -Force;
	}
}
