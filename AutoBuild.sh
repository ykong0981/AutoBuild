#!/bin/bash
# Project	AutoBuild
# Author	Hyy2001、Nxiz
# Github	https://github.com/Hyy2001X/AutoBuild
# Supported System:Ubuntu 20.04、Ubuntu 19.10、Ubuntu 18.04、Deepin 20
Update=2020.10.05
Version=V4.1

Second_Menu() {
while :
do
	clear
	if [ -f $Home/Projects/$Project/Makefile ];then
		Say="源码位置:$Home/Projects/$Project" && Color_Y
		if [ $Project == Lede ];then
			if [ -f $Home/Projects/$Project/package/lean/default-settings/files/zzz-default-settings ];then
				cd $Home/Projects/$Project/package/lean/default-settings/files
				Lede_Version=`egrep -o "R[0-9]+\.[0-9]+\.[0-9]+" ./zzz-default-settings`
				Say="源码版本:$Lede_Version" && Color_Y
			fi
		fi
		cd $Home
		if [ -f ./Configs/${Project}_Recently_Updated ];then
			Recently_Updated=`cat ./Configs/${Project}_Recently_Updated`
			Say="最近更新:$Recently_Updated" && Color_Y
		fi
		cd $Home/Projects/$Project
		Branch=`git branch | sed 's/* //g'`
	else
		Say="未检测到[$Project]源码,请前往[高级选项]下载!" && Color_R
	fi
	echo ""
	echo "1.更新源代码和Feeds"
	echo "2.打开固件配置菜单"
	echo "3.备份与恢复"
	echo "4.编译选项"
	echo "5.高级选项"
	Say="\nm.主菜单" && Color_G
	echo "q.返回"
	GET_Choose
	case $Choose in
	q)
		break
	;;
	m)
		AutoBuild_Core
	;;
	1)
		Enforce_Update=0
		Sources_Update_Check
	;;
	2)
		Make_Menuconfig
	;;
	3)
		BackupServices
	;;
	4)
		BuildFirmware_Check
	;;
	5)
		Project_Options
	esac
done
}

Project_Options() {
while :
do
	cd $Home/Projects/$Project
	clear
	Say="源码高级选项\n" && Color_B
	echo "1.下载源代码"
	echo "2.强制更新源代码和Feeds"
	Say="3.添加第三方主题包" && Color_Y
	Say="4.添加第三方软件包" && Color_Y
	echo "5.空间清理"
	echo "6.删除配置文件"
	echo "7.下载[dl]库"
	echo "8.源代码更新日志"
	Say="\nm.主菜单" && Color_G
	echo "q.返回"
	GET_Choose
	case $Choose in
	q)
		break
	;;
	m)
		AutoBuild_Core
	;;
	1)
		Sources_Download
	;;
	2)
		Enforce_Update=1
		Sources_Update_Check
	;;
	3)
		ExtraThemes
	;;
	4)
		ExtraPackages
	;;
	5)
	while :
	do
		clear
		Say="空间清理\n" && Color_B
		echo "1.make clean"
		echo "2.make dirclean"
		echo "3.make distclean"
		Say="4.删除[$Project]项目" && Color_R
		echo "5.清理[临时文件/编译缓存]"
		echo "6.清理[更新日志]"
		echo "7.清理[编译日志]"
		echo "q.返回"
		GET_Choose
		cd $Home/Projects/$Project
		case $Choose in
		q)
			break
		;;
		1)	
			make clean
		;;
		2)
			make dirclean
		;;
		3)
			make distclean
		;;
		4)
			cd $Home/Projects
			Say="\n正在删除$Project...\n" && Color_B
			rm -rf $Project
			rm -f $Home/Configs/${Project}_Recently_*
			rm -f $Home/Log/*_${Project}_*
			break
		;;
		5)
			rm -rf $Home/Projects/$Project/tmp
			Say="\n[临时文件/编译缓存]删除成功!" && Color_Y
		;;
		6)
			rm -f $Home/Log/Update_${Project}_*
			Say="\n[更新日志]删除成功!" && Color_Y
		;;
		7)
			rm -f $Home/Log/Compile_${Project}_*
			Say="\n[编译日志]删除成功!" && Color_Y
		;;
		esac
		sleep 2
	done
	;;
	6)
		cd $Home/Projects/$Project
		rm -f ./.config*
		Say="\n[配置文件]删除成功!" && Color_Y
		sleep 2
	;;
	7)
		timeout 3 ping -c 1 www.baidu.com > /dev/null 2>&1
		if [ $? -eq 0 ];then
			cd $Home/Projects/$Project
			clear
			dl_Logfile=$Home/Log/dl_${Project}_`(date +%Y%m%d_%H:%M)`.log
			make -j$CPU_Threads download V=s 2>&1 | tee -a $dl_Logfile
			find dl -size -1024c -exec rm -f {} \;
			Enter
		else
			Say="\n网络连接错误,[dl]库下载失败!" && Color_R
			sleep 2
		fi
	;;
	8)
		clear
		if [ -d $Home/Projects/$Project/.git ];then
			cd $Home/Projects/$Project
			git log -10 --graph --all --branches --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%cr)%C(reset) %C(bold green)(%ai)%C(reset) %C(white)%s'
			Enter
		fi
	;;
	esac
done
}

BackupServices() {
while :
do
	clear
	Say="备份与恢复\n" && Color_B
	echo "1.备份[.config]"
	echo "2.恢复[.config]"
	echo "3.备份[$Project]源码"
	echo "4.恢复[$Project]源码"
	Say="5.链接[dl]库" && Color_G
	echo -e "\nq.返回"
	GET_Choose
	case $Choose in
	q)
		break
	;;
	1)
	while :
	do
		cd $Home
		clear
		Say="备份[.config]\n" && Color_Y
		if [ $Project == Lede ];then
			echo -e "1.标准名称/$Yellow文件格式:[$Project-版本号-日期_时间]$White"
		else
			echo -e "1.标准名称/$Yellow文件格式:[$Project-日期_时间]$White"
		fi
		echo "2.自定义名称"
		echo -e "\nq.返回"
		GET_Choose
		echo ""
		case $Choose in
		q)
			break
		;;
		1)
			if [ $Project == Lede ];then
				Backup_Config=$Project-$Lede_Version-`(date +%m%d_%H:%M)`
			else
				Backup_Config=$Project-`(date +%m%d_%H:%M)`
			fi	
			if [ -f ./Projects/$Project/.config ];then
				cp ./Projects/$Project/.config ./Backups/Configs/$Backup_Config
				Say="备份成功![.config]已备份到:'/Backups/Configs/$Backup_Config'" && Color_Y
			else
				Say="备份失败!" && Color_R
			fi
		;;
		2)
			read -p '请输入自定义名称:' Backup_Config
			if [ -f ./Projects/$Project/.config ];then
				cp ./Projects/$Project/.config ./Backups/Configs/"$Backup_Config"
				Say="\n备份成功![.config]已备份到:'/Backups/Configs/$Backup_Config'" && Color_Y
			else
				Say="\n备份失败!" && Color_R
			fi
		;;	
		esac
		sleep 2
	done
	;;
	2)
	if [ ! "`ls -A $Home/Backups/Configs`" = "" ];then
	while :
	do
		clear
		Say="恢复[.config]\n" && Color_Y
		cd $Home/Backups/Configs
		ls -A | cat > $Home/TEMP/Config.List
		ConfigList_File=$Home/TEMP/Config.List
		Max_ConfigList_Line=`sed -n '$=' $ConfigList_File`
		for ((i=1;i<=$Max_ConfigList_Line;i++));
		do   
			ConfigFile_Name=`sed -n ${i}p $ConfigList_File`
			echo -e "${i}.$Yellow${ConfigFile_Name}$White"
		done
		echo -e "\nq.返回\n"
		read -p '请从上方选择一个文件:' Choose
		case $Choose in
		q)
			break
		;;
		*)
			if [ $Choose -le $Max_ConfigList_Line ] 2>/dev/null ;then
				if [ ! $Choose == 0 ] 2>/dev/null ;then
					echo ""
					ConfigFile=`sed -n ${Choose}p $ConfigList_File`
					if [ -f "$ConfigFile" ];then
						ConfigFile_Dir="$Home/Backups/Configs/$ConfigFile"
						cp "$ConfigFile_Dir" $Home/Projects/$Project/.config
						echo "$ConfigFile" > $Home/Configs/${Project}_Recently_Config
						Say="配置 [$ConfigFile] 恢复成功!" && Color_Y
						sleep 2
					else
						Say="未检测到对应的配置文件!" && Color_R
						sleep 2
					fi
				else
					Say="\n输入错误,请输入正确的数字!" && Color_R
					sleep 2
				fi
			else
				Say="\n输入错误,请输入正确的数字!" && Color_R
				sleep 2
			fi
		;;
		esac
	done
	else
		Say="未找到备份文件,恢复失败!" && Color_R
		sleep 2
	fi
	;;
	3)
		echo ""
		echo -ne "\r$Yellow正在备份[$Project]源码...$White\r"
		if [ -f $Home/Backups/Projects/$Project/Makefile ];then
			rm -rf $Home/Backups/Projects/$Project
		fi
		cp -a $Home/Projects/$Project $Home/Backups/Projects > /dev/null 2>&1
		Say="备份成功![$Project]源码已备份到:'/Backups/Projects/$Project'" && Color_Y
		Say="存储占用:$(du -sh $Home/Backups/Projects/$Project | awk '{print $1}')B" && Color_B
		Enter
	;;
	4)
		echo ""
		if [ -f $Home/Backups/Projects/$Project/Makefile ];then
			echo -ne "\r$Yellow正在恢复[$Project]源码...$White\r"
			cp -a $Home/Backups/Projects/$Project $Home/Projects/ > /dev/null 2>&1
			Say="恢复成功![$Project]源码已恢复到:'/Projects/$Project'" && Color_Y
			Say="存储占用:$(du -sh $Home/Projects/$Project | awk '{print $1}')B" && Color_B
			Enter
		else
			Say="未找到备份文件,恢复失败!" && Color_R
			sleep 2
		fi
	;;
	5)
		cd $Home/Projects
		if [ ! -h ./$Project/dl ];then
			[ -d ./$Project/dl ] && mv -f ./$Project/dl/* $Home/Backups/dl
			rm -rf ./$Project/dl
			ln -s $Home/Backups/dl $Home/Projects/$Project/dl
		fi
		Say="\n已创建软链接'$Home/Backups/dl' -> '$Home/Projects/$Project/dl'" && Color_Y
		sleep 3
	;;
	esac
done
}

Advanced_Options() {
while :
do
	clear
	Say="高级选项\n" && Color_B
	Say="1.更新系统软件包" && Color_Y
	Say="2.安装编译环境" && Color_G
	echo "3.SSH 服务"
	echo "4.同步网络时间"
	echo "5.存储空间统计"
	echo "6.快速启动"
	echo "7.系统信息"
	echo "8.更换系统下载源"
	Say="\nx.更新脚本" && Color_Y
	Say="q.主菜单" && Color_G
	GET_Choose
	case $Choose in
	q)
		break
	;;
	x)
		AutoBuild_Updater
	;;
	1)
		clear
		sudo apt-get update
		sudo apt-get upgrade
		sudo apt-get clean
		Enter
	;;
	2)
		clear
		Update_Times=1
		sudo apt-get update
		while [ $Update_Times -le 3 ];
		do
			clear
			echo -ne "\r开始第$Update_Times次安装...\r"
			sleep 2
			sudo apt-get -y install $Dependency $Extra_Dependency
			Update_Times=$(($Update_Times + 1))
		done
		sudo apt-get clean
		Enter
	;;
	3)
		SSHServices
	;;
	4)
		echo ""
		sudo ntpdate ntp1.aliyun.com
		sudo hwclock --systohc
		sleep 2
	;;
	5)
		StorageDetails
	;;
	6)
		echo ""
		read -p '请输入快速启动的名称:' FastOpen		
		echo "alias $FastOpen='$Home/AutoBuild.sh'" >> ~/.bashrc
		source ~/.bashrc
		Say="\n创建成功!在终端输入 $FastOpen 即可启动 AutoBuild [需要重启终端]." && Color_Y
		sleep 3
	;;
	7)
		Systeminfo
	;;
	8)
		ReplaceSourcesList
	;;
	esac
done
}

AutoBuild_Updater() {
timeout 3 ping -c 1 www.baidu.com > /dev/null 2>&1
if [ $? -eq 0 ];then
	clear
	Say="正在下载更新...\n" && Color_Y
	cd $Home/Backups
	if [ "`ls -A ./AutoBuild-Update`" = "" ];then
		git clone https://github.com/Hyy2001X/AutoBuild AutoBuild-Update
	fi
	cd ./AutoBuild-Update
	Update_Logfile=$Home/Log/Script_Update_`(date +%Y%m%d_%H:%M)`.log
	git pull 2>&1 | tee $Update_Logfile
	if [ $(grep -o "fatal: 无法访问" $Update_Logfile | wc -l) = "0" ];then
		Say="\n合并到本地文件..." && Color_Y
		Old_Version=`awk 'NR==7' $Home/AutoBuild.sh | awk -F'[="]+' '/Version/{print $2}'`
		Old_Version_Dir=$Old_Version-`(date +%Y%m%d_%H:%M)`
		Backups_Dir=$Home/Backups/OldVersion/AutoBuild-Core-$Old_Version_Dir
		[ -d $Backups_Dir ] && rm -rf $Backups_Dir
		mkdir -p $Backups_Dir
		mv $Home/AutoBuild.sh $Backups_Dir/AutoBuild.sh
		mv $Home/README.md $Backups_Dir/README.md
		mv $Home/LICENSE $Backups_Dir/LICENSE
		mv $Home/Additional $Backups_Dir/Additional 2>/dev/null 
		mv $Home/Modules $Backups_Dir/Modules
		cp -a * $Home
		echo -e "$Yellow"
		read -p "AutoBuild 更新成功!" Key
		$Home/AutoBuild.sh
	else
		echo -e "$Red"
		read -p "AutoBuild 更新失败!" Key
	fi
else
	Say="\n网络连接错误,更新失败!" && Color_R
	sleep 2
fi
}

Sources_Update_Check() {
timeout 3 ping -c 1 www.baidu.com > /dev/null 2>&1
if [ $? -eq 0 ];then
	Sources_Update_Core
	Enter
else
	Say="\n网络连接错误,更新失败!" && Color_R
	sleep 2
fi
}

Make_Menuconfig() {
clear
cd $Home/Projects/$Project
Say="Loading $Project Configuration..." && Color_B
make menuconfig
Enter
}

Sources_Update_Core() {
clear
Say="开始更新$Project...\n" && Color_Y
echo `(date +%Y-%m-%d_%H:%M)` > $Home/Configs/${Project}_Recently_Updated
cd $Home/Projects/$Project
if [ $Enforce_Update == 1 ];then
	git fetch --all
	git reset --hard origin/$Branch
	if [ $Project == Lede ];then
		sed -i "s/#src-git helloworld/src-git helloworld/g" ./feeds.conf.default
	fi
fi
Update_Logfile=$Home/Log/Update_${Project}_`(date +%Y%m%d_%H:%M)`.log
git pull 2>&1 | tee $Update_Logfile
./scripts/feeds update -a 2>&1 | tee -a $Update_Logfile
./scripts/feeds install -a 2>&1 | tee -a $Update_Logfile
}

Multi_Sources_Update() {
if [ -f $Home/Projects/$1/Makefile ];then
	Project=$1
	Enforce_Update=0
	Sources_Update_Core
	sleep 2
fi
}

Project_Details() {
if [ -f ./Projects/$1/Makefile ];then
	echo -e "${White}$2.$1$DE$Yellow[已检测到]$Blue	$3"
else
	echo -e "${White}$2.$1$DE$Red[未检测到]$Blue	$3"
fi
}

Sources_Download() {
if [ -f $Home/Projects/$Project/Makefile ];then
	Say="\n已检测到[$Project]源码,当前分支:$Branch" && Color_Y
	sleep 3
else
	clear
	Say="$Project源码下载-分支选择" && Color_B
	Github_File=$Home/Additional/GitLink_$Project
	Github_Source_Link=`sed -n 1p $Github_File`
	echo -e "仓库地址:$Github_Source_Link\n"
	Max_All_Line=`sed -n '$=' $Github_File`
	Max_Branch_Line=`expr $Max_All_Line - 1`
	for ((i=2;i<=$Max_All_Line;i++));
	do   
		Github_File_Branch=`sed -n ${i}p $Github_File`
		x=`expr $i - 1`
		echo "${x}.${Github_File_Branch}"
	done
	echo -e "q.返回\n"
	read -p '请从上方选择一个分支:' Choose_Branch
	case $Choose_Branch in
	q)
		break
	;;
	*)
		if [ $Choose_Branch -le $Max_Branch_Line ] 2>/dev/null ;then
			if [ ! $Choose_Branch == 0 ];then
				clear
				Branch_Line=`expr $Choose_Branch + 1`
				Github_Source_Branch=`sed -n ${Branch_Line}p $Github_File`
				Say="下载地址:$Yellow$Github_Source_Link" && Color_B
				Say="远程分支:$Yellow$Github_Source_Branch\n" && Color_B
				cd $Home/Projects
				[ -d ./$Project ] && rm -rf ./$Project
				git clone -b $Github_Source_Branch $Github_Source_Link $Project
				Sources_Download_Check
			else
				Say="\n输入错误,请选择正确的数字!" && Color_R
				sleep 2
				Sources_Download
			fi
		else
			Say="\n输入错误,请输入正确的数字!" && Color_R
			sleep 2
			Sources_Download
		fi
	;;
	esac
fi
}

Sources_Download_Check() {
if [ -f $Home/Projects/$Project/Makefile ];then
	cd $Home/Projects/$Project
	[ $Project == Lede ] && sed -i "s/#src-git helloworld/src-git helloworld/g" ./feeds.conf.default
	ln -s $Home/Backups/dl $Home/Projects/$Project/dl
	echo -e "$Yellow"
	read -p "[$Project]源代码下载成功!" Key
	Second_Menu
else
	echo -e "$Red"
	read -p "[$Project]源代码下载失败!" Key
fi
}

Dir_Check() {
clear
cd $Home
for WD in `cat  ./Additional/Working_Directory`
do
	[ ! -d ./$WD ] && mkdir -p $WD
done
}

First_Startup_Check() {
if [ ! -f $Home/Configs/Username ];then
	read -p '首次启动,请创建一个用户名:' Username
	echo "$Username" > $Home/Configs/Username
else
	Username=`cat $Home/Configs/Username`
fi
}

Second_Menu_Check() {
Project=$1
if [ -f ./Projects/$Project/Makefile ];then
	Second_Menu
else
	if [ $DeveloperMode == 1 ];then
		Second_Menu
	else
		Sources_Download
	fi
fi
}

AutoBuild_Core() {
while :
do
	Settings_Props
	ColorfulUI_Check
	clear
	Say="AutoBuild Core Script $Version" && Color_B
	Say="\n1.Get Started!" && Color_G
	echo "2.网络测试"
	echo "3.高级选项"
	echo "4.脚本设置"
	echo "q.退出"
	GET_Choose
	case $Choose in
	q)
		rm -rf $Home/TEMP
		clear
		break
	;;
	1)
	while :
	do
		clear
		Say="AutoBuild Core Script $Version\n" && Color_B
		cd $Home
		Say="项目名称		[项目状态]	维护者\n" && Color_G
		DE="			"
		Project_Details Lede 1 coolsnowwolf
		DE="		"
		Project_Details Openwrt 2 Openwrt_Team	
		Project_Details Lienol 3 Li2nOnline
		Say="\nx.更新所有源代码和Feeds" && Color_B
		Say="q.主菜单\n" && Color_G
		read -p '请从上方选择一个项目:' Choose
		case $Choose in
		q)
			break
		;;
		x)
			timeout 3 ping -c 1 www.baidu.com > /dev/null 2>&1
			if [ $? -eq 0 ];then
				cd $Home/Projects
				Multi_Sources_Update Lede
				Multi_Sources_Update Openwrt
				Multi_Sources_Update Lienol
			else
				Say="\n网络连接错误,更新失败!" && Color_R
				sleep 2	
			fi
		;;
		1)
			Second_Menu_Check Lede
		;;
		2)
			Second_Menu_Check Openwrt
		;;
		3)
			Second_Menu_Check Lienol
		;;
		esac
	done
	;;
	2)
		Network_Test
	;;
	3)
		Advanced_Options
	;;
	4)
		Settings
	;;
	esac
done
}

Home=$(cd $(dirname $0); pwd)
set -u

Dependency="build-essential asciidoc binutils bzip2 gawk gettext git libncurses5-dev libz-dev patch python3.5 python2.7 unzip zlib1g-dev lib32gcc1 libc6-dev-i386 subversion flex uglifyjs git-core gcc-multilib p7zip p7zip-full msmtp libssl-dev texinfo libglib2.0-dev xmlto qemu-utils upx libelf-dev autoconf automake libtool autopoint device-tree-compiler g++-multilib antlr3 gperf wget swig rsync curl"
Extra_Dependency="ntpdate httping ssh lm-sensors net-tools expect"

CPU_Model=`awk -F':[ ]' '/model name/{printf ($2);exit}' /proc/cpuinfo`
CPU_Cores=`cat /proc/cpuinfo | grep processor | wc -l`
CPU_Threads=`grep 'processor' /proc/cpuinfo | sort -u | wc -l`
CPU_Freq=`awk '/model name/{print ""$NF;exit}' /proc/cpuinfo`

chmod +x -R $Home/Modules
for Module in $Home/Modules/*.sh
do
	source $Module
done

Dir_Check
First_Startup_Check
AutoBuild_Core
