# AutoBuild Script Module by Hyy2001

BuildFirmware_UI() {
Update=2020.10.05
Module_Version=V3.0.1-BETA

while :
do
	GET_TARGET_INFO
	clear
	Say="AutoBuild Firmware Script $Module_Version\n" && Color_B
	Say="电脑信息:$CPU_Model $CPU_Cores核心$CPU_Threads线程 $CPU_TEMP\n" && Color_G
	if [ -f $Home/Configs/${Project}_Recently_Config ];then
		echo -e "$Yellow最近配置文件:$Blue[$(cat $Home/Configs/${Project}_Recently_Config)]$White\n"
	fi
	if [ ! $Firmware_Type == x86 ];then
		if [ $PROFILE_MaxLine -gt 1 ];then
			echo -e "设备数量:$PROFILE_MaxLine"
			Firmware_Type=Multi_Profile
		else
			echo -e "设备名称:${Yellow}$TARGET_PROFILE${White}"
			Firmware_Type=Common
		fi
	fi
	if [ $DEFCONFIG == 0 ];then
		echo -e "CPU 架构:$Yellow$TARGET_BOARD$White"
		echo -e "CPU 型号:$Yellow$TARGET_SUBTARGET$White"
		echo -e "软件架构:$Yellow$TARGET_ARCH_PACKAGES$White"
		echo -e "编译类型:$Blue$Firmware_Type"
	else
		Say="Please run 'make defconfig' first!" && Color_R
	fi
	echo -e "${Yellow}\n1.make -j1 V=s"
	echo "2.make -j2 V=s"
	echo "3.make -j4"
	echo -e "4.make -j4 V=s${White}"
	echo "5.make menuconfig"
	echo "6.make kernel_menuconfig"
	echo "7.make defconfig"
	echo -e "8.自动选择[$CPU_Threads 线程]"
	echo "9.手动输入参数"
	echo "q.返回"
	if [ -f $Home/Configs/${Project}_Recently_Compiled ];then
		Recently_Compiled=`awk 'NR==1' $Home/Configs/${Project}_Recently_Compiled`
		Recently_Compiled_Stat=`awk 'NR==2' $Home/Configs/${Project}_Recently_Compiled`
		echo -e "\n$Yellow最近编译:$Blue$Recently_Compiled $Recently_Compiled_Stat$White"
	fi
	GET_Choose
	case $Choose in
	q)
		break
	;;
	1)
		Compile_Threads="make -j1 V=s"
	;;
	2)
		Compile_Threads="make -j2 V=s"
	;;
	3)
		Compile_Threads="make -j4"
	;;
	4)
		Compile_Threads="make -j4 V=s"
	;;
	5)
		Make_Menuconfig
	;;
	6)
		clear
		make kernel_menuconfig
	;;
	7)
		Say="\n正在执行,请耐心等待..." && Color_B
		make defconfig
	;;
	8)
		Compile_Threads="make -j$CPU_Threads V=s"
	;;
	9)
		read -p '请输入编译参数:' Compile_Threads
	esac
	[ $Choose -gt 0 ]&&[ ! $Choose == 5 ]&&[ ! $Choose == 6 ]&&[ ! $Choose == 7 ]&&[ $Choose -le 9 ] && BuildFirmware_Core
done
}

BuildFirmware_Core() {
Firmware_PATH=$Home/Projects/$Project/bin/targets/$TARGET_BOARD/$TARGET_SUBTARGET
rm -rf $Firmware_PATH > /dev/null 2>&1
clear
case $Firmware_Type in
x86)
	X86_Images_Check
	Say="已选择的X86固件:\n" && Color_Y
	for TARGET_IMAGES in `cat $Home/TEMP/Choosed_FI`
	do
		Say="	$TARGET_IMAGES" && Color_B
	done
	if [ $Project == Lede ];then
		Firmware_INFO=AutoBuild-$TARGET_BOARD-$TARGET_SUBTARGET-$Project-$Lede_Version-`(date +%Y%m%d-%H:%M:%S)`
	else
		Firmware_INFO=AutoBuild-$TARGET_BOARD-$TARGET_SUBTARGET-$Project-`(date +%Y%m%d-%H:%M:%S)`
	fi
	echo ""
;;
Common)
	Firmware_Name=openwrt-$TARGET_BOARD-$TARGET_SUBTARGET-$TARGET_PROFILE-squashfs-sysupgrade.bin
	if [ $Project == Lede ];then
		Firmware_INFO=AutoBuild-$TARGET_PROFILE-$Project-$Lede_Version-`(date +%Y%m%d-%H:%M:%S)`
	else
		Firmware_INFO=AutoBuild-$TARGET_PROFILE-$Project-`(date +%Y%m%d-%H:%M:%S)`
	fi
	AB_Firmware=${Firmware_INFO}.bin
	Firmware_Detail=$Home/Firmware/Details/${Firmware_INFO}.detail
	echo -e "$Yellow固件名称:$Blue$AB_Firmware$White\n"
;;
Multi_Profile)
	rm -f $Home/TEMP/Multi_TARGET > /dev/null 2>&1
	for TARGET_PROFILE in `cat  $Home/TEMP/TARGET_PROFILE`
	do
		echo "openwrt-$TARGET_BOARD-$TARGET_SUBTARGET-$TARGET_PROFILE-squashfs-sysupgrade.bin" >> $Home/TEMP/Multi_TARGET
	done
;;
esac
if [ $Project == Lede ];then
	cd $Home/Projects/$Project/package/lean/default-settings/files
	Date=`date +%Y/%m/%d`
	if [ ! $(grep -o "Compiled by $Username" ./zzz-default-settings | wc -l) = "1" ];then
		sed -i "s?$Lede_Version?$Lede_Version Compiled by $Username [$Date]?g" ./zzz-default-settings
	fi
	Old_Date=`egrep -o "[0-9]+\/[0-9]+\/[0-9]+" ./zzz-default-settings`
	if [ ! $Date == $Old_Date ];then
		sed -i "s?$Old_Date?$Date?g" ./zzz-default-settings
	fi
	cd $Home/Projects/$Project/package/base-files/files/etc
	echo "$Lede_Version-`date +%Y%m%d`" > openwrt_info
fi
Say="开始编译$Project..." && Color_Y
cd $Home/Projects/$Project
Compile_Started=`date +'%Y-%m-%d %H:%M:%S'`
Compile_Date=`date +%Y%m%d_%H:%M`
echo $Compile_Started > $Home/Configs/${Project}_Recently_Compiled
if [ $SaveCompileLog == 0 ];then
	$Compile_Threads
else
	$Compile_Threads 2>&1 | tee $Home/Log/BuildOpenWrt_${Project}_${Compile_Date}.log
fi
case $Firmware_Type in
x86)
	Compile_Stopped
	cd $Firmware_PATH
	find ./ -size +20480k -exec echo $@ > $Home/TEMP/Compiled_FI {} \;
	IMAGES_MaxLine=`sed -n '$=' $Home/TEMP/Compiled_FI`
	echo ""
	if [ ! -z $IMAGES_MaxLine ];then
		mkdir -p $Home/Firmware/$Firmware_INFO
		for Compiled_FI in `cat $Home/TEMP/Compiled_FI`
		do
			Compiled_FI=${Compiled_FI##*/}
			echo -e "$Yellow已检测到: $Blue$Compiled_FI$White"
			mv $Compiled_FI $Home/Firmware/$Firmware_INFO
			MD5=`md5sum $Compiled_FI | cut -d ' ' -f1`
			SHA256=`sha256sum $Compiled_FI | cut -d ' ' -f1`
			echo -e "MD5:$MD5\nSHA256:$SHA256" > $Home/Firmware/$Firmware_INFO/${Compiled_FI}.detail
		done
		Say="\n固件位置:Firmware/$Firmware_INFO" && Color_Y
	fi
	Say="\n编译结束!" && Color_B
;;
Common)
	Compile_Stopped
	if [ -f $Firmware_PATH/$Firmware_Name ];then
		Checkout_Package
		echo "成功" >> $Home/Configs/${Project}_Recently_Compiled
		cd $Home/Projects/$Project
		mv $Firmware_PATH/$Firmware_Name $Home/Firmware/$AB_Firmware
		cd $Home/Firmware
		Say="\n固件位置:$Blue$Home/Firmware" && Color_Y
		echo -e "$Yellow固件名称:$Blue$AB_Firmware"
		Size=$(awk 'BEGIN{printf "%.2fMB\n",'$((`ls -l $AB_Firmware | awk '{print $5}'`))'/1000000}')
		echo -e "$Yellow固件大小:$Blue$Size$White"
		MD5=`md5sum $AB_Firmware | cut -d ' ' -f1`
		SHA256=`sha256sum $AB_Firmware | cut -d ' ' -f1`
		Say="\nMD5:$MD5\nSHA256:$SHA256" && Color_G
		echo -e "编译日期:$Compile_Started\n固件大小:$Size\n" > $Firmware_Detail
		echo -e "MD5:$MD5\nSHA256:$SHA256" >> $Firmware_Detail
	else
		Say="\n编译失败!" && Color_R
	fi
;;
Multi_Profile)
	Compile_Stopped
	Say="\n编译结束!" && Color_B
;;
esac
Enter
}

X86_Images_Check() {
	cd $Home/Projects/$Project
	source $Home/Additional/X86_IMAGES
	egrep -e "IMAGES*=y" -e "IMAGES_GZIP=y" -e "ROOTFS_SQUASHFS=y" .config > $Home/TEMP/X86_IMAGES
	source $Home/TEMP/X86_IMAGES
	touch $Home/TEMP/Choosed_FI
	Firmware_INFO=openwrt-$TARGET_BOARD-$TARGET_SUBTARGET-$TARGET_PROFILE
	if [ ! $CONFIG_TARGET_ROOTFS_SQUASHFS == n ];then
		if [ $CONFIG_GRUB_IMAGES == y ];then
			[ $CONFIG_ISO_IMAGES == y ] && echo "$Firmware_INFO-image.iso" >> $Home/TEMP/Choosed_FI
			[ $CONFIG_VDI_IMAGES == y ] && echo "$Firmware_INFO-squashfs-combind.vdi" >> $Home/TEMP/Choosed_FI
			[ $CONFIG_VMDK_IMAGES == y ] && echo "$Firmware_INFO-squashfs-combind.vmdk" >> $Home/TEMP/Choosed_FI
			if [ $CONFIG_TARGET_IMAGES_GZIP == y ];then
				echo "$Firmware_INFO-squashfs-combind.img.gz" >> $Home/TEMP/Choosed_FI
				echo "$Firmware_INFO-squashfs-rootfs.img.gz" >> $Home/TEMP/Choosed_FI
			fi
		fi
		if [ $CONFIG_GRUB_EFI_IMAGES == y ];then
			[ $CONFIG_ISO_IMAGES == y ] && echo "$Firmware_INFO-image-efi.iso" >> $Home/TEMP/Choosed_FI
			[ $CONFIG_VDI_IMAGES == y ] && echo "$Firmware_INFO-squashfs-combind-efi.vdi" >> $Home/TEMP/Choosed_FI
			[ $CONFIG_VMDK_IMAGES == y ] && echo "$Firmware_INFO-squashfs-combind-efi.vmdk" >> $Home/TEMP/Choosed_FI
			[ $CONFIG_TARGET_IMAGES_GZIP == y ] && echo "$Firmware_INFO-squashfs-combind-efi.img.gz" >> $Home/TEMP/Choosed_FI
		fi
	fi
}

Checkout_Package() {
	cd $Home/Projects/$Project
	Say="\n检出[dl]库到'$Home/Backups/dl'..." && Color_Y
	awk 'BEGIN { cmd="cp -ri ./dl/* ../../Backups/dl/"; print "n" |cmd; }' > /dev/null 2>&1
	Say="检出软件包到'$Home/Packages'..." && Color_Y
	cd $Home/Packages
	mkdir -p $TARGET_ARCH_PACKAGES
	Packages_Dir=$Home/Projects/$Project/bin
	cp -a $(find $Packages_Dir/packages -type f -name "*.ipk") ./$TARGET_ARCH_PACKAGES
	mv -f $(find ./$TARGET_ARCH_PACKAGES/ -type f -name "*all.ipk") ./
}

GET_TARGET_INFO() {
	rm -rf $Home/TEMP/* > /dev/null 2>&1
	CPU_TEMP=`sensors | grep 'Core 0' | cut -c17-24`
	[ -z $CPU_TEMP ] && CPU_TEMP=0
	cd $Home/Projects/$Project
	grep "CONFIG_TARGET_x86=y" .config > /dev/null 2>&1
	if [ ! $? -ne 0 ]; then
		Firmware_Type=x86
	else
		Firmware_Type=Common
	fi
	TARGET_BOARD=`awk -F'[="]+' '/TARGET_BOARD/{print $2}' .config | awk 'NR==1'`
	grep 'TARGET_BOARD' .config > /dev/null 2>&1
	if [ ! $? -eq 0 ];then
		DEFCONFIG=1
	else
		DEFCONFIG=0
	fi
	TARGET_SUBTARGET=`awk -F'[="]+' '/TARGET_SUBTARGET/{print $2}' .config`
	TARGET_PROFILE=`grep '^CONFIG_TARGET.*DEVICE.*=y' .config | sed -r 's/.*DEVICE_(.*)=y/\1/'`
	TARGET_ARCH_PACKAGES=`awk -F'[="]+' '/TARGET_ARCH_PACKAGES/{print $2}' .config`
	grep '^CONFIG_TARGET.*DEVICE.*=y' .config | sed -r 's/.*DEVICE_(.*)=y/\1/' > $Home/TEMP/TARGET_PROFILE
	PROFILE_MaxLine=`sed -n '$=' $Home/TEMP/TARGET_PROFILE`
	[ -z $PROFILE_MaxLine ] && PROFILE_MaxLine=0
}

BuildFirmware_Check() {
if [ ! -f $Home/Projects/$Project/.config ];then
	Say="\n未检测到[.config]文件,无法编译!" && Color_R
	sleep 3
else
	BuildFirmware_UI
fi
}

Compile_Stopped() {
	Compile_Ended=`date +'%Y-%m-%d %H:%M:%S'`
	Start_Seconds=`date -d "$Compile_Started" +%s`
	End_Seconds=`date -d "$Compile_Ended" +%s`
	let Compile_Cost=($End_Seconds-$Start_Seconds)/60
	Say="\n$Compile_Started --> $Compile_Ended 编译用时:$Compile_Cost分钟" && Color_G
}
