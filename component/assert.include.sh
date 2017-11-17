#!/bin/bash
# NOTES
#	> Variables declared within the functions below are prefixed by 'asrt'.
#	This prefix acts as a namespace to avoid accidentially colliding with
#	variables that are passed to the assert functions.
#	> Function names with "assert__"... are considered private to this include
#	file - they should only be called by functions within it.

assert_REGEX_COMPARE='<RegEx>'

# assert_output functions accept only a single argument.  That argument, in most
# cases should be the name of a bash function that writes to sysout.  
assert_output_true(){
	assert__output_bool "$1" ' '
}
assert_output_false(){ 
	assert__output_bool "$1" '!'
}
assert__output_bool(){
	local -r asrtExpectedFn="$1"
	# execute expected function before defining many other
	# local variables to ensure generation function binds,
    # if it needs to, to variables declared outside the
	# scope of this function. 
	local asrtFDesc
	exec {asrtFDesc}< <( $asrtExpectedFn ) 
	local -r asrtNegate="$2"

	local asrtCompOper
	local asrtEval
	local asrtGenerated
	local asrtGeneratedCnt=0
	local asrtExpected
	local asrtExpectedCnt=0
	while read -r asrtGenerated; do
		((asrtGeneratedCnt++))
		if read -r -u $asrtFDesc asrtExpected; then
			((asrtExpectedCnt++))
		fi
		asrtCompOper='true'
		if [[ "${asrtExpected:0:${#assert_REGEX_COMPARE}}" == "$assert_REGEX_COMPARE" ]]; then
			asrtCompOper='false'
			asrtExpected="${asrtExpected:${#assert_REGEX_COMPARE}}"
		fi
		asrtEval='true'
		# need two different comparators statements: 
		#	1. Regex expressions, that appear in RHS of regex comparison,
	   	#	must not be encapsulated in quotes because if they are quoted,
		#	they are evaluated as just an ordnary string of characters.    
	    #	2. The equality operator requires both its operands encapsulated
	   	#	by double quotes to prevent certain characters like '[' and ']'
		#	from interferring with its evaluation.
		#	3. Finally, the LHS operand of a regex operator must also be
		#	quote encapulated for the very same reason the equality operator's
	   	#	LHS is encapsulted by quotes.
		if $asrtCompOper; then 
			eval $asrtNegate \[ \"\$asrtGenerated\" == \"\$asrtExpected\" \] \|\| asrtEval\=\'false\'
		else
			eval $asrtNegate \[\[ \"\$asrtGenerated\" =~ \$asrtExpected \]\] \|\| asrtEval\=\'false\'
		 fi
		 if ! $asrtEval; then
			eval exec $asrtFDesc\<\&\-
			echo "generated: '$asrtGenerated'">&2
			echo "expected:  '$asrtExpected'" >&2	
			return 1
		fi
	done
	while read -r -u $asrtFDesc; do
		((asrtExpectedCnt++))
	done
	eval exec $asrtFDesc\>\&\- 
	if [ $asrtGeneratedCnt -ne $asrtExpectedCnt ]; then 
		echo "generated lines $asrtGeneratedCnt != $asrtExpectedCnt expected lines" >&2
		return 1
	fi
	true
}
assert_true(){
	assert__bool "$1" ' '
}

assert_false(){
	assert__bool "$1" '!'
}

assert__bool(){
	local -r asrtExpression="$1"
	local -r asrtNegate="$2"

	if eval $asrtNegate $asrtExpression; then
		return
	fi
	# indirectly called from failing test :: use [2] to identify it.  
	echo "status='${FUNCNAME[1]} failed' func='${FUNCNAME[2]}' lineno=${BASH_LINENO[1]} source='${BASH_SOURCE[2]}'" >&2
	return 1
}
