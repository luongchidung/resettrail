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
