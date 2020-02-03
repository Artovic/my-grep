#!/usr/bin/env bash


declare -a sources
declare -a matches
IFS=""
params=($@)

line_numbers_status=1
print_only_names_status=1
case_insensitive_status=1
invert_output_status=1
match_whole_lines_status=1


is_expression_set=0
expression=""
nl=$'\n'

IFS=""
for param in "${params[@]}"
do

        [[ $param = "-n" ]] && line_numbers_status=0 &&  continue
        [[ $param = "-l" ]] && print_only_names_status=0 && continue
        [[ $param = "-i" ]] && case_insensitive_status=0 && continue
        [[ $param = "-v" ]] && invert_output_status=0 && continue
        [[ $param = "-x" ]] && match_whole_lines_status=0 && continue

        if (( is_expression_set == 0 ))
        then
                expression="$param"
                is_expression_set=1


        elif ! [[ -r $param ]]
        then
                echo 'Usage : grep <flags> "expression" files'
                exit 1;
        else
                sources+=( "$param"  )
        fi
done
validateFlags(){

        #$1 - line_numbers_status
        #$2 - print_only_names_status
        if [[ $1 = "true" ]] && [[ $2 = "true" ]]
        then
                echo "You can't use -n and -l in one command."
                exit 0;
        fi
}


match_comparison_status=""


function setMatchComparisonStatus (){

	#$1 - line
        line=$1

        #$2 - current index sign of line
        line_index=$2

        #$3 - expression index
        expression_index=$3

        current_line_sign=${line:$line_index:1}
        current_expression_sign=${expression:$expression_index:1}
	
	if (( $match_whole_lines_status == 0 )); then
		test "$line" = "$expression"

	elif (( $case_insensitive_status == 0 )); then

		# case insensitive variables
		current_line_sign_ignore_case_sensitive=${current_line_sign^^}
        	expression_line_sign_ignore_case_sensitive=${current_expression_sign^^}

		test "$current_line_sign_ignore_case_sensitive" = "$expression_line_sign_ignore_case_sensitive"
	else
		test "$current_line_sign" = "$current_expression_sign"
	fi

		match_comparison_status=$?
}


function prepareAndAddMatch (){
	#$1 - line number
	#$2 - source name
	#$3 - line to add
	
	match=""

	if (( $line_numbers_status == 0 )); then
		match+="$1:"
	fi



	if (( $print_only_names_status == 0 )); then

		match="$2"
	else
		match+=$3
	fi
	
	
	
	if (( $match_whole_lines_status == 0 )); then
		matches+=(["$line_number"]="$match")
	
	else
		matches+=("$match")
	fi
}





#main logic:

#iterate through data sources
source_number=1
for src in "${sources[@]}"
do
	validateFlags "$line_numbers_status" "$print_only_names_status"
	line_number=1

	#iterate through lines in txt
	while read line; do 

		# iterate through the every sign of line
		for (( i=0; i < ${#line}; i++ ))
                do
						
			# iterate through the every sign of expression
                        for (( j=0; j < ${#expression}; j++ ))
                        do	
				
				let index=$i+$j
				setMatchComparisonStatus "$line" "$index" "$j"
				if (( $invert_output_status == 1 )) && (( $match_comparison_status == 0 )) && (( j+1 == ${#expression} )); then 
					
					prepareAndAddMatch "$line_number" "$src" "$line"
				
				elif (( $invert_output_status == 1 )) && (( $match_comparison_status == 0 )); then
					continue
				else
					break
				fi

			done
		done
		(( line_number++  ))	
	done <<< `cat $src`
	
	line_number=1
        (( source_number++ ))
done

printf "%s\n" "${matches[@]}"


