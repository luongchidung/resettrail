# Cài đặt mã hóa đầu ra là UTF-8
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Định nghĩa màu sắc
$RED = "`e[31m"
$GREEN = "`e[32m"
$YELLOW = "`e[33m"
$BLUE = "`e[34m"
$NC = "`e[0m"

# Đường dẫn tệp cấu hình và URL của key
$STORAGE_FILE = "$env:APPDATA\Cursor\User\globalStorage\storage.json"
$BACKUP_DIR = "$env:APPDATA\Cursor\User\globalStorage\backups"
$KEY_URL = "https://raw.githubusercontent.com/luongchidung/resettrail/master/scripts/key_usage.txt"  # URL của file key trên GitHub

# Kiểm tra quyền quản trị viên
function Test-Administrator {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($user)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Host "$RED[Lỗi]$NC Vui lòng chạy script này với quyền quản trị viên"
    Write-Host "Hãy nhấp chuột phải vào script và chọn 'Chạy với quyền quản trị viên'"
    Read-Host "Nhấn phím Enter để thoát"
    exit 1
}

# Tải file key_usage.txt từ GitHub
$KeyFilePath = "$env:APPDATA\Cursor\User\key_usage.txt"
Invoke-WebRequest -Uri $KEY_URL -OutFile $KeyFilePath

# Kiểm tra và hiển thị thời gian sử dụng key
function Check-KeyExpiration {
    if (Test-Path $KeyFilePath) {
        $keyData = Get-Content $KeyFilePath -Raw
        $keyParts = $keyData.Split("`n")
        
        # Kiểm tra nếu file không chứa key hoặc ngày kích hoạt
        if ($keyParts.Length -lt 2) {
            Write-Host "$RED[Lỗi]$NC Dữ liệu key không hợp lệ trong file."
            return $false
        }

        $key = $keyParts[0]
        $activationDateStr = $keyParts[1]

        # Cố gắng phân tích ngày kích hoạt
        try {
            $activationDate = [datetime]::Parse($activationDateStr)
        }
        catch {
            Write-Host "$RED[Lỗi]$NC Không thể phân tích ngày kích hoạt: $activationDateStr"
            return $false
        }

        $expirationDate = $activationDate.AddDays(30)
        $remainingTime = $expirationDate - (Get-Date)

        Write-Host "$GREEN[Thông tin]$NC Key: $key"
        Write-Host "$GREEN[Thông tin]$NC Ngày kích hoạt: $activationDate"
        Write-Host "$GREEN[Thông tin]$NC Ngày hết hạn: $expirationDate"
        Write-Host "$GREEN[Thông tin]$NC Trạng thái: Active"

        if ($remainingTime.TotalDays -le 0) {
            Write-Host "$RED[Thông báo]$NC Key đã hết hạn."
            return $false
        } else {
            Write-Host "$GREEN[Thông tin]$NC Key hợp lệ. Thời gian còn lại: $($remainingTime.Days) ngày."
            return $true
        }
    } else {
        Write-Host "$YELLOW[Cảnh báo]$NC Key chưa được kích hoạt."
        return $false
    }
}

# Hiển thị logo và thông tin cơ bản
Clear-Host
Write-Host @"

    ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗ 
   ██╔════╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗
   ██║     ██║   ██║██████╔╝███████╗██║   ██║██████╔╝
   ██║     ██║   ██║██╔══██╗╚════██║██║   ██║██╔══██╗
   ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║
    ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝

"@
Write-Host "$BLUE================================$NC"
Write-Host "$GREEN   Công cụ thay đổi ID thiết bị Cursor $NC"
Write-Host "$YELLOW  Facebook: Luong Chi Dung $NC"
Write-Host "$YELLOW  Zalo: 0847154088 $NC"
Write-Host "$BLUE================================$NC"
Write-Host ""

# Lấy và hiển thị phiên bản Cursor
function Get-CursorVersion {
    try {
        # Kiểm tra đường dẫn chính
        $packagePath = "$env:LOCALAPPDATA\Programs\cursor\resources\app\package.json"
        
        if (Test-Path $packagePath) {
            $packageJson = Get-Content $packagePath -Raw | ConvertFrom-Json
            if ($packageJson.version) {
                Write-Host "$GREEN[Thông tin]$NC Phiên bản Cursor hiện tại: v$($packageJson.version)"
                return $packageJson.version
            }
        }

        # Kiểm tra đường dẫn thay thế
        $altPath = "$env:LOCALAPPDATA\cursor\resources\app\package.json"
        if (Test-Path $altPath) {
            $packageJson = Get-Content $altPath -Raw | ConvertFrom-Json
            if ($packageJson.version) {
                Write-Host "$GREEN[Thông tin]$NC Phiên bản Cursor hiện tại: v$($packageJson.version)"
                return $packageJson.version
            }
        }

        Write-Host "$YELLOW[Cảnh báo]$NC Không thể phát hiện phiên bản Cursor"
        Write-Host "$YELLOW[Lưu ý]$NC Vui lòng đảm bảo rằng Cursor đã được cài đặt chính xác"
        return $null
    }
    catch {
        Write-Host "$RED[Lỗi]$NC Lỗi khi lấy phiên bản Cursor: $_"
        return $null
    }
}

# Lấy và hiển thị thông tin phiên bản
$cursorVersion = Get-CursorVersion
Write-Host ""

Write-Host "$YELLOW[Lưu ý quan trọng]$NC Phiên bản mới nhất là 0.47.x (được hỗ trợ)"
Write-Host ""

# Kiểm tra và đóng tiến trình Cursor
Write-Host "$GREEN[Thông tin]$NC Kiểm tra tiến trình Cursor..."

function Get-ProcessDetails {
    param($processName)
    Write-Host "$BLUE[Debug]$NC Đang lấy chi tiết tiến trình của ${processName}:"
    Get-WmiObject Win32_Process -Filter "name='$processName'" | 
        Select-Object ProcessId, ExecutablePath, CommandLine | 
        Format-List
}

# Định nghĩa số lần thử tối đa và thời gian chờ
$MAX_RETRIES = 5
$WAIT_TIME = 1

# Đóng tiến trình Cursor
function Close-CursorProcess {
    param($processName)
    
    $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
    if ($process) {
        Write-Host "$YELLOW[Cảnh báo]$NC Phát hiện $processName đang chạy"
        Get-ProcessDetails $processName
        
        Write-Host "$YELLOW[Cảnh báo]$NC Đang cố gắng đóng $processName..."
        Stop-Process -Name $processName -Force
        
        $retryCount = 0
        while ($retryCount -lt $MAX_RETRIES) {
            $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
            if (-not $process) { break }
            
            $retryCount++
            if ($retryCount -ge $MAX_RETRIES) {
                Write-Host "$RED[Lỗi]$NC Không thể đóng $processName sau $MAX_RETRIES lần thử"
                Get-ProcessDetails $processName
                Write-Host "$RED[Lỗi]$NC Vui lòng đóng tiến trình thủ công và thử lại"
                Read-Host "Nhấn phím Enter để thoát"
                exit 1
            }
            Write-Host "$YELLOW[Cảnh báo]$NC Đang chờ đóng tiến trình, thử $retryCount/$MAX_RETRIES..."
            Start-Sleep -Seconds $WAIT_TIME
        }
        Write-Host "$GREEN[Thông tin]$NC $processName đã được đóng thành công"
    }
}

# Đóng tất cả tiến trình Cursor
Close-CursorProcess "Cursor"
Close-CursorProcess "cursor"

# Tạo thư mục sao lưu
if (-not (Test-Path $BACKUP_DIR)) {
    New-Item -ItemType Directory -Path $BACKUP_DIR | Out-Null
}

# Sao lưu cấu hình hiện tại
if (Test-Path $STORAGE_FILE) {
    Write-Host "$GREEN[Thông tin]$NC Đang sao lưu tệp cấu hình..."
    $backupName = "storage.json.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $STORAGE_FILE "$BACKUP_DIR\$backupName"
}

# Tạo ID mới
Write-Host "$GREEN[Thông tin]$NC Đang tạo ID mới..."

# Hàm tạo số ngẫu nhiên
function Get-RandomHex {
    param (
        [int]$length
    )
    
    $bytes = New-Object byte[] ($length)
    $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
    $rng.GetBytes($bytes)
    $hexString = [System.BitConverter]::ToString($bytes) -replace '-',''
    $rng.Dispose()
    return $hexString
}

# Cải tiến hàm tạo ID
function New-StandardMachineId {
    $template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    $result = $template -replace '[xy]', {
        param($match)
        $r = [Random]::new().Next(16)
        $v = if ($match.Value -eq "x") { $r } else { ($r -band 0x3) -bor 0x8 }
        return $v.ToString("x")
    }
    return $result
}

# Tạo ID mới với hàm cải tiến
$MAC_MACHINE_ID = New-StandardMachineId
$UUID = [System.Guid]::NewGuid().ToString()
# Chuyển đổi auth0|user_ thành chuỗi hex
$prefixBytes = [System.Text.Encoding]::UTF8.GetBytes("auth0|user_")
$prefixHex = -join ($prefixBytes | ForEach-Object { '{0:x2}' -f $_ })
# Tạo phần ngẫu nhiên cho machineId
$randomPart = Get-RandomHex -length 32
$MACHINE_ID = "$prefixHex$randomPart"
$SQM_ID = "{$([System.Guid]::NewGuid().ToString().ToUpper())}"

# Kiểm tra quyền quản trị viên trước khi cập nhật MachineGuid
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "$RED[Lỗi]$NC Vui lòng sử dụng quyền quản trị viên để chạy script này"
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

function Update-MachineGuid {
    try {
        # Kiểm tra và tạo registry nếu không tồn tại
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Cryptography"
        if (-not (Test-Path $registryPath)) {
            Write-Host "$YELLOW[Cảnh báo]$NC Đường dẫn registry không tồn tại: $registryPath, đang tạo..."
            New-Item -Path $registryPath -Force | Out-Null
            Write-Host "$GREEN[Thông tin]$NC Đã tạo đường dẫn registry"
        }

        # Lấy MachineGuid hiện tại nếu có
        $originalGuid = ""
        try {
            $currentGuid = Get-ItemProperty -Path $registryPath -Name MachineGuid -ErrorAction SilentlyContinue
            if ($currentGuid) {
                $originalGuid = $currentGuid.MachineGuid
                Write-Host "$GREEN[Thông tin]$NC Giá trị MachineGuid hiện tại:"
                Write-Host "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography" 
                Write-Host "    MachineGuid    REG_SZ    $originalGuid"
            } else {
                Write-Host "$YELLOW[Cảnh báo]$NC Không tìm thấy giá trị MachineGuid, sẽ tạo giá trị mới"
            }
        } catch {
            Write-Host "$YELLOW[Cảnh báo]$NC Lỗi khi lấy MachineGuid: $($_.Exception.Message)"
        }

        # Tạo thư mục sao lưu nếu chưa có
        if (-not (Test-Path $BACKUP_DIR)) {
            New-Item -ItemType Directory -Path $BACKUP_DIR -Force | Out-Null
        }

        # Tạo tệp sao lưu (nếu có giá trị ban đầu)
        if ($originalGuid) {
            $backupFile = "$BACKUP_DIR\MachineGuid_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
            $backupResult = Start-Process "reg.exe" -ArgumentList "export", "`"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography`"", "`"$backupFile`"" -NoNewWindow -Wait -PassThru
            
            if ($backupResult.ExitCode -eq 0) {
                Write-Host "$GREEN[Thông tin]$NC Đã sao lưu registry vào: $backupFile"
            } else {
                Write-Host "$YELLOW[Cảnh báo]$NC Sao lưu thất bại, tiếp tục thực hiện..."
            }
        }

        # Tạo GUID mới và cập nhật registry
        $newGuid = [System.Guid]::NewGuid().ToString()
        Set-ItemProperty -Path $registryPath -Name MachineGuid -Value $newGuid -Force -ErrorAction Stop
        
        # Kiểm tra giá trị đã cập nhật
        $verifyGuid = (Get-ItemProperty -Path $registryPath -Name MachineGuid -ErrorAction Stop).MachineGuid
        if ($verifyGuid -ne $newGuid) {
            throw "Lỗi xác nhận registry: Giá trị sau khi cập nhật ($verifyGuid) không khớp với giá trị mong đợi ($newGuid)"
        }

        Write-Host "$GREEN[Thông tin]$NC Đã cập nhật registry thành công:"
        Write-Host "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography"
        Write-Host "    MachineGuid    REG_SZ    $newGuid"
        return $true
    }
    catch {
        Write-Host "$RED[Lỗi]$NC Lỗi khi thao tác với registry: $($_.Exception.Message)"
        
        # Khôi phục từ sao lưu nếu có
        if (($backupFile -ne $null) -and (Test-Path $backupFile)) {
            Write-Host "$YELLOW[Khôi phục]$NC Đang khôi phục từ sao lưu..."
            $restoreResult = Start-Process "reg.exe" -ArgumentList "import", "`"$backupFile`"" -NoNewWindow -Wait -PassThru
            
            if ($restoreResult.ExitCode -eq 0) {
                Write-Host "$GREEN[Khôi phục thành công]$NC Đã khôi phục giá trị registry ban đầu"
            } else {
                Write-Host "$RED[Lỗi]$NC Khôi phục thất bại, vui lòng nhập tệp sao lưu thủ công: $backupFile"
            }
        } else {
            Write-Host "$YELLOW[Cảnh báo]$NC Không tìm thấy tệp sao lưu hoặc sao lưu thất bại, không thể khôi phục tự động"
        }
        return $false
    }
}

# Cập nhật hoặc tạo tệp cấu hình
Write-Host "$GREEN[Thông tin]$NC Đang cập nhật cấu hình..."

try {
    # Kiểm tra xem tệp cấu hình có tồn tại không
    if (-not (Test-Path $STORAGE_FILE)) {
        Write-Host "$RED[Lỗi]$NC Không tìm thấy tệp cấu hình: $STORAGE_FILE"
        Write-Host "$YELLOW[Lưu ý]$NC Vui lòng cài đặt và chạy Cursor ít nhất một lần trước khi sử dụng script này"
        Read-Host "Nhấn phím Enter để thoát"
        exit 1
    }

    # Đọc tệp cấu hình hiện tại
    try {
        $originalContent = Get-Content $STORAGE_FILE -Raw -Encoding UTF8
        
        # Chuyển đổi chuỗi JSON thành đối tượng PowerShell
        $config = $originalContent | ConvertFrom-Json 

        # Sao lưu các giá trị hiện tại
        $oldValues = @{
            'machineId' = $config.'telemetry.machineId'
            'macMachineId' = $config.'telemetry.macMachineId'
            'devDeviceId' = $config.'telemetry.devDeviceId'
            'sqmId' = $config.'telemetry.sqmId'
        }

        # Cập nhật các giá trị cần thiết
        $config.'telemetry.machineId' = $MACHINE_ID
        $config.'telemetry.macMachineId' = $MAC_MACHINE_ID
        $config.'telemetry.devDeviceId' = $UUID
        $config.'telemetry.sqmId' = $SQM_ID

        # Chuyển đối tượng đã cập nhật trở lại thành JSON và lưu lại
        $updatedJson = $config | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText(
            [System.IO.Path]::GetFullPath($STORAGE_FILE), 
            $updatedJson, 
            [System.Text.Encoding]::UTF8
        )
        Write-Host "$GREEN[Thông tin]$NC Cập nhật cấu hình thành công"
    } catch {
        # Nếu gặp lỗi, thử phục hồi lại nội dung ban đầu
        if ($originalContent) {
            [System.IO.File]::WriteAllText(
                [System.IO.Path]::GetFullPath($STORAGE_FILE), 
                $originalContent, 
                [System.Text.Encoding]::UTF8
            )
        }
        throw "Lỗi khi xử lý JSON: $_"
    }

    # Cập nhật MachineGuid ngay lập tức mà không cần yêu cầu
    Update-MachineGuid

    # Hiển thị kết quả
    Write-Host ""
    Write-Host "$GREEN[Thông tin]$NC Đã cập nhật cấu hình:"
    Write-Host "$BLUE[Debug]$NC machineId: $MACHINE_ID"
    Write-Host "$BLUE[Debug]$NC macMachineId: $MAC_MACHINE_ID"
    Write-Host "$BLUE[Debug]$NC devDeviceId: $UUID"
    Write-Host "$BLUE[Debug]$NC sqmId: $SQM_ID"

    # Hiển thị cấu trúc thư mục
    Write-Host ""
    Write-Host "$GREEN[Thông tin]$NC Cấu trúc thư mục:"
    Write-Host "$BLUE$env:APPDATA\Cursor\User$NC"
    Write-Host "├── globalStorage"
    Write-Host "│   ├── storage.json (Đã chỉnh sửa)"
    Write-Host "│   └── backups"

    # Liệt kê các tệp sao lưu
    $backupFiles = Get-ChildItem "$BACKUP_DIR\*" -ErrorAction SilentlyContinue
    if ($backupFiles) {
        foreach ($file in $backupFiles) {
            Write-Host "│       └── $($file.Name)"
        }
    } else {
        Write-Host "│       └── (Trống)"
    }

    # Hiển thị thông tin tài khoản WeChat
    Write-Host ""
    Write-Host "$GREEN================================$NC"
    Write-Host "$GREEN   Công cụ thay đổi ID thiết bị Cursor $NC"
    Write-Host "$YELLOW  Facebook: Luong Chi Dung $NC"
    Write-Host "$YELLOW  Zalo: 0847154088 $NC"
    Write-Host "$GREEN================================$NC"
    Write-Host ""
    Write-Host "$GREEN[Thông tin]$NC Vui lòng khởi động lại Cursor để áp dụng cấu hình mới"
    Write-Host ""
    
    # Hỏi người dùng có muốn vô hiệu hóa cập nhật tự động không
    Write-Host ""
    Write-Host "$YELLOW[Hỏi]$NC Bạn có muốn vô hiệu hóa tính năng cập nhật tự động của Cursor không?"
    Write-Host "0) Không - Giữ cài đặt mặc định (Nhấn Enter)"
    Write-Host "1) Có - Vô hiệu hóa cập nhật tự động"
    $choice = Read-Host "Nhập lựa chọn (0)"

    if ($choice -eq "1") {
        Write-Host ""
        Write-Host "$GREEN[Thông tin]$NC Đang xử lý vô hiệu hóa cập nhật tự động..."
        $updaterPath = "$env:LOCALAPPDATA\cursor-updater"

        # Hướng dẫn cài đặt thủ công
        function Show-ManualGuide {
            Write-Host ""
            Write-Host "$YELLOW[Cảnh báo]$NC Cài đặt tự động thất bại, vui lòng thử thao tác thủ công:"
            Write-Host "$YELLOWCác bước vô hiệu hóa cập nhật thủ công:$NC"
            Write-Host "1. Mở PowerShell với quyền quản trị"
            Write-Host "2. Sao chép và dán lệnh sau:"
            Write-Host "$BLUELệnh 1 - Xóa thư mục hiện tại (nếu có):$NC"
            Write-Host "Remove-Item -Path `"$updaterPath`" -Force -Recurse -ErrorAction SilentlyContinue"
            Write-Host ""
            Write-Host "$BLUELệnh 2 - Tạo tệp ngừng cập nhật:$NC"
            Write-Host "New-Item -Path `"$updaterPath`" -ItemType File -Force | Out-Null"
            Write-Host ""
            Write-Host "$BLUELệnh 3 - Thiết lập thuộc tính chỉ đọc:$NC"
            Write-Host "Set-ItemProperty -Path `"$updaterPath`" -Name IsReadOnly -Value `$true"
            Write-Host ""
            Write-Host "$BLUELệnh 4 - Thiết lập quyền truy cập (tuỳ chọn):$NC"
            Write-Host "icacls `"$updaterPath`" /inheritance:r /grant:r `"`$($env:USERNAME):(R)`""
            Write-Host ""
            Write-Host "$YELLOWKiểm tra:$NC"
            Write-Host "1. Chạy lệnh: Get-ItemProperty `"$updaterPath`""
            Write-Host "2. Kiểm tra thuộc tính IsReadOnly có giá trị là True"
            Write-Host "3. Chạy lệnh: icacls `"$updaterPath`""
            Write-Host "4. Kiểm tra chỉ có quyền đọc"
            Write-Host ""
            Write-Host "$YELLOW[Lưu ý]$NC Sau khi hoàn thành, vui lòng khởi động lại Cursor"
        }

        try {
            # Kiểm tra sự tồn tại của thư mục cursor-updater
            if (Test-Path $updaterPath) {
                # Nếu là tệp, nghĩa là đã tạo tệp ngừng cập nhật
                if ((Get-Item $updaterPath) -is [System.IO.FileInfo]) {
                    Write-Host "$GREEN[Thông tin]$NC Đã tạo tệp ngừng cập nhật, không cần tạo lại"
                    return
                }
                # Nếu là thư mục, cố gắng xóa
                else {
                    try {
                        Remove-Item -Path $updaterPath -Force -Recurse -ErrorAction Stop
                        Write-Host "$GREEN[Thông tin]$NC Đã xóa thư mục cursor-updater thành công"
                    }
                    catch {
                        Write-Host "$RED[Lỗi]$NC Không thể xóa thư mục cursor-updater"
                        Show-ManualGuide
                        return
                    }
                }
            }

            # Tạo tệp ngừng cập nhật
            try {
                New-Item -Path $updaterPath -ItemType File -Force -ErrorAction Stop | Out-Null
                Write-Host "$GREEN[Thông tin]$NC Đã tạo tệp ngừng cập nhật thành công"
            }
            catch {
                Write-Host "$RED[Lỗi]$NC Không thể tạo tệp ngừng cập nhật"
                Show-ManualGuide
                return
            }

            # Thiết lập quyền tệp
            try {
                # Thiết lập thuộc tính chỉ đọc
                Set-ItemProperty -Path $updaterPath -Name IsReadOnly -Value $true -ErrorAction Stop
                
                # Sử dụng icacls để thiết lập quyền
                $result = Start-Process "icacls.exe" -ArgumentList "`"$updaterPath`" /inheritance:r /grant:r `"$($env:USERNAME):(R)`"" -Wait -NoNewWindow -PassThru
                if ($result.ExitCode -ne 0) {
                    throw "Lệnh icacls thất bại"
                }
                
                Write-Host "$GREEN[Thông tin]$NC Đã thiết lập quyền tệp thành công"
            }
            catch {
                Write-Host "$RED[Lỗi]$NC Không thể thiết lập quyền tệp"
                Show-ManualGuide
                return
            }

            # Kiểm tra cài đặt
            try {
                $fileInfo = Get-ItemProperty $updaterPath
                if (-not $fileInfo.IsReadOnly) {
                    Write-Host "$RED[Lỗi]$NC Kiểm tra thất bại: Thiết lập quyền tệp có thể không hiệu quả"
                    Show-ManualGuide
                    return
                }
            }
            catch {
                Write-Host "$RED[Lỗi]$NC Kiểm tra cài đặt thất bại"
                Show-ManualGuide
                return
            }

            Write-Host "$GREEN[Thông tin]$NC Đã vô hiệu hóa cập nhật tự động thành công"
        }
        catch {
            Write-Host "$RED[Lỗi]$NC Xảy ra lỗi không xác định: $_"
            Show-ManualGuide
        }
    }
    else {
        Write-Host "$GREEN[Thông tin]$NC Giữ nguyên cài đặt mặc định, không thay đổi gì"
    }

    # Giữ lại cập nhật registry hợp lệ
    Update-MachineGuid

} catch {
    Write-Host "$RED[Lỗi]$NC Lỗi chính khi thực hiện: $_"
    Write-Host "$YELLOW[Thử lại]$NC Sử dụng phương pháp thay thế..."
    
    try {
        # Phương pháp thay thế: sử dụng Add-Content
        $tempFile = [System.IO.Path]::GetTempFileName()
        $config | ConvertTo-Json | Set-Content -Path $tempFile -Encoding UTF8
        Copy-Item -Path $tempFile -Destination $STORAGE_FILE -Force
        Remove-Item -Path $tempFile
        Write-Host "$GREEN[Thông tin]$NC Đã ghi cấu hình thành công bằng phương pháp thay thế"
    } catch {
        Write-Host "$RED[Lỗi]$NC Tất cả các phương pháp đều thất bại"
        Write-Host "Chi tiết lỗi: $_"
        Write-Host "Tệp đích: $STORAGE_FILE"
        Write-Host "Vui lòng đảm bảo bạn có quyền truy cập đủ để sử dụng tệp này"
        Read-Host "Nhấn phím Enter để thoát"
        exit 1
    }
}

Write-Host ""
Read-Host "Nhấn phím Enter để thoát"
exit 0

# Chỉnh sửa khi ghi tệp
function Write-ConfigFile {
    param($config, $filePath)
    
    try {
        # Sử dụng mã hóa UTF8 không BOM
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        $jsonContent = $config | ConvertTo-Json -Depth 10
        
        # Sử dụng ký tự xuống dòng LF
        $jsonContent = $jsonContent.Replace("`r`n", "`n")
        
        [System.IO.File]::WriteAllText(
            [System.IO.Path]::GetFullPath($filePath),
            $jsonContent,
            $utf8NoBom
        )
        
        Write-Host "$GREEN[Thông tin]$NC Đã ghi tệp cấu hình thành công (UTF8 không BOM)"
    }
    catch {
        throw "Lỗi khi ghi tệp cấu hình: $_"
    }
}

# Lấy và hiển thị thông tin phiên bản
$cursorVersion = Get-CursorVersion
Write-Host ""
if ($cursorVersion) {
    Write-Host "$GREEN[Thông tin]$NC Đã phát hiện phiên bản Cursor: $cursorVersion, tiếp tục thực hiện..."
} else {
    Write-Host "$YELLOW[Cảnh báo]$NC Không thể phát hiện phiên bản, tiếp tục thực hiện..."
}
