#!/bin/bash

#this is the folder where all of our Diaries got stored
path=~/Diaries

welcome_screen(){
dialog --backtitle "Welcome Page" --colors --title "WELCOME" --msgbox "AUTHORS\n
\Zb——————————————————————\Zn\n
\ZbCem Özcan\Zn     20170601024\n
\ZbBuluthan İnan\Zn 20180601022\n
\ZbKaya Oğuz\Zn     Supervisor\n\n
ABOUT PROJECT\n
\Zb——————————————————————\Zn\n
Diary project is done under the course named CE 350 Linux Utilities and Shell Scripting. It is an simple program where a user
can save, edit and delete their diaries as they desire. Files are protected with password chosen by the User.\n\n
FUNCTIONS\n
\Zb——————————————————————\Zn\n
            \ZuHome Page\ZU\n
1)\ZbENTER\Zn\n
If given input is correct opens the selected zipped diary.(Prompts password secreen).\n
2)\ZbCreate New Diary\Zn\n
User can create new Diary with their selected password and name.\n
3)\ZbExit\Zn\n
Exits program.\n
4)\ZbDelete\Zn\n
Deletes the given diary.\n\n

            \ZuDiary Content\ZU\n
1)\ZbOk\Zn\n
Shows the content of selected date folder.\n
2)\ZbCreate Entry\Zn\n
Prompts entry creation page with date picker.\n
3)\ZbGo Home\Zn\n
Diary folder gets zipped. Redirects to Home Page .\n
4)\ZbSearch\Zn
Prompts search screen to get word that is going to be searched throughout diary.\n\n

             \ZuDate Content\ZU\n
1)\ZbOk\Zn\n
Shows selected entry.\n
2)\ZbCreate Entry\Zn\n
Prompts entry creation page without date picker.\n
3)\ZbGo Back\Zn\n
Redirects to Diary Content.\n\n
" \
0 0
home 
}

create_main_folder(){
	#check if Diaries exists else create
	if  [ ! -d "$path" ]
	then
		mkdir "$path"
	fi
}

create_diary(){

#nof number of
#check if foldername is existing, if it is- check how many then add +1 to that count and select as a new diary name
nof_whoami=$(find "$path"/$(whoami)* -maxdepth 1 | wc -l)
folder_name="$(whoami)${nof_whoami// }"

dialog --yesno "Your Dairy folder name is automatically selected as '$folder_name'\n
If you accept please select 'Yes'\nelse select 'No'" 15 25
local result=$?

#if answer is yes select automatically picked name
if [[ $result == 0 ]]
then
	dialog --infobox "Chosen folder name: '$folder_name'\nCreating diary folder ($folder_name) " 10 45;sleep 2
else
	#till input name is not empty ask for a folder name
	input_name=""
	while [[ -z ${input_name// } ]];
	do
		local input_name

		input_name=`$fdialog --colors --inputbox "Please enter your Diary folder name:\n\Z1Empty answers are not accepted\Zn" 10 25 3>&1 1>&2 2>&3 3>&-`
		local exitcode=$?
		
		case $exitcode in
			0)#ok
				if [ -z "$input_name" ]
				then
					dialog --pause "Please enter a valid name." 15 25 3
				else
					folder_name=${input_name// }
					
					if [ -f "$path/$input_name".zip ]
					then
						dialog --colors --pause "\Z1This file name exists.\Zn Please choose another name." 10 35 3
						input_name="" 
					fi

				fi
				;;
			1)#cancel
				home
				;;
		esac

	done
		
fi
		
	folder_password=""
	while [[ -z ${folder_password// } ]];
do
	folder_password=$(dialog --colors \
		 --passwordbox "Please enter your Diary password:\n\Z1Empty answers are not accepted\Zn" \
	 	10 25 \
		3>&1 1>&2 2>&3 3>&-)
	local exit_status=$?
	#remove spaces
	folder_password=${folder_password// }
	case "$exit_status" in
		0)#ok
			if [ -z "$folder_password" ]
			then
				echo "entered empty input try again"
				dialog --colors --pause "\Z1Entered a empty answer.\ZnPlease try again." 15 25 3
			else
			
				mkdir "$path"/$folder_name
				show_diary_content
			fi
			;;
		1)#cancel 	
			home ;;
	esac
done
}


home(){
	create_main_folder
			
	declare  -a diary_names=$(ls "$path")
	
	#ENTER
	#EXIT 1
	#CREATE NEW DIARY 3

	#for every available diaries add number next to it and show	
	user_input=$(dialog --colors \
	--backtitle "HOME PAGE" \
	--cancel-label 'EXIT' \
	--ok-label 'ENTER' \
	--clear \
	--extra-button --extra-label 'Create New Diary'\
	--help-button --help-label "Delete Diary"\
	--inputbox "Available diaries are listed below. Please enter the name of the diary you would like to access. \n 
	\Zb$(awk '{print "\\n"++i, $0}' <<<"${diary_names[@]}")\ZB" 0 0 \
	3>&1 1>&2 2>&3 3>&-)

	func_exit_code=$?
	case $func_exit_code in
    		0 )#ENTER
			check_exists $user_input ;;
    		1 )#EXIT
        		exit ;;
		2 )#Delete Diary
			delete_diary $user_input ;;
		3 )#Create New Diary
			create_diary ;;	
	esac
	
}

delete_diary(){
	
	local zip_name=$1
	local dir_path="$path/$zip_name"
	
	if [ -z $zip_name ]
	then
		dialog --colors --pause "\Z1EMPTY INPUT!\ZnRedirecting to Home Page." 15 25 3
		home
	elif [ -f $dir_path ]
	then
		
		local folder_password1=$(dialog --nocancel --passwordbox "Please enter the password for file $file_name" 0 0 3>&1 1>&2 2>&3 3>&-)
			
		
		unzip -P "$folder_password1" "$path/$zip_name" -d "$path/"
		local exit_code=$?
		
		local deleting_file_name=$(awk -F'.' '{print $1}' <<< $zip_name)
		rm -r "$path/$deleting_file_name"

		if [[ $exit_code == 0 ]] #if password is true
		then
			dialog --colors --pause "\ZbDeleting diary...\Zn" 15 25 3
			rm "$path/$zip_name"
			home
		else#returns 1 for wrong password
			dialog --colors --pause "\Zb Wrong password.\Zn\nRedirecting to Home Page..." 15 25 3
			home
		fi
		

	else
		dialog --colors --pause "No diary found. Redirecting to Home Page." 15 25 3
		home
	fi

}



check_exists(){

	local f=$1
	
	DIR="$path/$f"
	
	#if user input is empty refresh page 
	if [ -z $f ]
	then
		dialog --colors --infobox "\Z1EMPTY INPUT!\nRedirecting to previous page in 2 seconds.\Zn" 0 0; sleep 3
		home
		

	#if not exists go to previous page (home)
	elif ! [  -f  $DIR ]
	then
		dialog --colors \
		 --infobox "\Z1Directory do not exits!\nPlease be sure that you entered a valid name\nRedirecting to previous page in 2 seconds.\Zn" 0 0; sleep 3	
		home

	else 
		#delete .zip end of the string
		sliced_file_name=$(awk -F'.' '{print $1}' <<< $f)
		unzip_diaries $sliced_file_name
		folder_name=$sliced_file_name
		show_diary_content
	fi
}

show_diary_content(){
local txt=$(echo $(read_content "$path/$folder_name"))

if ! [ -z $txt ]
then
	local input
	input=`dialog --stdout --help-button --help-label "Search" --extra-button --extra-label "Create Entry" --backtitle "$folder_name Diary Contents" --cancel-label "Go Home" --menu "Select One" 0 0 0 $(echo $txt)`
	local exit_code=$?
	#user selects Go Home
	case $exit_code in
		1)#cancel
			zip_diaries $folder_password $folder_name
			home
			;;
		2)#search
			search	
			;;
		3)#create entry
			create_date_folder
			;;
		0)#ok
			#based on user input find the correlated file name in txt variable
			local selected_option=$(awk -v user_input="$input" '{for (I=1;I<NF;I++) if ( $I == user_input ) print $(I+1)}' <<< $txt)	
			local selected_path="$path/$folder_name/$selected_option"
			show_date_content $selected_path
			;;
	esac
else
	#if diary folder is empty go to date folder creation screen
	create_date_folder
fi
}
	
show_date_content(){
	#$1= ~/Diaries/"folder_name"/"selected_date"
	#txt can never be empty, since entry is always getting created by default
	local txt=$(echo $(read_content $1))	
	local input
	
	local date
	#take the date part from given path
	date=$(awk 'BEGIN{FS="/*/"} {print $6}' <<< $1)
	
	input=`dialog --stdout --cancel-label "Go Back" --extra-button --extra-label "Create Entry" --backtitle "$folder_name $date Contents" --menu "Select One" 0 0 0 $(echo $txt)`
	local exit_code=$?
	
	case "$exit_code" in
		1)#Go Back
			show_diary_content
			;;
		3)#Create Entry
			create_entry $1	
			;;
		*)$OK	
			#based on user input find the correlated file name in txt variable
			local selected_option=$(awk -v user_input="$input" '{for (I=1;I<NF;I++) if ( $I == user_input ) print $(I+1)}' <<< $txt) 
			local selected_path="$1/$selected_option"
			show_entry $selected_path
			;;
	esac
}

search(){
	local search_word	
	search_word=$(dialog --inputbox "Please enter a single word to search in this date folder!" 0 0 3>&1 1>&2 2>&3 3>&-)
	
	local exitcode=$?
	if [[ $exitcode == 1 ]] #cancel
	then	
		dialog --pause "Redirecting to previous page..." 15 25 3
		show_diary_content
	elif [[ $exitcode == 0 ]] #ok
	then
		#ignore case(i), match-exact-word(w), recursive-search(r), return-file-name(l) 
		results=$(grep -lriw "$search_word" "$path/$folder_name" | awk '{print v++,$0}')
		if [[ -z $results ]]
		then
			dialog --colors --pause "There is no match! Word: \Z1$search_word\Zn.Redirecting to previous page..." 15 25 3
			show_diary_content
			else
				local input
				input=`dialog --stdout --colors --menu "Here are the results of search for word: \Zb$search_word\Zn" 0 0 5 $results`
				local exit_status=$?

				case $exit_status in
					1)#cancel
						show_diary_content
						;;
					0)#ok show the content of selected txt
						local selected_option=$(awk -v user_input="$input" '{for (I=1;I<NF;I++) if ( $I == user_input ) print $(I+1)}' <<< $results)
						show_entry $selected_option
						;;

				esac
			fi
		fi

	

}



read_content(){
	#return available folder names based on given file name
	let local i=0
	local txt=""
 
	local f_name=$1

	#save all the file contents in txt variable
	for k in $( ls $f_name)
	do
   		((i++))
   		txt="$txt $i $k "
	done
	echo $txt
}

zip_diaries(){
	local f_password=$1
	local f_name=$2	
	
	#zip files but ignore unwanted pathing	
	pushd ~/Diaries
	zip --password $f_password -r "$f_name".zip "$f_name"
	rm -r $f_name/
	popd			
}

unzip_diaries(){
	local file_name=$1
		
	#ask for password
        folder_password=$(dialog --nocancel --passwordbox "Please enter the password for file $file_name" 0 0 3>&1 1>&2 2>&3 3>&-)

	#unzip files
	pushd ~/Diaries
	unzip -P $folder_password "$file_name".zip
	local exit_code=$?
	popd
	if [[ $exit_code == 0 ]]
	then	
		dialog --nocancel --colors --pause "\Z2Correct password!\Zn Entering $file_name" 13 30 3
		rm -r "$path"/"$file_name".zip
	else
		rm -r "$path"/$file_name
		dialog --colors --nocancel --pause "\ZbYou have entered a wrong password.\Zn Please try again" 15 20 3
		unzip_diaries $file_name
	fi
	echo $exit_code
}

show_entry(){
	local entry_path="$1"
	#get day-month-year info
	local dmy=$(awk 'BEGIN{FS="/*/"} {print $6}' <<< $entry_path)
	local hour=$(awk 'BEGIN{FS="/*/"} {print $7}' <<< $entry_path)
	new_entry=$(dialog --backtitle "$folder_name/$dmy/$hour" --nocancel --editbox $entry_path 0 0 3>&1 1>&2 2>&3 3>&-)
	echo $new_entry > $entry_path
	
	show_date_content "$path/$folder_name/$dmy"
}


create_date_folder(){
	local l_path="$path/$folder_name"
	local choice=$(dialog --clear --stdout \
	--backtitle "Date Selection" \
	--nocancel  \
	--menu "Select one of the following options: " 0 0 0 \
	1 "Create Using Current Date" 2 "Create Using Another Date") 
		
	case $choice in
		1)#Create using Current Date
			local current_date="$(date +'%d-%m-%Y')"	
			local folder_path="$l_path/$current_date"			
			
			if [ ! -d "$folder_path" ]
			then
				mkdir "$folder_path"
				create_entry $folder_path
				
			else
				dialog --nocancel --pause "Selected  date already exists as a Folder, redirecting...." 20 30 3
				create_entry $folder_path
			fi	
			;;
		2)#Create Using Another Date
			pick_date
			;;
	esac
}




pick_date(){
	local selected_date=$(dialog --title "Calendar" \
	--no-cancel \
	--backtitle "Date Selection" \
	--calendar "Please choose a date" \
	0 0 3>&1 1>&2 2>&3 3>&-)
	
	#date is current taken from user in DD/MM/YYYY format but we need to conver it to YYYY-MM-DD so that we can do basic comparison
	local selected_date_converted=$(awk 'BEGIN{FS="/*/"} {print $3"-"$2"-"$1}' <<< $selected_date)	
	local current_date=$(date +'%Y-%m-%d')

	#check if the selected date is in future
	if [[ "$selected_date_converted" > "$current_date" ]]
	then
		dialog --nocancel \
		--colors \
		--backtitle "Wrong Date Selection" \
		--pause "\ZbPlease do not pick future dates! " \
		11 20 3
		pick_date
	else
		#change '/' with '-' since our format is written like that
		local formatted_date=$(awk 'BEGIN{FS="/*/"} {print $1"-"$2"-"$3}' <<< $selected_date)
		
		if [ ! -d "$path/$folder_name/$formatted_date" ]
		then
			mkdir "$path/$folder_name/$formatted_date"
			create_entry "$path/$folder_name/$formatted_date"
		else
			show_date_content "$path/$folder_name/$formatted_date" 
		fi
	fi
}


create_entry(){
	local current_hour=$(date +'%H-%M-%S')
	local txt_name="$current_hour".txt
	local date_folder_path=$1
	
	#create new entry txt file	
	touch "$date_folder_path/$txt_name"	
			
	#enter newly created txt
	show_entry "$date_folder_path/$txt_name"
}
welcome_screen
