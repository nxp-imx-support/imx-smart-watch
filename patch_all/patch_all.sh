#!/bin/bash
# SPDX-License-Identifier: BSD-3

SHELL_NAME=$0
SHELL_NAME=${SHELL_NAME##*/}
echo "Shell name: $SHELL_NAME"

PWD=$(cd "$(dirname "$0")";pwd)
echo "Patch path: $PWD"

SDK_PATH=$MY_ANDROID
echo "SDK path: $SDK_PATH"

PRE_DIR=""

if [ -z ${SDK_PATH} ]; then
    echo "Please export MY_ANDROID according to i.MX Android User Guide. Then do patch_all.sh";
    exit;
fi

function do_patch(){
    local abs_file=$1;
    local rel_file=${abs_file#$PWD};
	local file_name=${abs_file##*/};
	local rel_dir=${rel_file%/*};
    local ret;
	
	if [[ ${rel_dir} != ${PRE_DIR} ]]; then
		PRE_DIR=${rel_dir};
		
		if [[ -s $2/${rel_dir}/.git ]]; then
			ret=`cd $2/${rel_dir} && git branch | grep default > /dev/null 2>&1`;
			if [ $? -ne '0' ]; then
				echo "> create \"default\" branch in ${rel_dir}";
				ret=`cd $2/${rel_dir} && git checkout -b default > /dev/null 2>&1`;
			fi
			ret=`cd $2/${rel_dir} && git checkout default > /dev/null 2>&1`;

			ret=`cd $2/${rel_dir} && git branch | grep test > /dev/null 2>&1`;
			if [ $? -eq '0' ]; then
				echo "> remove \"test\" branch in ${rel_dir}";
				ret=`cd $2/${rel_dir} && git branch -D test > /dev/null 2>&1`;
			fi
			echo "> create \"test\" branch in ${rel_dir}";
			ret=`cd $2/${rel_dir} && git checkout -b test > /dev/null 2>&1`;
		else
			echo "> enter ${rel_dir}";
		fi 
	fi
    
    cp $1 $2/$rel_file;
    if [ ${file_name##*\.} == "patch" ]; then
        ret=`cd $2/${rel_dir} && git apply --check $2/${rel_file} > /dev/null 2>&1`;
        if [ $? == '0' ]; then
            echo "  > patch ${rel_file}";
            ret=`cd $2/${rel_dir} && git am -3 --ignore-whitespace $2/${rel_file}`;
			if [ $? -ne '0' ]; then
				echo "=== !!! Patch err and stop !!! ===";
				exit 1
			fi
        else
            echo "  > skip ${rel_file}, maybe patched already";
        fi
        rm -rf $2/${rel_file};
    else
        echo "  > copy $rel_file";
    fi
}

function read_dir(){
    for file in `ls $1`
    do
        if [ -d $1"/"$file ]; then
            read_dir $1"/"$file $2;
        elif [ $file != $SHELL_NAME ]; then
            do_patch $1"/"$file $2;
        fi
    done
}

read_dir $PWD $SDK_PATH;
echo "=== !!! Patch succesfully !!! ===";
