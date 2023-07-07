Param(
    [parameter(Mandatory=$True)]
    [string]$StorageAccountName,

    [parameter(Mandatory=$True)]
    [string]$StorageContainerName,

    [parameter(Mandatory=$True)]
    [String]$StorageAccountKey,

    [parameter(Mandatory=$True)]
    [string] $mailTo
)

# ======== 設定 ========
# メール関連
$SendGridApiKey = "<Your Send Grid API Key>"
$mailFrom = "anyone@company.com"
$mailSubject = "#### AWS IP Ranges are Changed ####"
# ======== 設定終わり ========

# 変数の設定
$saveFileCompareAws = "IpCompare.txt"
$JsonNew = "Current.json"
$JsonOld = "Reference.json"
$blobProperties = @{"ContentType" = "application/json"};


# Azure Blob Storage に接続
$ctx = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey

# AWS の IP Ranges の json を取得
Write-Output ">> Get a new json."
$myNewObj = Invoke-RestMethod -Method GET "https://ip-ranges.amazonaws.com/ip-ranges.json"
$myNewObj | ConvertTo-Json -Depth 100 | Out-File -Encoding utf8 $JsonNew
Write-Output ">> Save a new json file to the Blob Storage."
Set-AzureStorageBlobContent -File $JsonNew -Container $StorageContainerName -Blob $JsonNew -Properties $blobProperties -Context $ctx -Force

# 現在の json の createDate の値を変数にセットする
$myDateNew = $myNewObj.createDate
Write-Output ">> Update time of the new json: $myDateNew"
# 過去の json ファイルを読み込み、createDate の値を変数にセットする
Write-Output ">> Read a reference (previous) json file from the Blob storage."
Get-AzureStorageBlobContent -Container $StorageContainerName -Blob $JsonOld -Destination .\ -Context $ctx
$myOldObj = Get-Content $JsonOld -Raw | ConvertFrom-Json
$myDateOld = $myOldObj.createDate
Write-Output ">> Update time of the reference json: $myDateOld"

# 新旧の createDate の値を比較して、同じであればスクリプトを終了する
Write-Output ">> Compare the createDate value of both json."
$myDateCheck = Compare-Object $myDateNew $myDateOld
If ($myDateCheck){
    Write-Output ">> Any AWS IP Ranges are changed!"
}Else{
    Write-Output ">> AWS IP Ranges are NOT changed."
    Write-Output ">> Exit the script."
    exit
}

# 新旧の json から必要な IP アドレス範囲を取得する
Write-Output ">> Compare required IP ranges from both json."
$myNewObj.prefixes | Where-Object {$_.region -eq 'ap-northeast-1'} | Select-Object ip_prefix | Sort-Object ip_prefix | Out-File "new.txt"
$myOldObj.prefixes | Where-Object {$_.region -eq 'ap-northeast-1'} | Select-Object ip_prefix | Sort-Object ip_prefix | Out-File "old.txt"
# 双方の IP アドレス範囲を比較する
$myCompare = Compare-Object (Get-Content "old.txt" | ForEach-Object { $_.trim() }) (Get-Content "new.txt" | ForEach-Object { $_.trim() })
Write-Output $myCompare

Set-AzureStorageBlobContent -File "new.txt" -Container $StorageContainerName -Blob "new.txt" -Properties $blobProperties -Context $ctx -Force
Set-AzureStorageBlobContent -File "old.txt" -Container $StorageContainerName -Blob "old.txt" -Properties $blobProperties -Context $ctx -Force

# IP アドレス範囲が変更されていたら、違いをファイルに保存してメールで通知する
If ($myCompare){
    Write-Output ">> Required IP ranges are changed."
    Write-Output ">> Save the difference in IP ranges to attach to the e-mail."
    Write-Output $myCompare | Out-File -Encoding utf8 $saveFileCompareAws
    $CompareFilePath = Resolve-Path $saveFileCompareAws
    Set-AzureStorageBlobContent -File $saveFileCompareAws -Container $StorageContainerName -Blob $saveFileCompareAws -Context $ctx -Force

    Write-Output ">> Set e-mail parameters."
    $msg = @"
AWS 東京リージョン (ap-northeast-1) にて IPアドレス範囲の変更がありました。
（添付ファイル参照）
  ●添付ファイルの見かた
       InputObject        SideIndicator
       -----------        -------------
      ［削除された IP範囲］ =>
      ［追加された IP範囲］ <=
"@
    Write-Output ">> Encode attachment content to Base64."
    $attachContent = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($CompareFilePath))
    $headers = @{
        "Authorization" = "Bearer $SendGridApiKey"
        "Content-Type" = "application/json"
    }
    Write-Output ">> Generate a request body."
    $body = @{
        "personalizations" = @(
            @{
                "to" = @(
                    @{"email" = $mailTo }
                )
            }
        )
        "subject" = $mailSubject
        "content" = @(
            @{"type" = "text/plain"
              "value" = $msg}
        )
        "attachments" = @(
            @{
                "content" = $attachContent
                "filename" = $saveFileCompareAws
            }
        )
        "from" = @{"email" = $mailFrom}
    }

    Write-Output $body

    Write-Output ">> Convert the request body to json."
    $bodyJson = $body | ConvertTo-Json -Depth 10
    # 文字化け防止
    Write-Output ">> Encode to utf8."
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($bodyJson)

    Write-Output ">> Send the e-mail."   
    $sendGridUri = "https://api.sendgrid.com/v3/mail/send"
    $res = Invoke-RestMethod -Uri $sendGridUri -Method Post -Headers $headers -Body $bodyBytes
    Write-Output $res
}Else{
    Write-Output ">> Required IP Ranges are NOT changed."
}

# ローカルのファイルをコピーして次回の処理に備える
Write-Output ">> Rename json files."
$ReferenceFileName = $JsonOld
$ReferenceFileName1 = "Reference.1.json"
$ReferenceFileName2 = "Reference.2.json"
$ReferenceFileName3 = "Reference.3.json"
$ReferenceFileName4 = "Reference.4.json"
$ReferenceFileName5 = "Reference.5.json"
$ReferenceFileName6 = "Reference.6.json"
$ReferenceFileName7 = "Reference.7.json"
$ReferenceFileName8 = "Reference.8.json"
$ReferenceFileName9 = "Reference.9.json"

$blob9 = Get-AzureStorageBlob -Blob $ReferenceFileName9 -Container $StorageContainerName -Context $ctx -ErrorAction Ignore
If ($blob9){
    Write-Output "Delete Reference9"
    Remove-AzureStorageBlob -Container $StorageContainerName -Blob $ReferenceFileName9 -Context $ctx -Force
}
$blob8 = Get-AzureStorageBlob -Blob $ReferenceFileName8 -Container $StorageContainerName -Context $ctx -ErrorAction Ignore
If ($blob8){
    Write-Output "Copy Reference8 to Reference9"
    Get-AzureStorageBlobContent -Container $StorageContainerName -Blob $ReferenceFileName8 -Destination ./ -Context $ctx -Force
    Rename-Item -Path $ReferenceFileName8 -NewName $ReferenceFileName9
    Set-AzureStorageBlobContent -File $ReferenceFileName9 -Container $StorageContainerName -Blob $ReferenceFileName9 -Properties $blobProperties -Context $ctx -Force
}
$blob7 = Get-AzureStorageBlob -Blob $ReferenceFileName7 -Container $StorageContainerName -Context $ctx -ErrorAction Ignore
If ($blob7){
    Write-Output "Copy Reference7 to Reference8"
    Get-AzureStorageBlobContent -Container $StorageContainerName -Blob $ReferenceFileName7 -Destination ./ -Context $ctx -Force
    Rename-Item -Path $ReferenceFileName7 -NewName $ReferenceFileName8
    Set-AzureStorageBlobContent -File $ReferenceFileName8 -Container $StorageContainerName -Blob $ReferenceFileName8 -Properties $blobProperties -Context $ctx -Force
}
$blob6 = Get-AzureStorageBlob -Blob $ReferenceFileName6 -Container $StorageContainerName -Context $ctx -ErrorAction Ignore
If ($blob6){
    Write-Output "Copy Reference6 to Reference7"
    Get-AzureStorageBlobContent -Container $StorageContainerName -Blob $ReferenceFileName6 -Destination ./ -Context $ctx -Force
    Rename-Item -Path $ReferenceFileName6 -NewName $ReferenceFileName7
    Set-AzureStorageBlobContent -File $ReferenceFileName7 -Container $StorageContainerName -Blob $ReferenceFileName7 -Properties $blobProperties -Context $ctx -Force
}
$blob5 = Get-AzureStorageBlob -Blob $ReferenceFileName5 -Container $StorageContainerName -Context $ctx -ErrorAction Ignore
If ($blob5){
    Write-Output "Copy Reference5 to Reference6"
    Get-AzureStorageBlobContent -Container $StorageContainerName -Blob $ReferenceFileName5 -Destination ./ -Context $ctx -Force
    Rename-Item -Path $ReferenceFileName5 -NewName $ReferenceFileName6
    Set-AzureStorageBlobContent -File $ReferenceFileName6 -Container $StorageContainerName -Blob $ReferenceFileName6 -Properties $blobProperties -Context $ctx -Force
}
$blob4 = Get-AzureStorageBlob -Blob $ReferenceFileName4 -Container $StorageContainerName -Context $ctx -ErrorAction Ignore
If ($blob4){
    Write-Output "Copy Reference4 to Reference5"
    Get-AzureStorageBlobContent -Container $StorageContainerName -Blob $ReferenceFileName4 -Destination ./ -Context $ctx -Force
    Rename-Item -Path $ReferenceFileName4 -NewName $ReferenceFileName5
    Set-AzureStorageBlobContent -File $ReferenceFileName5 -Container $StorageContainerName -Blob $ReferenceFileName5 -Properties $blobProperties -Context $ctx -Force
}
$blob3 = Get-AzureStorageBlob -Blob $ReferenceFileName3 -Container $StorageContainerName -Context $ctx -ErrorAction Ignore
If ($blob3){
    Write-Output "Coopy Reference3 to Reference4"
    Get-AzureStorageBlobContent -Container $StorageContainerName -Blob $ReferenceFileName3 -Destination ./ -Context $ctx -Force
    Rename-Item -Path $ReferenceFileName3 -NewName $ReferenceFileName4
    Set-AzureStorageBlobContent -File $ReferenceFileName4 -Container $StorageContainerName -Blob $ReferenceFileName4 -Properties $blobProperties -Context $ctx -Force
}
$blob2 = Get-AzureStorageBlob -Blob $ReferenceFileName2 -Container $StorageContainerName -Context $ctx -ErrorAction Ignore
If ($blob2){
    Write-Output "Copy Reference2 to Reference3"
    Get-AzureStorageBlobContent -Container $StorageContainerName -Blob $ReferenceFileName2 -Destination ./ -Context $ctx -Force
    Rename-Item -Path $ReferenceFileName2 -NewName $ReferenceFileName3
    Set-AzureStorageBlobContent -File $ReferenceFileName3 -Container $StorageContainerName -Blob $ReferenceFileName3 -Properties $blobProperties -Context $ctx -Force
}
$blob1 = Get-AzureStorageBlob -Blob $ReferenceFileName1 -Container $StorageContainerName -Context $ctx -ErrorAction Ignore
If ($blob1){
    Write-Output "Copy Reference1 to Reference2"
    Get-AzureStorageBlobContent -Container $StorageContainerName -Blob $ReferenceFileName1 -Destination ./ -Context $ctx -Force
    Rename-Item -Path $ReferenceFileName1 -NewName $ReferenceFileName2
    Set-AzureStorageBlobContent -File $ReferenceFileName2 -Container $StorageContainerName -Blob $ReferenceFileName2 -Properties $blobProperties -Context $ctx -Force
}
$blob = Get-AzureStorageBlob -Blob $ReferenceFileName -Container $StorageContainerName -Context $ctx -ErrorAction Ignore
If ($blob){
    Write-Output "Copy Reference to Reference1"
    Get-AzureStorageBlobContent -Container $StorageContainerName -Blob $ReferenceFileName -Destination ./ -Context $ctx -Force
    Rename-Item -Path $ReferenceFileName -NewName $ReferenceFileName1
    Set-AzureStorageBlobContent -File $ReferenceFileName1 -Container $StorageContainerName -Blob $ReferenceFileName1 -Properties $blobProperties -Context $ctx -Force
}
$blobJsonNew = Get-AzureStorageBlob -Blob $JsonNew -Container $StorageContainerName -Context $ctx -ErrorAction Ignore
If ($blobJsonNew){
    Write-Output "Copy New File to Reference"
    Get-AzureStorageBlobContent -Container $StorageContainerName -Blob $JsonNew -Destination ./ -Context $ctx -Force
    Rename-Item -Path $JsonNew -NewName $ReferenceFileName
    Set-AzureStorageBlobContent -File $ReferenceFileName -Container $StorageContainerName -Blob $ReferenceFileName -Properties $blobProperties -Context $ctx -Force
}

Write-Output ">> End of script."
