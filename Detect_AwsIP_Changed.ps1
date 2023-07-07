# ======== 設定 ========

# メール関連
$to = "anyone@company.co.jp"
$from = "someone@hogehoge.jp"
$subject = "#### AWS IP Ranges are Changed ####"
$smtp = "xxx.xxx.xxx.xxx"

# 各種保存用ファイル名（通常はこのままで良い）
$scriptFile = $MyInvocation.MyCommand.Path
$scriptPath = Split-Path -Parent $scriptFile
$FileNewDate = $scriptPath + "\PublicationDate.txt"
$FileOldDate = $scriptPath + "\PublicationDate_Old.txt"
$IpFileNew = $scriptPath + "\Data\AWS_IPRange.txt"
$IpFileOld = $scriptPath + "\Data\AwsIPs_Reference.txt"
$FileCompare = $scriptPath + "\AWS_IpCompate_Japan.txt"

# ======== 設定終わり ========


Import-Module AWSPowerShell

# AWS の IP Ranges の更新日付を取得し、過去との比較で変更が無ければ更新されていないので終了する
Get-AWSPublicIpAddressRange -OutputPublicationDate | Out-File $FileNewDate

$myDateCheck = Compare-Object (Get-Content $FileNewDate | ForEach-Object { $_.trim() }) (Get-Content $FileOldDate | ForEach-Object { $_.trim() })
Write-Output $myDateCheck

If ($myDateCheck){
    Write-Output "Any AWS IP Ranges are changed! (ap-northeast-1)"
}Else{
    Write-Output "AWS IP Ranges are not changed. (ap-northeast-1)"
    exit
}

# AWS 東京リージョンの IP アドレス範囲を取得して、ファイルに保存する
Get-AWSPublicIpAddressRange -Region ap-northeast-1 | Select-Object IpPrefix,IpAddressFormat,Region | Where-Object IpAddressFormat -match "Ipv4" | Out-File $IpFileNew

# 過去の IP アドレス範囲と比較する
$myCompare = Compare-Object (Get-Content $IpFileNew | ForEach-Object { $_.trim() }) (Get-Content $IpFileOld | ForEach-Object { $_.trim() })
Write-Output $myCompare

# IP アドレス範囲が変更されていたらメールで通知する
Compare-Object (Get-Content $IpFileNew | ForEach-Object { $_.trim() }) (Get-Content $IpFileOld | ForEach-Object { $_.trim() }) | Out-File $FileCompare

If ($myCompare){
    Write-Output "IP Ranges are changed! (AWS ap-northeast-1)"
    $MailBody = "AWS 東京リージョン (ap-northeast-1) にて IPアドレス範囲の変更がありました。（添付ファイル参照）"
    Write-Output "Send a mail."
    Send-MailMessage -To $to -From $from -SmtpServer $smtp -Subject $subject -Body $MailBody -Attachments $FileCompare -Encoding UTF8
}Else{
    Write-Output "IP Ranges are not changed. (AWS ap-northeast-1)"
}

# ローカルのファイルをコピーして次回の処理に備える
$ReferenceFileName = $IpFileOld
$ReferenceFileName1 = $scriptPath + "\Data\AwsIPs_Reference.1.txt"
$ReferenceFileName2 = $scriptPath + "\Data\AwsIPs_Reference.2.txt"
$ReferenceFileName3 = $scriptPath + "\Data\AwsIPs_Reference.3.txt"
$ReferenceFileName4 = $scriptPath + "\Data\AwsIPs_Reference.4.txt"
$ReferenceFileName5 = $scriptPath + "\Data\AwsIPs_Reference.5.txt"
$ReferenceFileName6 = $scriptPath + "\Data\AwsIPs_Reference.6.txt"
$ReferenceFileName7 = $scriptPath + "\Data\AwsIPs_Reference.7.txt"
$ReferenceFileName8 = $scriptPath + "\Data\AwsIPs_Reference.8.txt"
$ReferenceFileName9 = $scriptPath + "\Data\AwsIPs_Reference.9.txt"

If (Test-Path $ReferenceFileName8){
    Write-Output "Copy Reference8 to Reference9"
    Copy-Item $ReferenceFileName8 $ReferenceFileName9
}
If (Test-Path $ReferenceFileName7){
    Write-Output "Copy Reference7 to Reference8"
    Copy-Item $ReferenceFileName7 $ReferenceFileName8
}
If (Test-Path $ReferenceFileName6){
    Write-Output "Copy Reference6 to Reference7"
    Copy-Item $ReferenceFileName6 $ReferenceFileName7
}
If (Test-Path $ReferenceFileName5){
    Write-Output "Copy Reference5 to Reference6"
    Copy-Item $ReferenceFileName5 $ReferenceFileName6
}
If (Test-Path $ReferenceFileName4){
    Write-Output "Copy Reference4 to Reference5"
    Copy-Item $ReferenceFileName4 $ReferenceFileName5
}
If (Test-Path $ReferenceFileName3){
    Write-Output "Copy Reference3 to Reference4"
    Copy-Item $ReferenceFileName3 $ReferenceFileName4
}
If (Test-Path $ReferenceFileName2){
    Write-Output "Copy Reference2 to Reference3"
    Copy-Item $ReferenceFileName2 $ReferenceFileName3
}
If (Test-Path $ReferenceFileName1){
    Write-Output "Copy Reference1 to Reference2"
    Copy-Item $ReferenceFileName1 $ReferenceFileName2
}
If (Test-Path $ReferenceFileName){
    Write-Output "Copy Reference to Reference1"
    Copy-Item $ReferenceFileName $ReferenceFileName1
}
Write-Output "Copy New File to Reference"
Copy-Item $IpFileNew $ReferenceFileName

Write-Output "Copy PublicationDate File to Old File"
Copy-Item $FileNewDate $FileOldDate

