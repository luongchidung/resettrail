# 设置输出编码为 UTF-8
$OutputEncoding = [Hệ thống.Văn bản.Mã hóa]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Màu sắc
$RED = "`e[31m"
$GREEN = "`e[32m"
$YELLOW = "`e[33m"
$BLUE = "`e[34m"
$NC = "`e[0m"

# 配置文件路径
$STORAGE_FILE = "$env:APPDATA\Cursor\User\globalStorage\storage.json"
$BACKUP_DIR = "$env:APPDATA\Cursor\User\globalStorage\backups"

# 检查管理员权限
chức năng Test-Administrator {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = Đối tượng mới Security.Principal.WindowsPrincipal($user)
    trả về $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

nếu (-không (Test-Administrator)) {
    Máy chủ ghi "$RED[错误]$NC 请以管理员身份运行此脚本"
    Máy chủ ghi "请右键点击脚本，选择'以管理员身份运行'"
    Máy chủ đọc "按回车键退出"
    lối ra 1
}

# Logo của 显示
Xóa Host
Viết-Máy chủ @"

    ██████╗██╗ ██╗██████╗ ███████╗ ██████╗ ██████╗
   ██╔════╝██║ ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗
   ██║ ██║ ██║██████╔╝███████╗██║ ██║██████╔╝
   ██║ ██║ ██║██╔══██╗╚════██║██║ ██║██╔══██╗
   ╚██████╗╚██████╔╝██║ ██║███████║╚██████╔╝██║ ██║
    ╚═════╝ ╚═════╝ ╚═╝ ╚═╝╚══════╝ ╚═════╝ ╚═╝ ╚═╝

"@
Viết-Máy chủ "$BLUE================================$NC"
Write-Host "$GREEN Cursor 设备ID 修改工具 $NC"
Máy chủ ghi "$YELLOW 关注公众号(煎饼果子卷AI】 $NC"
Máy chủ ghi "$YELLOW 一起交流更多Cursor技巧和AI知识(脚本免费、关注公众号加群有更多技巧和大佬) $NC"
Write-Host "$YELLOW [重要提示] 本工具免费，如果对您有帮助，请关注公众号(煎饼果子卷AI】 $NC"
Viết-Máy chủ "$BLUE================================$NC"
Viết-Máy chủ ""

# 获取并显示 Con trỏ 版本
chức năng Get-CursorVersion {
    thử {
        # 主要检测路径
        $packagePath = "$env:LOCALAPPDATA\Programs\cursor\resources\app\package.json"
        
        nếu (Đường dẫn thử nghiệm $packagePath) {
            $packageJson = Lấy-Nội-dung $packagePath -Raw | Chuyển-đổi-Từ-Json
            nếu ($packageJson.version) {
                Máy chủ ghi "$GREEN[信息]$NC 当前安装的 Cursor 版本: v$($packageJson.version)"
                trả về $packageJson.version
            }
        }

        # 备用路径检测
        $altPath = "$env:LOCALAPPDATA\cursor\resources\app\package.json"
        nếu (Đường dẫn thử nghiệm $altPath) {
            $packageJson = Lấy-Nội-dung $altPath -Raw | Chuyển-đổi-Từ-Json
            nếu ($packageJson.version) {
                Máy chủ ghi "$GREEN[信息]$NC 当前安装的 Cursor 版本: v$($packageJson.version)"
                trả về $packageJson.version
            }
        }

        Máy chủ ghi "$YELLOW[警告]$NC 无法检测到 Cursor 版本"
        Máy chủ ghi "$YELLOW[提示]$NC 请确保 Con trỏ 已正确安装"
        trả về $null
    }
    nắm lấy {
        Máy chủ ghi "$RED[错误]$NC 获取 Con trỏ 版本失败: $_"
        trả về $null
    }
}

# 获取并显示版本信息
$cursorVersion = Lấy-CursorVersion
Viết-Máy chủ ""

Máy chủ ghi "$YELLOW[重要提示]$NC 最新的 0.47.x (以支持)"
Viết-Máy chủ ""

# 检查并关闭 Con trỏ 进程
Máy chủ ghi "$GREEN[信息]$NC 检查 Con trỏ 进程..."

hàm Get-ProcessDetails {
    tham số($processName)
    Máy chủ ghi "$BLUE[调试]$NC 正在获取 $processName 进程详细信息:"
    Get-WmiObject Win32_Process -Bộ lọc "tên='$processName'" |
        Chọn-Đối tượng ProcessId, ExecutablePath, CommandLine |
        Định dạng-Danh sách
}

# 定义最大重试次数和等待时间
$MAX_RETRIES = 5
$WAIT_TIME = 1

# 处理进程关闭
hàm Close-CursorProcess {
    tham số($processName)
    
    $process = Get-Process -Name $processName -ErrorAction Tiếp tục im lặng
    nếu ($process) {
        Máy chủ ghi "$YELLOW[警告]$NC 发现 $processName 正在运行"
        Lấy-ProcessDetails $processName
        
        Máy chủ ghi "$YELLOW[警告]$NC 尝试关闭 $processName..."
        Dừng-Quy trình -Tên $processName -Buộc
        
        $retryCount = 0
        trong khi ($retryCount -lt $MAX_RETRIES) {
            $process = Get-Process -Name $processName -ErrorAction Tiếp tục im lặng
            nếu (-không phải $process) { ngắt}
            
            $retryCount++
            nếu ($retryCount -ge $MAX_RETRIES) {
                Máy chủ ghi "$RED[错误]$NC 在 $MAX_RETRIES 次尝试后仍无法关闭 $processName"
                Lấy-ProcessDetails $processName
                Máy chủ ghi "$RED[错误]$NC 请手动关闭进程后重试"
                Máy chủ đọc "按回车键退出"
                lối ra 1
            }
            Máy chủ ghi "$YELLOW[警告]$NC 等待进程关闭，尝试 $retryCount/$MAX_RETRIES..."
            Bắt đầu-Ngủ-Giây $WAIT_TIME
        }
        Máy chủ ghi "$GREEN[信息]$NC $processName 已成功关闭"
    }
}

# 关闭所有 Cursor 进程
Đóng-Con trỏProcess "Con trỏ"
Close-CursorProcess "con trỏ"

# 创建备份目录
nếu (-không (Đường dẫn thử nghiệm $BACKUP_DIR)) {
    Mục mới -ItemType Thư mục -Đường dẫn $BACKUP_DIR | Out-Null
}

# 备份现有配置
nếu (Đường dẫn thử nghiệm $STORAGE_FILE) {
    Máy chủ ghi "$GREEN[信息]$NC 正在备份配置文件..."
    $backupName = "storage.json.backup_$(Lấy-Ngày -Định dạng 'yyyyMMdd_HHmmss')"
    Sao chép mục $STORAGE_FILE "$BACKUP_DIR\$backupName"
}

# ID của bạn mới
Máy chủ ghi "$GREEN[信息]$NC 正在生成新的 ID..."

# 在颜色定义后添加此函数
hàm Get-RandomHex {
    tham số (
        [int]$chiều dài
    )
    
    $bytes = Đối tượng mới byte[] ($length)
    $rng = [Hệ thống.Bảo mật.Mật mã.RNGCryptoServiceProvider]::new()
    $rng.GetBytes($byte)
    $hexString = [System.BitConverter]::ToString($bytes) -thay thế '-',''
    $rng.Vứt bỏ()
    trả về $hexString
}

# 改进 ID 生成函数
chức năng New-StandardMachineId {
    $template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    $result = $template -thay thế '[xy]', {
        tham số($match)
        $r = [Ngẫu nhiên]::new().Next(16)
        $v = nếu ($match.Value -eq "x") { $r } nếu không { ($r -band 0x3) -bor 0x8 }
        trả về $v.ToString("x")
    }
    trả về $result
}

# 在生成 ID 时使用新函数
$MAC_MACHINE_ID = Mã máy chuẩn mới
$UUID = [System.Guid]::NewGuid().ToString()
# 将 auth0|user_ 转换为字节数组的十六进制
$prefixBytes = [System.Text.Encoding]::UTF8.GetBytes("auth0|user_")
$prefixHex = -join ($prefixBytes | Đối với mỗi đối tượng { '{0:x2}' -f $_ })
# 生成32字节(64个十六进制字符)的随机数作为 machineId 的随机部分
$randomPart = Get-RandomHex - chiều dài 32
$MACHINE_ID = "$prefixHex$randomPart"
$SQM_ID = "{$([System.Guid]::NewGuid().ToString().ToUpper())}"

# 在Update-MachineGuid函数前添加权限检查
nếu (-KHÔNG ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Quản trị viên")) {
    Máy chủ ghi "$RED[错误]$NC 请使用管理员权限运行此脚本"
    Bắt đầu-Quy trình powershell "-NoProfile -ExecutionPolicy Bỏ qua -File `"$PSCommandPath`"" -Verb RunAs
    ra
}

chức năng Update-MachineGuid {
    thử {
        # 检查注册表路径是否存在,不存在则创建
        $registryPath = "HKLM:\PHẦN MỀM\Microsoft\Mật mã"
        nếu (-không (Đường dẫn thử nghiệm $registryPath)) {
            Máy chủ ghi "$YELLOW[警告]$NC 注册表路径不存在: $registryPath,正在创建..."
            Mục mới -Đường dẫn $registryPath -Force | Out-Null
            Máy chủ ghi "$GREEN[信息]$NC 注册表路径创建成功"
        }

        # 获取当前的 MachineGuid,如果不存在则使用空字符串作为默认值
        $originalGuid = ""
        thử {
            $currentGuid = Get-ItemProperty -Path $registryPath -Name MachineGuid -ErrorAction Tiếp tục im lặng
            nếu ($currentGuid) {
                $originalGuid = $currentGuid.MachineGuid
                Máy chủ ghi "$GREEN[信息]$NC 当前注册表值:"
                Ghi-Máy chủ "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography"
                Ghi-Máy chủ " MachineGuid REG_SZ $originalGuid"
            } khác {
                Máy chủ ghi "$YELLOW[警告]$NC MachineGuid 值不存在，将创建新值"
            }
        } nắm lấy {
            Máy chủ ghi "$YELLOW[警告]$NC 获取 MachineGuid 失败: $($_.Exception.Message)"
        }

        # 创建备份目录（如果不存在）
        nếu (-không (Đường dẫn thử nghiệm $BACKUP_DIR)) {
            Mục mới -ItemType Thư mục -Đường dẫn $BACKUP_DIR -Buộc | Out-Null
        }

        # 创建备份文件（仅当原始值存在时）
        nếu ($originalGuid) {
            $backupFile = "$BACKUP_DIR\MachineGuid_$(Lấy-Ngày -Định dạng 'yyyyMMdd_HHmmss').reg"
            $backupResult = Bắt đầu-Quy trình "reg.exe" -ArgumentList "xuất", "`"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography`"", "`"$backupFile`"" -NoNewWindow -Wait -PassThru
            
            nếu ($backupResult.ExitCode -eq 0) {
                Máy chủ ghi "$GREEN[信息]$NC 注册表项已备份到:$backupFile"
            } khác {
                Máy chủ ghi "$YELLOW[警告]$NC 备份创建失败，继续执行..."
            }
        }

        # Hướng dẫn mới nhất
        $newGuid = [System.Guid]::NewGuid().ToString()

        # Thêm nhiều thông tin về dịch vụ khách hàng
        Set-ItemProperty -Path $registryPath -Name MachineGuid -Value $newGuid -Force -ErrorAction Dừng
        
        # Xem thêm tin tức
        $verifyGuid = (Get-ItemProperty -Path $registryPath -Name MachineGuid -Dừng hành động lỗi).MachineGuid
        nếu ($verifyGuid -ne $newGuid) {
            ném "注册表验证失败：更新后的值 ($verifyGuid) 与预期值 ($newGuid) 不匹配"
        }

        Máy chủ ghi "$GREEN[信息]$NC 注册表更新成功:"
        Ghi-Máy chủ "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography"
        Ghi-Máy chủ " MachineGuid REG_SZ $newGuid"
        trả về $true
    }
    nắm lấy {
        Máy chủ ghi "$RED[错误]$NC 注册表操作失败:$($_.Exception.Message)"
        
        # 尝试恢复备份（如果存在）
        nếu (($backupFile -ne $null) -và (Test-Path $backupFile)) {
            Máy chủ ghi "$YELLOW[恢复]$NC 正在从备份恢复..."
            $restoreResult = Bắt đầu-Quy trình "reg.exe" -ArgumentList "nhập", "`"$backupFile`"" -NoNewWindow -Chờ -PassThru
            
            nếu ($restoreResult.ExitCode -eq 0) {
                Máy chủ ghi "$GREEN[恢复成功]$NC 已还原原始注册表值"
            } khác {
                Máy chủ ghi "$RED[错误]$NC 恢复失败，请手动导入备份文件:$backupFile"
            }
        } khác {
            Máy chủ ghi "$YELLOW[警告]$NC 未找到备份文件或备份创建失败，无法自动恢复"
        }
        trả về $false
    }
}

# Thêm nhiều nội dung mới hơn
Máy chủ ghi "$GREEN[信息]$NC 正在更新配置..."

thử {
    # 检查配置文件是否存在
    nếu (-không (Đường dẫn thử nghiệm $STORAGE_FILE)) {
        Máy chủ ghi "$RED[错误]$NC 未找到配置文件: $STORAGE_FILE"
        Máy chủ ghi "$YELLOW[提示]$NC 请先安装并运行一次 Con trỏ 后再使用此脚本"
        Máy chủ đọc "按回车键退出"
        lối ra 1
    }

    # 读取现有配置文件
    thử {
        $originalContent = Get-Content $STORAGE_FILE -Raw -Mã hóa UTF8
        
        # 将 JSON có thể sử dụng PowerShell
        $config = $originalContent | Chuyển đổi từ-Json

        # 备份当前值
        $oldValues ​​= @{
            'machineId' = $config.'telemetry.machineId'
            'macMachineId' = $config.'telemetry.macMachineId'
            'devDeviceId' = $config.'telemetry.devDeviceId'
            'sqmId' = $config.'telemetry.sqmId'
        }

        # Thêm thông tin về nhà mới
        $config.'telemetry.machineId' = $MACHINE_ID
        $config.'telemetry.macMachineId' = $MAC_MACHINE_ID
        $config.'telemetry.devDeviceId' = $UUID
        $config.'telemetry.sqmId' = $SQM_ID

        # 将更新后的对象转换回 JSON 并保存
        $updatedJson = $config | ConvertTo-Json - Độ sâu 10
        [System.IO.File]::WriteAllText(
            [System.IO.Path]::GetFullPath($STORAGE_FILE),
            $updatedJson,
            [Hệ thống.Mã hóa văn bản]::UTF8
        )
        Máy chủ ghi "$GREEN[信息]$NC 成功更新配置文件"
    } nắm lấy {
        # 如果出错,尝试恢复原始内容
        nếu ($originalContent) {
            [System.IO.File]::WriteAllText(
                [System.IO.Path]::GetFullPath($STORAGE_FILE),
                $originalNội dung,
                [Hệ thống.Văn bản.Mã hóa]::UTF8
            )
        }
        ném "处理 JSON 失败: $_"
    }
    # 直接执行更新 MachineGuid,不再询问
    Cập nhật-MachineGuid
    # 显示结果
    Viết-Máy chủ ""
    Máy chủ ghi "$GREEN[信息]$NC 已更新配置:"
    Máy chủ ghi "$BLUE[调试]$NC machineId: $MACHINE_ID"
    Máy chủ ghi "$BLUE[调试]$NC macMachineId: $MAC_MACHINE_ID"
    Máy chủ ghi "$BLUE[调试]$NC devDeviceId: $UUID"
    Write-Host "$BLUE[Trả lời]$NC sqmId: $SQM_ID"

    # 显示文件树结构
    Viết-Máy chủ ""
    Máy chủ ghi "$GREEN[信息]$NC 文件结构:"
    Ghi-Máy chủ "$BLUE$env:APPDATA\Cursor\User$NC"
    Ghi-Máy chủ "├── globalStorage"
    Máy chủ ghi "│ ├── storage.json (已修改)"
    Write-Host "│ └── sao lưu"

    # 列出备份文件
    $backupFiles = Get-ChildItem "$BACKUP_DIR\*" -ErrorAction Tiếp tục im lặng
    nếu ($backupFiles) {
        foreach ($file trong $backupFiles) {
            Ghi-Máy chủ "│ └── $($file.Name)"
        }
    } khác {
        Máy chủ ghi "│ └── (空)"
    }

    # 显示公众号信息
    Viết-Máy chủ ""
    Viết-Máy chủ "$GREEN===============================$NC"
    Máy chủ ghi "$YELLOW关注公众号(煎饼果子卷AI)一起交流更多Con trỏ技巧和AI知识(脚本免费、关注公众号加群有更多技巧和大佬) $NC"
    Viết-Máy chủ "$GREEN===============================$NC"
    Viết-Máy chủ ""
    Máy chủ ghi "$GREEN[信息]$NC 请重启 Con trỏ 以应用新的配置"
    Viết-Máy chủ ""

    # 询问是否要禁用自动更新
    Viết-Máy chủ ""
    Máy chủ ghi "$YELLOW[询问]$NC 是否要禁用 Con trỏ 自动更新功能？"
    Máy chủ ghi "0) 否 - 保持默认设置 (按回车键)"
    Máy chủ ghi "1) 是 - 禁用自动更新"
    $choice = Máy chủ đọc "请输入选项 (0)"

    nếu ($choice -eq "1") {
        Viết-Máy chủ ""
        Máy chủ ghi "$GREEN[信息]$NC 正在处理自动更新..."
        $updaterPath = "$env:LOCALAPPDATA\cursor-updater"

        # 定义手动设置教程
        chức năng Show-ManualGuide {
            Viết-Máy chủ ""
            Write-Host "$YELLOW[警告]$NC 自动设置失败,请尝试手动操作:"
            Máy chủ ghi "$YELLOW手动禁用更新步骤:$NC"
            Máy chủ ghi "1. 以管理员身份打开 PowerShell"
            Máy chủ ghi "2. 复制粘贴以下命令:"
            Máy chủ ghi "$BLUE命令1 - 删除现有目录（如果存在):$NC"
            Write-Host "Xóa-Mục -Đường dẫn `"$updaterPath`" -Buộc -Đệ quy -Hành động lỗi Tiếp tục im lặng"
            Viết-Máy chủ ""
            Máy chủ ghi "$BLUE命令2 - 创建阻止文件:$NC"
            Write-Host "New-Item -Path `"$updaterPath`" -ItemType File -Force | Out-Null"
            Viết-Máy chủ ""
            Máy chủ ghi "$BLUE命令3 - 设置只读属性:$NC"
            Write-Host "Set-ItemProperty -Path `"$updaterPath`" -Name IsReadOnly -Giá trị `$true"
            Viết-Máy chủ ""
            Máy chủ ghi "$BLUE命令4 - 设置权限（可选）:$NC"
            Ghi-Máy chủ "icacls `"$updaterPath`" /inheritance:r /grant:r `"`$($env:USERNAME):(R)`""
            Viết-Máy chủ ""
            Máy chủ ghi "$YELLOW验证方法:$NC"
            Máy chủ ghi "1. 运行命令:Get-ItemProperty `"$updaterPath`""
            Write-Host "2. 确认 IsReadOnly 属性为 True"
            Máy chủ ghi "3. 运行命令:icacls `"$updaterPath`""
            Máy chủ ghi "4. 确认只有读取权限"
            Viết-Máy chủ ""
            Máy chủ ghi "$YELLOW[提示]$NC 完成后请重启 Con trỏ"
        }

        thử {
            # 检查cursor-updater是否存在
            nếu (Đường dẫn thử nghiệm $updaterPath) {
                # 如果是文件,说明已经创建了阻止更新
                nếu ((Get-Item $updaterPath) -là [System.IO.FileInfo]) {
                    Máy chủ ghi "$GREEN[信息]$NC 已创建阻止更新文件,无需再次阻止"
                    trở lại
                }
                # 如果是目录,尝试删除
                khác {
                    thử {
                        Remove-Item -Path $updaterPath -Force -Recurse -ErrorAction Dừng
                        Máy chủ ghi "$GREEN[信息]$NC 成功删除 trình cập nhật con trỏ 目录"
                    }
                    nắm lấy {
                        Máy chủ ghi "$RED[错误]$NC 删除 trình cập nhật con trỏ 目录失败"
                        Hiển thị-ManualGuide
                        trở lại
                    }
                }
            }

            # 创建阻止文件
            thử {
                New-Item -Path $updaterPath -ItemType File -Force -ErrorAction Dừng | Out-Null
                Máy chủ ghi "$GREEN[信息]$NC 成功创建阻止文件"
            }
            nắm lấy {
                Máy chủ ghi "$RED[错误]$NC 创建阻止文件失败"
                Hiển thị-ManualGuide
                trở lại
            }

            # 设置文件权限
            thử {
                # 设置只读属性
                Set-ItemProperty -Path $updaterPath -Name IsReadOnly -Value $true -ErrorAction Dừng
                
                # Sử dụng icacls để tạo tệp
                $result = Bắt đầu-Quy trình "icacls.exe" -ArgumentList "`"$updaterPath`" /inheritance:r /grant:r `"$($env:USERNAME):(R)`"" -Wait -NoNewWindow -PassThru
                nếu ($result.ExitCode -ne 0) {
                    ném "icacls 命令失败"
                }
                
                Máy chủ ghi "$GREEN[信息]$NC 成功设置文件权限"
            }
            nắm lấy {
                Máy chủ ghi "$RED[错误]$NC 设置文件权限失败"
                Hiển thị-ManualGuide
                trở lại
            }

            # Xem thêm
            thử {
                $fileInfo = Get-ItemProperty $updaterPath
                nếu (-không phải $fileInfo.IsReadOnly) {
                    Máy chủ ghi "$RED[错误]$NC 验证失败:文件权限设置可能未生效"
                    Hiển thị-ManualGuide
                    trở lại
                }
            }
            nắm lấy {
                Máy chủ ghi "$RED[错误]$NC 验证设置失败"
                Hiển thị-ManualGuide
                trở lại
            }

            Máy chủ ghi "$GREEN[信息]$NC 成功禁用自动更新"
        }
        nắm lấy {
            Máy chủ ghi "$RED[错误]$NC 发生未知错误: $_"
            Hiển thị-ManualGuide
        }
    }
    khác {
        Máy chủ ghi "$GREEN[信息]$NC 保持默认设置，不进行更改"
    }

    # 保留有效的注册表更新
    Cập nhật-MachineGuid

} nắm lấy {
    Máy chủ ghi "$RED[错误]$NC 主要操作失败: $_"
    Máy chủ ghi "$YELLOW[尝试]$NC 使用备选方法..."
    
    thử {
        # 备选方法: 使用 Nội dung bổ sung
        $tempFile = [System.IO.Path]::GetTempFileName()
        $config | ConvertTo-Json | Set-Content -Path $tempFile -Mã hóa UTF8
        Copy-Item -Đường dẫn $tempFile -Điểm đến $STORAGE_FILE -Buộc
        Xóa-Mục -Đường dẫn $tempFile
        Máy chủ ghi "$GREEN[信息]$NC 使用备选方法成功写入配置"
    } nắm lấy {
        Máy chủ ghi "$RED[错误]$NC 所有尝试都失败了"
        Write-Host "Tên người dùng: $_"
        Máy chủ ghi "目标文件: $STORAGE_FILE"
        Máy chủ ghi "请确保您有足够的权限访问该文件"
        Máy chủ đọc "按回车键退出"
        lối ra 1
    }
}

Viết-Máy chủ ""
Máy chủ đọc "按回车键退出"
thoát 0

# 在文件写入部分修改
chức năng Write-ConfigFile {
    tham số($config, $filePath)
    
    thử {
        # Sử dụng UTF8 để mã hóa BOM
        $utf8NoBom = Hệ thống đối tượng mới.Text.UTF8Encoding $false
        $jsonContent = $config | ConvertTo-Json - Độ sâu 10
        
        # 统一使用 LF 换行符
        $jsonContent = $jsonContent.Replace("`r`n", "`n")
        
        [System.IO.File]::WriteAllText(
            [System.IO.Path]::GetFullPath($filePath),
            $jsonNội dung,
            $utf8NoBom
        )
        
        Máy chủ ghi "$GREEN[信息]$NC 成功写入配置文件(UTF8 无 BOM)"
    }
    nắm lấy {
        ném "写入配置文件失败: $_"
    }
}

# 获取并显示版本信息
$cursorVersion = Lấy-CursorVersion
Viết-Máy chủ ""
nếu ($cursorVersion) {
    Máy chủ ghi "$GREEN[信息]$NC 检测到 Cursor 版本: $cursorVersion,继续执行..."
} khác {
    Máy chủ ghi "$YELLOW[警告]$NC 无法检测版本，将继续执行..."
}
