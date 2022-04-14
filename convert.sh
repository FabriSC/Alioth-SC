#!/bin/bash
SCRIPTDIR=$(readlink -f "$0")
CURRENTDIR=$(dirname "$SCRIPTDIR")
TOOLS=$CURRENTDIR/tools
OUT=$CURRENTDIR/out
ZIP=$CURRENTDIR/zip
UNZIP=$CURRENTDIR/unzip
VERIFY=$CURRENTDIR/verify

# update linux
sudo apt update -y  >/dev/null; sudo apt upgrade -y  >/dev/null
sudo apt install zip unzip python3 brotli curl simg2img liblzma-dev liblz4-tool python3-pip img2simg simg2img python3-testresources -y  >/dev/null

# Requerimientos
pip3 --no-cache-dir install -r $TOOLS/requirements.txt  >/dev/null

# comenzando proceso
echo ". Comenzando proyecto"
mkdir out
mkdir verify
mkdir unzip
mkdir zip
cp -af rom/* zip; mkdir $ZIP/firmware-update
echo ". Descomprimiendo Archivo"

verifyzip=`ls *.zip | rev | cut -c 1,2,3 | rev`

if [[ "zip" = "$verifyzip" ]]; then
mv *.zip romsc.zip >/dev/null
else
mv *.tgz romsc.tgz >/dev/null
fi

if [[ -e $CURRENTDIR/romsc.zip ]]; then
unzip -d $VERIFY $CURRENTDIR/romsc.zip  >/dev/null
else
tar xzvf romsc.tgz
mv romsc/images/* $UNZIP
python3 $TOOLS/lu.py $UNZIP/super.img $UNZIP >/dev/null
mv $UNZIP/system_a.img $UNZIP/system.img >/dev/null
mv $UNZIP/system_ext_a.img $UNZIP/system_ext.img >/dev/null
mv $UNZIP/vendor_a.img $UNZIP/vendor.img  >/dev/null
mv $UNZIP/odm_a.img $UNZIP/odm.img  >/dev/null
mv $UNZIP/product_a.img $UNZIP/product.img  >/dev/null
rm -rf $UNZIP/super.img
fi

if [[ -e $VERIFY/images/super.img ]]; then
mv $VERIFY/images/* $UNZIP
python3 $TOOLS/lu.py $UNZIP/super.img $UNZIP >/dev/null
mv $UNZIP/system_a.img $UNZIP/system.img >/dev/null
mv $UNZIP/system_ext_a.img $UNZIP/system_ext.img >/dev/null
mv $UNZIP/vendor_a.img $UNZIP/vendor.img  >/dev/null
mv $UNZIP/odm_a.img $UNZIP/odm.img  >/dev/null
mv $UNZIP/product_a.img $UNZIP/product.img  >/dev/null
rm -rf $UNZIP/super.img
else
mv $VERIFY/* $UNZIP
fi

if [[ -e $UNZIP/payload.bin ]]; then
python3 $TOOLS/payload.py $UNZIP/payload.bin --out payload  >/dev/null
fi

echo ". unzip images"
python3 $TOOLS/imgextractor.py $UNZIP/system.img $OUT/system  >/dev/null
systemz=`du -sk $OUT/system/system | awk '{$1*=1024;$1=int($1*1.05);printf $1}'`
python3 $TOOLS/imgextractor.py $UNZIP/vendor.img $OUT/vendor  >/dev/null
vendorz=`du -sk $OUT/vendor/vendor | awk '{$1*=1024;$1=int($1*1.05);printf $1}'`
python3 $TOOLS/imgextractor.py $UNZIP/system_ext.img $OUT/system_ext  >/dev/null
system_extz=`du -sk $OUT/system_ext/system_ext | awk '{$1*=1024;$1=int($1*1.05);printf $1}'`
python3 $TOOLS/imgextractor.py $UNZIP/product.img $OUT/product >/dev/null
productz=`du -sk $OUT/product/product | awk '{$1*=1024;$1=int($1*1.05);printf $1}'`
python3 $TOOLS/imgextractor.py $UNZIP/odm.img $OUT/odm  >/dev/null
odmz=`du -sk $OUT/odm | awk '{$1*=1024;$1=int($1*1.05);printf $1}'`
echo ". Delete images"
cd $UNZIP
rm -rf  system.img vendor.img system_ext.img product.img odm.img payload.py requirements.txt update_payload payload.bin
mv boot.img $ZIP
mv abl.img $ZIP/firmware-update
mv aop.img $ZIP/firmware-update
mv bluetooth.img $ZIP/firmware-update
mv cmnlib.img $ZIP/firmware-update
mv cmnlib64.img $ZIP/firmware-update
mv devcfg.img $ZIP/firmware-update
mv dsp.img $ZIP/firmware-update
mv dtbo.img $ZIP/firmware-update
mv featenabler.img $ZIP/firmware-update
mv hyp.img $ZIP/firmware-update
mv imagefv.img $ZIP/firmware-update
mv keymaster.img $ZIP/firmware-update
mv modem.img $ZIP/firmware-update
mv qupfw.img $ZIP/firmware-update
mv tz.img $ZIP/firmware-update 
mv uefisecapp.img $ZIP/firmware-update
mv vbmeta.img $ZIP/firmware-update
mv vbmeta_system.img $ZIP/firmware-update
mv xbl.img $ZIP/firmware-update
mv xbl_config.img $ZIP/firmware-update

# Version
MIUIVERSION=$(grep ro.miui.ui.version.code= $OUT/system/system/system/build.prop | sed "s/ro.miui.ui.version.code=//g"; )
ROMANDROID=$(grep ro.build.version.release= $OUT/system/system/system/build.prop | sed "s/ro.build.version.release=//g"; )
ROMBUILD=$(grep ro.build.id= $OUT/system/system/system/build.prop | sed "s/ro.build.id=//g"; )

# dfe
echo ". delete encryptation"
sed -i "s/fileencryption=/encryptable=ice:/g" $OUT/vendor/vendor/etc/fstab.qcom
echo ". creando images"
cd $OUT/system
$TOOLS/mkuserimg_mke2fs.sh "system" "system.img" "ext4" "/system" $systemz -j "0" -T "1230768000" -C "config/system_fs_config" -L "system" -I "256" -M "/system" -m "0" "config/system_file_contexts"  >/dev/null
mv system.img $OUT
rm -rf ../system
cd $OUT/vendor
$TOOLS/mkuserimg_mke2fs.sh "vendor" "vendor.img" "ext4" "/vendor " $vendorz  -j "0" -T "1230768000" -C "config/vendor_fs_config" -L "vendor" -I "256" -M "/vendor" -m "0" "config/vendor_file_contexts" >/dev/null
mv vendor.img $OUT
rm -rf ../vendor
cd $OUT/system_ext
$TOOLS/mkuserimg_mke2fs.sh "system_ext" "system_ext.img" "ext4" "/system_ext" $system_extz -j "0" -T "1230768000" -C "config/system_ext_fs_config" -L "system_ext" -I "256" -M "/system_ext" -m "0" "config/system_ext_file_contexts"  >/dev/null
mv system_ext.img $OUT
rm -rf ../system_ext
cd $OUT/product
$TOOLS/mkuserimg_mke2fs.sh "product" "product.img" "ext4" "/product" $productz -j "0" -T "1230768000" -C "config/product_fs_config" -L "product" -I "256" -M "/product" -m "0" "config/product_file_contexts"  >/dev/null
mv product.img $OUT
rm -rf ../product
cd $OUT/odm
$TOOLS/mkuserimg_mke2fs.sh "odm" "odm.img" "ext4" "/odm" $odmz -j "0" -T "1230768000" -C "config/odm_fs_config" -L "odm" -I "256" -M "/odm" -m "0" "config/odm_file_contexts"  >/dev/null
mv odm.img $OUT
rm -rf ../odm
cd $OUT
echo ". configs dynamic list"
systemop=`du -b system.img | awk '{print $1}'`
sed -i "s/systemop/$systemop/g" $ZIP/dynamic_partitions_op_list
system_extop=`du -b system_ext.img | awk '{print $1}'`
sed -i "s/system_extop/$system_extop/g" $ZIP/dynamic_partitions_op_list
vendorop=`du -b vendor.img | awk '{print $1}'`
sed -i "s/vendorop/$vendorop/g" $ZIP/dynamic_partitions_op_list
productop=`du -b product.img | awk '{print $1}'`
sed -i "s/productop/$productop/g" $ZIP/dynamic_partitions_op_list
odmop=`du -b odm.img | awk '{print $1}'`
sed -i "s/odmop/$odmop/g" $ZIP/dynamic_partitions_op_list
echo ". rw-sparse images"
img2simg system.img systemrw.img; rm -rf system.img
img2simg product.img productrw.img; rm -rf product.img
img2simg system_ext.img system_extrw.img; rm -rf system_ext.img
img2simg vendor.img vendorrw.img; rm -rf vendor.img
img2simg odm.img odmrw.img; rm -rf odm.img
echo ". sparse a dat"
$TOOLS/img2sdat/img2sdat.py -v 4 -o $ZIP -p system systemrw.img  >/dev/null
$TOOLS/img2sdat/img2sdat.py -v 4 -o $ZIP -p system_ext system_extrw.img  >/dev/null
$TOOLS/img2sdat/img2sdat.py -v 4 -o $ZIP -p vendor vendorrw.img  >/dev/null
$TOOLS/img2sdat/img2sdat.py -v 4 -o $ZIP -p product productrw.img >/dev/null
$TOOLS/img2sdat/img2sdat.py -v 4 -o $ZIP -p odm odmrw.img  >/dev/null
rm -rf $OUT/*

# brotli
cd $ZIP
echo ". convertiendo images a br"
brotli -j -v -q 6 system.new.dat
brotli -j -v -q 6 system_ext.new.dat
brotli -j -v -q 6 vendor.new.dat
brotli -j -v -q 6 product.new.dat
brotli -j -v -q 6 odm.new.dat
echo ". Empaquetando"
zip -ry MIUI$MIUIVERSION-Alioth-$ROMBUILD-A$ROMANDROID-$1-SC.zip *  >/dev/null
mv MIUI$MIUIVERSION-Alioth-$ROMBUILD-A$ROMANDROID-$1-SC.zip $CURRENTDIR
echo "listo"
echo "Subiendo a Sourceforge....."
cd $CURRENTDIR
mv $TOOLS/uploadsf $CURRENTDIR
sudo bash $CURRENTDIR/uploadsf MIUI$MIUIVERSION-Alioth-$ROMBUILD-A$ROMANDROID-$1-SC.zip
 
