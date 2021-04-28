#!/bin/bash

#=============================#
#                             #
#      Edited By 东竹茶       #
#   Bilibili UID: 27092707    #
#                             #
#=============================#

# ========== -+ Config +- ==========

# == 服务端 ==
    # - 服务端核心文件名
CorePath='spigot-1.16.1.jar'
    # - 自动删除崩溃日志
    #   只保留 n 个日志
        # - JVM日志
        #   默认 0
LastJVMLogs='0'
        # - 服务端日志(Logs目录下文件)
        #   默认 3
LastServerLogs='3'
    # - 重启等待(秒)
    #   不可小于 0
    #   默认 3
RDelay='3'

# == Java ==
    # Java路径 / Java环境变量
    #   默认 java
JavaPath='/usr/lib/jvm/jdk-11/bin/java'
    # - 虚拟机最大内存 xx<单位>
MaxMem='3000M'
    # - 虚拟机最小内存 xx<单位>
MinMem='3000M'
    # - 调优参数
    #   默认 Minecraft官启参数
    #   -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1NewSizePercent=20 -XX:G1ReservePercent=20 -XX:MaxGCPauseMillis=50 -XX:G1HeapRegionSize=32M
JavaTuning="-XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:ParallelGCThreads=5 -XX:G1NewSizePercent=20 -XX:G1ReservePercent=20 -XX:MaxGCPauseMillis=50 -XX:G1HeapRegionSize=16M -XX:+AggressiveOpts -XX:+UseCompressedOops"

# == 备份 ==
    # - 自动备份,可配合自动重启使用
    #   默认 启用
AutoBackup='true'
    # - 备份主目录
    #   此目录不会被压缩入备份压缩包，可存放备份和其他你不想压缩的文件
    #   目录结尾需加"/"
    #   默认 'BackupMainFolder/'
MainBackupFolder='BackupMainFolder/'
    # - 每重启n次备份一次服务端
    #   不可小于 1
    #   默认 20
MakeBakPer='20'
    # - 重启次数大于n次后再执行备份 0则禁用
    #   默认 禁用
MakeBakDelay='0'
    # - 备份文件储存位置 默认 Backups/ 目录结尾需加"/"
    #   默认 Backups
BackupFolder='ServerBackups/'
    # - 自动删除过期备份
    #   保留最新的n个备份 n小于等于1则禁用自动删除
    #   默认 5
MaxBackupNum='5'

# == 其他 ==
    # - 启用 AntiAttack MCPR提供支持 默认关闭
MCPR_Act='true'
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

# =============================

# 注意：以下为逻辑部分，除有特殊需求(例如加入自定义方法和任务)外，请勿随意改动！

# ========== -+ Functions +- ==========
    # 初始化
function Init () {
    # - 检索 MCPR
    if [ $MCPR_Act == "true" ]; then
        MCPR='-javaagent:MCPRBAPI.jar'
    else
         MCPR=''
    fi
    # - 检查主备份目录
    if [ ! -d $MainBackupFolder ]; then
        mkdir $MainBackupFolder
    fi
    # - 备份计数器移位
    if [ $MakeBakDelay -lt 0 ]; then
        MakeBakDelay=1
    fi
    # - 配置计数器
    RestartTimer='0'
    let RestartTimer-=$MakeBakDelay
    RestartTimes='0'
}

    # 自动删除日志/报告
function mAutoDelLog () {
    echo ""
    echo "= = ---------- 准备删除过期日志 ---------- = ="
    if [ $LastJVMLogs -ge 0 ] || [ $LastServerLogs -ge 0 ]; then
    # - JVM
        JVMLogNum=`ls -t ./hs_err*.log 2> /dev/null | wc -l`;
        if [ $JVMLogNum -gt $LastJVMLogs ]; then
            JVMLogNum=`expr $JVMLogNum - $LastJVMLogs`
            ls -tr ./hs_err*.log 2> /dev/null | head -$JVMLogNum | xargs rm
            echo "  - 已清理过期JVM崩溃报告"
        fi
    # - 服务端
        ServerLogNum=`ls -t ./logs/*.log* 2> /dev/null | wc -l`;
        if [ $ServerLogNum -gt $LastServerLogs ]; then
            ServerLogNum=`expr $ServerLogNum - $LastServerLogs`
            ls -tr ./logs/*.log* 2> /dev/null | head -$ServerLogNum | xargs rm
            echo "  - 已清理过期服务端日志"
        fi
    fi
    echo ""
    echo "= = ---------- 完成 ---------- = ="
    echo ""
}

    # 自动备份
function mAutoBackup () {
    mDate=`date '+%Y年%m月%d日-%H:%M'`
    # - 游戏版本
    GameVersion='1.16.1'
    # - 文件类型
    FileType='zip'
    # - 文件后缀
    FileTile='bak'
    # - 检查备份目录
    if [ ! -d $MainBackupFolder$BackupFolder ]; then
        mkdir $MainBackupFolder$BackupFolder
    fi

    if [ $AutoBackup == "true"  ]; then
        echo ""
        echo "= = ----- 现在是 $mDate ,开始备份服务器 ----- = ="
         zip -r ./$FileType-$mDate-v$GameVersion.bak ./ -x "./$MainBackupFolder*"
         mv ./*.bak ./$MainBackupFolder$BackupFolder 2> /dev/null
         echo ""
         echo "= = ---------- 备份完毕 ---------- = ="
         echo ""
    fi
}

    # 自动删除过期备份
function autoDelOld () {
    echo ""
    echo "= = ---------- 准备删除过期备份 ---------- = ="
    echo ""
    if [ $MaxBackupNum -gt 0 ]; then
        FileNum=`ls -t $MainBackupFolder$BackupFolder*.bak 2> /dev/null | wc -l`
        if [ $FileNum -gt $MaxBackupNum ]; then
            DelNum=$[ $FileNum-$MaxBackupNum ]
            echo '  - 备份文件总数: '$FileNum
            echo '  - 准备删除的文件数: '$DelNum
            for((mint = 1; mint<=$DelNum; mint++)); do
                TargetFileName=`ls -tr $MainBackupFolder$BackupFolder*.bak | head -n 1`
                Target=$TargetFileName
                rm $Target
            done
            echo "  - 已删除过期备份"
        else
            echo  '  - 备份文件总数: '$FileNum '<=' $MaxBackupNum
            echo "  - 已跳过此步"
        fi
    else
        echo ""
        echo "  - 参数设置错误，已跳过此步"
    fi
    echo ""
    echo "= = ---------- 完成 ---------- = ="
    echo ""
}

# CoreProtect
function AutoRemoveCoreProtectDB () {
    echo ""
    echo "= = ---------- 准备清理数据库 ---------- = ="
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
    echo "= = ---------- 完成 ---------- = ="
    echo ""
}

# =============================

# ========== -+ Main +- ==========
    # 初始化
Init
    # 启动
echo ""
echo "= = ---------- 服务端正在启动 请稍后 ---------- = ="
echo ""
    # 主循环
while [ true ]; do
    # 检查配置错误
    if [ $RDelay -le "0" ] || [ $MakeBakPer -lt "0" ]; then
        echo "  - 配置错误，请排查错误后重试！ -"
        break
    fi
    # 拉起服务端
    $JavaPath $MCPR -Xmx$MaxMem -Xms$MinMem $JavaTuning -jar $CorePath nogui
    echo ""
    let RestartTimes+=1
    let RestartTimer+=1
        # 日志删除
    mAutoDelLog

        # 自动备份
    BackupIndex=$(( $RestartTimer % $MakeBakPer ))
    if [ $BackupIndex == "0" ] && [ $RestartTimer -gt 1 ]; then
        echo "= = ---------- 服务端已关闭 开始备份 ---------- = ="
        mAutoBackup
        echo "= = ---------- 完成自定义任务后将在 $RDelay 秒后重启 ---------- = ="
    else
        echo "= = ---------- 服务端已关闭 完成自定义任务后将在 $RDelay 秒后重启 ---------- = ="
    fi

    # ====== 自定义任务 ==========
    echo ''
    echo '  - 执行自定义任务 -'
    echo ''
        # 自动删除过期备份
    autoDelOld
        # 移动CoreProtect数据库
        RCPDBIndex=$(( $RestartTimer % $CP_RemoveDBNum))
    if [ $RCPDBIndex == "0" ] && [ $CP_AutoRemoveDB == "true" ]; then
        AutoRemoveCoreProtectDB
    fi

    # ===== 完成 =====

    # 延迟启动
    sleep $RDelay
    echo ""
    echo "= = ---------- 服务端正在重启 | 第 $RestartTimes 次重启 ---------- = ="

done
