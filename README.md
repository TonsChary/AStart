# AStart
 一个简单的MC启服Shell

详情页在B站： [[Minecraft\]AStart 一个简单的服务端启动脚本，适用于Linux - 哔哩哔哩 (bilibili.com)](https://www.bilibili.com/read/cv11817163)

更新会以模块的形式（文字）的形式，就像这样：

```sh
   # === 此段放在 配置部分-其他 下
   # ==== CoreProtect ====
        # - 自动移动 CoreProtect 的数据库文件到指定回收站
        #   默认 启用
CP_AutoRemoveDB='true'
        # - 重启 n 次后移动数据库到回收站
        #   默认 40
CP_RemoveDBNum='40'
        # - 回收站目录 固定位于 服务端备份 目录下子目录 目录结尾需加"/"
        #   默认 BackupMainFolder/'OverdueCoreProtectDB/'
CP_DBfolder='OverdueCoreProtectDB/'
        # - 保留n个数据库 不可小于1
        #   默认 2
CP_MaxDBNum='2'

# === 此段放在 Functions 部分下
# CoreProtect
function AutoRemoveCoreProtectDB () {
    echo ""
    echo "  = = - 准备清理数据库 = ="
    echo ""
    # - 检查数据库回收站目录
    if [ ! -d $MainBackupFolder$CP_DBfolder ]; then
        mkdir $MainBackupFolder$CP_DBfolder
    fi
    # - 移动数据库文件
    CP_Date=`date '+%Y年%m月%d日-%H:%M:%S'`
        # - 文件类型
    CP_FileType='db'
        # - 文件后缀
    CP_FileTile='bak'
        # - 移动数据库
    mv ./plugins/CoreProtect/*.db $MainBackupFolder$CP_DBfolder$CP_FileType-$CP_Date-database.bak 2> /dev/null
    # - 检查配置是否正确
    if [ $CP_MaxDBNum -ge 1 ];then
        # - 自动清理过期数据库
        CP_DBNum=`ls -t $MainBackupFolder$CP_DBfolder*.bak 2> /dev/null | wc -l`;
        if [ $CP_DBNum -gt $CP_MaxDBNum ]; then
            CP_DelNum=$[ $CP_DBNum-$CP_MaxDBNum ]
            echo '  - 将保留 '$CP_MaxDBNum' 个数据库'
            echo '  - 准备删除: '$CP_DelNum' 个数据库'
            for((CP_mint = 1; CP_mint<=$CP_DelNum; CP_mint++)); do
                CP_TargetFileName=`ls -tr $MainBackupFolder$CP_DBfolder | head -n 1`
                CP_Target=$MainBackupFolder$CP_DBfolder$CP_TargetFileName
                rm $CP_Target
            done
            echo "  - 已删除过期数据库"
        else
            echo ""
            echo  '  - 总文件数: '$CP_DBNum '<' $CP_MaxDBNum
            echo "  - 已跳过此步"
        fi
        
    else
        echo "  - CoreProtect配置错误，但我们还是将数据库移入了回收站，请排查错误后重试！"
    fi
    echo ""
    echo "= = - 完成 - = ="
    echo ""
}

# === 此段放在 Main-自动任务 部分下
# 移动CoreProtect数据库
        RCPDBIndex=$(( $RestartTimer % $CP_RemoveDBNum))
    if [ $RCPDBIndex == "0" ] && [ $CP_AutoRemoveDB == "true" ]; then
        AutoRemoveCoreProtectDB
    fi
```

所有代码在原有代码基础上顺延粘贴就好√

保存并重新使用Astart即可
