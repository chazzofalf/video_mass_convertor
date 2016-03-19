#!/bin/bash
# This is a work in progress and work is still being done for the auto configuration functions so they do not work yet.
# In order for this to be used FFMpeg and GNU Screen must be installed and environment variable $conv_daemon_conf must set and point to an ini file of this format
# This looks like this. SHOUTED words are values you must set yourself.
# cat $conv_daemon_conf
# [Configuration]
# input=BASE_DIRECTORY_FOR_UNCONVERTED_VIDEOS
# output=BASE_DIRECTORY_FOR_CONVERTED_VIDEOS
# convconf=FILE_PATH_FOR_FFMPEG_CONVERSION_CONFIGURATION #more on this to come shortly
# dlfoldr=NAME_OF_FOLDER_FOR_VIDEOS_BEING_COPIED_FROM_A_REMOTE_SOURCE #prevents ffmpeg from touching files that are currently being downloaded. Move the files yourself have some other process do it.

# For the $convconf file this is the format. Note SHOUTS are descriptions of what should go there not literal text.

# [CONVERSION_INPUT_FOLDER_NAME_ONE]
# inputflags=FFMPEG_INPUT_ARGUMENTS
# outputflags=FFMPEG_OUTPUT_ARGUMENTS
# ext=FILE_EXTENSION_FOR_OUTPUT_FILES 
# BLANK_LINE
# [CONVERSION_INPUT_FOLDER_NAME_TWO]
# inputflags=FFMPEG_INPUT_ARGUMENTS
# outputflags=FFMPEG_OUTPUT_ARGUMENTS
# ext=FILE_EXTENSION_FOR_OUTPUT_FILES
# BLANK_LINE
# ...
# [LAST_CONVERSION_INPUT_FOLDER_NAME]
# inputflags=FFMPEG_INPUT_ARGUMENTS
# outputflags=FFMPEG_OUTPUT_ARGUMENTS
# ext=FILE_EXTENSION_FOR_OUTPUT_FILES
# BLANK_LINE

export input
export output
export donefldr
export convconf
export dlfldr

run_generic() #NECESSARY
{
	local inputflags
	local outputflags
	local inputFile
	local outputFile
	local cmd
	inputflags="$1"
	outputflags="$2"
	inputFile="$3"
	outputFile="$4"
	cmd="ffmpeg $inputflags -i \"$inputFile\" $outputflags \"$outputFile\""
	echo "$cmd"
	eval "$cmd"
#	if [ ! -d "$input"/"$donefldr" ]
#	then
#		mkdir "$input"/"$donefldr"
#	fi
#	mv "$inputFile" "$input"/"$donefldr"/
	rm "$inputFile"
}
load_main_configuration() #NECESSARY
{
#	echo "configuration file is $conv_daemon_conf"
#	return 0
	local inisection
	local key
	local value
	local cmd
	local conf_line
	local conf_line_length
	inisection=""
	if [ -z "$conv_daemon_conf" ]
	then
		return 1
	else
		cat "$conv_daemon_conf" | while read conf_line
		do
#			echo "line: $conf_line"
			conf_line_length=${#conf_line}
			if [[ ${conf_line:0:1} == "[" && ${conf_line:$((conf_line_length-1)):1} == "]" ]]
			then
				inisection="${conf_line:1:$conf_line_length-2}"
#				echo "inisection is $inisection"
			else
				if [[ "$inisection" == "Configuration" ]]
				then
					key="`echo $conf_line | cut -d\= -f 1`"
					value="`echo $conf_line | cut -d\= -f 2`"
					cmd="$key=\"$value\""
					if [ ! -z "$key" ]
					then
                                            echo "$cmd"
                                        fi
					eval "$cmd"
				else
					return 1
				fi
			fi
		done
		return 0
	fi
}
read_conv_conf_line_by_line() #NECESSARY
{
#	echo "$convconf"
#	return 0
	local foldersection
	local outputflags
	local inputflags
	local ext
	local key
	local value
	local cmd	
	cat "$convconf" | while read convconf_line
	do
		convconf_line_length=${#convconf_line}
#		echo $convconf_line_length
#		return 0
                       	if [ -z "$convconf_line" ]
			then
				if [ -z "$foldersection" ]
				then
					echo "Ignoring blank folder section"
				else
					if [ -z "$ext" ] 
					then
						echo "Ignoring folder section with no specified file extension. Sorry\!"
					else
						if [[ ! -d "$input"/"$foldersection" ]]
						then
							mkdir "$input"/"$foldersection"
						fi
						if [[ ! -d "$output"/"$foldersection" ]]
						then
							mkdir "$output"/"$foldersection"
						fi
						for f in "$input"/"$foldersection"/*
						do
							if [ -f "$f" ]
							then                                                                     
                                                            run_generic "$inputflags" "$outputflags" "$f" "$output"/"$foldersection"/"`echo $f | rev | cut -d/ -f 1 | cut -d. -f 2- | rev`"."$ext"                                                            
							fi
						done						
						
					fi
				fi				
			elif [[ "${convconf_line:0:1}" == "[" && "${convconf_line:$((convconf_line_length-1)):1}" == "]" ]]
                        then
                                foldersection="${convconf_line:1:$((convconf_line_length-2))}"
				echo "folder section : $foldersection"
				#return 0
			else
				key="`echo $convconf_line | cut -d\= -f 1`"
				value="`echo $convconf_line | cut -d\= -f 2`"
				cmd="$key=\"$value\""
				#echo "$cmd"
                                if [ ! -z "$key" ]
                                then                                
                                    eval "$cmd" 2> /dev/stdout
                                fi
			fi
	done
}
main_piped() #NECESSARY
{
	echo test > out
	main 2> /dev/stdout | tee conv_damon_`date +%Y%m%d_%H%M%S`.log
}
main() #NECESSARY
{
        
#	load_main_configuration
#	return 0
	cmd="`load_main_configuration`"	
	eval "$cmd"

	if [ ! -d "$input"/"$dlfldr" ]
	then
		mkdir "$input"/"$dlfldr"
	fi
#	export
#	return 0
	flagvalue=$?
	if [ $flagvalue -eq 0 ]
	then
		while true
		do
                        
			read_conv_conf_line_by_line
			sleep 1
		done
	fi

}
daemon() #NECESSARY
{
	screen -dmS "conv_daemon_$RANDOM" bash -c "main_piped"
}
helpMe() #NECESSARY
{
	echo "Before you run this make sure you have ffmpeg and screen installed on your system and they are in its \$PATH."
	echo "$0 invocation guide"
        echo
        echo "Show this helpful text:"
        echo "$0 --help"
        echo
        echo "Run the daemon:"
        echo "conv_daemon_conf=\$conv_daemon_conf $0"
        echo
        echo "Generate a conversion configuration file (Hint do this first):"
        echo "$0 --genconv"
        echo   
        echo "Generate a main configuration file (Hint do this second):"
        echo "$0 --genconfig"
        echo        
        echo "Generate a wrapper for easy execution (Hint do this last):"
        echo "$0 --genwrapper"
        echo
        echo "Give a shout out to Charles Montgomery"
        echo "http://www.github.com/chazzofalf"
        echo "chazzofalf@gmail.com"
        echo
        echo "Do you have any questions, suggestions, ideas, or problems with running this? Contact Me."
	echo "Have a nice day!"
}
generateConversionConfiguration() #NECESSARY
{
    local convfldrname
    local ffmpegInArgs
    local ffmpegOutArgs
    local fileExt
    local convConfFile
    local continueAllowed
    continueAllowed="y"
    echo -n "Where do you want to put the conversion configuration file?: "
    read convConfFile
    if [ -f "$convConfFile" ]
    then
        echo "$convConfFile already exists. Continuing will force it to be removed."
        echo "Do you want to continue? [y/N]: "
	read continueAllowed
	if [ -z "$continueAllowed" ]
	then
            continueAllowed="n"
	fi
    fi
    if [ "$continueAllowed" == "y" ]
    then
        if [ -f "$convConfFile" ]
        then
            rm "$convConfFile"
        fi
    
        while [ "$continueAllowed" == "y" ]
        do        
            echo -n "What is the name of the conversion folder?: "
            read convfldrname
            echo -n "Specify the input arguments for ffmpeg for files in this folder (Do not specify the -i for this will be done automatically during conversion): "
            read ffmpegInArgs
            echo -n "Specify the output arguments for ffmpeg for file in this folder (Do not specify the output file for this is also done automatically during conversion): "
            read ffmpegOutArgs
            echo -n "Specify the file extension for ffmpeg to use for this file. (Example: MPEG4 files use mp4,m4v, or m4a depending on content): "
            read fileExt
            echo "[$convfldrname]" >> "$convConfFile"
            echo "inputflags=$ffmpegInArgs" >> "$convConfFile"
            echo "outputflags=$ffmpegOutArgs" >> "$convConfFile"
            echo "ext=$fileExt" >> "$convConfFile"
            echo >> "$convConfFile"
            echo -n "Do you want to specify another conversion folder option? [y/N]: "
            read continueAllowed
        done
    fi
}
generateMainConfiguration() #NECESSARY
{
    local inputBasePath
    local outputBasePath
    local convConfPath
    local dlfldrname
    local confFile
    local continueAllowed
    continueAllowed="y"
    echo -n "Where do you want to put the main configuration file?: "
    read confFile
    if [ -f  "$confFile" ]
    then
        echo "$confFile alread exists. Continuing will force it to be removed."
        echo -n "Do you want to continue? [y/N]: "
        read continueAllowed
        if [ -z "$continueAllowed" ]
        then
            continueAllowed="n"
        fi            
    fi
    if [ "$continueAllowed" == "y" ]
    then
        if [ -f "$confFile" ]
        then
            rm "$confFile"
        fi
        echo -n "Where is general location for videos that are going to be converted?: "
        read inputBasePath
        echo -n "Where are the converted videos going to go?: "
        read outputBasePath
        echo -n "Where is the conversion configuation file located?: "
        read convConfPath
        echo -n "What is the name of the staging/download directory?: "
        read dlfldrname
        echo "[Configuration]" > "$confFile"
        echo "input=$inputBasePath" >> "$confFile"
        echo "output=$outputBasePath" >> "$confFile"
        echo "convconf=$convConfPath" >> "$confFile"
        echo "dlfldr=$dlfldrname" >> "$confFile"
        echo >> "$confFile"
    fi
}
generateWrapper() #NECESSARY
{
    local wrapperPath
    local confPath
    local fmcPath
    local continueAllowed
    continueAllowed="y"
    echo -n "Where will the wrapper be placed?: "
    read wrapperPath
    if [ -f "$wrapperPath" ]
    then
        echo -n "$wrapperPath already exists. Do you want to overwrite? [y/N]: "
        read continueAllowed
        if [ -z "$continueAllowed" ]
        then
            continueAllowed="n"
        fi   
    fi
    if [ "$continueAllowed" == "y" ]
    then
        echo -n "Where is the configuration file?: "
        read confPath
        fmcPath="$0"
        echo "#!/bin/bash" > "$wrapperPath"
        echo "conv_daemon_conf=\"$confPath\" \"$fmcPath\"" >> "$wrapperPath"
        chmod +x "$wrapperPath"
        
    fi
}
export -f run_generic
export -f main
export -f daemon
export -f load_main_configuration
export -f read_conv_conf_line_by_line
export -f main_piped
argc=$#
if [ $argc -eq 0 ]
then
	daemon
elif [ $argc -eq 1 ]
then
	if [ "$1" == "--help" ]
	then
            helpMe
        elif [ "$1" == "--genconv" ]
        then
            generateConversionConfiguration
        elif [ "$1" == "--genconfig" ]
        then
            generateMainConfiguration
        elif [ "$1" == "--genwrapper" ]
        then
            generateWrapper
	fi
fi
