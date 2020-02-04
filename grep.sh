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

match_comparison_status=""

function setMatchComparisonStatus (){

	#$1 - line
        line=$1

        #$2 - current index sign of line
        line_index=$2

        #$3 - expression index
        expression_index=$3


	compareable_expression=""
	compareable_source=""


	if (( $match_whole_lines_status == 0 )); then
		compareable_expression=$expression
		compareable_source=$line
	else
		compareable_source=${line:$line_index:1}
                compareable_expression=${expression:$expression_index:1}
	fi


	if (( $case_insensitive_status == 0 )); then
		compareable_expression=${compareable_expression^^}
		compareable_source=${compareable_source^^}
	fi
	
	if (( $invert_output_status == 0 )); then

		test ! $compareable_expression = $compareable_source
	else
	#	echo debug - to linia $line	
	#	echo debug - compareable source : $compareable_source
	#	echo debug - compareable expression :  $compareable_expression
	

	if [[ $compareable_expression = "" ]]
	then
		echo znalazłem wadliwe expression
	fi

	if [[ $compareable_source = "" ]]
        then
		
                echo znalazłem wadliwe source
        	echo line index jest wtedy $line_index
		echo długość lini natomiast ${#line}
	fi



		test $compareable_expression = $compareable_source 
	fi
	match_comparison_status=$?
}


function prepareAndAddMatch (){
	#$1 - line number
	#$2 - source name
	#$3 - line to add
	#$4 - source number
	#echo prepareMatchFunction: source_number: $4
	# Hierarchy of pushing to matches: 1.File names OR and only OR
	
	match=""

	
	



	if (( $print_only_names_status == 0 )); then
		matches+=(["$4"]="$2")
	else

		if (( ${#sources[@]} > 1 )); then
			match+="$2:"	
		fi

		if (( $line_numbers_status == 0 )); then
			match+="$1:"
		fi


	
			match+=$3
		if (( $match_whole_lines_status == 0 )); then
			matches+=(["$line_number"]="$match")
		else
			matches+=("$match")
		fi


	#	match+=$3
	fi


}





#main logic:

#iterate through data sources
source_number=1
for src in "${sources[@]}"
do
	line_number=1

	found_false_match_while_invert_output=1
	#iterate through lines in txt
	while read line; do 
		# iterate through the every sign of line
		for (( i=0; i < ${#line}; i++ ))
                do
			if (( $found_false_match_while_invert_output == 0 )); then
			  
				found_false_match_while_invert_output=1
				break
			fi
			# iterate through the every sign of expression
                        for (( j=0; j < ${#expression}; j++ ))
                        do	
				
				let index=$i+$j
				if (( $index >= ${#line} )); then
					break
				fi

				
				setMatchComparisonStatus "$line" "$index" "$j"
				# START OF INVERT OUTPUT SECTION
				if (( $invert_output_status == 0 )) && (( $match_comparison_status == 1 )) && (( j+1 == ${#expression} )); then
				
					found_false_match_while_invert_output=0
					break	
				elif (( $invert_output_status == 0 )) && (( $match_comparison_status == 0 )) && (( i + 1 == ${#line} )); then
					prepareAndAddMatch "$line_number" "$src" "$line" "$source_number"
					break
				elif (( $invert_output_status == 0 )) && (( $match_comparison_status == 0 )); then
					break
				elif (( $invert_output_status == 0 )) && (( $match_comparison_status == 1 )); then
					continue
				# END OF INVERT OUTPUT SECTION
				elif (( $match_comparison_status == 0 )) && (( j+1 == ${#expression} )); then 
					prepareAndAddMatch "$line_number" "$src" "$line" "$source_number"
				elif (( $match_comparison_status == 0 )); then
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


