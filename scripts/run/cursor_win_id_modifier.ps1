# Thiết lập mã hóa đầu ra là UTF-8
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Định nghĩa màu sắc
$RED = "`e[31m"
$GREEN = "`e[32m"
$YELLOW = "`e[33m"
$BLUE = "`e[34m"
$NC = "`e[0m"

# Đường dẫn tệp cấu hình
$STORAGE_FILE = "$env:APPDATA\Cursor\User\globalStorage\storage.json"
$BACKUP_DIR = "$env:APPDATA\Cursor\User\globalStorage\backups"

# Kiểm tra quyền quản trị
function Test-Administrator {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($user)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Host "$RED[Error]$NC Vui lòng chạy script này với quyền quản trị"
    Write-Host "Hãy nhấp chuột phải vào script và chọn 'Run as Administrator'"
    Read-Host "Nhấn Enter để thoát"
    exit 1
}

# Hiển thị logo
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
Write-Host "$GREEN   Công cụ thay đổi ID thiết bị Cursor     $NC"
Write-Host "$YELLOW  Theo dõi tài khoản công cộng【煎饼果子卷AI】 $NC"
Write-Host "$YELLOW  Cùng trao đổi thêm về mẹo Cursor và kiến thức AI (script miễn phí, theo dõi tài khoản công cộng và tham gia nhóm sẽ có thêm mẹo và các chuyên gia) $NC"
Write-Host "$YELLOW  [Lưu ý quan trọng] Công cụ này miễn phí, nếu hữu ích, vui lòng theo dõi tài khoản công cộng【煎饼果子卷AI】  $NC"
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
        Write-Host "$YELLOW[Lưu ý]$NC Hãy chắc chắn rằng Cursor đã được cài đặt đúng cách"
        return $null
    }
    catch {
        Write-Host "$RED[Lỗi]$NC Không thể lấy phiên bản Cursor: $_"
        return $null
    }
}

# Lấy và hiển thị thông tin phiên bản
$cursorVersion = Get-CursorVersion
Write-Host ""

Write-Host "$YELLOW[Lưu ý quan trọng]$NC Phiên bản mới nhất 0.47.x (hỗ trợ)"
Write-Host ""

# Kiểm tra và đóng tiến trình Cursor
Write-Host "$GREEN[Thông tin]$NC Đang kiểm tra tiến trình Cursor..."

function Get-ProcessDetails {
    param($processName)
    Write-Host "$BLUE[Debug]$NC Đang lấy chi tiết tiến trình $processName:"
    Get-WmiObject Win32_Process -Filter "name='$processName'" | 
        Select-Object ProcessId, ExecutablePath, CommandLine | 
        Format-List
}

# Định nghĩa số lần thử tối đa và thời gian chờ
$MAX_RETRIES = 5
$WAIT_TIME = 1

# Đóng tiến trình
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
                Read-Host "Nhấn Enter để thoát"
                exit 1
            }
            Write-Host "$YELLOW[Cảnh báo]$NC Đang chờ tiến trình đóng, thử lần $retryCount/$MAX_RETRIES..."
            Start-Sleep -Seconds $WAIT_TIME
        }
        Write-Host "$GREEN[Thông tin]$NC $processName đã đóng thành công"
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

# Thêm hàm tạo ID ngẫu nhiên sau phần định nghĩa màu sắc
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

# Cải thiện hàm tạo ID
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

# Sử dụng hàm mới để tạo ID
$MAC_MACHINE_ID = New-StandardMachineId
$UUID = [System.Guid]::NewGuid().ToString()
# Chuyển auth0|user_ thành mảng byte hex
$prefixBytes = [System.Text.Encoding]::UTF8.GetBytes("auth0|user_")
$prefixHex = -join ($prefixBytes | ForEach-Object { '{0:x2}' -f $_ })
# Tạo một số ngẫu nhiên dài 32 byte (64 ký tự hex) làm phần ngẫu nhiên của machineId
$randomPart = Get-RandomHex -length 32
$MACHINE_ID = "$prefixHex$randomPart"
$SQM_ID = "{$([System.Guid]::NewGuid().ToString().ToUpper())}"

# Kiểm tra quyền quản trị trước khi gọi hàm Update-MachineGuid
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "$RED[Lỗi]$NC Vui lòng chạy script với quyền quản trị"
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

function Update-MachineGuid {
    try {
        # Kiểm tra xem đường dẫn trong đăng ký có tồn tại không, nếu không thì tạo mới
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Cryptography"
        if (-not (Test-Path $registryPath)) {
            Write-Host "$YELLOW[Cảnh báo]$NC Đường dẫn đăng ký không tồn tại: $registryPath, đang tạo mới..."
            New-Item -Path $registryPath -Force | Out-Null
            Write-Host "$GREEN[Thông tin]$NC Đã tạo đường dẫn đăng ký thành công"
        }

        # Lấy giá trị MachineGuid hiện tại, nếu không có thì sử dụng chuỗi rỗng làm giá trị mặc định
        $originalGuid = ""
        try {
            $currentGuid = Get-ItemProperty -Path $registryPath -Name MachineGuid -ErrorAction SilentlyContinue
            if ($currentGuid) {
                $originalGuid = $currentGuid.MachineGuid
                Write-Host "$GREEN[Thông tin]$NC Giá trị đăng ký hiện tại:"
                Write-Host "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography" 
                Write-Host "    MachineGuid    REG_SZ    $originalGuid"
            } else {
                Write-Host "$YELLOW[Cảnh báo]$NC Giá trị MachineGuid không tồn tại, sẽ tạo giá trị mới"
            }
        } catch {
            Write-Host "$YELLOW[Cảnh báo]$NC Lấy giá trị MachineGuid thất bại: $($_.Exception.Message)"
        }

        # Tạo thư mục sao lưu (nếu chưa tồn tại)
        if (-not (Test-Path $BACKUP_DIR)) {
            New-Item -ItemType Directory -Path $BACKUP_DIR -Force | Out-Null
        }

        # Tạo tệp sao lưu (chỉ khi giá trị gốc tồn tại)
        if ($originalGuid) {
            $backupFile = "$BACKUP_DIR\MachineGuid_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
            $backupResult = Start-Process "reg.exe" -ArgumentList "export", "`"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography`"", "`"$backupFile`"" -NoNewWindow -Wait -PassThru
            
            if ($backupResult.ExitCode -eq 0) {
                Write-Host "$GREEN[Thông tin]$NC Đã sao lưu mục đăng ký vào: $backupFile"
            } else {
                Write-Host "$YELLOW[Cảnh báo]$NC Sao lưu không thành công, tiếp tục thực hiện..."
            }
        }

        # Tạo GUID mới
        $newGuid = [System.Guid]::NewGuid().ToString()

        # Cập nhật hoặc tạo giá trị trong đăng ký
        Set-ItemProperty -Path $registryPath -Name MachineGuid -Value $newGuid -Force -ErrorAction Stop
        
        # Kiểm tra lại sau khi cập nhật
        $verifyGuid = (Get-ItemProperty -Path $registryPath -Name MachineGuid -ErrorAction Stop).MachineGuid
        if ($verifyGuid -ne $newGuid) {
            throw "Kiểm tra đăng ký thất bại: Giá trị đã cập nhật ($verifyGuid) không khớp với giá trị mong đợi ($newGuid)"
        }

        Write-Host "$GREEN[Thông tin]$NC Đã cập nhật thành công đăng ký:"
        Write-Host "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography"
        Write-Host "    MachineGuid    REG_SZ    $newGuid"
        return $true
    }
    catch {
        Write-Host "$RED[Lỗi]$NC Thao tác với đăng ký thất bại: $($_.Exception.Message)"
        
        # Cố gắng phục hồi từ sao lưu (nếu có)
        if (($backupFile -ne $null) -and (Test-Path $backupFile)) {
            Write-Host "$YELLOW[Khôi phục]$NC Đang khôi phục từ sao lưu..."
            $restoreResult = Start-Process "reg.exe" -ArgumentList "import", "`"$backupFile`"" -NoNewWindow -Wait -PassThru
            
            if ($restoreResult.ExitCode -eq 0) {
                Write-Host "$GREEN[Khôi phục thành công]$NC Đã phục hồi giá trị gốc từ đăng ký"
            } else {
                Write-Host "$RED[Lỗi]$NC Phục hồi thất bại, vui lòng nhập thủ công tệp sao lưu: $backupFile"
            }
        } else {
            Write-Host "$YELLOW[Cảnh báo]$NC Không tìm thấy tệp sao lưu hoặc sao lưu không thành công, không thể tự động phục hồi"
        }
        return $false
    }
}

# Tạo hoặc cập nhật tệp cấu hình
Write-Host "$GREEN[Thông tin]$NC Đang cập nhật tệp cấu hình..."

try {
    # Kiểm tra xem tệp cấu hình có tồn tại không
    if (-not (Test-Path $STORAGE_FILE)) {
        Write-Host "$RED[Lỗi]$NC Không tìm thấy tệp cấu hình: $STORAGE_FILE"
        Write-Host "$YELLOW[Thông báo]$NC Vui lòng cài đặt và chạy Cursor một lần trước khi sử dụng script này"
        Read-Host "Nhấn Enter để thoát"
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

        # Cập nhật các giá trị cụ thể
        $config.'telemetry.machineId' = $MACHINE_ID
        $config.'telemetry.macMachineId' = $MAC_MACHINE_ID
        $config.'telemetry.devDeviceId' = $UUID
        $config.'telemetry.sqmId' = $SQM_ID

        # Chuyển đổi đối tượng đã cập nhật trở lại JSON và lưu vào tệp
        $updatedJson = $config | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText(
            [System.IO.Path]::GetFullPath($STORAGE_FILE), 
            $updatedJson, 
            [System.Text.Encoding]::UTF8
        )
        Write-Host "$GREEN[Thông tin]$NC Đã cập nhật tệp cấu hình thành công"

   } catch {
    # Nếu có lỗi, thử khôi phục nội dung gốc
    if ($originalContent) {
        [System.IO.File]::WriteAllText(
            [System.IO.Path]::GetFullPath($STORAGE_FILE), 
            $originalContent, 
            [System.Text.Encoding]::UTF8
        )
    }
    throw "Xử lý JSON thất bại: $_"
}

# Thực hiện trực tiếp việc cập nhật MachineGuid, không hỏi lại
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
Write-Host "│   ├── storage.json (Đã sửa đổi)"
Write-Host "│   └── backups"

# Liệt kê các tệp sao lưu
$backupFiles = Get-ChildItem "$BACKUP_DIR\*" -ErrorAction SilentlyContinue
if ($backupFiles) {
    foreach ($file in $backupFiles) {
        Write-Host "│       └── $($file.Name)"
    }
} else {
    Write-Host "│       └── (Rỗng)"
}

# Hiển thị thông tin về tài khoản công khai
Write-Host ""
Write-Host "$GREEN================================$NC"
Write-Host "$YELLOW Theo dõi tài khoản công khai 【煎饼果子卷AI】 để trao đổi thêm về kỹ thuật Cursor và kiến thức AI (kịch bản miễn phí, theo dõi tài khoản công khai để tham gia nhóm và nhận thêm mẹo và chuyên gia)  $NC"
Write-Host "$GREEN================================$NC"
Write-Host ""
Write-Host "$GREEN[Thông tin]$NC Vui lòng khởi động lại Cursor để áp dụng cấu hình mới"
Write-Host ""

# Hỏi người dùng có muốn vô hiệu hóa cập nhật tự động hay không
Write-Host ""
Write-Host "$YELLOW[Hỏi]$NC Bạn có muốn vô hiệu hóa chức năng cập nhật tự động của Cursor không?"
Write-Host "0) Không - Giữ cài đặt mặc định (Nhấn Enter)"
Write-Host "1) Có - Vô hiệu hóa cập nhật tự động"
$choice = Read-Host "Nhập lựa chọn (0)"

if ($choice -eq "1") {
    Write-Host ""
    Write-Host "$GREEN[Thông tin]$NC Đang xử lý cập nhật tự động..."
    $updaterPath = "$env:LOCALAPPDATA\cursor-updater"

    # Định nghĩa hướng dẫn thiết lập thủ công
    function Show-ManualGuide {
        Write-Host ""
        Write-Host "$YELLOW[Cảnh báo]$NC Thiết lập tự động thất bại, vui lòng thử thao tác thủ công:"
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
        Write-Host "$BLUELệnh 4 - Thiết lập quyền (tùy chọn):$NC"
        Write-Host "icacls `"$updaterPath`" /inheritance:r /grant:r `"`$($env:USERNAME):(R)`""
        Write-Host ""
        Write-Host "$YELLOWPhương pháp kiểm tra:$NC"
        Write-Host "1. Chạy lệnh: Get-ItemProperty `"$updaterPath`""
        Write-Host "2. Xác nhận thuộc tính IsReadOnly là True"
        Write-Host "3. Chạy lệnh: icacls `"$updaterPath`""
        Write-Host "4. Xác nhận chỉ có quyền đọc"
        Write-Host ""
        Write-Host "$YELLOW[Mẹo]$NC Sau khi hoàn thành, vui lòng khởi động lại Cursor"
    }

    try {
        # Kiểm tra xem cursor-updater có tồn tại không
        if (Test-Path $updaterPath) {
            # Nếu là tệp, có nghĩa là đã tạo tệp ngừng cập nhật
            if ((Get-Item $updaterPath) -is [System.IO.FileInfo]) {
                Write-Host "$GREEN[Thông tin]$NC Đã tạo tệp ngừng cập nhật, không cần tạo lại"
                return
            }
            # Nếu là thư mục, thử xóa
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

        # Thiết lập quyền cho tệp
        try {
            # Thiết lập thuộc tính chỉ đọc
            Set-ItemProperty -Path $updaterPath -Name IsReadOnly -Value $true -ErrorAction Stop
            
            # Dùng icacls để thiết lập quyền
            $result = Start-Process "icacls.exe" -ArgumentList "`"$updaterPath`" /inheritance:r /grant:r `"$($env:USERNAME):(R)`"" -Wait -NoNewWindow -PassThru
            if ($result.ExitCode -ne 0) {
                throw "Lệnh icacls thất bại"
            }
            
            Write-Host "$GREEN[Thông tin]$NC Đã thiết lập quyền cho tệp thành công"
        }
        catch {
            Write-Host "$RED[Lỗi]$NC Không thể thiết lập quyền cho tệp"
            Show-ManualGuide
            return
        }

        # Kiểm tra cài đặt
        try {
            $fileInfo = Get-ItemProperty $updaterPath
            if (-not $fileInfo.IsReadOnly) {
                Write-Host "$RED[Lỗi]$NC Kiểm tra thất bại: thuộc tính quyền tệp có thể không được thiết lập"
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
    Write-Host "$GREEN[Thông tin]$NC Giữ cài đặt mặc định, không thay đổi gì"
}

# Giữ lại các thay đổi trong đăng ký
Update-MachineGuid
} catch {
    Write-Host "$RED[Lỗi]$NC Thao tác chính thất bại: $_"
    Write-Host "$YELLOW[Thử]$NC Sử dụng phương pháp thay thế..."

    try {
        # Phương pháp thay thế: sử dụng Add-Content
        $tempFile = [System.IO.Path]::GetTempFileName()
        $config | ConvertTo-Json | Set-Content -Path $tempFile -Encoding UTF8
        Copy-Item -Path $tempFile -Destination $STORAGE_FILE -Force
        Remove-Item -Path $tempFile
        Write-Host "$GREEN[Thông tin]$NC Đã ghi cấu hình thành công bằng phương pháp thay thế"
    } catch {
        Write-Host "$RED[Lỗi]$NC Tất cả các thử nghiệm đều thất bại"
        Write-Host "Chi tiết lỗi: $_"
        Write-Host "Tệp đích: $STORAGE_FILE"
        Write-Host "Vui lòng đảm bảo bạn có đủ quyền truy cập tệp"
        Read-Host "Nhấn Enter để thoát"
        exit 1
    }
}

Write-Host ""
Read-Host "Nhấn Enter để thoát"
exit 0

# Cập nhật phần ghi tệp
function Write-ConfigFile {
    param($config, $filePath)
    
    try {
        # Sử dụng mã hóa UTF8 không BOM
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        $jsonContent = $config | ConvertTo-Json -Depth 10
        
        # Thay thế ký tự xuống dòng bằng LF
        $jsonContent = $jsonContent.Replace("`r`n", "`n")
        
        [System.IO.File]::WriteAllText(
            [System.IO.Path]::GetFullPath($filePath),
            $jsonContent,
            $utf8NoBom
        )
        
        Write-Host "$GREEN[Thông tin]$NC Đã ghi tệp cấu hình thành công (UTF8 không BOM)"
    }
    catch {
        throw "Ghi tệp cấu hình thất bại: $_"
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
